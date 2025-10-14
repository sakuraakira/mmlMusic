-- MMLParser.lua
-- 參考 Java MabiMmlPlayer 實現的 MML 解析器
local MMLParser = {}

function MMLParser:new(sharedTempo)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  -- 解析狀態
  o.currentTick = 0
  o.currentOctave = 4
  o.currentLength = 4
  o.currentVelocity = 100
  o.currentInstrument = nil

  -- ========== 新增:支援共享 tempo ==========
  if sharedTempo then
    -- Track 2/3 使用共享的 tempo table
    o.tempoRef = sharedTempo
    o.isSharedTempo = true
  else
    -- Track 1 創建自己的 tempo table
    o.tempoRef = { value = 120 }
    o.isSharedTempo = false
  end
  -- ==========================================

  o.PPQ = 480
  o.notes = {}
  o.totalTicks = 0

  return o
end

-- ============================================================
-- 主解析函數
-- ============================================================
function MMLParser:parse(mml, defaultInstrument)
  self.notes = {}
  self.currentTick = 0
  self.currentInstrument = defaultInstrument or "Piano"

  -- 移除空白並轉大寫
  mml = mml:upper():gsub("%s+", "")

  local i = 1
  while i <= #mml do
    local char = mml:sub(i, i)

    if char:match("[CDEFGAB]") then
      -- 音符
      i = self:parseNote(mml, i)
    elseif char == 'R' then
      -- 休止符
      i = self:parseRest(mml, i)
    elseif char == 'O' then
      -- 設定八度
      i = self:parseOctave(mml, i)
    elseif char == 'L' then
      -- 設定預設音符長度
      i = self:parseDefaultLength(mml, i)
    elseif char == 'T' then
      -- 設定速度
      i = self:parseTempo(mml, i)
    elseif char == 'V' then
      -- 設定力度
      i = self:parseVelocity(mml, i)
    elseif char == '@' then
      -- 設定樂器 (暫不實現，PZ 中需要在 MMLPlayer 層處理)
      i = self:parseProgram(mml, i)
    elseif char == '<' then
      -- 降低八度
      self.currentOctave = math.max(0, self.currentOctave - 1)
      i = i + 1
    elseif char == '>' then
      -- 升高八度
      self.currentOctave = math.min(8, self.currentOctave + 1)
      i = i + 1
    elseif char == 'N' then
      -- 絕對音高
      i = self:parseAbsoluteNote(mml, i)
    else
      -- 未知字符，跳過
      i = i + 1
    end
  end

  self.totalTicks = self.currentTick

  -- 轉換為時間（毫秒）
  return self:convertToTimeSequence()
end

-- ============================================================
-- 解析音符
-- ============================================================
function MMLParser:parseNote(mml, pos)
  local noteName = mml:sub(pos, pos)
  pos = pos + 1

  -- 升降號
  local accidental = 0
  if pos <= #mml then
    local acc = mml:sub(pos, pos)
    if acc == '#' or acc == '+' then
      accidental = 1
      pos = pos + 1
    elseif acc == '-' then
      accidental = -1
      pos = pos + 1
    end
  end

  -- 獲取音符編號
  local noteNumber = self:getNoteNumber(noteName, self.currentOctave, accidental)

  -- 解析音符長度
  local length, newPos = self:parseNoteLength(mml, pos)
  pos = newPos
  local duration = math.floor((self.PPQ * 4) / length)

  -- 附點（延長 1.5 倍）
  while pos <= #mml and mml:sub(pos, pos) == '.' do
    duration = duration + math.floor(duration / 2)
    pos = pos + 1
  end

  -- Tie 連音符（&）
  while pos <= #mml and mml:sub(pos, pos) == '&' do
    pos = pos + 1
    local len2, newPos2 = self:parseNoteLength(mml, pos)
    len2 = len2 > 0 and len2 or self.currentLength
    pos = newPos2
    local add = math.floor((self.PPQ * 4) / len2)

    -- 附點
    while pos <= #mml and mml:sub(pos, pos) == '.' do
      add = add + math.floor(add / 2)
      pos = pos + 1
    end

    duration = duration + add
  end

  -- 添加音符
  self:addNote(noteNumber, duration, self.currentVelocity)

  return pos
