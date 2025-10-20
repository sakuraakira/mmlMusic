-- MMLClientRecvCommands.lua (修正版)
local MMLClientRecvCommands = {}
local MMLPlayer = require('MMLPlayer')

-- 接收服务器发来的 MML 播放命令
MMLClientRecvCommands['ServerStartMML'] = function(args)
  print(string.format("[MMLClient] Received MML from server (Player: %s, Instrument: %s)",
    args.sourceId, args.instrument))

  local player = getPlayer()
  local sourcePlayer = getPlayerByOnlineID(args.sourceId)

  if not sourcePlayer then
    print("[MMLClient] Source player not found: " .. args.sourceId)
    return
  end

  -- 检查距离
  local distance = player:DistTo(sourcePlayer:getX(), sourcePlayer:getY())
  local maxRange = MMLPlayer.getRange() -- 使用模块函数

  if distance > maxRange + 10 then
    print("[MMLClient] Player too far away: " .. distance)
    return
  end

  -- 停止该玩家之前的播放
  if MMLPlayer.activePlayers[args.sourceId] then
    MMLPlayer.activePlayers[args.sourceId]:stop()
  end

  -- 创建新的播放器实例
  local mmlPlayer = MMLPlayer:new(args.instrument, false)
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

-- 接收音效范围设定
MMLClientRecvCommands['ServerAnswerRange'] = function(args)
  MMLPlayer.setRange(args.SoundRange) -- 使用模块函数
  print("[MMLClient] Sound range set to: " .. args.SoundRange)
end

-- 注册事件处理
local function OnServerCommand(module, command, args)
  if module == 'MMLMusic' and MMLClientRecvCommands[command] then
    MMLClientRecvCommands[command](args)
  end
end

Events.OnServerCommand.Add(OnServerCommand)

-- 游戏启动时请求音效范围
local lastAskedTime = 0
local function AskServerData()
  local currentTime = GetCurrentTimeInMs()
  if currentTime - lastAskedTime < 2000 then
    return
  end
  lastAskedTime = currentTime

  if MMLPlayer.getRange() ~= 40 then -- 已经设定过了
    Events.OnPostRender.Remove(AskServerData)
    return
  end

  local MMLClientSendCommands = require('MMLClientSendCommands')
  MMLClientSendCommands.sendAskRange()
end

function GetCurrentTimeInMs()
  return Calendar.getInstance():getTimeInMillis()
end

Events.OnPostRender.Add(AskServerData)

return MMLClientRecvCommands
