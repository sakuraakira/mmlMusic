-- MMLClientRecvCommands.lua
local MMLClientRecvCommands = {}
local MMLPlayer = require('MMLPlayer')

-- 接收MML 播放命令
MMLClientRecvCommands['ServerStartMML'] = function(args)
  print(string.format("[MMLClient] Received MML from server (Player: %s, Instrument: %s)",
    args.sourceId, args.instrument))

  local player = getPlayer()
  local sourcePlayer = getPlayerByOnlineID(args.sourceId)

  if not sourcePlayer then
    print("[MMLClient] Source player not found: " .. args.sourceId)
    return
  end

  local distance = player:DistTo(sourcePlayer:getX(), sourcePlayer:getY())
  local maxRange = MMLPlayer.getRange()

  if distance > maxRange + 10 then
    print("[MMLClient] Player too far away: " .. distance)
    return
  end

  -- 停止玩家之前的播放
  if MMLPlayer.activePlayers[args.sourceId] then
    MMLPlayer.activePlayers[args.sourceId]:stop()
  end

  -- 新的播放器實例
  local mmlPlayer = MMLPlayer:new(args.instrument, true)
  mmlPlayer:setSourcePlayer(sourcePlayer)

  if not mmlPlayer:loadMML(args.mml) then
    print("[MMLClient] Failed to load MML")
    return
  end

  mmlPlayer:play()
  print("[MMLClient] Started MML playback")
end

-- 接收停止命令
MMLClientRecvCommands['ServerStopMML'] = function(args)
  print("[MMLClient] Received stop command for player: " .. args.sourceId)

  if MMLPlayer.activePlayers[args.sourceId] then
    MMLPlayer.activePlayers[args.sourceId]:stop()
  end
end

-- 接收音效
MMLClientRecvCommands['ServerAnswerRange'] = function(args)
  MMLPlayer.setRange(args.SoundRange)
  print("[MMLClient] Sound range set to: " .. args.SoundRange)
end

-- 接收停止命令
MMLClientRecvCommands['ServerMusicBuff'] = function(args)
  print("[MMLClient] Received MusicBuff command for player: " .. args.sourceId)
  local MMLMusicEffectHandler = require("MMLMusicEffectHandler")
  MMLMusicEffectHandler.receiveEffect(args)
end

-- 事件處理
local function OnServerCommand(module, command, args)
  if module == 'MMLMusic' and MMLClientRecvCommands[command] then
    MMLClientRecvCommands[command](args)
  end
end

Events.OnServerCommand.Add(OnServerCommand)

return MMLClientRecvCommands