end

-- ============================================================
-- 解析休止符
-- ============================================================
function MMLParser:parseRest(mml, pos)
  pos = pos + 1 -- 跳過 'R'

  local length, newPos = self:parseNoteLength(mml, pos)
  pos = newPos
  local duration = math.floor((self.PPQ * 4) / length)

  -- 附點
  while pos <= #mml and mml:sub(pos, pos) == '.' do
    duration = duration + math.floor(duration / 2)
    pos = pos + 1
  end

  -- 休止符只增加時間，不添加音符
  self.currentTick = self.currentTick + duration

  return pos
end

-- ============================================================
-- 解析八度
-- ============================================================
function MMLParser:parseOctave(mml, pos)
  pos = pos + 1 -- 跳過 'O'
  local num, newPos = self:parseNumber(mml, pos)
  if num > 0 then
    self.currentOctave = num
  end
  return newPos
end

-- ============================================================
-- 解析預設音符長度
-- ============================================================
function MMLParser:parseDefaultLength(mml, pos)
  pos = pos + 1 -- 跳過 'L'
  local num, newPos = self:parseNumber(mml, pos)
  if num > 0 then
    self.currentLength = num
  end
  return newPos
end

-- ============================================================
-- 解析速度
-- ============================================================
function MMLParser:parseTempo(mml, pos)
  pos = pos + 1 -- 跳過 'T'
  local num, newPos = self:parseNumber(mml, pos)

  if num > 0 then
    if self.isSharedTempo then
      -- Track 2/3:忽略 tempo 指令
      print(string.format("[MMLParser] Warning: Tempo change (t%d) ignored in shared track", num))
    else
      -- Track 1:允許修改
      self.tempoRef.value = num
      print(string.format("[MMLParser] Tempo changed to %d BPM", num))
    end
  end

  return newPos
end

-- ============================================================
-- 解析力度
-- ============================================================
function MMLParser:parseVelocity(mml, pos)
  pos = pos + 1 -- 跳過 'V'
  local num, newPos = self:parseNumber(mml, pos)
  if num >= 0 then
    -- MML 的 V 值通常是 0-15，轉換為 MIDI 的 0-127
    self.currentVelocity = math.min(127, num * 8)
  end
  return newPos
end

-- ============================================================
-- 解析樂器切換（暫時只記錄，不處理）
-- ============================================================
function MMLParser:parseProgram(mml, pos)
  pos = pos + 1 -- 跳過 '@'
  local num, newPos = self:parseNumber(mml, pos)
  if num >= 0 then
    -- 在 PZ 中，我們暫時不處理 MIDI Program Change
    -- 可以在這裡記錄，讓 MMLPlayer 切換樂器
    -- self.currentInstrument = self:midiProgramToInstrument(num)
  end
  return newPos
end

-- ============================================================
-- 工具函數：解析數字
-- ============================================================
function MMLParser:parseNumber(mml, pos)
  local start = pos
  while pos <= #mml and mml:sub(pos, pos):match("%d") do
    pos = pos + 1
  end

  local num = 0
  if start < pos then
    num = tonumber(mml:sub(start, pos - 1))
  end

  return num, pos
end

-- ============================================================
-- 工具函數：解析音符長度
-- ============================================================
function MMLParser:parseNoteLength(mml, pos)
  local num, newPos = self:parseNumber(mml, pos)
  local length = num > 0 and num or self.currentLength
  return length, newPos
end

-- ============================================================
-- 工具函數：獲取 MIDI 音符編號
-- ============================================================
function MMLParser:getNoteNumber(noteName, octave, accidental)
  -- MIDI note mapping: A B C D E F G
  local offsets = {
    A = 9,
    B = 11,
    C = 0,
    D = 2,
    E = 4,
    F = 5,
    G = 7
  }

  local offset = offsets[noteName]
  return (octave + 1) * 12 + offset + accidental
