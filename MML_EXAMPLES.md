# MML 範例 / MML Examples

這個檔案包含一些 MML 音樂範例，幫助您快速開始創作音樂。
This file contains some MML music examples to help you get started with music composition.

---

## 基礎範例 / Basic Examples

### 1. 簡單音階 / Simple Scale
```
t120 l4 o4 cdefgab>c
```
說明：以 120 BPM 播放 C 大調音階
Description: Play C major scale at 120 BPM

### 2. 附點音符 / Dotted Notes
```
t100 l4 o4 c. d8 e. f8 g2
```
說明：使用附點四分音符創造節奏變化
Description: Use dotted quarter notes for rhythmic variation

### 3. 連音符 / Tied Notes
```
t120 l4 o4 c&c8 d e&e&e8 f2
```
說明：使用 & 符號連接音符延長持續時間
Description: Use & to tie notes for longer duration

### 4. 休止符 / Rests
```
t120 l4 o4 c r e r g r >c2
```
說明：使用 r 表示休止符（靜音）
Description: Use r for rests (silence)

### 5. 八度變化 / Octave Changes
```
t120 l4 o3 c o4 c o5 c >c <c <c o3 c1
```
說明：使用 o, <, > 改變八度
Description: Use o, <, > to change octaves

---

## 多軌範例 / Multi-track Examples

### 1. 簡單和弦進行 / Simple Chord Progression
```
t100 l4 o4 cdefg>c<g2, l4 o3 ccccccc2, l2 o2 cg c1
```
說明：三軌同時演奏，創造和聲效果
Description: Three tracks playing together for harmonic effect

### 2. 旋律與伴奏 / Melody and Accompaniment
```
t120 l8 o5 cde fga >c <b ag2, l4 o3 c r c r c r c2, l2 o2 c g c1
```
說明：主旋律配上簡單的和弦伴奏
Description: Main melody with simple chord accompaniment

---

## 經典曲目範例 / Classic Song Examples

### 小星星 / Twinkle Twinkle Little Star
```
t120 l4 o4 ccggaag2 ffeeddc2 ggffeed2 ggffeed2 ccggaag2 ffeeddc1
```

### 瑪莉有隻小綿羊 / Mary Had a Little Lamb
```
t120 l4 o4 edcdeee2 ddd2 eee2 edcdeeee ddeddc1
```

### 生日快樂歌 / Happy Birthday
```
t120 l8 o4 c. c16 d c f e2 c. c16 d c g f2
```

---

## 進階技巧 / Advanced Techniques

### 1. 複雜節奏 / Complex Rhythm
```
t140 l8 o5 c16d16e8 d8 e8f8 e2 r4 c16d16e8 d8 c8d8 c2
```
說明：混合十六分音符和八分音符
Description: Mix sixteenth and eighth notes

### 2. 速度變化（多段）/ Tempo Changes
```
t100 l4 o4 cdef t140 gab>c t80 <gfed t120 c1
```
說明：在不同段落改變速度
Description: Change tempo in different sections

### 3. 力度控制 / Velocity Control
```
t120 l4 o4 v4 c v8 d v12 e v15 f v12 g v8 a v4 b >c1
```
說明：改變音符的音量（0-15）
Description: Change note volume (0-15)

### 4. 絕對音高 / Absolute Pitch
```
t120 l4 n60 n62 n64 n65 n67 n69 n71 n72
```
說明：使用 MIDI 音符編號（60 = 中央 C）
Description: Use MIDI note numbers (60 = Middle C)

---

## 樂器建議 / Instrument Suggestions

### 鋼琴 Piano
最適合：複雜和弦、古典音樂
Best for: Complex chords, classical music

### 吉他 Guitar
- GuitarClean: 流行音樂、民謠
- GuitarSteel: 鄉村音樂
- GuitarDistortion: 搖滾音樂

### 小提琴 Violin
最適合：抒情旋律、古典音樂
Best for: Lyrical melodies, classical music

### 長笛 Flute
最適合：輕快旋律、自然主題
Best for: Light melodies, nature themes

### 貝斯 Bass
最適合：低音伴奏、節奏基礎
Best for: Bass lines, rhythm foundation

---

## MML 語法快速參考 / MML Syntax Quick Reference

### 音符 Notes
- C D E F G A B (或 H)
- 升記號: # 或 +
- 降記號: -

### 長度 Length
- 1 = 全音符 (whole note)
- 2 = 二分音符 (half note)
- 4 = 四分音符 (quarter note)
- 8 = 八分音符 (eighth note)
- 16 = 十六分音符 (sixteenth note)

### 八度 Octave
- O0 到 O8: 設定八度
- <: 降低一個八度
- >: 升高一個八度

### 其他指令 Other Commands
- T: 速度 (BPM)
- L: 預設長度
- V: 力度/音量
- R: 休止符
- N: 絕對音高 (MIDI)
- &: 連音符
- .: 附點

---

## 創作技巧 / Composition Tips

### 1. 從簡單開始
Start simple: 先創作單軌旋律，再添加伴奏
Create a single melody track first, then add accompaniment

### 2. 使用驗證功能
Use validation: 在作曲介面中使用驗證按鈕檢查錯誤
Use the validate button in compose UI to check for errors

### 3. 分軌思考
Think in tracks:
- Track 1: 主旋律 (Main melody)
- Track 2: 和弦/伴奏 (Chords/Accompaniment)
- Track 3: 低音/節奏 (Bass/Rhythm)

### 4. 速度建議
Tempo suggestions:
- 慢速: 60-80 BPM (Slow)
- 中速: 90-120 BPM (Medium)
- 快速: 130-160 BPM (Fast)

### 5. 測試播放
Test playback: 經常播放測試，確保聽起來符合預期
Play frequently to ensure it sounds as expected

---

## 常見問題 / Common Issues

### Q: 音符聽起來太短？
A: 使用更長的音符值或連音符 (&)

### Q: 多軌不同步？
A: 確保只在 Track 1 設定速度 (T)，其他軌會自動同步

### Q: 超出字數限制？
A: 每軌最多 1500 字元，簡化 MML 或分段演奏

### Q: 音符超出範圍？
A: MIDI 音高範圍是 0-127，相當於 O0-O8

---

## 學習資源 / Learning Resources

### 在線 MML 工具
- MML Editor (線上編輯器)
- MIDI to MML 轉換器

### MML 社群
- Project Zomboid 模組社群
- MML 音樂創作論壇

---

祝您創作愉快！
Happy composing!
