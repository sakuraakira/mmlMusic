-- TAPlayMMLFromInventory.lua
-- 播放樂譜的 TimedAction
local TAPlayMMLFromInventory = ISBaseTimedAction:derive('TAPlayMMLFromInventory')
local MMLPlayer = require('MMLPlayer')

-- ============================================================
-- 創建新的 Action
-- ============================================================
function TAPlayMMLFromInventory:new(character, item)
  local o = ISBaseTimedAction:new(character)
  setmetatable(o, self)
  self.__index = self

  o.item = item
  o.stopOnWalk = true
  o.stopOnRun = true
  o.stopOnAim = true
  o.maxTime = -1   -- 無限時間（直到播放完成或被打斷）

  -- MML 播放器
  o.mmlPlayer = nil
  o.isPlaying = false

  return o
end

-- ============================================================
-- 檢查是否有效
-- ============================================================
function TAPlayMMLFromInventory:isValid()
  -- 檢查物品是否還在背包中
  return self.character:getInventory():contains(self.item)
end

-- ============================================================
-- 開始
-- ============================================================
function TAPlayMMLFromInventory:start()
  -- 獲取 MML 資料
  local mml = self.item:getModData().mml
  local instrument = self.item:getModData().instrument or "Piano"

  if not mml or mml == "" then
    print("[TAPlayMML] No MML data found in item")
    self:forceStop()
    return
  end

  print(string.format("[TAPlayMML] Starting playback: %s (%s)",
    self.item:getName(), instrument))

  -- 創建播放器
  self.mmlPlayer = MMLPlayer:new(instrument)

  if not self.mmlPlayer:loadMML(mml) then
    print("[TAPlayMML] Failed to load MML")
    self:forceStop()
    return
  end

  -- 開始播放
  if self.mmlPlayer:play() then
    self.isPlaying = true

    -- 設定動畫（可選）
    self:setActionAnim("Read")     -- 使用閱讀動畫
    self.character:setReading(true)

    -- 播放音效（翻開樂譜的聲音）
    self.character:playSound("OpenBook")
  else
    print("[TAPlayMML] Failed to start playback")
    self:forceStop()
  end
end

-- ============================================================
-- 更新
-- ============================================================
function TAPlayMMLFromInventory:update()
  -- 檢查是否還在播放
  if self.mmlPlayer and not self.mmlPlayer:isPlayingMusic() then
    -- 播放完成
    self:forceComplete()
  end

  -- 可以在這裡添加 UI 更新（進度條等）
end

-- ============================================================
-- 停止
-- ============================================================
function TAPlayMMLFromInventory:stop()
  self:cleanup()
  ISBaseTimedAction.stop(self)
end

-- ============================================================
-- 完成
-- ============================================================
function TAPlayMMLFromInventory:perform()
  self:cleanup()
  ISBaseTimedAction.perform(self)
end

-- ============================================================
-- 清理
-- ============================================================
function TAPlayMMLFromInventory:cleanup()
  -- 停止播放
  if self.mmlPlayer then
    self.mmlPlayer:stop()
    self.mmlPlayer = nil
  end

  -- 停止動畫
  self.character:setReading(false)

  self.isPlaying = false

  print("[TAPlayMML] Cleanup completed")
end

return TAPlayMMLFromInventory
