import Foundation

enum SidecarExit: Equatable {
    case success
    case cancelled
    case failed(message: String)
}

enum SidecarRunner {
    static func bundledVoleURL() -> URL? {
        Bundle.main.url(forAuxiliaryExecutable: "vole")
            ?? Bundle.main.bundleURL
                .appendingPathComponent("Contents/MacOS/vole")
    }

    static func mapExitCode(_ code: Int32, stderr: String) -> SidecarExit {
        switch code {
        case 0: return .success
        case 130: return .cancelled
        default:
            let trimmed = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            return .failed(message: trimmed.isEmpty ? "vole exited with code \(code)" : trimmed)
        }
    }

    static func rulesEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let relative = Bundle.main.bundleURL
            .appendingPathComponent("Contents/share/vole/rules").path
        if FileManager.default.fileExists(atPath: relative) {
            env["VOLE_RULES_DIR"] = relative
        }
        return env
    }
}

private final class PipeAccumulator: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ chunk: Data) {
        lock.lock()
        defer { lock.unlock() }
        data.append(chunk)
    }

    var snapshot: Data {
        lock.lock()
        defer { lock.unlock() }
        return data
    }
}

private final class StdoutLineAccumulator: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = Data()
    private let onLine: @Sendable (String) -> Void

    init(onLine: @escaping @Sendable (String) -> Void) {
        self.onLine = onLine
    }

    func append(_ chunk: Data) {
        guard !chunk.isEmpty else { return }
        lock.lock()
        defer { lock.unlock() }
        buffer.append(chunk)
        drainCompleteLines()
    }

    func flushTrailing() {
        lock.lock()
        defer { lock.unlock() }
        guard !buffer.isEmpty else { return }
        if let line = String(data: buffer, encoding: .utf8), !line.isEmpty {
            onLine(line)
        }
        buffer.removeAll()
    }

    private func drainCompleteLines() {
        while let range = buffer.range(of: Data([0x0A])) {
            let lineData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
            buffer.removeSubrange(buffer.startIndex...range.lowerBound)
            if let line = String(data: lineData, encoding: .utf8), !line.isEmpty {
                onLine(line)
            }
        }
    }
}

actor VoleProcess {
    private var process: Process?

    func run(
        arguments: [String],
        onStdoutLine: @escaping @Sendable (String) -> Void
    ) async -> SidecarExit {
        guard let vole = SidecarRunner.bundledVoleURL() else {
            return .failed(message: "embedded vole binary missing; rebuild the app")
        }

        let proc = Process()
        proc.executableURL = vole
        proc.arguments = arguments
        proc.environment = SidecarRunner.rulesEnvironment()
        proc.currentDirectoryURL = vole.deletingLastPathComponent()

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe
        proc.standardInput = FileHandle.nullDevice

        self.process = proc

        do {
            try proc.run()
        } catch {
            return .failed(message: error.localizedDescription)
        }

        return await withCheckedContinuation { continuation in
            let stderrAccumulator = PipeAccumulator()
            let stdoutAccumulator = StdoutLineAccumulator(onLine: onStdoutLine)
            let outHandle = outPipe.fileHandleForReading
            let errHandle = errPipe.fileHandleForReading

            outHandle.readabilityHandler = { handle in
                let chunk = handle.availableData
                if chunk.isEmpty {
                    handle.readabilityHandler = nil
                    return
                }
                stdoutAccumulator.append(chunk)
            }

            errHandle.readabilityHandler = { handle in
                let chunk = handle.availableData
                if chunk.isEmpty {
                    handle.readabilityHandler = nil
                    return
                }
                stderrAccumulator.append(chunk)
            }

            Task.detached {
                proc.waitUntilExit()

                outHandle.readabilityHandler = nil
                errHandle.readabilityHandler = nil

                stdoutAccumulator.append(outHandle.availableData)
                stdoutAccumulator.flushTrailing()
                stderrAccumulator.append(errHandle.availableData)

                let code = proc.terminationStatus
                let stderr = String(data: stderrAccumulator.snapshot, encoding: .utf8) ?? ""
                continuation.resume(returning: SidecarRunner.mapExitCode(code, stderr: stderr))
            }
        }
    }

    func cancel() {
        process?.terminate()
    }
}
