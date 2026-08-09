import Foundation

/// Shared busy / pose signal for `VoleMascotView` (sidebar + content).
enum MascotActivity: Equatable {
    case idle
    case scanning
    case applying
    case success
}

/// Session phase shape shared by Clean + Plan modules for mascot aggregation.
enum MascotSessionPhase: Equatable {
    case idle
    case scanning
    case candidates
    case applying
    case result
}

enum MascotMotionKind: Equatable {
    case still
    case stillBusy
    case scanningLoop
    case applyingLoop
    case successSettle
}

enum MascotMotion {
    static func profile(for state: MascotActivity, reduceMotion: Bool) -> MascotMotionKind {
        if reduceMotion {
            switch state {
            case .scanning, .applying:
                return .stillBusy
            case .idle, .success:
                return .still
            }
        }
        switch state {
        case .idle:
            return .still
        case .scanning:
            return .scanningLoop
        case .applying:
            return .applyingLoop
        case .success:
            return .successSettle
        }
    }

    static func isBusyAnnounced(for kind: MascotMotionKind) -> Bool {
        switch kind {
        case .stillBusy, .scanningLoop, .applyingLoop:
            return true
        case .still, .successSettle:
            return false
        }
    }
}

extension MascotActivity {
    static func from(sessionPhase: MascotSessionPhase) -> MascotActivity {
        switch sessionPhase {
        case .idle, .candidates:
            return .idle
        case .scanning:
            return .scanning
        case .applying:
            return .applying
        case .result:
            return .success
        }
    }

    /// Priority: applying > scanning > success > idle.
    static func aggregate(_ activities: [MascotActivity]) -> MascotActivity {
        if activities.contains(.applying) { return .applying }
        if activities.contains(.scanning) { return .scanning }
        if activities.contains(.success) { return .success }
        return .idle
    }

    static func resolve(clean: MascotSessionPhase, plans: [MascotSessionPhase]) -> MascotActivity {
        let mapped = [from(sessionPhase: clean)] + plans.map(from(sessionPhase:))
        return aggregate(mapped)
    }
}

extension CleanSession.Phase {
    var mascotSessionPhase: MascotSessionPhase {
        switch self {
        case .idle: return .idle
        case .scanning: return .scanning
        case .candidates: return .candidates
        case .applying: return .applying
        case .result: return .result
        }
    }
}

extension PlanModuleSession.Phase {
    var mascotSessionPhase: MascotSessionPhase {
        switch self {
        case .idle: return .idle
        case .scanning: return .scanning
        case .candidates: return .candidates
        case .applying: return .applying
        case .result: return .result
        }
    }
}
