-- TAPlayMMLFromInventory.lua
-- 播放樂譜的 TimedAction
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
function TAPlayMMLFromInventory:new(character, instrument)
  local o = ISBaseTimedAction:new(character)
  setmetatable(o, self)
  self.__index = self
  o.instrument = instrument
  o.item = character:getPrimaryHandItem()
  o.stopOnWalk = true
  o.stopOnRun = true
  o.stopOnAim = true
  o.maxTime = -1 -- 無限時間（直到播放完成或被打斷）
  o.isPlaying = false
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
  return true
end

-- ============================================================
-- 開始動作
-- ============================================================
function TAPlayMMLFromInventory:start()
  print("[MML] Starting to play instrument: " .. tostring(self.instrument))

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

  self.isPlaying = true
end

-- ============================================================
-- 更新
-- ============================================================
function TAPlayMMLFromInventory:update()
  -- 可以在這裡添加播放邏輯
  -- 檢查是否需要停止
end

-- ============================================================
-- 停止
-- ============================================================
function TAPlayMMLFromInventory:stop()
  print("[MML] Stopping action")
  self.isPlaying = false
  self:EquipInstrumentAsBefore()
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

function TAPlayMMLFromInventory:perform()
  print("[MML] Action completed")
  self.isPlaying = false
  self:EquipInstrumentAsBefore()
  ISBaseTimedAction.perform(self)
end

return TAPlayMMLFromInventory
