local MMLPlayer = require('MMLPlayer')
local MMLMusicBuff = require('MMLMusicBuff')
local MMLMusicSkill = require('MMLMusicSkill')

---@class TAPlayMMLFromWorld: ISBaseTimedAction
---@field instrumentObject IsoObject
---@field orientation string
---@field instrument string
---@field seated boolean
---@field onComplete fun(): nil 顯示視窗
---@field new fun(self: TAPlayMMLFromWorld,character: IsoPlayer, instrument: string, instrumentObject: IsoObject, orientation: string, seated: boolean , mml: string , sendToServer: boolean): TAPlayMMLFromWorld
local TAPlayMMLFromWorld = ISBaseTimedAction:derive('TAPlayMMLFromWorld')

-- Normalize any orientation to east/south (mirror west->east, north->south)
local function normalizeOrientation(orientation)
  local s = tostring(orientation or ""):lower()
  if s == 'e' or s == 'east' then return 'east' end
  if s == 'w' or s == 'west' then return 'east' end
  if s == 's' or s == 'south' then return 'south' end
  if s == 'n' or s == 'north' then return 'south' end
  return 'south'
end

function TAPlayMMLFromWorld:new(character, instrument, instrumentObject, orientation, seated, mml, sendToServer)
  ---@class TAPlayMMLFromWorld
  local o = ISBaseTimedAction:new(character)
  setmetatable(o, self)
  self.__index = self
  self.handItems = {}
  o.stopOnRun = true
  o.stopOnAim = true
  o.stopOnWalk = true
  o.maxTime = -1 -- 無限時間（直到播放完成或被打斷）

  o.instrument = instrument
  o.mml = mml
  o.instrumentObject = instrumentObject
  o.orientation = normalizeOrientation(orientation)
  o.seated = seated
  o.playing = true
  o.mmlPlayer = MMLPlayer:new(o.instrument, false)
  o.lastCheckTime = 0
  o.checkInterval = 100 -- 每100ms檢查一次狀態
  o.sendToServer = sendToServer or false
  self.MusicBuff = MMLMusicBuff:new(character, {
    xp = sendToServer == false and 3 or 2,
    applyUnhappyness = MMLMusicSkill.getLevel(character),
    applyBoredom = MMLMusicSkill.getLevel(character),
    applyPanic = MMLMusicSkill.getLevel(character),
  })
  return o
end

local AnimationsParameters = {
  { animation = 'BardPlayPianoEast',             seated = false, orientation = 'east',  instrument = 'Piano' },
  { animation = 'BardPlayPianoSouth',            seated = false, orientation = 'south', instrument = 'Piano' },
  { animation = 'BardPlayPianoSeatedEast',       seated = true,  orientation = 'east',  instrument = 'Piano' },
  { animation = 'BardPlayPianoSeatedSouth',      seated = true,  orientation = 'south', instrument = 'Piano' },
  { animation = 'BardPlayGrandPianoEast',        seated = false, orientation = 'east',  instrument = 'GrandPiano' },
  { animation = 'BardPlayGrandPianoSouth',       seated = false, orientation = 'south', instrument = 'GrandPiano' },
  { animation = 'BardPlayGrandPianoSeatedEast',  seated = true,  orientation = 'east',  instrument = 'GrandPiano' },
  { animation = 'BardPlayGrandPianoSeatedSouth', seated = true,  orientation = 'south', instrument = 'GrandPiano' },
}

function TAPlayMMLFromWorld:startAnimation()
  -- Full match first
  for _, parameters in ipairs(AnimationsParameters) do
    if parameters.seated == self.seated
        and parameters.orientation == self.orientation
        and parameters.instrument == self.instrument then
      self:setActionAnim(parameters.animation)
      return
    end
  end
  -- Fallback: prefer south, then east (instrument/seated must match)
  for _, pref in ipairs({ 'south', 'east' }) do
    for _, parameters in ipairs(AnimationsParameters) do
      if parameters.seated == self.seated
          and parameters.instrument == self.instrument
          and parameters.orientation == pref then
        self.orientation = pref
        self:setActionAnim(parameters.animation)
        return
      end
    end
  end
  print(string.format("[MML] Warning: No matching animation (instrument=%s, seated=%s).",
    tostring(self.instrument), tostring(self.seated)))
