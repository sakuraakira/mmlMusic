# mmlMusic - MML Music Player for Project Zomboid

[中文說明](#中文說明) | [English](#english)

---

## 中文說明

### 📖 這個專案是什麼？

**mmlMusic** 是一個 Project Zomboid 遊戲模組，讓玩家可以使用 **MML (Music Macro Language)** 語言來演奏音樂！

### ✨ 主要功能

1. **MML 音樂解析與播放**
   - 支援完整的 MML 語法（音符、八度、節奏、速度、力度等）
   - 支援多軌播放（最多 3 軌同時演奏）
   - 支援連音符 (&)、附點音符 (.)、休止符 (R)
   - 支援絕對音高 (N) 指令

2. **多種樂器支援**
   - 鋼琴 (Piano)
   - 吉他 (Guitar Clean, Steel, Distortion)
   - 貝斯 (Bass Finger)
   - 小提琴 (Violin)
   - 長笛 (Flute)
   - 以及更多...

3. **遊戲內介面**
   - 樂器演奏介面 (MMLInstrumentUI)
   - 作曲介面 (MMLComposeUI)
   - 樂譜物品系統
   - 右鍵選單整合

4. **多人遊戲支援**
   - 客戶端與伺服器端通訊
   - 音樂播放範圍限制
   - 網路同步

### 📁 專案結構

```
mmlMusic/
├── media/
│   ├── lua/
│   │   ├── client/          # 客戶端 Lua 腳本
│   │   │   ├── MMLParser.lua      # MML 語法解析器
│   │   │   ├── MMLPlayer.lua      # 音樂播放器
│   │   │   ├── MMLInstrumentUI.lua # 樂器介面
│   │   │   ├── MMLComposeUI.lua   # 作曲介面
│   │   │   ├── MusicPlayer.lua    # 音效播放控制
│   │   │   └── ...
│   │   ├── server/          # 伺服器端腳本
│   │   └── shared/          # 共用腳本
│   ├── sound/              # 樂器音效檔案
│   ├── scripts/            # 物品定義
│   └── textures/           # 貼圖資源
├── mod.info                # 模組資訊
└── README.md
```

### 🎵 MML 語法範例

```
# 簡單的旋律
t120 l4 o4 cdefgab>c

# 多軌範例（使用逗號分隔）
t120 l4 o4 cdefg, l4 o3 ccccg, l2 o2 cg

# 複雜範例
t140 l8 o5 c16d16e8 d8 e8f8 e2 , l8 o4 eee e4 ddd d4
```

### 🔧 核心模組說明

#### MMLParser.lua
MML 語法解析器，負責將 MML 字串轉換為可播放的音符序列。

主要功能：
- 解析音符 (CDEFGABH)
- 解析八度 (O, <, >)
- 解析節奏長度 (L, 數字, 附點)
- 解析速度 (T)
- 解析力度 (V)
- 支援共享速度（多軌同步）

#### MMLPlayer.lua
音樂播放器，負責管理音樂的播放流程。

主要功能：
- 載入和解析 MML
- 多軌同步播放
- 音量距離衰減
- 播放進度追蹤
- 網路同步

#### MusicPlayer.lua
底層音效播放控制，負責實際的音效播放。

主要功能：
- 音效播放與停止
- 音符音高映射
- 音量控制
- 樂器切換

### 🎮 如何使用

1. 在遊戲中找到或製作樂器物品
2. 右鍵點擊樂器，選擇「演奏」
3. 在介面中輸入 MML 樂譜
4. 點擊播放按鈕開始演奏

### 🛠️ 技術特點

- 使用 Lua 編寫
- 完整的 MML 解析器實作
- 支援 Project Zomboid 41 版本
- 客戶端/伺服器架構
- 模組化設計

---

## English

### 📖 What is this project?

**mmlMusic** is a Project Zomboid mod that allows players to play music using **MML (Music Macro Language)**!

### ✨ Key Features

1. **MML Music Parsing & Playback**
   - Full MML syntax support (notes, octaves, rhythm, tempo, velocity, etc.)
   - Multi-track playback (up to 3 tracks simultaneously)
   - Support for tied notes (&), dotted notes (.), rests (R)
   - Support for absolute pitch (N) command

2. **Multiple Instrument Support**
   - Piano
   - Guitar (Clean, Steel, Distortion)
   - Bass (Finger)
   - Violin
   - Flute
   - And more...

3. **In-Game Interface**
   - Instrument playing UI (MMLInstrumentUI)
   - Composition UI (MMLComposeUI)
   - Sheet music item system
   - Context menu integration

4. **Multiplayer Support**
   - Client-server communication
   - Music playback range limitation
   - Network synchronization

### 📁 Project Structure

```
mmlMusic/
├── media/
│   ├── lua/
│   │   ├── client/          # Client-side Lua scripts
│   │   │   ├── MMLParser.lua      # MML syntax parser
│   │   │   ├── MMLPlayer.lua      # Music player
│   │   │   ├── MMLInstrumentUI.lua # Instrument UI
│   │   │   ├── MMLComposeUI.lua   # Composition UI
│   │   │   ├── MusicPlayer.lua    # Sound playback control
│   │   │   └── ...
│   │   ├── server/          # Server-side scripts
│   │   └── shared/          # Shared scripts
│   ├── sound/              # Instrument sound files
│   ├── scripts/            # Item definitions
│   └── textures/           # Texture resources
├── mod.info                # Mod information
└── README.md
```

### 🎵 MML Syntax Examples

```
# Simple melody
t120 l4 o4 cdefgab>c

# Multi-track example (comma-separated)
t120 l4 o4 cdefg, l4 o3 ccccg, l2 o2 cg

# Complex example
t140 l8 o5 c16d16e8 d8 e8f8 e2 , l8 o4 eee e4 ddd d4
```

### 🔧 Core Module Description

#### MMLParser.lua
MML syntax parser that converts MML strings into playable note sequences.

Main features:
- Parse notes (CDEFGABH)
- Parse octaves (O, <, >)
- Parse rhythm lengths (L, numbers, dots)
- Parse tempo (T)
- Parse velocity (V)
- Support shared tempo (multi-track sync)

#### MMLPlayer.lua
Music player that manages the music playback process.

Main features:
- Load and parse MML
- Multi-track synchronized playback
- Volume distance attenuation
- Playback progress tracking
- Network synchronization

#### MusicPlayer.lua
Low-level sound playback control for actual sound playing.

Main features:
- Sound playback and stop
- Note pitch mapping
- Volume control
- Instrument switching

### 🎮 How to Use

1. Find or craft an instrument item in-game
2. Right-click the instrument and select "Play"
3. Enter MML notation in the interface
4. Click the play button to start performing

### 🛠️ Technical Features

- Written in Lua
- Complete MML parser implementation
- Support for Project Zomboid version 41
- Client/server architecture
- Modular design

---

### 📝 License

This is a fan-made mod for Project Zomboid.

### 🤝 Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

### 📧 Contact

For questions or suggestions, please open an issue on GitHub.
