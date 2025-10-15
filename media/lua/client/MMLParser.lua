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
  o.currentLengthDots = 0        -- 新增：預設長度的附點數 (例如 l1. )
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

    if char:match("[CDEFGABH]") then
      -- 音符 (支援 H 作為 B)
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
-- 工具函數：解析音符長度
-- 回傳：length, newPos, dotCount
-- 若有明確數字 -> 消耗數字與其後 '.' 並回傳 dotCount
-- 若無明確數字 -> 若緊接位置有 '.' 則消耗這些點作為此音符的附點並回傳（不使用 currentLengthDots）
--                  否則回傳 currentLength 與 currentLengthDots（pos 不變）
-- ============================================================
function MMLParser:parseNoteLength(mml, pos)
  -- 嘗試讀數字
  local num, newPos = self:parseNumber(mml, pos)
  if num > 0 then
    pos = newPos
    local dotCount = 0
    while pos <= #mml and mml:sub(pos, pos) == '.' do
      dotCount = dotCount + 1
      pos = pos + 1
    end
    return num, pos, dotCount
  end

  -- 沒有數字，檢查是否緊接著有附點（代表針對該音符的附點）
  local p = pos
  local dotCountLocal = 0
  while p <= #mml and mml:sub(p, p) == '.' do
    dotCountLocal = dotCountLocal + 1
    p = p + 1
  end
  if dotCountLocal > 0 then
    -- 消耗這些附點並回傳為此音符的附點數
    return self.currentLength, p, dotCountLocal
  end

  -- 都沒有明確數字或附點，使用目前預設長度與其附點（位置不前進）
  return self.currentLength, pos, (self.currentLengthDots or 0)
end

-- 內部輔助：計算附點乘數（1 + 1/2 + 1/4 + ...）
local function dotMultiplier(dotCount)
  if not dotCount or dotCount <= 0 then return 1.0 end
  local add = 0.0
  for i = 1, dotCount do
    add = add + 1.0 / (2 ^ i)
  end
  return 1.0 + add
end

-- 新增：解析被 & 連接的下一個段，回傳該段的 tick 長度與新的游標位置 (pos 指向該段開頭)
function MMLParser:parseTiedSegment(mml, pos)
  if pos > #mml then
    return 0, pos
  end

  -- 消耗並套用可能出現在被連接段前的控制符（<, >, O#, L#）
  while pos <= #mml do
    local ch = mml:sub(pos, pos)
    if ch == '<' then
      self.currentOctave = math.max(0, self.currentOctave - 1)
      pos = pos + 1
    elseif ch == '>' then
      self.currentOctave = math.min(8, self.currentOctave + 1)
      pos = pos + 1
    elseif ch == 'O' then
      -- 明確設定八度 O#
      pos = pos + 1
      local num, newPos = self:parseNumber(mml, pos)
      if num > 0 then
        self.currentOctave = num
        pos = newPos
      end
    elseif ch == 'L' then
      -- 改變預設長度（並支持附點 L1.）
      pos = pos + 1
      local num, newPos = self:parseNumber(mml, pos)
      if num > 0 then
        local dotCount = 0
        local p = newPos
        while p <= #mml and mml:sub(p, p) == '.' do
          dotCount = dotCount + 1
          p = p + 1
        end
        self.currentLength = num
        self.currentLengthDots = dotCount
        pos = p
      end
    else
      break
    end
  end

  if pos > #mml then
    return 0, pos
  end

  local ch = mml:sub(pos, pos)

  -- 處理音符字母段 (CDEFGABH)
  if ch:match("[CDEFGABH]") then
    -- 跳過音符字母
    pos = pos + 1

    -- 跳過升降號（如果有）
    if pos <= #mml then
      local acc = mml:sub(pos, pos)
      if acc == '#' or acc == '+' or acc == '-' then
        pos = pos + 1
      end
    end

    -- 解析該段的長度與附點 (parseNoteLength 會回傳 currentLength/currentLengthDots 當沒有數字)
    local len2, newPos2, dotCount2 = self:parseNoteLength(mml, pos)
    local baseAdd = math.floor((self.PPQ * 4) / len2)
    local add = math.floor(baseAdd * dotMultiplier(dotCount2) + 0.5)
    return add, newPos2
  end

  -- 處理絕對音高 N 開頭的段
  if ch == 'N' then
    pos = pos + 1
    -- 讀取 MIDI 編號 (消耗)
    local _, newPosNum = self:parseNumber(mml, pos)
    pos = newPosNum
    -- 長度與附點
    local len2, newPos2, dotCount2 = self:parseNoteLength(mml, pos)
    local baseAdd = math.floor((self.PPQ * 4) / len2)
    local add = math.floor(baseAdd * dotMultiplier(dotCount2) + 0.5)
    return add, newPos2
  end

  -- 處理休止符 R（如果有人把休止放在被連接段）
  if ch == 'R' then
    pos = pos + 1
    local len2, newPos2, dotCount2 = self:parseNoteLength(mml, pos)
    local baseAdd = math.floor((self.PPQ * 4) / len2)
    local add = math.floor(baseAdd * dotMultiplier(dotCount2) + 0.5)
    return add, newPos2
  end

  -- 其他情況：嘗試僅以長度解析（容錯）
  local len2, newPos2, dotCount2 = self:parseNoteLength(mml, pos)
  local baseAdd = math.floor((self.PPQ * 4) / len2)
  local add = math.floor(baseAdd * dotMultiplier(dotCount2) + 0.5)
  return add, newPos2
