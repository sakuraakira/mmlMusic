# mmlMusic 程式碼文件 / Code Documentation

[中文文件](#中文文件) | [English Documentation](#english-documentation)

---

## 中文文件

### 🏗️ 系統架構

本專案採用模組化設計，主要分為以下幾個層次：

```
使用者界面層 (UI Layer)
    ↓
播放控制層 (Playback Control)
    ↓
解析層 (Parser Layer)
    ↓
音效播放層 (Sound Layer)
```

### 📦 核心模組詳解

#### 1. MMLParser.lua - MML 語法解析器

**職責：** 將 MML 字串轉換為可播放的音符序列

**主要類別：** `MMLParser`

**關鍵方法：**

```lua
-- 創建新的解析器實例
MMLParser:new(sharedTempo)
-- 參數：
--   sharedTempo: (可選) 共享的 tempo 參考，用於多軌同步

-- 解析 MML 字串
MMLParser:parse(mml, defaultInstrument)
-- 參數：
--   mml: MML 字串
--   defaultInstrument: 預設樂器名稱
-- 回傳：音符序列表, 總時長(毫秒)
```

**支援的 MML 指令：**

| 指令 | 說明 | 範例 |
|------|------|------|
| C-B, H | 音符 | `c d e f g a b` |
| O | 設定八度 | `o4` |
| < | 降低八度 | `<c` |
| > | 升高八度 | `>c` |
| L | 設定預設長度 | `l4` (四分音符) |
| T | 設定速度 (BPM) | `t120` |
| V | 設定力度 | `v8` |
| R | 休止符 | `r4` |
| N | 絕對音高 (MIDI) | `n60` |
| # / + | 升記號 | `c#` |
| - | 降記號 | `b-` |
| . | 附點 | `c4.` |
| & | 連音符 | `c4&c8` |

**解析流程：**

1. 初始化解析器狀態（八度、長度、速度等）
2. 移除空白並轉大寫
3. 逐字符解析 MML 字串
4. 將 tick 序列轉換為時間序列（毫秒）

**多軌同步機制：**

- Track 1 創建自己的 tempo reference
- Track 2 和 Track 3 共享 Track 1 的 tempo
- 確保所有軌道以相同速度播放

---

#### 2. MMLPlayer.lua - 音樂播放器

**職責：** 管理音樂播放流程，處理多軌同步

**主要類別：** `MMLPlayer`

**關鍵方法：**

```lua
-- 創建新的播放器
MMLPlayer:new(instrument, isSilent)
-- 參數：
--   instrument: 樂器名稱
--   isSilent: 是否靜音（用於測試）

-- 載入 MML
MMLPlayer:loadMML(mmlInput)
-- 參數：
--   mmlInput: 單軌或多軌 MML 字串（用逗號分隔）
-- 回傳：是否成功載入

-- 開始播放
MMLPlayer:play()

-- 停止播放
MMLPlayer:stop()

-- 獲取播放進度 (0.0-1.0)
MMLPlayer:getProgress()

-- 獲取剩餘時間（秒）
MMLPlayer:getRemainingTime()
```

**播放流程：**

1. `loadMML()` - 解析並準備音符序列
2. `play()` - 開始播放
   - 註冊更新函數到 `Events.OnPostRender`
   - 發送網路指令（多人遊戲）
3. `update()` - 每幀更新
   - 檢查距離（音量衰減）
   - 排程播放音符
   - 管理音符生命週期
4. `stop()` - 停止播放
   - 停止所有活動音符
   - 移除更新函數
   - 發送網路指令

**多軌處理：**

- 支援最多 3 軌同時播放
- 每軌獨立的音符序列
- 共享相同的 `startTime` 實現同步
- 自動補全空軌道

---

#### 3. MusicPlayer.lua - 音效播放控制器

**職責：** 底層音效播放，管理音效實例

**主要類別：** `MusicPlayer` (單例模式)

**樂器參數配置：**

```lua
InstrumentParameters = {
  ["Piano"] = { 
    baseTime = 400,      -- 基礎持續時間(ms)
    fadingTime = 200,    -- 淡出時間(ms)
    polyphonic = true    -- 是否支援和弦
  },
  ["Violin"] = { ... },
  -- 其他樂器...
}
```

**音符播放流程：**

1. 計算音高（MIDI note number）
2. 載入對應的音效檔案
3. 計算音量（基於距離）
4. 播放音效並追蹤
5. 在適當時機停止音效

**音效檔案命名規則：**

```
sound/{instrument}/{NoteName}.ogg
例如：sound/piano/C4.ogg
```

---

#### 4. MMLInstrumentUI.lua - 樂器演奏介面

**職責：** 提供遊戲內樂器演奏界面

**主要功能：**

- 選擇樂譜（從物品或預設曲目）
- 播放/停止控制
- 顯示播放進度
- 處理樂器動畫
- 座位檢測（鋼琴等）

**介面組件：**

- 樂譜選擇下拉選單
- 播放/停止按鈕
- 進度條
- 狀態標籤

---

#### 5. MMLComposeUI.lua - 作曲介面

**職責：** 提供遊戲內音樂創作界面

**主要功能：**

- 多軌 MML 輸入（3 軌）
- 即時驗證
- 播放預覽
- 儲存到樂譜物品
- 字數限制（每軌 1500 字元）

**驗證功能：**

```lua
-- 驗證按鈕會檢查：
1. MML 語法是否正確
2. 每軌的音符數量
3. 總播放時長
4. 錯誤訊息顯示
```

---

#### 6. MMLContextMenu.lua - 右鍵選單整合

**職責：** 整合到遊戲的右鍵選單系統

**功能：**

- 物品右鍵選單（樂器、樂譜）
- 世界物件右鍵選單（鋼琴等大型樂器）
- 條件檢查（距離、狀態等）

---

#### 7. 網路通訊模組

**客戶端發送：** `MMLClientSendCommands.lua`
- `sendStartMML()` - 開始播放
- `sendStopMML()` - 停止播放

**客戶端接收：** `MMLClientRecvCommands.lua`
- 接收並處理伺服器指令

**伺服器端：** `MMLServerCommands.lua`
- 轉發播放指令給範圍內的玩家
- 驗證播放請求

---

### 🎯 關鍵設計模式

#### 1. 單例模式 (Singleton)
- `MusicPlayer` - 確保只有一個音效管理器
- `MMLInstrumentUI` - 確保只有一個樂器介面
- `MMLComposeUI` - 確保只有一個作曲介面

#### 2. 觀察者模式 (Observer)
- 使用 Project Zomboid 的 Events 系統
- `Events.OnPostRender` - 播放更新
- `Events.OnPreFillInventoryObjectContextMenu` - 右鍵選單

#### 3. 工廠模式 (Factory)
- `MMLParser:new()` 創建不同配置的解析器
- `MMLPlayer:new()` 創建不同樂器的播放器

---

### 🔧 資料流向

```
使用者輸入 MML
    ↓
MMLComposeUI / MMLInstrumentUI
    ↓
MMLPlayer.loadMML()
    ↓
MMLParser.parse() (每軌)
    ↓
音符序列 (時間軸)
    ↓
MMLPlayer.play()
    ↓
MMLPlayer.update() (每幀)
    ↓
MusicPlayer.playNote()
    ↓
實際音效播放
```

---

### 📝 MML 解析細節

#### Tick 系統

- PPQ (Pulses Per Quarter) = 480
- 一個四分音符 = 480 ticks
- 八分音符 = 240 ticks
- 十六分音符 = 120 ticks

#### 時間轉換

```lua
-- Tick 轉毫秒
msPerTick = (60000 / tempo) / PPQ
startTime = tick * msPerTick
duration = tickDuration * msPerTick
```

#### 附點音符計算

```lua
-- 附點乘數
function dotMultiplier(dotCount)
  -- 1 個附點: 1.5x
  -- 2 個附點: 1.75x
  -- 3 個附點: 1.875x
  return 1.0 + sum(1/2^i for i=1 to dotCount)
end
```

---

### 🎮 遊戲整合

#### 物品系統

樂譜物品存儲 MML 資料：

```lua
item:getModData().mml = {
  track1 = "t120 l4 o4 cdefg",
  track2 = "l4 o3 ccccg",
  track3 = "l2 o2 cg"
}
```

#### 動畫系統

支援多種樂器動畫：
- 鋼琴演奏（坐姿/站姿）
- 吉他演奏
- 小提琴演奏
- 長笛演奏
- 等等...

#### 音效資源

每個樂器包含完整的音階音效檔案：
```
media/sound/{instrument}/
  C0.ogg, Cs0.ogg, D0.ogg, ...
  C1.ogg, Cs1.ogg, D1.ogg, ...
  ...
  C8.ogg, Cs8.ogg, D8.ogg
```

---

### 🐛 除錯功能

#### 控制台輸出

主要模組都包含詳細的 `print()` 語句：

```lua
print("[MMLParser] Tempo changed to 120 BPM")
print("[MMLPlayer] Starting playback (Player: 1, Instrument: Piano)")
print("[MusicPlayer] Playing note C4 at volume 0.8")
```

#### 解析除錯

```lua
MMLParser:debugPrint()
-- 輸出：
-- - 當前速度
-- - 音符總數
-- - 總時長
-- - 每個音符的詳細資訊
```

---

### 🔐 錯誤處理

#### 輸入驗證

```lua
-- 檢查空輸入
if not mmlInput or mmlInput == "" then
  print("[MMLPlayer] Error: Empty MML input")
  return false
end

-- MIDI 音高範圍檢查
if noteNumber < 0 or noteNumber > 127 then
  print("[MMLParser] Warning: Invalid MIDI note number")
  return pos
end
```

#### 安全的屬性訪問

```lua
-- 使用短路運算子
local ui = MMLInstrumentUI.getExistingInstance and 
           MMLInstrumentUI.getExistingInstance() or nil
```

---

### 🚀 效能優化

#### 1. 音符排程

- 使用當前索引追蹤，避免重複檢查已播放的音符
- 只在音符到達播放時間時才處理

#### 2. 距離檢查

- 每幀檢查玩家距離
- 超出範圍自動停止播放

#### 3. 音效管理

- 追蹤活動音符
- 及時停止已結束的音效
- 避免音效洩漏

---

### 📚 延伸閱讀

#### MML 語法參考

MML (Music Macro Language) 起源於早期的電腦音樂系統，廣泛用於：
- 遊戲音樂創作
- MIDI 音序
- 嵌入式系統音樂

#### Project Zomboid 模組開發

- ISCollapsableWindow - UI 視窗基類
- Events 系統 - 遊戲事件掛鉤
- ModData - 物品資料持久化
- TimedAction - 時間動作系統

---

## English Documentation

### 🏗️ System Architecture

This project uses a modular design with the following layers:

```
UI Layer
    ↓
Playback Control Layer
    ↓
Parser Layer
    ↓
Sound Layer
```

### 📦 Core Module Details

#### 1. MMLParser.lua - MML Syntax Parser

**Responsibility:** Convert MML strings into playable note sequences

**Main Class:** `MMLParser`

**Key Methods:**

```lua
-- Create a new parser instance
MMLParser:new(sharedTempo)
-- Parameters:
--   sharedTempo: (optional) Shared tempo reference for multi-track sync

-- Parse MML string
MMLParser:parse(mml, defaultInstrument)
-- Parameters:
--   mml: MML string
--   defaultInstrument: Default instrument name
-- Returns: Note sequence table, Total duration (milliseconds)
```

**Supported MML Commands:**

| Command | Description | Example |
|---------|-------------|---------|
| C-B, H | Notes | `c d e f g a b` |
| O | Set octave | `o4` |
| < | Lower octave | `<c` |
| > | Raise octave | `>c` |
| L | Set default length | `l4` (quarter note) |
| T | Set tempo (BPM) | `t120` |
| V | Set velocity | `v8` |
| R | Rest | `r4` |
| N | Absolute pitch (MIDI) | `n60` |
| # / + | Sharp | `c#` |
| - | Flat | `b-` |
| . | Dot | `c4.` |
| & | Tie | `c4&c8` |

**Parsing Flow:**

1. Initialize parser state (octave, length, tempo, etc.)
2. Remove whitespace and convert to uppercase
3. Parse MML string character by character
4. Convert tick sequence to time sequence (milliseconds)

**Multi-track Synchronization:**

- Track 1 creates its own tempo reference
- Tracks 2 and 3 share Track 1's tempo
- Ensures all tracks play at the same speed

---

#### 2. MMLPlayer.lua - Music Player

**Responsibility:** Manage music playback process, handle multi-track synchronization

**Main Class:** `MMLPlayer`

**Key Methods:**

```lua
-- Create a new player
MMLPlayer:new(instrument, isSilent)
-- Parameters:
--   instrument: Instrument name
--   isSilent: Silent mode (for testing)

-- Load MML
MMLPlayer:loadMML(mmlInput)
-- Parameters:
--   mmlInput: Single or multi-track MML string (comma-separated)
-- Returns: Success boolean

-- Start playback
MMLPlayer:play()

-- Stop playback
MMLPlayer:stop()

-- Get playback progress (0.0-1.0)
MMLPlayer:getProgress()

-- Get remaining time (seconds)
MMLPlayer:getRemainingTime()
```

**Playback Flow:**

1. `loadMML()` - Parse and prepare note sequences
2. `play()` - Start playback
   - Register update function to `Events.OnPostRender`
   - Send network commands (multiplayer)
3. `update()` - Update every frame
   - Check distance (volume attenuation)
   - Schedule note playback
   - Manage note lifecycle
4. `stop()` - Stop playback
   - Stop all active notes
   - Remove update function
   - Send network commands

**Multi-track Handling:**

- Support up to 3 simultaneous tracks
- Independent note sequences per track
- Shared `startTime` for synchronization
- Automatic empty track completion

---

#### 3. MusicPlayer.lua - Sound Playback Controller

**Responsibility:** Low-level sound playback, manage sound instances

**Main Class:** `MusicPlayer` (Singleton pattern)

**Instrument Parameter Configuration:**

```lua
InstrumentParameters = {
  ["Piano"] = { 
    baseTime = 400,      -- Base duration (ms)
    fadingTime = 200,    -- Fade time (ms)
    polyphonic = true    -- Chord support
  },
  ["Violin"] = { ... },
  -- Other instruments...
}
```

**Note Playback Flow:**

1. Calculate pitch (MIDI note number)
2. Load corresponding sound file
3. Calculate volume (based on distance)
4. Play sound and track it
5. Stop sound at appropriate time

**Sound File Naming Convention:**

```
sound/{instrument}/{NoteName}.ogg
Example: sound/piano/C4.ogg
```

---

#### 4. MMLInstrumentUI.lua - Instrument Playing Interface

**Responsibility:** Provide in-game instrument playing interface

**Main Features:**

- Select sheet music (from items or preset songs)
- Play/Stop controls
- Display playback progress
- Handle instrument animations
- Seat detection (for piano, etc.)

**Interface Components:**

- Sheet music selection dropdown
- Play/Stop buttons
- Progress bar
- Status label

---

#### 5. MMLComposeUI.lua - Composition Interface

**Responsibility:** Provide in-game music creation interface

**Main Features:**

- Multi-track MML input (3 tracks)
- Real-time validation
- Playback preview
- Save to sheet music item
- Character limit (1500 per track)

**Validation Feature:**

```lua
-- Validate button checks:
1. MML syntax correctness
2. Note count per track
3. Total playback duration
4. Error message display
```

---

#### 6. MMLContextMenu.lua - Context Menu Integration

**Responsibility:** Integrate with game's context menu system

**Features:**

- Item context menu (instruments, sheet music)
- World object context menu (large instruments like piano)
- Condition checking (distance, state, etc.)

---

#### 7. Network Communication Modules

**Client Send:** `MMLClientSendCommands.lua`
- `sendStartMML()` - Start playback
- `sendStopMML()` - Stop playback

**Client Receive:** `MMLClientRecvCommands.lua`
- Receive and process server commands

**Server Side:** `MMLServerCommands.lua`
- Forward playback commands to players in range
- Validate playback requests

---

### 🎯 Key Design Patterns

#### 1. Singleton Pattern
- `MusicPlayer` - Ensures single sound manager
- `MMLInstrumentUI` - Ensures single instrument interface
- `MMLComposeUI` - Ensures single composition interface

#### 2. Observer Pattern
- Uses Project Zomboid's Events system
- `Events.OnPostRender` - Playback updates
- `Events.OnPreFillInventoryObjectContextMenu` - Context menu

#### 3. Factory Pattern
- `MMLParser:new()` creates parsers with different configurations
- `MMLPlayer:new()` creates players with different instruments

---

### 🔧 Data Flow

```
User Input MML
    ↓
MMLComposeUI / MMLInstrumentUI
    ↓
MMLPlayer.loadMML()
    ↓
MMLParser.parse() (per track)
    ↓
Note Sequence (timeline)
    ↓
MMLPlayer.play()
    ↓
MMLPlayer.update() (every frame)
    ↓
MusicPlayer.playNote()
    ↓
Actual Sound Playback
```

---

### 📝 MML Parsing Details

#### Tick System

- PPQ (Pulses Per Quarter) = 480
- One quarter note = 480 ticks
- Eighth note = 240 ticks
- Sixteenth note = 120 ticks

#### Time Conversion

```lua
-- Tick to milliseconds
msPerTick = (60000 / tempo) / PPQ
startTime = tick * msPerTick
duration = tickDuration * msPerTick
```

#### Dotted Note Calculation

```lua
-- Dot multiplier
function dotMultiplier(dotCount)
  -- 1 dot: 1.5x
  -- 2 dots: 1.75x
  -- 3 dots: 1.875x
  return 1.0 + sum(1/2^i for i=1 to dotCount)
end
```

---

### 🎮 Game Integration

#### Item System

Sheet music items store MML data:

```lua
item:getModData().mml = {
  track1 = "t120 l4 o4 cdefg",
  track2 = "l4 o3 ccccg",
  track3 = "l2 o2 cg"
}
```

#### Animation System

Supports various instrument animations:
- Piano playing (seated/standing)
- Guitar playing
- Violin playing
- Flute playing
- And more...

#### Sound Resources

Each instrument contains complete scale sound files:
```
media/sound/{instrument}/
  C0.ogg, Cs0.ogg, D0.ogg, ...
  C1.ogg, Cs1.ogg, D1.ogg, ...
  ...
  C8.ogg, Cs8.ogg, D8.ogg
```

---

### 🐛 Debugging Features

#### Console Output

Main modules include detailed `print()` statements:

```lua
print("[MMLParser] Tempo changed to 120 BPM")
print("[MMLPlayer] Starting playback (Player: 1, Instrument: Piano)")
print("[MusicPlayer] Playing note C4 at volume 0.8")
```

#### Parser Debug

```lua
MMLParser:debugPrint()
-- Outputs:
-- - Current tempo
-- - Total note count
-- - Total duration
-- - Detailed info for each note
```

---

### 🔐 Error Handling

#### Input Validation

```lua
-- Check empty input
if not mmlInput or mmlInput == "" then
  print("[MMLPlayer] Error: Empty MML input")
  return false
end

-- MIDI pitch range check
if noteNumber < 0 or noteNumber > 127 then
  print("[MMLParser] Warning: Invalid MIDI note number")
  return pos
end
```

#### Safe Property Access

```lua
-- Use short-circuit operators
local ui = MMLInstrumentUI.getExistingInstance and 
           MMLInstrumentUI.getExistingInstance() or nil
```

---

### 🚀 Performance Optimization

#### 1. Note Scheduling

- Use current index tracking to avoid rechecking played notes
- Process notes only when they reach playback time

#### 2. Distance Checking

- Check player distance every frame
- Automatically stop playback when out of range

#### 3. Sound Management

- Track active notes
- Stop finished sounds promptly
- Avoid sound leaks

---

### 📚 Further Reading

#### MML Syntax Reference

MML (Music Macro Language) originated from early computer music systems, widely used in:
- Game music creation
- MIDI sequencing
- Embedded system music

#### Project Zomboid Mod Development

- ISCollapsableWindow - UI window base class
- Events system - Game event hooks
- ModData - Item data persistence
- TimedAction - Timed action system
