-- MMLMusicBuff.lua

local MMLMusicBuff = {}
MMLMusicBuff.__index = MMLMusicBuff

local DEFAULTS = {
  interval = 10000, -- 每 10000 ms = 10 秒觸發一次
  applyUnhappyness = 0,
  applyBoredom = 0,
  applyPanic = 0,
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
  o.cfg = {}
  for k, v in pairs(DEFAULTS) do o.cfg[k] = v end
  if cfg then
    for k, v in pairs(cfg) do o.cfg[k] = v end
  end
  o._running = false
  o._last = 0
  print("[MMLMusicBuff] Created with config: %d", o.character:getOnlineID())
  return o
end

function MMLMusicBuff:start()
  if not self.character then return end
  print("[MMLMusicBuff] Started with config: %d", self.character:getOnlineID())
  self._running = true
  self._last = getTimestampMs()
end

function MMLMusicBuff:stop()
  print("[MMLMusicBuff] Stopped for character: %d", self.character:getOnlineID())
  self._running = false
end

-- call from TA:update() each tick (this function throttles by interval)
function MMLMusicBuff:update()
  if not self._running or not self.character then return end
  local now = getTimestampMs()
  if now - self._last < self.cfg.interval then return end
  self._last = now
  ---@class BodyDamage
  local bodyDamage = self.character:getBodyDamage() or nil

  if bodyDamage then
    local changes = {}
    changes.sourceId = self.character:getOnlineID()
    if self.cfg.applyUnhappyness ~= 0 then
      local cur = bodyDamage:getUnhappynessLevel() or 0
      local new = clamp(cur - self.cfg.applyUnhappyness, 0, 100)
      bodyDamage:setUnhappynessLevel(new)
      print(string.format("[MMLMusicBuff] unhappyness: %.3f -> %.3f", cur, new))
      changes.unhappyness = self.cfg.applyUnhappyness
    end

    if self.cfg.applyBoredom ~= 0 then
      local cur = bodyDamage:getBoredomLevel() or 0
      local new = clamp(cur - self.cfg.applyBoredom, 0, 100)
      bodyDamage:setBoredomLevel(new)
      print(string.format("[MMLMusicBuff] boredom: %.3f -> %.3f", cur, new))
      changes.boredom = self.cfg.applyBoredom
    end

    if self.cfg.applyPanic ~= 0 then
      local stats = self.character:getStats()
      local cur = stats:getPanic() or 0
      local new = clamp(cur - self.cfg.applyPanic, 0, 100)
      stats:setPanic(new)
      print(string.format("[MMLMusicBuff] panic: %.3f -> %.3f", cur, new))
      changes.panic = self.cfg.applyPanic
    end

    -- 如果是 client 並且需要發給 server，發送一個簡短命令（包含實際改動數值）
    if isClient() then
      local SendMMLClientCommand = require("MMLClientSendCommands")
      SendMMLClientCommand('ClientMusicBuff', {
        sourceId = self.character:getOnlineID(),
        args = changes -- 如 {unhappyness=5, boredom=10, panic=0}
      })


      return
    end
  end
end

return MMLMusicBuff
