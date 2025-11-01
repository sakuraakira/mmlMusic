local MusicPlayer = {}

local instance = nil
function MusicPlayer.getInstance()
  if instance == nil then
    instance = MusicPlayer:new()
    return instance
  end
  return instance
end

local InstrumentParameters = {
  ["Piano"] = { baseTime = 400, fadingTime = 200, polyphonic = true },
  ["Violin"] = { baseTime = 200, fadingTime = 100, polyphonic = true },
  ["GuitarDistortion"] = { baseTime = 300, fadingTime = 150, polyphonic = true },
  ["GuitarClean"] = { baseTime = 250, fadingTime = 150, polyphonic = true },
  ["GuitarSteel"] = { baseTime = 200, fadingTime = 150, polyphonic = true },
  ["BassFinger"] = { baseTime = 350, fadingTime = 150, polyphonic = true },
  ["BassPick"] = { baseTime = 350, fadingTime = 150, polyphonic = true },
  ["Flute"] = { baseTime = 100, fadingTime = 20, polyphonic = true },
  ["Saxophone"] = { baseTime = 0, fadingTime = 50, polyphonic = true },
  ["Trumpet"] = { baseTime = 0, fadingTime = 50, polyphonic = true },
  ["Banjo"] = { baseTime = 200, fadingTime = 150, polyphonic = true },
}

function MusicPlayer:new()
  assert(instance == nil,
    'MusicPlayer is a singleton, call getInstance instead')
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.soundsPlaying = {}
  o.soundsStopping = {}
  o.baseVolume = 0.7
  o.maxDistance = 40 -- tiles
  o.range = nil
  o.playCounter = 0  -- 唯一播放計數器

  -- 安全地獲取沙盒變數，如果不存在則使用預設值
  if not isClient() then
    if SandboxVars and SandboxVars.BardInteractiveMusic and SandboxVars.BardInteractiveMusic.SoundRange then
      self.range = SandboxVars.BardInteractiveMusic.SoundRange
    else
      self.range = 40 -- 預設值
    end
  end

  return o
end

function MusicPlayer:setRange(range)
  self.range = range
  print("[MusicPlayer] Sound range set to: " .. range)
end

local function GetFileName(instrument, note)
  local filename = instrument .. note
  return filename
end


function MusicPlayer:setEmitterVolume(emitter, soundId, volume, sourceId)
  local player = getPlayer()
  local source = getPlayerByOnlineID(sourceId)
  local modifiedVolume = volume
  if isClient() and source ~= nil and player:getOnlineID() ~= sourceId then
    local distance = player:DistTo(source:getX(), source:getY())
    modifiedVolume = math.max(0, volume - volume * (distance / self.range))
  end
  emitter:setVolume(soundId, modifiedVolume)
end

function MusicPlayer:playNote(sourcePlayerId, instrument, note, velocity, isSilent)
  if self.range == nil then
    self.range = 40 -- 緊急預設值
  end
  local instrumentNote = GetFileName(instrument, note)
  assert(instrumentNote ~= nil, string.format("Unknown note %s", note))

  local player = getPlayer()
  local source
  if isClient() then
    source = getPlayerByOnlineID(sourcePlayerId)
  else
    source = player
  end

  if not source then
    print("[MusicPlayer] ERROR: Source player not found")
    return nil
  end

  local soundEmitter = getWorld():getFreeEmitter()
  local square = source:getSquare()

  if not square then
    print("[MusicPlayer] ERROR: Player square not found")
    return nil
  end

  local soundId = soundEmitter:playSoundImpl(instrumentNote, square)
  if not isSilent then
    addSound(source, square:getX(), square:getY(), square:getZ(), self.range, velocity or self.baseVolume)
  end

  if not isClient() or player:getOnlineID() == sourcePlayerId then
    soundEmitter:set3D(soundId, false)
  end

  self:setEmitterVolume(soundEmitter, soundId, velocity or self.baseVolume, sourcePlayerId)

  -- 若 instrument 非 polyphonic，先停止該 player 的所有音符
  if InstrumentParameters[instrument] and InstrumentParameters[instrument].polyphonic == false then
    self:stopPlayerNotes(sourcePlayerId)
  end

  -- 產生唯一 key 並儲存聲音實例
  self.playCounter = (self.playCounter or 0) + 1
  local uniqueKey = tostring(sourcePlayerId) .. ":" .. tostring(note) .. ":" .. tostring(self.playCounter)

  self.soundsPlaying[uniqueKey] = {
    emitter = soundEmitter,
    soundId = soundId,
    startingTime = GetCurrentTimeInMs(),
    volume = 0.7,
    sourcePlayerId = sourcePlayerId,
    note = note,
    instrument = instrument
  }

  return uniqueKey
end

-- 修改：以 key 為單位停止
function MusicPlayer:stopNoteByKey(key)
  if not key then return end
  local sound = self.soundsPlaying[key]
  if sound then
    table.insert(self.soundsStopping, sound)
    self.soundsPlaying[key] = nil
  end
end

-- 保留並調整舊的 stopNote 以停止該 player 下所有相同 note 的實例（相容性）
function MusicPlayer:stopNote(sourcePlayerId, note)
  local toRemove = {}
  for key, sound in pairs(self.soundsPlaying) do
    if sound.sourcePlayerId == sourcePlayerId and sound.note == note then
      table.insert(self.soundsStopping, sound)
      table.insert(toRemove, key)
    end
  end
  for _, k in ipairs(toRemove) do
    self.soundsPlaying[k] = nil
  end
end

function MusicPlayer:stopPlayerNotes(playerId)
  for _, sound in pairs(self.soundsPlaying) do
    if sound.sourcePlayerId == playerId then
      self:stopNote(sound.sourcePlayerId, sound.note)
    end
  end
end

function MusicPlayer:stopPlayer(action)
  for _, sound in pairs(self.soundsPlaying) do
    if sound.sourcePlayerId == getPlayer():getOnlineID() then
      self:stopNote(sound.sourcePlayerId, sound.note)
      action(sound.note)
    end
  end
end

function GetCurrentTimeInMs()
  return Calendar.getInstance():getTimeInMillis()
end

function MusicPlayer:update()
  local idsToRemove = {}
  for index, sound in pairs(self.soundsStopping) do
    assert(sound.startingTime ~= nil, "Note starting time not found")
    local delta = GetCurrentTimeInMs() - sound.startingTime
    local duration = InstrumentParameters[sound.instrument]
    if delta >
        duration.baseTime
        + (self.baseVolume - sound.volume) / self.baseVolume
        * duration.fadingTime
    then
      sound.volume = sound.volume - 0.1
      if sound.volume <= 0 then sound.volume = 0 end
      self:setEmitterVolume(sound.emitter, sound.soundId, sound.volume, sound.sourcePlayerId)
    end
    if sound.volume <= 0 then
      table.insert(idsToRemove, index)
    end
  end
  for _, index in pairs(idsToRemove) do
    self.soundsStopping[index] = nil
  end
end

Events.OnPostRender.Add(function() MusicPlayer.getInstance():update() end)

return MusicPlayer
