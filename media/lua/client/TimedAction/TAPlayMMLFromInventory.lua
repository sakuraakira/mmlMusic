-- TAPlayMMLFromInventory.lua
-- 播放樂譜的 TimedAction

local MMLPlayer = require('MMLPlayer')

---@class TAPlayMMLFromInventory: ISBaseTimedAction
---@field onComplete fun(): nil 顯示視窗
---@field instrument string
---@field item InventoryItem
---@field mml string
---@field Playing boolean
---@field lastCheckTime number
---@field checkInterval number
---@field mmlPlayer MMLPlayer
---@field handItem string
---@field walkSpeedModifier number
local TAPlayMMLFromInventory = ISBaseTimedAction:derive('TAPlayMMLFromInventory')

local ItemToAnimation = {
  ['BassFinger'] = 'BardPlayGuitarBass',
  ['GuitarDistortion'] = 'BardPlayGuitarElectric',
  ['Keytar'] = 'BardPlaySynthesizer',
  ['Flute'] = 'BardPlayFlute',
  ['Saxophone'] = 'BardPlaySaxophone',
  ['Trumpet'] = 'BardPlayTrumpet',
  ['Violin'] = 'BardPlayViolin',
}

-- ============================================================
-- 創建新的 Action
-- ============================================================
function TAPlayMMLFromInventory:new(character, instrument, mml)
  ---@type TAPlayMMLFromInventory
  local o = ISBaseTimedAction.new(self, character)
  setmetatable(o, self)
  self.__index = self


  o.instrument = instrument
  o.item = character:getPrimaryHandItem()
  o.mml = mml
  o.stopOnWalk = false
  o.walkSpeedModifier = 0.6
  o.stopOnRun = true
  o.stopOnAim = true
  o.maxTime = -1 -- 無限時間（直到播放完成或被打斷）
  o.Playing = true
  o.mmlPlayer = MMLPlayer:new(o.instrument)
  o.lastCheckTime = 0
  o.checkInterval = 100 -- 每100ms檢查一次狀態
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
  return self.Playing
end

-- ============================================================
-- 開始動作
-- ============================================================
function TAPlayMMLFromInventory:start()
  local ok = self.mmlPlayer:loadMML(self.mml)
  if not ok then
    print("[MML] Error: Failed to load MML data")
    self.Playing = false
    return
  end
  -- 設置手部模型
  if self.item then
    self:equipInstrumentOnSecondaryHand()
  end
  -- 設置動畫
  local animName = ItemToAnimation[self.instrument]
  if animName then
    print("[MML] Setting animation: " .. animName)
    self:setActionAnim(animName)
  else
    print("[MML] Warning: No animation found for instrument: " .. tostring(self.instrument))
  end

  self.mmlPlayer:play()
  self.character:ModSpeed(self.walkSpeedModifier)
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
    if not isPlaying and self.Playing then
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
end

function TAPlayMMLFromInventory:getProgress()
  if self.mmlPlayer then
    return self.mmlPlayer:getProgress()
  end
  return 0
end

function TAPlayMMLFromInventory:isPlaying()
  return self.Playing
end

-- ============================================================
-- 停止
-- ============================================================
function TAPlayMMLFromInventory:stop()
  self.Playing = false
  if self.mmlPlayer then
    self.mmlPlayer:stop()
  end
  self:EquipInstrumentAsBefore()
  self.character:ModSpeed(1.0)
  if self.onComplete and type(self.onComplete) == "function" then
    self.onComplete()
  end
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
  self.Playing = false
  if self.mmlPlayer then
    self.mmlPlayer:stop()
  end
  self:EquipInstrumentAsBefore()
  -- 恢復移動速度

  self.character:ModSpeed(1.0)

  if self.onComplete and type(self.onComplete) == "function" then
    self.onComplete()
  end
  ISBaseTimedAction.perform(self)
end

return TAPlayMMLFromInventory