end

-- ============================================================
-- 解析音符
-- 已改为使用 parseTiedSegment 來正確消耗被連接的段
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

  -- 解析音符長度 (回傳 length, newPos, dotCount)
  local length, newPos, dotCount = self:parseNoteLength(mml, pos)
  pos = newPos
  local baseDuration = math.floor((self.PPQ * 4) / length)
  local duration = math.floor(baseDuration * dotMultiplier(dotCount) + 0.5)

  -- Tie 連音符（&）: 使用 parseTiedSegment 消耗下一段並取得其長度
  while pos <= #mml and mml:sub(pos, pos) == '&' do
    pos = pos + 1
    local add, newPosAfter = self:parseTiedSegment(mml, pos)
    duration = duration + add
    pos = newPosAfter
  end

  -- 添加音符
  self:addNote(noteNumber, duration, self.currentVelocity)

  return pos
end

-- ============================================================
-- 解析休止符
-- 使用相同的附點規則
-- ============================================================
function MMLParser:parseRest(mml, pos)
  pos = pos + 1 -- 跳過 'R'

  local length, newPos, dotCount = self:parseNoteLength(mml, pos)
  pos = newPos
  local baseDuration = math.floor((self.PPQ * 4) / length)
  local duration = math.floor(baseDuration * dotMultiplier(dotCount) + 0.5)

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
-- 解析預設音符長度 (L)，現在支援附點 (如 L1.)
-- ============================================================
function MMLParser:parseDefaultLength(mml, pos)
  pos = pos + 1 -- 跳過 'L'
  local num, newPos = self:parseNumber(mml, pos)
  if num > 0 then
    -- 讀取附點並記錄為 currentLengthDots
    local dotCount = 0
    local p = newPos
    while p <= #mml and mml:sub(p, p) == '.' do
      dotCount = dotCount + 1
      p = p + 1
    end
    self.currentLength = num
    self.currentLengthDots = dotCount
    pos = p
  end
  return pos
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
-- 工具函數：獲取 MIDI 音符編號
-- ============================================================
function MMLParser:getNoteNumber(noteName, octave, accidental)
  -- MIDI note mapping: A B C D E F G  (支援 H 當作 B)
  local offsets = {
    A = 9,
    B = 11,
    H = 11, -- 德語習慣：H 視作 B
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
-- 使用相同的附點與 & 處理，且使用 parseTiedSegment 來正確消耗段
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

  -- 音長由 currentLength 決定 (不能從 n 後直接讀取，parseNoteLength 會回傳 currentLength 與 currentLengthDots)
  local length, newPos2, dotCount = self:parseNoteLength(mml, pos)
  pos = newPos2
  local baseDuration = math.floor((self.PPQ * 4) / length)
  local duration = math.floor(baseDuration * dotMultiplier(dotCount) + 0.5)

  -- Tie 連音符處理（消耗被連接段）
  while pos <= #mml and mml:sub(pos, pos) == '&' do
    pos = pos + 1
    local add, newPosAfter = self:parseTiedSegment(mml, pos)
    duration = duration + add
    pos = newPosAfter
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