end

function TAPlayMMLFromWorld:unequipHandItems()
  local secondaryItem = self.character:getSecondaryHandItem()
  if secondaryItem ~= nil then
    table.insert(self.handItems,
      { item = secondaryItem, hands = "secondary" })
  end
  self.character:setSecondaryHandItem(nil)
end

function TAPlayMMLFromWorld:start()
  print("[MML] Starting playback")
  self.character:faceThisObject(self.instrumentObject)
  self:startAnimation()
  self:unequipHandItems()
  local ok = self.mmlPlayer:loadMML(self.mml)
  if not ok then
    print("[MML] Error: Failed to load MML data")
    self.playing = false
    return
  end

  self.mmlPlayer:play()
  if isClient() and self.sendToServer then
    local MMLClientSendCommands = require("MMLClientSendCommands")
    MMLClientSendCommands.sendStartMML(
      self.character:getOnlineID(),
      self.instrument,
      self.mml,
      { x = self.character:getX(), y = self.character:getY(), z = self.character:getZ() }
    )
  end
  self.MusicBuff:start()
end

function TAPlayMMLFromWorld:isValid()
  return self.playing
end

function TAPlayMMLFromWorld:equipHandItemsAsBefore()
  for _, handItemInfo in ipairs(self.handItems) do
    if handItemInfo.hands == 'both' then
      self.character:setSecondaryHandItem(handItemInfo.item)
    elseif handItemInfo.hands == 'secondary' then
      self.character:setSecondaryHandItem(handItemInfo.item)
    end
  end
  self.handItems = {}
end

function TAPlayMMLFromWorld:terminateAction()
  self:equipHandItemsAsBefore()
end

-- ============================================================
-- 強制完成
-- ============================================================
function TAPlayMMLFromWorld:forceComplete()
  self:perform()
end

function TAPlayMMLFromWorld:perform()
  self.playing = false
  if isClient() then
    local MMLClientSendCommands = require("MMLClientSendCommands")
    MMLClientSendCommands.sendStopMML(self.character:getOnlineID())
  end
  if self.mmlPlayer then
    self.mmlPlayer:stop()
  end
  self:equipHandItemsAsBefore()
  if self.onComplete and type(self.onComplete) == "function" then
    self.onComplete()
  end
  self.MusicBuff:stop()
  ISBaseTimedAction.perform(self)
end

function TAPlayMMLFromWorld:stop()
  self.playing = false

  if isClient() then
    local MMLClientSendCommands = require("MMLClientSendCommands")
    MMLClientSendCommands.sendStopMML(self.character:getOnlineID())
  end
  if self.mmlPlayer then
    self.mmlPlayer:stop()
  end


  self:equipHandItemsAsBefore()
  if self.onComplete and type(self.onComplete) == "function" then
    self.onComplete()
  end
  self.MusicBuff:stop()
  ISBaseTimedAction.stop(self)
end

-- ============================================================
-- 更新
-- ============================================================
function TAPlayMMLFromWorld:update()
  local currentTime = getTimestampMs()
  if currentTime - self.lastCheckTime < self.checkInterval then
    return
  end
  self.lastCheckTime = currentTime

  -- 檢查播放器是否還在播放
  if self.mmlPlayer then
    local isPlaying = self.mmlPlayer:isPlayingMusic()
    if not isPlaying and self.playing then
      self:forceComplete()
      return
    end
    local progress = self.mmlPlayer:getProgress()
    if progress >= 1.0 then
      self:forceComplete()
      return
    end
  else
    self:forceStop()
  end
  self.MusicBuff:update()
end

function TAPlayMMLFromWorld:getProgress()
  if self.mmlPlayer then
    return self.mmlPlayer:getProgress()
  end
  return 0
end

function TAPlayMMLFromWorld:isPlaying()
  return self.playing
end

-- Graceful forceStop to match callers in update()
function TAPlayMMLFromWorld:forceStop()
  self:stop()
end

return TAPlayMMLFromWorld
