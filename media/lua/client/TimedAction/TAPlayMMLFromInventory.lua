-- TAPlayMMLFromInventory.lua
-- 播放樂譜的 TimedAction

local MMLPlayer = require('MMLPlayer')
local MMLMusicBuff = require('MMLMusicBuff')
local MMLMusicSkill = require('MMLMusicSkill')
---@class TAPlayMMLFromInventory: ISBaseTimedAction
---@field onComplete fun(): nil 顯示視窗
local TAPlayMMLFromInventory = ISBaseTimedAction:derive('TAPlayMMLFromInventory')

local ItemToAnimation = {
  ['BassFinger'] = 'BardPlayGuitarBass',
  ['GuitarDistortion'] = 'BardPlayGuitarElectric',
  ['GuitarClean'] = 'BardPlayGuitarElectric',
  ['GuitarSteel'] = 'BardPlayGuitarElectric',
  ['Keytar'] = 'BardPlaySynthesizer',
  ['Flute'] = 'BardPlayFlute',
  ['Saxophone'] = 'BardPlaySaxophone',
  ['Trumpet'] = 'BardPlayTrumpet',
  ['Violin'] = 'BardPlayViolin',
}

-- ============================================================
-- 創建新的 Action
-- ============================================================
function TAPlayMMLFromInventory:new(character, instrument, mml, sendToServer)
  ---@class TAPlayMMLFromInventory
  local o = ISBaseTimedAction:new(character)
  setmetatable(o, self)
  self.__index = self
  o.stopOnWalk = false
  o.stopOnRun = true
  o.stopOnAim = true
  o.maxTime = -1 -- 無限時間（直到播放完成或被打斷）

  o.instrument = instrument
  o.item = character:getPrimaryHandItem()
  o.mml = mml

  o.playing = true
  o.mmlPlayer = MMLPlayer:new(o.instrument, false)
  o.mmlPlayer:loadMML(mml)
  o.lastCheckTime = 0
  o.checkInterval = 100 -- 每100ms檢查一次狀態
  o.sendToServer = sendToServer or false
  local musicSkill = MMLMusicSkill.getLevel(character)
  self.MusicBuff = MMLMusicBuff:new(character, {
    xp = sendToServer == false and 2 or 1,
    applyUnhappyness = musicSkill,
    applyBoredom = musicSkill,
    applyPanic = musicSkill,
    applyStress = musicSkill,
  })
  return o
end

function TAPlayMMLFromInventory:equipInstrumentOnSecondaryHand()
  if self.character:isItemInBothHands(self.item) then
    self.handItem = 'BothHands'
  elseif self.character:isPrimaryHandItem(self.item) then
    self.handItem = 'PrimaryHand'
  elseif self.character:isSecondaryHandItem(self.item) then
    self.handItem = 'SecondaryHand'
  end
  self.character:setPrimaryHandItem(nil)
  self.character:setSecondaryHandItem(self.item)
end

function TAPlayMMLFromInventory:isValid()
  return self.playing
end

-- ============================================================
-- 開始動作
-- ============================================================
function TAPlayMMLFromInventory:start()
  self.mmlPlayer:play()

  local animName = ItemToAnimation[self.instrument]
  if animName then
    print("[MML] Setting animation: " .. animName)
    self:setActionAnim(animName)
  else
    print("[MML] Warning: No animation found for instrument: " .. tostring(self.instrument))
  end

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

-- ============================================================
-- 更新
-- ============================================================
function TAPlayMMLFromInventory:update()
  -- 限制檢查頻率，避免每幀都檢查
  local currentTime = getTimestampMs()
  if currentTime - self.lastCheckTime < self.checkInterval then
    return
  end
  self.lastCheckTime = currentTime

  -- 檢查播放器是否還在播放
  if self.mmlPlayer then
    local isPlaying = self.mmlPlayer:isPlayingMusic()
    if not isPlaying and self.playing then
      self:forceComplete() -- 正常完成
      return
    end

    -- 可選：檢查進度
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

function TAPlayMMLFromInventory:getProgress()
  if self.mmlPlayer then
    return self.mmlPlayer:getProgress()
  end
  return 0
end

function TAPlayMMLFromInventory:isPlaying()
  return self.playing
end

-- ============================================================
-- 停止
-- ============================================================
function TAPlayMMLFromInventory:stop()
  self.playing = false
  if isClient() then
    local MMLClientSendCommands = require("MMLClientSendCommands")
    MMLClientSendCommands.sendStopMML(self.character:getOnlineID())
  end
  if self.mmlPlayer then
    self.mmlPlayer:stop()
  end

  if self.onComplete and type(self.onComplete) == "function" then
    self.onComplete()
  end
  -- 發送停止命令
  if isClient() then
    local MMLClientSendCommands = require("MMLClientSendCommands")
    MMLClientSendCommands.sendStopMML(self.character:getOnlineID())
  end
  self.MusicBuff:stop()
  ISBaseTimedAction.stop(self)
end

-- ============================================================
-- 完成
-- ============================================================
function TAPlayMMLFromInventory:EquipInstrumentAsBefore()
  if self.handItem == 'PrimaryHand' then
    self.character:setPrimaryHandItem(self.item)
    self.character:setSecondaryHandItem(nil)
  elseif self.handItem == 'SecondaryHand' then
    self.character:setPrimaryHandItem(nil)
    self.character:setSecondaryHandItem(self.item)
  elseif self.handItem == 'BothHands' then
    self.character:setPrimaryHandItem(self.item)
    self.character:setSecondaryHandItem(self.item)
  end
end

-- ============================================================
-- 強制完成
-- ============================================================
function TAPlayMMLFromInventory:forceComplete()
  self:perform()
end

function TAPlayMMLFromInventory:perform()
  self.playing = false
  if isClient() then
    local MMLClientSendCommands = require("MMLClientSendCommands")
    MMLClientSendCommands.sendStopMML(self.character:getOnlineID())
  end
  if self.mmlPlayer then
    self.mmlPlayer:stop()
  end

  if self.onComplete and type(self.onComplete) == "function" then
    self.onComplete()
  end
  self.MusicBuff:stop()
  ISBaseTimedAction.perform(self)
end

-- Graceful forceStop to match callers in update()
function TAPlayMMLFromInventory:forceStop()
  self:stop()
end

return TAPlayMMLFromInventory
