local MMLParser = require("MMLParser")
local MusicPlayer = require("MusicPlayer")


-- MMLPlayer.lua
---@class MMLPlayer
---@field new fun(self: MMLPlayer ,instrument: string , isSilent:boolean): MMLPlayer
local MMLPlayer = {}
-- 全局設定
MMLPlayer.activePlayers = {}
MMLPlayer.soundRange = nil
MMLPlayer.GlobalStartAt = nil

-- ============================================================
-- 全局設定函數
-- ============================================================
function MMLPlayer.setRange(range)
  MMLPlayer.soundRange = range
  print("[MMLPlayer] Sound range set to: " .. range)
end

function MMLPlayer.getRange()
  return MMLPlayer.soundRange or 40
end

function MMLPlayer.setGlobalStartAt(t)
  MMLPlayer.GlobalStartAt = t
end

-- ============================================================
-- 創建新的播放器實例
-- ============================================================
function MMLPlayer:new(instrument, isSilent)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.instrument = instrument or "Piano"
  o.tracks = {}
  o.totalDuration = 0
  o.isPlaying = false
  o.startTime = 0
  o.updateFunc = nil
  o.sourcePlayer = nil
  o.originalMML = ""
  o.playerId = nil
  o.isSilent = isSilent or false
  o.activeNotes = {}

  return o
end

-- ============================================================
-- 輔助函數:trim 字符串
-- ============================================================
local function trim(s)
  if not s then return "" end
  return s:match("^%s*(.-)%s*$")
end


