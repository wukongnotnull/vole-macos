<div align="center">

<img src="images/vole.webp" alt="Vole mascot" width="180" />

# Vole for macOS

**给 macOS 用的清理工具**  
先看再清 · 默认进废纸篓 · 一键扫出占空间的垃圾

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/github/v/tag/wukongnotnull/vole-macos?label=version)](https://github.com/wukongnotnull/vole-macos/releases)
[![Platform](https://img.shields.io/badge/platform-macOS-black.svg)](https://github.com/wukongnotnull/vole-macos)
[![Download](https://img.shields.io/github/downloads/wukongnotnull/vole-macos/total.svg)](https://github.com/wukongnotnull/vole-macos/releases/latest)
[![Stars](https://img.shields.io/github/stars/wukongnotnull/vole-macos?style=social)](https://github.com/wukongnotnull/vole-macos/stargazers)

</div>

**多语言：** [English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

> 缓存、日志、卸载残留、安装包、构建垃圾……Vole 帮你找出来，**勾选后再删**。默认进废纸篓，删错还能找回。

---

**快捷导航**
[界面预览](#界面预览) · [能做什么](#能做什么) · [下载安装](#下载安装) · [第一次使用](#第一次使用) · [安全说明](#安全说明) · [常见问题](#常见问题) · [命令行版](#更喜欢命令行) · [关于我](#关于我) · [鸣谢](#鸣谢) · [许可证](#许可证)

---

## 界面预览

<p align="center">
  <img src="images/clean-idle.png" alt="清理首页" width="48%" />
  <img src="images/candidates.png" alt="清理候选列表" width="48%" />
</p>

---

## 能做什么

| 功能 | 你能得到什么 |
|------|-------------|
| **清理** | 扫出缓存、日志、残留数据，勾选后清理 |
| **卸载** | 卸掉 App，并尽量清掉用户域残留 |
| **优化** | 跑一组有界的系统维护任务（如缓存重建等） |
| **净化** | 清理陈旧项目构建物等占空间的大件 |
| **安装包** | 找出磁盘上落灰的 `.dmg` / `.pkg` 等安装包 |
| **分析** | 看目录谁占空间、大文件在哪 |
| **历史** | 回看做过的清理与删除记录 |
| **状态** | 一眼看健康分、CPU、内存、磁盘 |

适合：想用图形界面清理 Mac，又不想「一键全删、删完才后悔」的人。

---

## 下载安装

1. 打开 [最新 Release](https://github.com/wukongnotnull/vole-macos/releases/latest)
2. 下载 **`Vole-*.dmg`**（也提供 `.zip`）
3. 打开 DMG，把 **Vole** 拖进「应用程序」
4. 从启动台或「应用程序」打开 Vole

当前版本：**[v0.1.0](https://github.com/wukongnotnull/vole-macos/releases/tag/v0.1.0)**（Developer ID 签名并经 Apple 公证）。

若系统提示「无法验证开发者」：在「系统设置 → 隐私与安全性」里允许打开，或对 App 右键 → 打开。

---

## 第一次使用

装好后建议做两件事，清理会更完整：

### 1. 打开「完全磁盘访问」

没有这项权限时，很多用户目录扫不全，结果会偏少。

1. 打开 **系统设置 → 隐私与安全性 → 完全磁盘访问**
2. 打开开关，勾选 **Vole**

### 2. （可选）启用 Root 特权助手

要清理部分**系统路径**时才需要。不启用也能正常清理个人文件。

1. 在 App 首页点 **「启用 Root 特权助手」**
2. 在系统设置里批准后台项
3. 状态变为「已启用」即可

未启用时：系统路径会**跳过并明确提示**，不会假装已经删掉。

---

## 安全说明

```
你        ❯ 选「清理」→ 扫描 → 勾选想删的项 → 确认

Vole      ❯ ✓ 先列出候选，不直接动手
            ✓ 默认放进废纸篓（可恢复）
            ✓ 系统路径走特权助手；未批准就跳过
            ✓ 不在白名单里的危险路径不会删
```

| 原则 | 含义 |
|------|------|
| **先预览再执行** | 总是先看到候选列表，勾选后才动手 |
| **默认可恢复** | 个人文件默认进废纸篓，不是一上来永久删除 |
| **权限不足就跳过** | 没开 Root 特权助手时，系统路径跳过并说清楚 |
| **可追溯** | 「历史」里能回看做过什么 |

---

## 常见问题

**Q：扫描结果很少？**  
A：去「系统设置 → 隐私与安全性 → 完全磁盘访问」勾选 **Vole**，然后重新扫描。

**Q：提示系统路径被跳过？**  
A：正常。需要先在首页启用 Root 特权助手，并在系统设置里批准后台项。

**Q：删错了怎么办？**  
A：默认进废纸篓，打开废纸篓还原即可。若你主动选了永久删除，则无法从废纸篓找回。

**Q：会不会联网乱传数据？**  
A：日常清理在本地完成。自更新等联网能力需你在设置里明确使用，不会后台偷偷上传你的文件。

**Q：和 Mole 是什么关系？**  
A：清理规则与安全思路受到 [Mole](https://github.com/tw93/Mole) 启发；Vole 是独立开源项目，不隶属于 Mole。

---

## 更喜欢命令行？

同一套能力也有终端版：[vole](https://github.com/wukongnotnull/vole)。

```bash
brew tap wukongnotnull/vole https://github.com/wukongnotnull/vole
brew install vole
```

桌面版与命令行版共用同一套清理引擎与安全语义。

---

## 关于我

**悟空非空也** — AI之道创始人，独立开发者，Up主。

| 平台 | 链接 |
|------|------|
| 🌐 官网 | [AI之道官网](https://waytoai.cn) |
| 𝕏 Twitter | [悟空非空也](https://x.com/wukongnotnull) |
| 📺 B站 | [悟空非空也](https://space.bilibili.com/456634391) |
| ▶️ YouTube | [悟空非空也](https://www.youtube.com/@wukongnotnull) |
| 📕 小红书 | [悟空非空也](https://www.xiaohongshu.com/user/profile/5ca89c2f000000001100952b) |
| 💬 公众号 | 微信搜「悟空非空也」 |

---

## 鸣谢

感谢这些产品与开源项目在 macOS 清理体验上的探索与积累，Vole 从中获益良多：

- [Mole](https://github.com/tw93/Mole) — 开源清理工具；规则与安全思路的重要启发
- [CleanMyMac](https://macpaw.com/cleanmymac) — 成熟的桌面清理产品体验参考
- [腾讯柠檬清理](https://lemon.qq.com/) — 中文用户熟悉的系统清理产品参考

Vole 是独立开源项目，与上述产品无隶属或商业关系。

---

## 许可证

Vole for macOS 遵循 [GPL-3.0](LICENSE)。  
如需基于本项目做自有产品，请更换名称以避免混淆，并注明来源于 Mole / Vole。

---

<div align="center">

GPL-3.0 license © [悟空非空也](https://github.com/wukongnotnull)

</div>
