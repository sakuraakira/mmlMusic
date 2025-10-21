# mmlMusic 專案總覽 / Project Summary

## 這是什麼？ / What is this?

**mmlMusic** 是一個為 Project Zomboid 遊戲開發的音樂播放模組，允許玩家使用 MML (Music Macro Language) 語言來演奏和創作音樂。

**mmlMusic** is a music playing mod for Project Zomboid that allows players to play and compose music using MML (Music Macro Language).

---

## 📚 文件導航 / Documentation Navigation

### 快速開始 / Quick Start
1. **[README.md](README.md)** - 專案概述與功能介紹 / Project overview and features
2. **[INSTALLATION.md](INSTALLATION.md)** - 安裝與配置指南 / Installation and configuration guide
3. **[MML_EXAMPLES.md](MML_EXAMPLES.md)** - MML 語法範例與教學 / MML syntax examples and tutorials

### 深入了解 / Deep Dive
4. **[DOCUMENTATION.md](DOCUMENTATION.md)** - 程式碼架構與技術文件 / Code architecture and technical documentation
5. **[Info.txt](Info.txt)** - 模組資訊 / Mod information

---

## 🎯 核心功能 / Core Features

### 1. MML 音樂系統
- ✅ 完整的 MML 語法解析器
- ✅ 多軌播放支援（最多 3 軌）
- ✅ 支援音符、休止符、附點、連音符
- ✅ 速度、八度、力度控制

### 2. 遊戲整合
- ✅ 多種樂器支援（鋼琴、吉他、小提琴等）
- ✅ 遊戲內作曲介面
- ✅ 樂器演奏介面
- ✅ 樂譜物品系統

### 3. 多人遊戲
- ✅ 客戶端-伺服器同步
- ✅ 音效範圍限制
- ✅ 網路通訊系統

---

## 🏗️ 技術架構 / Technical Architecture

```
使用者介面層 (UI Layer)
├── MMLInstrumentUI.lua    # 樂器演奏介面
└── MMLComposeUI.lua       # 作曲介面

播放控制層 (Control Layer)
└── MMLPlayer.lua          # 播放器管理

解析層 (Parser Layer)
└── MMLParser.lua          # MML 語法解析

音效層 (Sound Layer)
└── MusicPlayer.lua        # 音效播放控制

網路層 (Network Layer)
├── MMLClientSendCommands.lua   # 客戶端發送
├── MMLClientRecvCommands.lua   # 客戶端接收
└── MMLServerCommands.lua       # 伺服器處理
```

---

## 💻 程式碼統計 / Code Statistics

### 核心模組檔案
- **MMLParser.lua**: ~534 行 - MML 語法解析器
- **MMLPlayer.lua**: ~600 行 - 音樂播放器
- **MusicPlayer.lua**: ~200+ 行 - 音效控制
- **MMLInstrumentUI.lua**: ~400+ 行 - 演奏介面
- **MMLComposeUI.lua**: ~500+ 行 - 作曲介面

### 程式語言
- **Lua**: 100%
- **專案類型**: Project Zomboid 模組

### 資源檔案
- **音效檔案**: 9 種樂器 × 多個音階
- **3D 模型**: 17 個動畫檔案
- **貼圖**: 樂譜物品圖示

---

## 🎵 支援的樂器 / Supported Instruments

| 中文名稱 | 英文名稱 | 類型 |
|---------|---------|------|
| 鋼琴 | Piano | 鍵盤 |
| 古典吉他 | GuitarClean | 弦樂 |
| 鋼弦吉他 | GuitarSteel | 弦樂 |
| 失真吉他 | GuitarDistortion | 弦樂 |
| 貝斯 | BassFinger | 低音 |
| 小提琴 | Violin | 弦樂 |
| 長笛 | Flute | 木管 |
| 薩克斯風 | Saxophone | 銅管 |
| 小號 | Trumpet | 銅管 |

---

## 📖 MML 語法快速參考 / MML Syntax Quick Reference

### 基本指令 / Basic Commands
```
C D E F G A B    音符 / Notes
O4               設定八度 / Set octave
< >              八度升降 / Octave up/down
L4               預設長度 / Default length
T120             速度 / Tempo
V8               力度 / Velocity
R                休止符 / Rest
```

### 範例 / Example
```
t120 l4 o4 cdefgab>c
```
解釋：以 120 BPM 播放 C 大調音階
Translation: Play C major scale at 120 BPM

---

## 🚀 快速開始 / Quick Start

### 1. 安裝模組
參考 [INSTALLATION.md](INSTALLATION.md)

### 2. 學習 MML
參考 [MML_EXAMPLES.md](MML_EXAMPLES.md)

### 3. 遊戲中使用
1. 找到樂器
2. 右鍵點擊 → 選擇「演奏」
3. 輸入 MML 或選擇樂譜
4. 播放音樂！

---

## 🛠️ 開發資訊 / Development Info

### 技術棧 / Tech Stack
- **語言**: Lua
- **平台**: Project Zomboid Build 41+
- **設計模式**: 單例、觀察者、工廠模式

### 核心演算法 / Core Algorithms
- **Tick 系統**: PPQ = 480
- **時間轉換**: `msPerTick = (60000 / tempo) / PPQ`
- **附點計算**: `multiplier = 1.0 + sum(1/2^i)`

### 程式碼品質 / Code Quality
- ✅ 模組化設計
- ✅ 完整的中文註解
- ✅ 錯誤處理機制
- ✅ 除錯輸出功能

---

## 📊 專案統計 / Project Statistics

### 檔案數量
- Lua 腳本: 15+ 個檔案
- 音效檔案: 100+ 個檔案
- 3D 模型: 17 個檔案
- 文件檔案: 5 個文件

### 程式碼行數（估計）
- 總計: ~3000+ 行 Lua 程式碼
- 註解率: >30%

---

## 🎓 學習路徑 / Learning Path

### 初學者 / Beginner
1. 閱讀 README.md 了解專案
2. 參考 INSTALLATION.md 安裝模組
3. 使用 MML_EXAMPLES.md 學習 MML

### 進階使用者 / Advanced User
1. 深入研究 DOCUMENTATION.md
2. 了解程式碼架構
3. 自訂樂器和音效

### 開發者 / Developer
1. 研究核心模組原始碼
2. 理解 MML 解析演算法
3. 擴展功能或修改程式碼

---

## 🔗 相關連結 / Related Links

### 官方資源
- Project Zomboid 官網
- Steam 工作坊

### 學習資源
- MML 語法參考
- Lua 程式設計教學
- Project Zomboid 模組開發文件

---

## 📝 版本資訊 / Version Info

**當前版本 / Current Version**: 1
**支援遊戲版本 / Supported Game Version**: Project Zomboid Build 41+
**最後更新 / Last Updated**: 2024

---

## 🤝 貢獻 / Contributing

歡迎提交問題、建議或拉取請求！
Issues, suggestions, and pull requests are welcome!

---

## 📄 授權 / License

本專案為 Project Zomboid 的愛好者模組。
This is a fan-made mod for Project Zomboid.

---

**祝您遊戲愉快！/ Happy Gaming!**
