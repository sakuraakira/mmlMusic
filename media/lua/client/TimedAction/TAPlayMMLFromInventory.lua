-- TAPlayMMLFromInventory.lua
-- 播放樂譜的 TimedAction

local MMLPlayer = require('MMLPlayer')
local MMLMusicBuff = require('MMLMusicBuff')

---@class TAPlayMMLFromInventory: ISBaseTimedAction
---@field onComplete fun(): nil 顯示視窗
local TAPlayMMLFromInventory = ISBaseTimedAction:derive('TAPlayMMLFromInventory')

local ItemToAnimation = {
  ['BassFinger'] = 'BardPlayGuitarBass',
  ['BassPick'] = 'BardPlayGuitarBass',
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

  return o
end

function TAPlayMMLFromInventory:isValid()
  return self.playing
end

function TAPlayMMLFromInventory:setMusicBuff(cfg)
  self.MusicBuff = MMLMusicBuff:new(self.character, cfg)
end

-- ============================================================
-- 開始動作
-- ============================================================
function TAPlayMMLFromInventory:start()
  self.mmlPlayer:play()

  local animName = ItemToAnimation[self.instrument]
  if animName then
    self:setActionAnim(animName)
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

  if self.MusicBuff then
    self.MusicBuff:start()
  end
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
  if self.MusicBuff then
    self.MusicBuff:update()
  end
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
  if self.MusicBuff then
    self.MusicBuff:stop()
  end
  ISBaseTimedAction.stop(self)
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
  if self.MusicBuff then
    self.MusicBuff:stop()
  end
  ISBaseTimedAction.perform(self)
end

-- Graceful forceStop to match callers in update()
function TAPlayMMLFromInventory:forceStop()
  self:stop()
end

return TAPlayMMLFromInventory