end

-- ============================================================
-- 解析絕對音高 (n指令)
-- ============================================================
function MMLParser:parseAbsoluteNote(mml, pos)
  pos = pos + 1 -- 跳過 'N'

  -- 解析 MIDI note number
  local noteNumber, newPos = self:parseNumber(mml, pos)
  pos = newPos

  if noteNumber < 0 or noteNumber > 127 then
    print(string.format("[MMLParser] Warning: Invalid MIDI note number %d", noteNumber))
    return pos
  end

  -- 音長由 currentLength 決定 (不能從 n 後直接讀取)
  local length = self.currentLength
  local duration = math.floor((self.PPQ * 4) / length)

  -- 附點處理
  while pos <= #mml and mml:sub(pos, pos) == '.' do
    duration = duration + math.floor(duration / 2)
    pos = pos + 1
  end

  -- Tie 連音符處理
  while pos <= #mml and mml:sub(pos, pos) == '&' do
    pos = pos + 1
    local len2, newPos2 = self:parseNoteLength(mml, pos)
    pos = newPos2
    local add = math.floor((self.PPQ * 4) / len2)

    while pos <= #mml and mml:sub(pos, pos) == '.' do
      add = add + math.floor(add / 2)
      pos = pos + 1
    end

    duration = duration + add
  end

  -- 添加音符 (直接使用 MIDI note number)
  self:addNote(noteNumber, duration, self.currentVelocity)

  return pos
end

-- ============================================================
-- 工具函數：MIDI 音符編號轉音符名稱
-- ============================================================
function MMLParser:midiNumberToNoteName(midiNumber)
  local noteNames = {
    'C', 'Cs', 'D', 'Ds', 'E', 'F',
    'Fs', 'G', 'Gs', 'A', 'As', 'B'
  }

  local octave = math.floor(midiNumber / 12) - 1
  local noteIndex = (midiNumber % 12) + 1
  local noteName = noteNames[noteIndex]

  return noteName .. octave
end

-- ============================================================
-- 工具函數：添加音符到序列
-- ============================================================
function MMLParser:addNote(midiNumber, duration, velocity)
  local noteName = self:midiNumberToNoteName(midiNumber)

  table.insert(self.notes, {
    note = noteName,
    tick = self.currentTick,
    duration = duration,
    velocity = velocity,
    instrument = self.currentInstrument
  })

  self.currentTick = self.currentTick + duration
end

-- ============================================================
-- 轉換 Tick 序列為時間序列（毫秒）
-- ============================================================
function MMLParser:convertToTimeSequence()
  local result = {}

  -- 使用共享的 tempo 值
  local tempo = self.tempoRef.value
  local msPerTick = (60000 / tempo) / self.PPQ

  for _, note in ipairs(self.notes) do
    table.insert(result, {
      note = note.note,
      startTime = math.floor(note.tick * msPerTick),
      duration = math.floor(note.duration * msPerTick),
      velocity = note.velocity,
      instrument = note.instrument,
      played = false
    })
  end

  local totalDuration = math.floor(self.totalTicks * msPerTick)

  return result, totalDuration
end

-- ============================================================
-- 調試：列印解析結果
-- ============================================================
function MMLParser:debugPrint()
  print("=== MML Parser Debug ===")
  print(string.format("Tempo: %d BPM", self.currentTempo))
  print(string.format("Total Notes: %d", #self.notes))
  print(string.format("Total Duration: %.2f seconds", self.totalTicks * (60000 / self.currentTempo) / self.PPQ / 1000))
  print("\nNotes:")

  for i, note in ipairs(self.notes) do
    local timeMs = note.tick * (60000 / self.currentTempo) / self.PPQ
    print(string.format("  %3d: %4s at %7.0fms (dur:%5.0fms) vel:%3d",
      i, note.note, timeMs,
      note.duration * (60000 / self.currentTempo) / self.PPQ,
      note.velocity))
  end
end

return MMLParser