function MMLPlayer:loadMML(mmlInput)
  if not mmlInput or mmlInput == "" then
    print("[MMLPlayer] Error: Empty MML input")
    return false
  end

  local MAX_TRACKS = 15

  -- 1) 切成多軌（最多 15 軌）
  local rawTracks = {}
  for token in mmlInput:gmatch("([^,]+)") do
    table.insert(rawTracks, trim(token))
    if #rawTracks >= MAX_TRACKS then break end
  end
  if #rawTracks == 0 then table.insert(rawTracks, "") end

  -- 2) 從 1~15 軌「開頭」找初始 tempo
  local initialTempoToken, tempoCarrierIndex = nil, nil
  for i = 1, #rawTracks do
    local headTempo = rawTracks[i]:match('^%s*([tT]%s*%d+)')
    if headTempo then
      initialTempoToken = headTempo:gsub('%s+', '') -- "t 120" -> "t120"
      tempoCarrierIndex = i
      break
    end
  end

  -- 3) 建立共用狀態
  self.tracks = {}
  self.totalDuration = 0
  self.originalMML = ""
  local sharedTempo = { value = 120 } -- 全域 tempo 參照
  local anyNotes = 0

  -- 4) 先整理各軌文字：
  --    - 只有第 1 軌允許保留 tempo（包含中途變速）
  --    - 若初始 tempo 在第 1 軌之外，移到第 1 軌最前面，並從原軌移除「開頭 tempo」
  local cleanedTracks = {}
  for i = 1, #rawTracks do
    local s = rawTracks[i] or ""

    if i == 1 then
      -- 第 1 軌：預設保留所有 tempo（包含中途變速）
      -- 如果初始 tempo 不在第 1 軌，將它插入到最前面；為避免重覆，不要移除第 1 軌原有的頭部 tempo
      if initialTempoToken and tempoCarrierIndex ~= 1 then
        -- 只在最前面插一次
        s = initialTempoToken .. " " .. s
        -- 並把來源軌的「開頭 tempo」移掉（僅移除開頭一次）
        if tempoCarrierIndex then
          local src = rawTracks[tempoCarrierIndex] or ""
          src = src:gsub('^%s*[tT]%s*%d+%s*', '', 1)
          rawTracks[tempoCarrierIndex] = trim(src)
        end
      end
      cleanedTracks[i] = trim(s)
    else
      -- 非第 1 軌：移除所有 tempo 指令
      s = s:gsub('[tT]%s*%d+', '')
      cleanedTracks[i] = trim(s)
    end
  end

  -- 若初始 tempo 在第 1 軌本來就有，就保留原樣；若完全沒有找到，沿用 sharedTempo.value=120
  -- 逐軌解析：**先解析第 1 軌**（讓中途變速填入 sharedTempo），再解析其餘軌
  local parseOrder = {}
  if #cleanedTracks >= 1 then table.insert(parseOrder, 1) end
  for i = 2, #cleanedTracks do table.insert(parseOrder, i) end

  for _, i in ipairs(parseOrder) do
    local s = cleanedTracks[i] or ""

    -- 補上軌頭 l4 / o4
    local hasL = s:match('^%s*[lL]%d+') ~= nil
    local hasO
    if hasL then
      local lToken = s:match('^%s*([lL]%d+)')
      local rest = s:sub((lToken and #lToken or 0) + 1)
      hasO = rest:match('^%s*[oO]%d+') ~= nil
    else
      hasO = s:match('^%s*[oO]%d+') ~= nil
    end
    if not hasL then s = "l4 " .. s end
    if not hasO then s = "o4 " .. s end

    -- 建立 Parser：第 1 軌建立 tempoRef，其餘軌共享
    local parser
    if i == 1 then
      parser = MMLParser:new() -- 由第 1 軌建立 tempoRef
      -- 若 parser 內有 tempoRef，從 initialTempoToken / 預設同步到 sharedTempo
      if parser.tempoRef then
        sharedTempo = parser.tempoRef
        if initialTempoToken then
          -- 把初始 tempo 寫入 parser（若 MML 有 tXXX 會自行覆蓋；若沒有，就用這個）
          -- 多半 parse 時會自行處理，這裡不強制插入指令，保持來源字串已經有正確開頭 tempo
        else
          -- 沒有初始 tempo：可由 parser 的預設 120 決定；無需改字串
        end
      end
    else
      parser = MMLParser:new(sharedTempo) -- 非第 1 軌共享全域 tempo
    end

    local seq, dur = {}, 0
    if s ~= "" then
      seq, dur = parser:parse(s, self.instrument)

      -- 確保 note.played 欄位存在
      for _, note in ipairs(seq) do
        note.played = false
      end

      anyNotes = anyNotes + #seq
      if dur and dur > self.totalDuration then
        self.totalDuration = dur
      end
    end

    self.tracks[i] = {
      sequence = seq or {},
      totalDuration = dur or 0,
      currentIndex = 1
    }

    cleanedTracks[i] = trim(s)
  end

  -- originalMML：tempo 只出現在第 1 軌；其他軌不帶 tempo
  self.originalMML = table.concat(cleanedTracks, ",")
  return anyNotes > 0
end

-- ============================================================
-- 獲取原始 MML 字符串(用於網絡同步)
-- ============================================================
function MMLPlayer:getMMLString()
  return self.originalMML
end

-- ============================================================
-- 設定音源玩家
-- ============================================================
function MMLPlayer:setSourcePlayer(player)
  self.sourcePlayer = player
end

-- ============================================================
-- 開始播放
-- ============================================================
function MMLPlayer:play()
  local haveNotes = false
  for _, t in ipairs(self.tracks) do
    if #t.sequence > 0 then
      haveNotes = true
      break
    end
  end

  if not haveNotes then
    print("[MMLPlayer] No notes to play!")
    return false
  end

  if self.isPlaying then
    print("[MMLPlayer] Already playing!")
    return false
  end

  self.isPlaying   = true
  self.activeNotes = {}
  self.startTime   = MMLPlayer.GlobalStartAt or GetCurrentTimeInMs()

  -- 重置每個 track 的播放狀態與索引
  for _, t in ipairs(self.tracks) do
    t.currentIndex = 1
    for _, note in ipairs(t.sequence) do
      note.played = false
    end
  end

  -- 設定音源玩家
  local player = getPlayer()
  if self.sourcePlayer == nil then
    self.sourcePlayer = player
  end

  self.playerId = self.sourcePlayer:getOnlineID()
  MMLPlayer.activePlayers[self.playerId] = self


  -- 註冊更新函數
  self.updateFunc = function()
    self:update()
  end
  Events.OnPostRender.Add(self.updateFunc)

  return true
end

-- ============================================================
-- 每幀更新(播放調度) - 處理多個 track 並同步啟動
-- ============================================================
function MMLPlayer:update()
  if not self.isPlaying then return end

  -- 檢查 sourcePlayer 是否還存在（是否已下線）
  if isClient() and self.sourcePlayer ~= getPlayer() then
    -- 檢查玩家是否還在遊戲中
    local sourceId = self.sourcePlayer:getOnlineID()
    local currentSourcePlayer = getPlayerByOnlineID(sourceId)
    if not currentSourcePlayer then
      self:stop()
      return
    end
  end

  local player = getPlayer()
  -- 計算音量(基於距離)
  if self.sourcePlayer and self.sourcePlayer ~= player then
    local distance = player:DistTo(
      self.sourcePlayer:getX(),
      self.sourcePlayer:getY()
    )
    local maxRange = MMLPlayer.getRange()
    if distance > maxRange then
      self:stop()
      return
    end
  end


  -- 尚未到開演時間 -> 不做任何事（同步的關鍵）
  local currentTime = nowMs() - self.startTime
  if currentTime < 0 then
    return
  end

  -- 遍歷 track 排程播放(各 track 的 startTime 都是相對同一個 start)
  for _, t in ipairs(self.tracks) do
    local seq = t.sequence
    while t.currentIndex <= #seq do
      local noteData = seq[t.currentIndex]
      if not noteData then break end
      if currentTime >= (noteData.startTime or 0) then
        if not noteData.played then
          local key = self:playNote(noteData)
          noteData.played = true
          table.insert(self.activeNotes, {
            key = key,
            note = noteData.note,
            endTime = (noteData.startTime or 0) + (noteData.duration or 0)
          })
        end
        t.currentIndex = t.currentIndex + 1
      else
        break
      end
    end
  end

  -- 停止應結束的音符(以 key 停止)
  for i = #self.activeNotes, 1, -1 do
    local activeNote = self.activeNotes[i]
    if currentTime >= activeNote.endTime then
      self:stopNote(activeNote.key)
      table.remove(self.activeNotes, i)
    end
  end

  -- 檢查是否播放完畢:所有 track 的索引都到末尾,且沒有活躍音符
  local finished = true
  for _, t in ipairs(self.tracks) do
    if t.currentIndex <= #t.sequence then
      finished = false
      break
    end
  end

  if finished and #self.activeNotes == 0 then
    self:stop()
    print("[MMLPlayer] Playback finished!")
  end
end

-- ============================================================
-- 播放單個音符
-- ============================================================
function MMLPlayer:playNote(noteData)
  local musicPlayer = MusicPlayer.getInstance()

  local key = musicPlayer:playNote(
    self.playerId,
    self.instrument,
    noteData.note,
    noteData.velocity,
    self.isSilent
  )

  return key
end

-- ============================================================
-- 停止單個音符
-- ============================================================
function MMLPlayer:stopNote(key)
  local musicPlayer = MusicPlayer.getInstance()
  if key == nil then return end
  if musicPlayer.stopNoteByKey then
    musicPlayer:stopNoteByKey(key)
  else
    musicPlayer:stopNote(self.playerId, key)
  end
end

-- ============================================================
-- 停止播放
-- ============================================================
function MMLPlayer:stop()
  if not self.isPlaying then return end

  self.isPlaying = false

  -- 停止所有剩餘音符(使用 key)
  local musicPlayer = MusicPlayer.getInstance()
  for _, activeNote in ipairs(self.activeNotes) do
    if musicPlayer.stopNoteByKey then
      musicPlayer:stopNoteByKey(activeNote.key)
    else
      musicPlayer:stopNote(self.playerId, activeNote.note)
    end
  end
  self.activeNotes = {}

  -- 移除更新函數
  if self.updateFunc then
    Events.OnPostRender.Remove(self.updateFunc)
    self.updateFunc = nil
  end

  -- 從全局追蹤中移除
  if self.playerId then
    MMLPlayer.activePlayers[self.playerId] = nil
  end
end

-- ============================================================
-- 檢查是否正在播放
-- ============================================================
function MMLPlayer:isPlayingMusic()
  return self.isPlaying
end

-- ============================================================
-- 獲取播放進度(0.0 - 1.0)
-- ============================================================
function MMLPlayer:getProgress()
  if self.totalDuration <= 0 then return 0 end
  local currentTime = GetCurrentTimeInMs() - self.startTime
  return math.min(1.0, currentTime / self.totalDuration)
end

-- ============================================================
-- 獲取剩餘時間(秒)
-- ============================================================
function MMLPlayer:getRemainingTime()
  if not self.isPlaying then return 0 end
  local currentTime = GetCurrentTimeInMs() - self.startTime
  local remaining = math.max(0, self.totalDuration - currentTime)
  return remaining / 1000
end

-- ============================================================
-- 工具函數
-- ============================================================
function GetCurrentTimeInMs()
  return Calendar.getInstance():getTimeInMillis()
end

-- ============================================================
-- 全局函數:停止所有播放
-- ============================================================
function MMLPlayer.stopAll()
  for playerId, player in pairs(MMLPlayer.activePlayers) do
    player:stop()
  end
end

-- ============================================================
-- 全局函數:獲取活動播放器數量
-- ============================================================
function MMLPlayer.getActivePlayerCount()
  local count = 0
  for _ in pairs(MMLPlayer.activePlayers) do
    count = count + 1
  end
  return count
end

-- ============================================================
-- 嘗試解析多個 MML 字符串, 回傳每軌解析細節（支援最多 15 軌，TMP 規則同上）
function MMLPlayer:parseTracks(mmlArray)
  local MAX_TRACKS = 15
  local rawTracks = {}
  local n = math.min(MAX_TRACKS, (mmlArray and #mmlArray or 0))
  if n == 0 then n = 1 end
  for i = 1, n do
    local s = (mmlArray and mmlArray[i]) or ""
    rawTracks[i] = trim(s)
  end

  -- 1) 找初始 tempo（只看開頭）
  local initialTempoToken, tempoCarrierIndex = nil, nil
  for i = 1, #rawTracks do
    local headTempo = rawTracks[i]:match('^%s*([tT]%s*%d+)')
    if headTempo then
      initialTempoToken = headTempo:gsub('%s+', '')
      tempoCarrierIndex = i
      break
    end
  end

  -- 2) 清理：只讓第 1 軌保留 tempo；若初始 tempo 不在第 1 軌，移到第 1 軌
  local cleanedTracks = {}
  for i = 1, #rawTracks do
    local s = rawTracks[i] or ""
    if i == 1 then
      if initialTempoToken and tempoCarrierIndex ~= 1 then
        s = initialTempoToken .. " " .. s
        -- 移除來源軌的開頭 tempo
        local src = rawTracks[tempoCarrierIndex] or ""
        src = src:gsub('^%s*[tT]%s*%d+%s*', '', 1)
        rawTracks[tempoCarrierIndex] = trim(src)
      end
      cleanedTracks[i] = trim(s)
    else
      s = s:gsub('[tT]%s*%d+', '')
      cleanedTracks[i] = trim(s)
    end
  end

  -- 3) 共用 tempo，先跑第 1 軌
  local results = {}
  local sharedTempo = { value = 120 }
  local function normalizeTrackText(s)
    local hasL = s:match('^%s*[lL]%d+') ~= nil
    local hasO
    if hasL then
      local lToken = s:match('^%s*([lL]%d+)')
      local rest = s:sub((lToken and #lToken or 0) + 1)
      hasO = rest:match('^%s*[oO]%d+') ~= nil
    else
      hasO = s:match('^%s*[oO]%d+') ~= nil
    end
    if not hasL then s = "l4 " .. s end
    if not hasO then s = "o4 " .. s end
    return s
  end

  local order = {}
  if #cleanedTracks >= 1 then table.insert(order, 1) end
  for i = 2, #cleanedTracks do table.insert(order, i) end

  for _, i in ipairs(order) do
    local s = normalizeTrackText(cleanedTracks[i] or "")

    local parser
    if i == 1 then
      parser = MMLParser:new()
      if parser.tempoRef then
        sharedTempo = parser.tempoRef
      end
    else
      parser = MMLParser:new(sharedTempo)
    end

    local ok, seq, dur = pcall(function()
      local seq1, dur1 = parser:parse(s, self.instrument)
      return seq1 or {}, dur1 or 0
    end)

    if ok then
      results[i] = { ok = true, notes = #seq, duration = dur }
    else
      results[i] = { ok = false, err = tostring(seq) }
    end
  end

  return results
end

return MMLPlayer
