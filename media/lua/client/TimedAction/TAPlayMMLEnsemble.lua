-- TAPlayMMLEnsemble.lua
-- 合奏準備動作
require('TimedActions/ISBaseTimedAction')
---@class TAPlayMMLEnsemble: ISBaseTimedAction
---@field character IsoPlayer
TAPlayMMLEnsemble = ISBaseTimedAction:derive("TAPlayMMLEnsemble")

function TAPlayMMLEnsemble:new(character, item)
  ---@class TAPlayMMLEnsemble
  local o = ISBaseTimedAction:new(character)
  setmetatable(o, self)
  self.__index = self
  o.stopOnWalk = false
  o.stopOnRun = true
  o.stopOnAim = true
  o.maxTime = -1 -- 無限時間（直到播放完成或被打斷）

  o.instrument = instrument
  o.item = item

  o.playing = true
  o.lastCheckTime = 0
  o.checkInterval = 100 -- 每100ms檢查一次狀態
  return o
end

function TAPlayMMLEnsemble:isValid()
  return true
end

function TAPlayMMLEnsemble:start()
  -- 發送合奏準備完成指令

  self:setActionAnim("PrepareEnsemble")

  local instrument = nil
  if self.item then
    local PlayerItemToMMLInstrument = require('MMLInstrument')
    instrument = PlayerItemToMMLInstrument[self.item:getFullType()] or "Piano"
  else
    instrument = "Piano"
  end

  if isClient() then
    local MMLClientSendCommands = require('MMLClientSendCommands')
    MMLClientSendCommands.sendEnsembleReady(
      self.character:getOnlineID(),
      self.character:getDisplayName(),
      instrument,
      {
        x = self.character:getX(),
        y = self.character:getY(),
        z = self.character:getZ()
      }
    )
  end

  -- 本地也添加自己到準備列表
  local MMLEnsembleManager = require("MMLEnsembleManager")
  MMLEnsembleManager.addEnsemblePlayer(
    self.character:getOnlineID(),
    self.character:getDisplayName(),
    instrument
  )
end

function TAPlayMMLEnsemble:stop()
  self:sendCancelCommand()
  ISBaseTimedAction.stop(self)
end

function TAPlayMMLEnsemble:perform()
  ISBaseTimedAction.perform(self)
end

function TAPlayMMLEnsemble:sendCancelCommand()
  -- 發送取消合奏準備指令
  if isClient() then
    local MMLClientSendCommands = require('MMLClientSendCommands')
    MMLClientSendCommands.sendEnsembleCancel(
      self.character:getOnlineID(),
      {
        x = self.character:getX(),
        y = self.character:getY(),
        z = self.character:getZ()
      }
    )
  end

  -- 本地也移除自己
  local MMLEnsembleManager = require("MMLEnsembleManager")
  MMLEnsembleManager.removeEnsemblePlayer(self.character:getOnlineID())
end

return TAPlayMMLEnsemble
