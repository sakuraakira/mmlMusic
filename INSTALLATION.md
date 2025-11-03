# 安裝與配置指南 / Installation and Configuration Guide

[中文指南](#中文指南) | [English Guide](#english-guide)

---

## 中文指南

### 📥 安裝方式

#### 方法 1: Steam 工作坊（推薦）
1. 在 Steam 工作坊搜尋 "mmlMusic"
2. 點擊訂閱
3. 啟動遊戲並在模組選單中啟用

#### 方法 2: 手動安裝
1. 下載模組檔案
2. 解壓縮到 Project Zomboid 模組資料夾：
   - Windows: `C:\Users\<使用者名稱>\Zomboid\mods\`
   - Linux: `~/.zomboid/mods/`
   - Mac: `~/Zomboid/mods/`
3. 啟動遊戲並在模組選單中啟用

### ⚙️ 沙盒設定

模組提供以下沙盒選項（在創建新遊戲時設定）：

#### 音效範圍 (Sound Range)
- **位置：** 沙盒選項 > BardInteractiveMusic > Sound Range
- **預設值：** 40 方格
- **範圍：** 10-100 方格
- **說明：** 設定音樂可以被聽到的最大距離

**建議設定：**
- 小型房間/室內：10-20
- 一般遊戲：30-50（預設 40）
- 大型場地/戶外：60-100

### 🎮 遊戲內使用

#### 1. 找到樂器
- 從世界中尋找樂器物品
- 製作樂器（如果有配方）
- 使用世界中的大型樂器（鋼琴等）

#### 2. 開始演奏

**方式 A：從背包物品**
1. 右鍵點擊背包中的樂器
2. 選擇 "演奏" (Play)
3. 在介面中選擇樂譜或輸入 MML
4. 點擊播放

**方式 B：從世界物件**
1. 靠近鋼琴等大型樂器
2. 右鍵點擊樂器
3. 選擇 "演奏" (Play)
4. 角色會坐下或站在樂器旁

#### 3. 創作音樂
1. 右鍵點擊樂譜物品
2. 選擇 "編輯" (Edit/Compose)
3. 在三個軌道輸入 MML
4. 點擊驗證檢查語法
5. 點擊播放預覽
6. 儲存到樂譜物品

### 🎵 支援的樂器清單

| 樂器名稱 | 物品 ID | 特性 |
|---------|---------|------|
| Piano | Piano | 全音域，適合複雜曲目 |
| GuitarClean | GuitarClean | 清晰音色，適合流行曲 |
| GuitarSteel | GuitarSteel | 鋼弦吉他，鄉村風格 |
| GuitarDistortion | GuitarDistortion | 失真音色，搖滾風格 |
| BassFinger | BassFinger | 低音，適合伴奏 |
| Violin | Violin | 弦樂，抒情旋律 |
| Flute | Flute | 木管，輕快旋律 |
| Saxophone | Saxophone | 薩克斯風，爵士風格 |
| Trumpet | Trumpet | 小號，明亮音色 |

### 🔧 進階設定

#### 修改音效範圍（伺服器管理員）

編輯伺服器設定檔案：
```
<伺服器目錄>/Server/<伺服器名稱>.ini
```

添加或修改：
```ini
BardInteractiveMusic.SoundRange=40
```

#### 自訂樂器音效

1. 找到模組資料夾中的 `media/sound/` 目錄
2. 創建新的樂器資料夾
3. 放入音階音效檔案（C0.ogg - C8.ogg）
4. 在 `media/lua/client/MusicPlayer.lua` 中註冊樂器參數

### 🐛 疑難排解

#### 問題：聽不到音樂
**解決方案：**
- 檢查遊戲音量設定
- 確認音效範圍設定
- 檢查角色是否在範圍內

#### 問題：MML 語法錯誤
**解決方案：**
- 使用作曲介面的驗證功能
- 參考 MML_EXAMPLES.md 中的範例
- 檢查 MML 指令大小寫（不區分，但建議統一）

#### 問題：多軌不同步
**解決方案：**
- 確保只在第一軌設定速度 (t120)
- 其他軌會自動同步第一軌的速度

#### 問題：音符範圍錯誤
**解決方案：**
- 檢查八度設定（O0-O8）
- MIDI 音符範圍：0-127

### 📊 效能建議

#### 單人遊戲
- 預設設定即可
- 音效範圍：30-50

#### 多人伺服器
- 建議音效範圍：20-40
- 避免同時播放太多複雜曲目
- 考慮限制同時演奏的玩家數量

### 🔄 更新模組

#### Steam 工作坊
- 自動更新
- 重啟遊戲即可

#### 手動安裝
1. 備份現有設定
2. 刪除舊版本模組資料夾
3. 下載並安裝新版本
4. 恢復設定（如有需要）

---

## English Guide

### 📥 Installation

#### Method 1: Steam Workshop (Recommended)
1. Search for "mmlMusic" in Steam Workshop
2. Click Subscribe
3. Launch the game and enable the mod in the mod menu

#### Method 2: Manual Installation
1. Download the mod files
2. Extract to Project Zomboid mods folder:
   - Windows: `C:\Users\<username>\Zomboid\mods\`
   - Linux: `~/.zomboid/mods/`
   - Mac: `~/Zomboid/mods/`
3. Launch the game and enable the mod in the mod menu

### ⚙️ Sandbox Settings

The mod provides the following sandbox options (set when creating a new game):

#### Sound Range
- **Location:** Sandbox Options > BardInteractiveMusic > Sound Range
- **Default:** 40 tiles
- **Range:** 10-100 tiles
- **Description:** Sets the maximum distance at which music can be heard

**Recommended Settings:**
- Small rooms/indoor: 10-20
- Normal gameplay: 30-50 (default 40)
- Large venues/outdoor: 60-100

### 🎮 In-Game Usage

#### 1. Find an Instrument
- Search for instrument items in the world
- Craft instruments (if recipes are available)
- Use world objects like pianos

#### 2. Start Playing

**Method A: From Inventory Item**
1. Right-click an instrument in your inventory
2. Select "Play"
3. Choose sheet music or enter MML in the interface
4. Click play

**Method B: From World Object**
1. Approach a large instrument like a piano
2. Right-click the instrument
3. Select "Play"
4. Character will sit or stand by the instrument

#### 3. Compose Music
1. Right-click a sheet music item
2. Select "Edit" or "Compose"
3. Enter MML in the three tracks
4. Click validate to check syntax
5. Click play to preview
6. Save to the sheet music item

### 🎵 Supported Instruments

| Instrument | Item ID | Characteristics |
|-----------|---------|----------------|
| Piano | Piano | Full range, suitable for complex pieces |
| GuitarClean | GuitarClean | Clean tone, suitable for pop |
| GuitarSteel | GuitarSteel | Steel string, country style |
| GuitarDistortion | GuitarDistortion | Distortion, rock style |
| BassFinger | BassFinger | Bass, suitable for accompaniment |
| Violin | Violin | Strings, lyrical melodies |
| Flute | Flute | Woodwind, light melodies |
| Saxophone | Saxophone | Jazz style |
| Trumpet | Trumpet | Bright tone |

### 🔧 Advanced Configuration

#### Modify Sound Range (Server Admins)

Edit server configuration file:
```
<server_directory>/Server/<server_name>.ini
```

Add or modify:
```ini
BardInteractiveMusic.SoundRange=40
```

#### Custom Instrument Sounds

1. Locate the `media/sound/` directory in the mod folder
2. Create a new instrument folder
3. Add scale sound files (C0.ogg - C8.ogg)
4. Register instrument parameters in `media/lua/client/MusicPlayer.lua`

### 🐛 Troubleshooting

#### Issue: Cannot hear music
**Solution:**
- Check game volume settings
- Verify sound range settings
- Check if character is within range

#### Issue: MML syntax error
**Solution:**
- Use validation feature in compose UI
- Refer to examples in MML_EXAMPLES.md
- Check MML command case (case-insensitive but consistency recommended)

#### Issue: Multi-track out of sync
**Solution:**
- Ensure tempo is only set in first track (t120)
- Other tracks will automatically sync to first track's tempo

#### Issue: Note range error
**Solution:**
- Check octave settings (O0-O8)
- MIDI note range: 0-127

### 📊 Performance Recommendations

#### Single Player
- Default settings are fine
- Sound range: 30-50

#### Multiplayer Server
- Recommended sound range: 20-40
- Avoid too many complex pieces playing simultaneously
- Consider limiting concurrent performing players

### 🔄 Updating the Mod

#### Steam Workshop
- Automatic updates
- Restart the game

#### Manual Installation
1. Backup existing settings
2. Delete old mod folder
3. Download and install new version
4. Restore settings (if needed)

---

### 📝 Version History

**Version 1 (Current)**
- Initial release
- Full MML parser implementation
- Multi-track support (3 tracks)
- Multiple instrument support
- Multiplayer synchronization
- In-game composition interface

---

### 🤝 Compatibility

**Game Version:** Project Zomboid Build 41+

**Compatible with:**
- Single player mode
- Multiplayer mode
- Dedicated servers

**Known Conflicts:**
- None reported

---

### 📞 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing documentation
- Review MML_EXAMPLES.md for syntax help
- Consult DOCUMENTATION.md for technical details
