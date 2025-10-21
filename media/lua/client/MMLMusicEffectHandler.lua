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
  local stats = player:getStats()
  if not stats then return end

  if changes.unhappyness and type(changes.unhappyness) == "number" then
    local cur = tonumber(stats:getUnhappyness()) or 0
    local new = clamp(cur - changes.unhappyness, 0, 100)
    stats:setUnhappyness(new)
  end
  if changes.boredom and type(changes.boredom) == "number" then
    local cur = tonumber(stats:getBoredom()) or 0
    local new = clamp(cur - changes.boredom, 0, 100)
    stats:setBoredom(new)
  end
  if changes.panic and type(changes.panic) == "number" then
    local cur = tonumber(stats:getPanic()) or 0
    local new = clamp(cur - changes.panic, 0, 100)
    stats:setPanic(new)
  end
end

-- public: 收到 server 廣播/通知要套用效果時呼叫
-- args: { sourceId = <num>, changes = {unhappyness=10, boredom=10, panic=10}, timestamp = <ms, optional> }
function MMLMusicEffectHandler.receiveEffect(args)
  if not args then return false end

  local now = getTimestampMs()
  local last = MMLMusicEffectHandler.lastApplied or 0
  local throttle = MMLMusicEffectHandler.throttleMs

  if last ~= 0 and now - last < throttle then
    return false   -- 被節流
  end

  -- 通過 throttle，套用本地變更
  local player = getPlayer()
  if not player then return false end

  -- 套用（client 視覺/音效回饋可在此觸發）
  applyLocalChangesToPlayer(player, args)

  -- 更新 timestamp
  MMLMusicEffectHandler.lastApplied = now

  -- 回傳 true 表示有套用（caller 可用來觸發 UI/音效）
  return true
end

return MMLMusicEffectHandler
