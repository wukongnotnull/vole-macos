<div align="center">

<img src="images/vole.webp" alt="Vole mascot" width="180" />

# Vole for macOS

**Mac 向けクリーンアップアプリ**  
先に確認 · ゴミ箱が既定 · 容量を食うゴミをまとめて発見

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/github/v/tag/wukongnotnull/vole-macos?label=version)](https://github.com/wukongnotnull/vole-macos/releases)
[![Platform](https://img.shields.io/badge/platform-macOS-black.svg)](https://github.com/wukongnotnull/vole-macos)
[![Download](https://img.shields.io/github/downloads/wukongnotnull/vole-macos/total.svg)](https://github.com/wukongnotnull/vole-macos/releases/latest)
[![Stars](https://img.shields.io/github/stars/wukongnotnull/vole-macos?style=social)](https://github.com/wukongnotnull/vole-macos/stargazers)

</div>

**言語：** [English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

> キャッシュ、ログ、アンインストール残骸、インストーラ、ビルド残骸……Vole が見つけ、**選んでから削除**できます。既定はゴミ箱行きなので、間違えても戻せます。

---

**クイックナビ**
[画面プレビュー](#画面プレビュー) · [できること](#できること) · [ダウンロードとインストール](#ダウンロードとインストール) · [初回セットアップ](#初回セットアップ) · [安全について](#安全について) · [よくある質問](#よくある質問) · [CLI](#コマンドラインが好きなら) · [About](#about) · [謝辞](#謝辞) · [ライセンス](#ライセンス)

---

## 画面プレビュー

<p align="center">
  <img src="images/clean-idle.png" alt="クリーンホーム" width="48%" />
  <img src="images/candidates.png" alt="クリーン候補一覧" width="48%" />
</p>

---

## できること

| 機能 | 得られること |
|------|-------------|
| **クリーン** | キャッシュ・ログ・残骸を検出し、選んで削除 |
| **アンインストール** | App を削除し、ユーザー領域の残骸もできるだけ除去 |
| **最適化** | キャッシュ再構築など、範囲の限られたメンテ作業を実行 |
| **パージ** | 古いプロジェクトのビルド成果物など大きなゴミを掃除 |
| **インストーラ** | ディスクに残った `.dmg` / `.pkg` などを発見 |
| **分析** | どのフォルダ・大きなファイルが容量を使っているかを確認 |
| **履歴** | 過去のクリーンと削除を振り返る |
| **ステータス** | ヘルススコア、CPU、メモリ、ディスクを一目で把握 |

「ワンクリック全削除で後悔したくない」人向けの GUI クリーナーです。

---

## ダウンロードとインストール

1. [最新 Release](https://github.com/wukongnotnull/vole-macos/releases/latest) を開く
2. **`Vole-*.dmg`** をダウンロード（`.zip` もあり）
3. DMG を開き、**Vole** を「アプリケーション」へドラッグ
4. Launchpad または「アプリケーション」から起動

現在のバージョン：**[v0.2.0](https://github.com/wukongnotnull/vole-macos/releases/tag/v0.2.0)**（Developer ID 署名＋Apple 公証済み）。

「開発元を確認できない」と出る場合：**システム設定 → プライバシーとセキュリティ** で許可するか、App を右クリック → 開く。

---

## 初回セットアップ

より完全に掃除するために、次の 2 つをおすすめします。

### 1. 「フルディスクアクセス」をオンにする

権限がないと多くのユーザーフォルダを十分にスキャンできず、結果が少なく見えます。

1. **システム設定 → プライバシーとセキュリティ → フルディスクアクセス** を開く
2. オンにして **Vole** にチェック

### 2. （任意）Root 特権ヘルパーを有効化

一部の**システムパス**を掃除する場合のみ必要です。個人ファイルだけなら不要です。

1. ホーム画面で **「Root 特権ヘルパーを有効化」** をタップ
2. システム設定でバックグラウンド項目を許可
3. 状態が「有効」になれば完了

未有効時：システムパスは**スキップされ、はっきり表示**されます。消したフリはしません。

---

## 安全について

```
あなた     ❯ 「クリーン」→ スキャン → 削除したい項目を選択 → 確認

Vole      ❯ ✓ まず候補を表示し、すぐには削除しない
            ✓ 既定はゴミ箱（復元可能）
            ✓ システムパスは特権ヘルパー経由；未許可ならスキップ
            ✓ ホワイトリスト外の危険パスは削除しない
```

| 原則 | 意味 |
|------|------|
| **プレビューしてから実行** | 必ず候補を見て、選んでから削除 |
| **既定で復元可能** | 個人ファイルはゴミ箱行き（いきなり完全削除しない） |
| **権限不足ならスキップ** | Root ヘルパーなしではシステムパスをスキップし説明する |
| **追跡可能** | 「履歴」で何をしたか確認できる |

---

## よくある質問

**Q：スキャン結果が少なすぎる？**  
A：**システム設定 → プライバシーとセキュリティ → フルディスクアクセス** で **Vole** を許可し、再スキャンしてください。

**Q：システムパスがスキップされた？**  
A：想定どおりです。ホーム画面で Root 特権ヘルパーを有効化し、システム設定でバックグラウンド項目を許可してください。

**Q：間違って消した？**  
A：既定はゴミ箱です。ゴミ箱から復元できます。完全削除を選んだ場合はゴミ箱からは戻せません。

**Q：ファイルをネットに送りませんか？**  
A：日常のクリーンはローカルで完結します。自己更新などのネット機能は設定で明示的に使うときだけ動作し、裏でファイルをアップロードしません。

**Q：Mole との関係は？**  
A：クリーン規則と安全の考え方は [Mole](https://github.com/tw93/Mole) から着想を得ています。Vole は独立したオープンソースで、Mole に所属しません。

---

## コマンドラインが好きなら？

同じエンジンの CLI 版もあります：[vole](https://github.com/wukongnotnull/vole)。

```bash
brew tap wukongnotnull/vole https://github.com/wukongnotnull/vole
brew install vole
```

デスクトップ版と CLI 版は同じクリーンエンジンと安全モデルを共有します。

---

## About

**悟空非空也（Wukong）** — AI之道創業者、インディー開発者、クリエイター。

| プラットフォーム | リンク |
|------|------|
| 🌐 Web | [waytoai.cn](https://waytoai.cn) |
| 𝕏 Twitter | [悟空非空也](https://x.com/wukongnotnull) |
| 📺 Bilibili | [悟空非空也](https://space.bilibili.com/456634391) |
| ▶️ YouTube | [悟空非空也](https://www.youtube.com/@wukongnotnull) |
| 📕 小紅書 | [悟空非空也](https://www.xiaohongshu.com/user/profile/5ca89c2f000000001100952b) |
| 💬 WeChat | 「悟空非空也」で検索 |

---

## 謝辞

macOS クリーン体験を切り拓いてきた製品・OSS に感謝します。Vole は多くを学びました：

- [Mole](https://github.com/tw93/Mole) — OSS クリーナー。規則と安全の大きな着想源
- [CleanMyMac](https://macpaw.com/cleanmymac) — 洗練されたデスクトップ掃除 UX の参考
- [Tencent Lemon](https://lemon.qq.com/) — 中国語圏で親しまれるシステムクリーナーの参考

Vole は独立したオープンソースであり、上記との所属・商業関係はありません。

---

## ライセンス

Vole for macOS は [GPL-3.0](LICENSE) です。  
自社製品として派生させる場合は、混同を避けるため名称を変え、Mole / Vole を出典として明記してください。

---

<div align="center">

GPL-3.0 license © [悟空非空也](https://github.com/wukongnotnull)

</div>
