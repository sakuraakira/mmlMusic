-- MMLServerCommands.lua
local MMLServerCommands = {}

function SendMMLServerCommand(player, commandName, args)
  sendServerCommand(player, 'MMLMusic', commandName, args)
end

-- 廣播 MML 給範圍內的玩家
MMLServerCommands['ClientStartMML'] = function(player, args)
  print(string.format("[MMLServer] Broadcasting MML from player %s", args.sourceId))

  local soundRange = SandboxVars.MMLMusic and SandboxVars.MMLMusic.SoundRange or 40
  local connectedPlayers = getOnlinePlayers()
  local broadcastCount = 0

  for i = 0, connectedPlayers:size() - 1 do
    local connectedPlayer = connectedPlayers:get(i)

    -- 廣播給範圍內的所有玩家（包括自己）
    if connectedPlayer:DistTo(args.x, args.y) < soundRange + 10 then
      SendMMLServerCommand(connectedPlayer, 'ServerStartMML', args)
      broadcastCount = broadcastCount + 1
    end
  end

  print(string.format("[MMLServer] Broadcasted to %d players", broadcastCount))
end

-- 廣播停止命令
MMLServerCommands['ClientStopMML'] = function(player, args)
  print(string.format("[MMLServer] Broadcasting stop from player %s", args.sourceId))

  local soundRange = SandboxVars.MMLMusic and SandboxVars.MMLMusic.SoundRange or 40
  local connectedPlayers = getOnlinePlayers()

  for i = 0, connectedPlayers:size() - 1 do
    local connectedPlayer = connectedPlayers:get(i)

    if connectedPlayer:DistTo(player:getX(), player:getY()) < soundRange + 20 then
      SendMMLServerCommand(connectedPlayer, 'ServerStopMML', args)
    end
  end
end

-- 回應音效範圍設定請求
MMLServerCommands['ClientAskRange'] = function(player, args)
  local soundRange = SandboxVars.MMLMusic and SandboxVars.MMLMusic.SoundRange or 40
  SendMMLServerCommand(player, 'ServerAnswerRange', {
    SoundRange = soundRange
  })
  print(string.format("[MMLServer] Sent sound range to player: %d", soundRange))
end

-- 註冊事件處理
local function OnClientCommand(module, command, player, args)
  if module == 'MMLMusic' and MMLServerCommands[command] then
    MMLServerCommands[command](player, args)
  end
end

Events.OnClientCommand.Add(OnClientCommand)

return MMLServerCommands
