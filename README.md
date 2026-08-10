<div align="center">

<img src="images/vole.webp" alt="Vole mascot" width="180" />

# Vole for macOS

**A cleanup app for your Mac**  
Preview first · Trash by default · Find what’s eating your disk

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/github/v/tag/wukongnotnull/vole-macos?label=version)](https://github.com/wukongnotnull/vole-macos/releases)
[![Platform](https://img.shields.io/badge/platform-macOS-black.svg)](https://github.com/wukongnotnull/vole-macos)
[![Download](https://img.shields.io/github/downloads/wukongnotnull/vole-macos/total.svg)](https://github.com/wukongnotnull/vole-macos/releases/latest)
[![Stars](https://img.shields.io/github/stars/wukongnotnull/vole-macos?style=social)](https://github.com/wukongnotnull/vole-macos/stargazers)

</div>

**Languages:** [English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

> Caches, logs, leftover files, installers, build junk… Vole finds them so you can **select what to remove**. Items go to Trash by default—easy to undo if you change your mind.

---

**Quick nav**
[Screenshots](#screenshots) · [Features](#features) · [Download](#download--install) · [First run](#first-run) · [Safety](#safety) · [FAQ](#faq) · [CLI](#prefer-the-command-line) · [About](#about) · [Credits](#credits) · [License](#license)

---

## Screenshots

<p align="center">
  <img src="images/clean-idle.png" alt="Clean home" width="48%" />
  <img src="images/candidates.png" alt="Cleanup candidates" width="48%" />
</p>

---

## Features

| Feature | What you get |
|------|-------------|
| **Clean** | Find caches, logs, and leftovers—then clean what you select |
| **Uninstall** | Remove apps and as much user-domain leftover data as possible |
| **Optimize** | Run a bounded set of system maintenance tasks (e.g. cache rebuilds) |
| **Purge** | Clear bulky items like stale project build artifacts |
| **Installer** | Find forgotten `.dmg` / `.pkg` installers on disk |
| **Analyze** | See which folders and large files use the most space |
| **History** | Review past cleanups and deletions |
| **Status** | Health score, CPU, memory, and disk at a glance |

For anyone who wants a GUI to clean their Mac—without “one-click delete everything” regret.

---

## Download & install

1. Open the [latest Release](https://github.com/wukongnotnull/vole-macos/releases/latest)
2. Download **`Vole-*.dmg`** (a `.zip` is also available)
3. Open the DMG and drag **Vole** into Applications
4. Launch Vole from Launchpad or Applications

Current version: **[v0.1.0](https://github.com/wukongnotnull/vole-macos/releases/tag/v0.1.0)** (Developer ID signed and notarized by Apple).

If macOS says the developer cannot be verified: allow it under **System Settings → Privacy & Security**, or right-click the app → Open.

---

## First run

Do these two steps for a more complete cleanup:

### 1. Enable Full Disk Access

Without this, many user folders cannot be scanned fully, so results look sparse.

1. Open **System Settings → Privacy & Security → Full Disk Access**
2. Turn it on and check **Vole**

### 2. (Optional) Enable the Root privileged helper

Only needed to clean some **system paths**. Personal files work fine without it.

1. On the home screen, tap **Enable Root privileged helper**
2. Approve the background item in System Settings
3. Wait until status shows **Enabled**

If it’s not enabled, system paths are **skipped with a clear message**—Vole will not pretend they were deleted.

---

## Safety

```
You        ❯ Choose Clean → Scan → Select items → Confirm

Vole       ❯ ✓ Lists candidates first—nothing is deleted yet
             ✓ Trash by default (recoverable)
             ✓ System paths use the privileged helper; skipped if not approved
             ✓ Dangerous paths outside the whitelist are never removed
```

| Principle | Meaning |
|------|------|
| **Preview before act** | You always see candidates and choose what to remove |
| **Recoverable by default** | Personal files go to Trash, not permanent delete |
| **Skip when unauthorized** | Without the Root helper, system paths are skipped and explained |
| **Auditable** | History shows what was done |

---

## FAQ

**Q: Scan results look too small?**  
A: Enable **Full Disk Access** for **Vole** under System Settings → Privacy & Security, then scan again.

**Q: System paths were skipped?**  
A: Expected. Enable the Root privileged helper on the home screen and approve the background item in System Settings.

**Q: I deleted the wrong thing?**  
A: Default is Trash—open Trash and restore. Permanent delete (if you chose it) cannot be restored from Trash.

**Q: Does it upload my files?**  
A: Everyday cleanup stays on your Mac. Network features like self-update only run when you use them in Settings—nothing is uploaded in the background.

**Q: What’s the relationship to Mole?**  
A: Cleanup rules and safety ideas were inspired by [Mole](https://github.com/tw93/Mole). Vole is an independent open-source project and is not affiliated with Mole.

---

## Prefer the command line?

The same engine is available as a CLI: [vole](https://github.com/wukongnotnull/vole).

```bash
brew tap wukongnotnull/vole https://github.com/wukongnotnull/vole
brew install vole
```

Desktop and CLI share the same cleanup engine and safety model.

---

## About

**悟空非空也 (Wukong)** — Founder of Way to AI, indie developer, content creator.

| Platform | Link |
|------|------|
| 🌐 Website | [waytoai.cn](https://waytoai.cn) |
| 𝕏 Twitter | [悟空非空也](https://x.com/wukongnotnull) |
| 📺 Bilibili | [悟空非空也](https://space.bilibili.com/456634391) |
| ▶️ YouTube | [悟空非空也](https://www.youtube.com/@wukongnotnull) |
| 📕 Xiaohongshu | [悟空非空也](https://www.xiaohongshu.com/user/profile/5ca89c2f000000001100952b) |
| 💬 WeChat | Search「悟空非空也」 |

---

## Credits

Thanks to these products and open-source projects for pioneering macOS cleanup UX—Vole learned a lot from them:

- [Mole](https://github.com/tw93/Mole) — open-source cleaner; major inspiration for rules and safety
- [CleanMyMac](https://macpaw.com/cleanmymac) — reference for polished desktop cleanup UX
- [Tencent Lemon](https://lemon.qq.com/) — familiar system-cleaner experience for Chinese users

Vole is an independent open-source project and has no affiliation or commercial relationship with the above.

---

## License

Vole for macOS is licensed under [GPL-3.0](LICENSE).  
If you fork it into your own product, please rename it to avoid confusion and credit Mole / Vole as sources.

---

<div align="center">

GPL-3.0 license © [悟空非空也](https://github.com/wukongnotnull)

</div>
