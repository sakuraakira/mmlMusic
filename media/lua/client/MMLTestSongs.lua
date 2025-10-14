-- MMLTestSongs.lua
-- 用於測試的 MML 樂曲集合
local MMLTestSongs = {}

-- ============================================================
-- 測試樂曲庫
-- ============================================================
MMLTestSongs.songs = {
  -- 1. 基礎測試 - 簡單音階
  {
    name = "Scale Test",
    description = "Basic scale test (C major)",
    mml = "T120 L4 O4 CDEFGAB O5 C",
    duration = "~4s"
  },

  -- 2. 小星星
  {
    name = "Twinkle Twinkle",
    description = "Twinkle Twinkle Little Star",
    mml = "T120 L4 O4 CCGGAAG2 FFEEDDC2 GGFFEED2 GGFFEED2 CCGGAAG2 FFEEDDC2",
    duration = "~32s"
  },

  -- 3. 快樂頌
  {
    name = "Ode to Joy",
    description = "Beethoven - Ode to Joy",
    mml = "T120 L4 O4 EEFG GFED CCDE E2D2 EEFG GFED CCDE D2C2",
    duration = "~16s"
  },

  -- 4. 速度測試
  {
    name = "Speed Test",
    description = "Fast tempo test (240 BPM)",
    mml = "T240 L8 O4 CDEFGAB O5 C O4 BAGFEDC",
    duration = "~2s"
  },

  -- 5. 慢速測試
  {
    name = "Slow Test",
    description = "Slow tempo test (60 BPM)",
    mml = "T60 L4 O4 CDEFGAB O5 C",
    duration = "~16s"
  },

  -- 6. 音符長度測試
  {
    name = "Duration Test",
    description = "Various note durations",
    mml = "T120 O4 C1 C2 C4 C8 C16",
    duration = "~8s"
  },

  -- 7. 升降音測試
  {
    name = "Accidental Test",
    description = "Sharp and flat notes",
    mml = "T120 L4 O4 C C# D D# E F F# G G# A A# B",
    duration = "~6s"
  },

  -- 8. 八度測試
  {
    name = "Octave Test",
    description = "Multiple octaves",
    mml = "T120 L4 O2 C O3 C O4 C O5 C O4 C O3 C O2 C",
    duration = "~7s"
  },

  -- 9. 休止符測試
  {
    name = "Rest Test",
    description = "Notes with rests",
    mml = "T120 L4 O4 C R C R C R C",
    duration = "~7s"
  },

  -- 10. 附點音符測試
  {
    name = "Dotted Notes",
    description = "Dotted note durations",
    mml = "T120 L4 O4 C. D8 E. F8 G2",
    duration = "~5s"
  },

  -- 11. 瑪莉有隻小綿羊
  {
    name = "Mary Had A Little Lamb",
    description = "Classic children's song",
    mml = "T120 L4 O4 EDCDEEE2 DDD2 EGG2 EDCDEEE2 EDDEDC",
    duration = "~16s"
  },

  -- 12. 生日快樂
  {
    name = "Happy Birthday",
    description = "Happy Birthday to You",
    mml = "T100 L4 O4 GG A G O5 C O4 B2 GG A G O5 D C2 O4 GG O5 G E C O4 BA O5 FF E C D C2",
    duration = "~16s"
  },

  -- 13. 複雜節奏測試
  {
    name = "Complex Rhythm",
    description = "Mixed note lengths and tempos",
    mml = "T140 L8 O4 C16D16E4 F8G8A4 B8O5C8D4 L4 O4 E F G A",
    duration = "~6s"
  },

  -- 14. 音域測試 (A1-E6)
  {
    name = "Full Range Test",
    description = "Test full piano range (A1 to E6)",
    mml = "T120 L4 O1 A O2 C O3 C O4 C O5 C O6 C O6 E O5 C O4 C O3 C O2 C O1 A",
    duration = "~12s"
  },

  -- 15. 錯誤測試 (測試解析器容錯)
  {
    name = "Error Test",
    description = "Intentional syntax errors",
    mml = "T120 L4 O4 C D E XYZ F G",     -- XYZ 是無效指令
    duration = "~4s"
  },
}

-- ============================================================
-- 獲取測試樂曲
-- ============================================================
function MMLTestSongs.getSong(index)
  return MMLTestSongs.songs[index]
end

function MMLTestSongs.getSongByName(name)
  for _, song in ipairs(MMLTestSongs.songs) do
    if song.name == name then
      return song
    end
  end
  return nil
end

function MMLTestSongs.getTotalCount()
  return #MMLTestSongs.songs
end

-- ============================================================
-- 列印所有測試樂曲
-- ============================================================
function MMLTestSongs.printAll()
  print("[MML Test Songs] ========================================")
  print("[MML Test Songs] Available test songs:")
  for i, song in ipairs(MMLTestSongs.songs) do
    print(string.format("[MML Test Songs] %2d. %-25s %s (%s)",
      i, song.name, song.description, song.duration))
  end
  print("[MML Test Songs] ========================================")
end

-- ============================================================
-- 快速測試函數
-- ============================================================
function MMLTestSongs.quickTest(index)
  local song = MMLTestSongs.getSong(index)
  if not song then
    print("[MML Test] Invalid song index: " .. tostring(index))
    return false
  end

  print("[MML Test] ========================================")
  print("[MML Test] Testing: " .. song.name)
  print("[MML Test] " .. song.description)
  print("[MML Test] Duration: " .. song.duration)
  print("[MML Test] MML: " .. song.mml)
  print("[MML Test] ========================================")

  local MMLPlayer = require('MMLPlayer')
  local player = MMLPlayer:new("Piano")

  if not player:loadMML(song.mml) then
    print("[MML Test] Failed to load MML!")
    return false
  end

  if player:play() then
    print("[MML Test] Playing...")
    return true
  else
    print("[MML Test] Failed to play!")
    return false
  end
end

-- ============================================================
-- 測試所有樂曲（僅解析，不播放）
-- ============================================================
function MMLTestSongs.validateAll()
  local MMLParser = require('MMLParser')
  local passed = 0
  local failed = 0

  print("[MML Test] ========================================")
  print("[MML Test] Validating all test songs...")
  print("[MML Test] ========================================")

  for i, song in ipairs(MMLTestSongs.songs) do
    local parser = MMLParser:new()
    local success, result = pcall(function()
      return parser:parse(song.mml, "Piano")
    end)

    if success and result and #result > 0 then
      passed = passed + 1
      print(string.format("[MML Test] ✓ %2d. %-25s OK (%d notes)",
        i, song.name, #result))
    else
      failed = failed + 1
      print(string.format("[MML Test] ✗ %2d. %-25s FAILED",
        i, song.name))
    end
  end

  print("[MML Test] ========================================")
  print(string.format("[MML Test] Results: %d passed, %d failed", passed, failed))
  print("[MML Test] ========================================")

  return passed, failed
end

return MMLTestSongs
