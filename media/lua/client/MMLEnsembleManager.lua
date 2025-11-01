-- MMLEnsembleManager.lua
-- 管理合奏準備狀態的玩家列表
local MMLEnsembleManager = {}

-- 準備合奏的玩家列表
local ensemblePlayers = {}

-- 添加準備合奏的玩家
function MMLEnsembleManager.addEnsemblePlayer(playerId, playerName, instrument)
  ensemblePlayers[playerId] = {
    name = playerName,
    instrument = instrument,
    timestamp = getTimestamp()
  }
end

-- 移除準備合奏的玩家
function MMLEnsembleManager.removeEnsemblePlayer(playerId)
  if ensemblePlayers[playerId] then
    ensemblePlayers[playerId] = nil
  end
end

-- 獲取所有準備合奏的玩家
function MMLEnsembleManager.getEnsemblePlayers()
  local players = {}
  for playerId, playerData in pairs(ensemblePlayers) do
    table.insert(players, {
      id = playerId,
      name = playerData.name,
      instrument = playerData.instrument
    })
  end
  return players
end

-- 清除所有準備合奏的玩家
function MMLEnsembleManager.clearAllPlayers()
  ensemblePlayers = {}
end

-- 檢查玩家是否在準備合奏
function MMLEnsembleManager.isPlayerReady(playerId)
  return ensemblePlayers[playerId] ~= nil
end

return MMLEnsembleManager
