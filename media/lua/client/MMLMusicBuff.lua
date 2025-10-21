-- MMLMusicBuff.lua

local MMLMusicBuff = {}
MMLMusicBuff.__index = MMLMusicBuff

local DEFAULTS = {
  interval = 10000, -- 每 10000 ms = 10 秒觸發一次
  applyUnhappyness = 0,
  applyBoredom = 0,
  applyPanic = 0,
  sendToServer = true, -- client 模式是否送到 server（若 isClient() 才會送）
}

local function clamp(val, lo, hi)
  if val < lo then return lo end
  if val > hi then return hi end
  return val
end

function MMLMusicBuff:new(character, cfg)
  local o = {}
  setmetatable(o, self)
  o.character = character
  o.stats = character and character:getStats() or nil
  o.cfg = {}
  for k, v in pairs(DEFAULTS) do o.cfg[k] = v end
  if cfg then
    for k, v in pairs(cfg) do o.cfg[k] = v end
  end
  o._running = false
  o._last = 0
  return o
end

function MMLMusicBuff:start()
  if not self.character or not self.stats then return end
  self._running = true
  self._last = getTimestampMs()
end

function MMLMusicBuff:stop()
  self._running = false
end

-- call from TA:update() each tick (this function throttles by interval)
function MMLMusicBuff:update()
  if not self._running or not self.character or not self.stats then return end
  local now = getTimestampMs()
  if now - self._last < self.cfg.interval then return end
  self._last = now

  local changes = {}
  changes.sourceId = self.character:getOnlineID()
  if self.cfg.applyUnhappyness ~= 0 then
    local cur = tonumber(self.stats:getUnhappyness()) or 0
    local new = clamp(cur - self.cfg.applyUnhappyness, 0, 100)
    self.stats:setUnhappyness(new)
    changes.unhappyness = self.cfg.applyUnhappyness
  end

  if self.cfg.applyBoredom ~= 0 then
    local cur = tonumber(self.stats:getBoredom()) or 0
    local new = clamp(cur - self.cfg.applyBoredom, 0, 100)
    self.stats:setBoredom(new)
    changes.boredom = self.cfg.applyBoredom
  end

  if self.cfg.applyPanic ~= 0 then
    local cur = tonumber(self.stats:getPanic()) or 0
    local new = clamp(cur - self.cfg.applyPanic, 0, 100)
    self.stats:setPanic(new)
    changes.panic = self.cfg.applyPanic
  end

  -- 如果是 client 並且需要發給 server，發送一個簡短命令（包含實際改動數值）
  if isClient() and self.cfg.sendToServer then
    local SendMMLClientCommand = require("MMLClientSendCommands")
    SendMMLClientCommand('ClientMusicBuff', {
      sourceId = self.character:getOnlineID(),
      args = changes -- 如 {unhappyness=5, boredom=10, panic=0}
    })
  end
end

return MMLMusicBuff
