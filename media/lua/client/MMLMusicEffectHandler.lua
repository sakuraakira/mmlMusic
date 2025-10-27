-- MMLMusicEffectHandler.lua

local MMLMusicEffectHandler = {}
MMLMusicEffectHandler.__index = MMLMusicEffectHandler

-- 設定
MMLMusicEffectHandler.throttleMs = 10000 -- 10 秒內不重覆套用同一 source 的效果
MMLMusicEffectHandler.lastApplied = nil  -- map sourceId -> timestamp ms

local function clamp(val, lo, hi)
  if val < lo then return lo end
  if val > hi then return hi end
  return val
end

-- 內部：在 client 端直接套用 stats（只改本地 player）
local function applyLocalChangesToPlayer(player, changes)
  if not player or not changes then return end

  ---@class BodyDamage
  local bodyDamage = player:getBodyDamage()
  if not bodyDamage then return end

  if changes.unhappyness and type(changes.unhappyness) == "number" then
    local cur = bodyDamage:getUnhappynessLevel() or 0
    local new = clamp(cur - changes.unhappyness, 0, 100)
    bodyDamage:setUnhappynessLevel(new)
  end
  if changes.boredom and type(changes.boredom) == "number" then
    local cur = bodyDamage:getBoredomLevel() or 0
    local new = clamp(cur - changes.boredom, 0, 100)
    bodyDamage:setBoredomLevel(new)
  end

  ---@class Stats
  local stats = player:getStats()
  if changes.panic and type(changes.panic) == "number" then
    local cur = stats:getPanic() or 0
    local new = clamp(cur - changes.panic, 0, 100)
    stats:setPanic(new)
  end
  if changes.stress and type(changes.stress) == "number" then
    local cur = stats:getStress() or 0
    local new = clamp(cur - (self.cfg.applyStress / 100), 0, 1)
    stats:setStress(new)
  end
end

-- public: 收到 server 廣播/通知要套用效果時呼叫
function MMLMusicEffectHandler.receiveEffect(args)
  if not args then return false end

  local now = getTimestampMs()
  local last = MMLMusicEffectHandler.lastApplied or 0
  local throttle = MMLMusicEffectHandler.throttleMs

  if last ~= 0 and now - last < throttle then
    return false -- 被節流
  end

  -- 通過 throttle，套用本地變更
  local player = getPlayer()
  if not player then return false end
  applyLocalChangesToPlayer(player, args)
  MMLMusicEffectHandler.lastApplied = now

  -- 回傳 true 表示有套用（caller 可用來觸發 UI/音效）
  return true
end

return MMLMusicEffectHandler
