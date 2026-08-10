<div align="center">

<img src="images/vole.webp" alt="Vole mascot" width="180" />

# Vole for macOS

**給 macOS 用的清理工具**  
先看再清 · 預設進廢紙簍 · 一鍵掃出佔空間的垃圾

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/github/v/tag/wukongnotnull/vole-macos?label=version)](https://github.com/wukongnotnull/vole-macos/releases)
[![Platform](https://img.shields.io/badge/platform-macOS-black.svg)](https://github.com/wukongnotnull/vole-macos)
[![Download](https://img.shields.io/github/downloads/wukongnotnull/vole-macos/total.svg)](https://github.com/wukongnotnull/vole-macos/releases/latest)
[![Stars](https://img.shields.io/github/stars/wukongnotnull/vole-macos?style=social)](https://github.com/wukongnotnull/vole-macos/stargazers)

</div>

**多語言：** [English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

> 快取、日誌、解除安裝殘留、安裝套件、建置垃圾……Vole 幫你找出來，**勾選後再刪**。預設進廢紙簍，刪錯還能找回。

---

**快捷導覽**
[介面預覽](#介面預覽) · [能做什麼](#能做什麼) · [下載安裝](#下載安裝) · [第一次使用](#第一次使用) · [安全說明](#安全說明) · [常見問題](#常見問題) · [命令列版](#更喜歡命令列) · [關於我](#關於我) · [鳴謝](#鳴謝) · [授權條款](#授權條款)

---

## 介面預覽

<p align="center">
  <img src="images/clean-idle.png" alt="清理首頁" width="48%" />
  <img src="images/candidates.png" alt="清理候選列表" width="48%" />
</p>

---

## 能做什麼

| 功能 | 你能得到什麼 |
|------|-------------|
| **清理** | 掃出快取、日誌、殘留資料，勾選後清理 |
| **解除安裝** | 卸掉 App，並盡量清掉使用者網域殘留 |
| **最佳化** | 執行一組有界的系統維護工作（如快取重建等） |
| **淨化** | 清理陳舊專案建置物等佔空間的大件 |
| **安裝套件** | 找出磁碟上落灰的 `.dmg` / `.pkg` 等安裝套件 |
| **分析** | 看目錄誰佔空間、大檔在哪 |
| **歷史** | 回看做過的清理與刪除紀錄 |
| **狀態** | 一眼看健康分數、CPU、記憶體、磁碟 |

適合：想用圖形介面清理 Mac，又不想「一鍵全刪、刪完才後悔」的人。

---

## 下載安裝

1. 開啟 [最新 Release](https://github.com/wukongnotnull/vole-macos/releases/latest)
2. 下載 **`Vole-*.dmg`**（也提供 `.zip`）
3. 開啟 DMG，把 **Vole** 拖進「應用程式」
4. 從 Launchpad 或「應用程式」開啟 Vole

目前版本：**[v0.1.0](https://github.com/wukongnotnull/vole-macos/releases/tag/v0.1.0)**（Developer ID 簽名並經 Apple 公證）。

若系統提示「無法驗證開發者」：在「系統設定 → 隱私權與安全性」裡允許開啟，或對 App 按右鍵 → 打開。

---

## 第一次使用

裝好後建議做兩件事，清理會更完整：

### 1. 開啟「完整磁碟取用權限」

沒有這項權限時，很多使用者目錄掃不全，結果會偏少。

1. 開啟 **系統設定 → 隱私權與安全性 → 完整磁碟取用權限**
2. 打開開關，勾選 **Vole**

### 2. （可選）啟用 Root 特權助手

要清理部分**系統路徑**時才需要。不啟用也能正常清理個人檔案。

1. 在 App 首頁點 **「啟用 Root 特權助手」**
2. 在系統設定裡批准背景項目
3. 狀態變為「已啟用」即可

未啟用時：系統路徑會**略過並明確提示**，不會假裝已經刪掉。

---

## 安全說明

```
你        ❯ 選「清理」→ 掃描 → 勾選想刪的項 → 確認

Vole      ❯ ✓ 先列出候選，不直接動手
            ✓ 預設放進廢紙簍（可復原）
            ✓ 系統路徑走特權助手；未批准就略過
            ✓ 不在白名單裡的危險路徑不會刪
```

| 原則 | 含義 |
|------|------|
| **先預覽再執行** | 總是先看到候選列表，勾選後才動手 |
| **預設可復原** | 個人檔案預設進廢紙簍，不是一上來永久刪除 |
| **權限不足就略過** | 沒開 Root 特權助手時，系統路徑略過並說清楚 |
| **可追溯** | 「歷史」裡能回看做過什麼 |

---

## 常見問題

**Q：掃描結果很少？**  
A：去「系統設定 → 隱私權與安全性 → 完整磁碟取用權限」勾選 **Vole**，然後重新掃描。

**Q：提示系統路徑被略過？**  
A：正常。需要先在首頁啟用 Root 特權助手，並在系統設定裡批准背景項目。

**Q：刪錯了怎麼辦？**  
A：預設進廢紙簍，打開廢紙簍還原即可。若你主動選了永久刪除，則無法從廢紙簍找回。

**Q：會不會連網亂傳資料？**  
A：日常清理在本機完成。自我更新等連網能力需你在設定裡明確使用，不會背景偷偷上傳你的檔案。

**Q：和 Mole 是什麼關係？**  
A：清理規則與安全思路受到 [Mole](https://github.com/tw93/Mole) 啟發；Vole 是獨立開源專案，不隸屬於 Mole。

---

## 更喜歡命令列？

同一套能力也有終端機版：[vole](https://github.com/wukongnotnull/vole)。

```bash
brew tap wukongnotnull/vole https://github.com/wukongnotnull/vole
brew install vole
```

桌面版與命令列版共用同一套清理引擎與安全語意。

---

## 關於我

**悟空非空也** — AI之道創辦人，獨立開發者，Up 主。

| 平台 | 連結 |
|------|------|
| 🌐 官網 | [AI之道官網](https://waytoai.cn) |
| 𝕏 Twitter | [悟空非空也](https://x.com/wukongnotnull) |
| 📺 B站 | [悟空非空也](https://space.bilibili.com/456634391) |
| ▶️ YouTube | [悟空非空也](https://www.youtube.com/@wukongnotnull) |
| 📕 小紅書 | [悟空非空也](https://www.xiaohongshu.com/user/profile/5ca89c2f000000001100952b) |
| 💬 公眾號 | 微信搜「悟空非空也」 |

---

## 鳴謝

感謝這些產品與開源專案在 macOS 清理體驗上的探索與累積，Vole 從中獲益良多：

- [Mole](https://github.com/tw93/Mole) — 開源清理工具；規則與安全思路的重要啟發
- [CleanMyMac](https://macpaw.com/cleanmymac) — 成熟的桌面清理產品體驗參考
- [騰訊檸檬清理](https://lemon.qq.com/) — 中文使用者熟悉的系統清理產品參考

Vole 是獨立開源專案，與上述產品無隸屬或商業關係。

---

## 授權條款

Vole for macOS 遵循 [GPL-3.0](LICENSE)。  
如需基於本專案做自有產品，請更換名稱以避免混淆，並註明來源於 Mole / Vole。

---

<div align="center">

GPL-3.0 license © [悟空非空也](https://github.com/wukongnotnull)

</div>
