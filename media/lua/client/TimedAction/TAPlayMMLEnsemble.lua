-- TAPlayMMLFromInventory.lua
-- 播放樂譜的 TimedAction

---@class TAPlayMMLEnsemble: ISBaseTimedAction
---@field onComplete fun(): nil 顯示視窗
local TAPlayMMLEnsemble = ISBaseTimedAction:derive('TAPlayMMLEnsemble')

-- ============================================================
-- 創建新的 Action
-- ============================================================
function TAPlayMMLEnsemble:new(character, instrument)
  ---@class TAPlayMMLEnsemble
  local o = ISBaseTimedAction:new(character)
  setmetatable(o, self)
  self.__index = self
  o.stopOnWalk = false
  o.stopOnRun = true
  o.stopOnAim = true
  o.maxTime = -1 -- 無限時間（直到播放完成或被打斷）

  o.instrument = instrument
  o.item = character:getSecondaryHandItem()

  o.playing = true
  o.lastCheckTime = 0
  o.checkInterval = 100 -- 每100ms檢查一次狀態
  return o
end

function TAPlayMMLEnsemble:isValid()
  return self.item ~= nil
end

-- ============================================================
-- 開始動作
-- ============================================================
function TAPlayMMLEnsemble:start()
  --if self.item then
  --  self:equipInstrumentOnSecondaryHand()
  --end

  self:setActionAnim("PrepareEnsemble")

  if isClient() then
    local MMLClientSendCommands = require("MMLClientSendCommands")
  end
end

-- ============================================================
-- 更新
-- ============================================================

function TAPlayMMLEnsemble:isPlaying()
  return self.playing
end

-- ============================================================
-- 停止
-- ============================================================
function TAPlayMMLEnsemble:stop()
  self.playing = false
  ISBaseTimedAction.stop(self)
end

-- ============================================================
-- 完成
-- ============================================================
function TAPlayMMLEnsemble:perform()
  self.playing = false
  ISBaseTimedAction.perform(self)
end

-- ============================================================
-- 強制完成
-- ============================================================


-- Graceful forceStop to match callers in update()
function TAPlayMMLEnsemble:forceStop()
  self:stop()
end

return TAPlayMMLEnsemble
