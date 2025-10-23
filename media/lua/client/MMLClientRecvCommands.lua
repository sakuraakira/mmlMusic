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

-- 接收果效
MMLClientRecvCommands['ServerAnswerRange'] = function(args)
  MMLPlayer.setRange(args.SoundRange)
  print("[MMLClient] Sound range set to: " .. args.SoundRange)
end

MMLClientRecvCommands['ServerMusicBuff'] = function(args)
  print("[MMLClient] Received MusicBuff command for player: " .. args.sourceId)
  local MMLMusicEffectHandler = require("MMLMusicEffectHandler")
  MMLMusicEffectHandler.receiveEffect(args)
end

-- 接收合奏準備狀態
MMLClientRecvCommands['ServerEnsembleReady'] = function(args)
  print("[MMLClient] Received ensemble ready for player: " .. args.sourceId)
  local MMLEnsembleManager = require("MMLEnsembleManager")
  MMLEnsembleManager.addEnsemblePlayer(args.sourceId, args.playerName, args.instrument)

  -- 更新 UI 如果存在
  local MMLInstrumentUI = require('MMLInstrumentUI')
  local ui = MMLInstrumentUI.getExistingInstance()
  if ui then
    ui:updateEnsemblePlayers()
  end
end

-- 接收取消合奏準備狀態
MMLClientRecvCommands['ServerEnsembleCancel'] = function(args)
  print("[MMLClient] Received ensemble cancel for player: " .. args.sourceId)
  local MMLEnsembleManager = require("MMLEnsembleManager")
  MMLEnsembleManager.removeEnsemblePlayer(args.sourceId)

  -- 更新 UI 如果存在
  local MMLInstrumentUI = require('MMLInstrumentUI')
  local ui = MMLInstrumentUI.getExistingInstance()
  if ui then
    ui:updateEnsemblePlayers()
  end
end

-- 接收合奏開始指令
MMLClientRecvCommands['ServerEnsembleStart'] = function(args)
  print("[MMLClient] Received ensemble start command")

  local player = getPlayer()
  local myId = player:getOnlineID()

  -- 檢查是否有分配給自己的部分
  if args.assignments[myId] then
    local assignment = args.assignments[myId]
    local mml = table.concat(assignment.mmlParts, ",")

    print("[MMLClient] Playing my ensemble part")

    -- 如果有 UI，通過 UI 播放
    local MMLInstrumentUI = require('MMLInstrumentUI')
    local ui = MMLInstrumentUI.getExistingInstance()
    if ui then
      ui:onEnsemblePlay(mml)
    else
      -- 否則直接播放
      ISTimedActionQueue.clear(player)
      ISTimedActionQueue.add(MMLFromInventory:new(
        player,
        assignment.instrument,
        mml,
        false -- 不發送給服務器，因為已經是合奏了
      ))
    end
  end

  -- 播放其他玩家的音效
  for playerId, assignment in pairs(args.assignments) do
    if playerId ~= myId then
      local sourcePlayer = getPlayerByOnlineID(playerId)

      if sourcePlayer then
        local distance = player:DistTo(sourcePlayer:getX(), sourcePlayer:getY())
        local maxRange = MMLPlayer.getRange()

        if distance <= maxRange + 10 then
          local mml = table.concat(assignment.mmlParts, ",")

          -- 停止玩家之前的播放
          if MMLPlayer.activePlayers[playerId] then
            MMLPlayer.activePlayers[playerId]:stop()
          end

          -- 新的播放器實例
          local mmlPlayer = MMLPlayer:new(assignment.instrument, true)
          mmlPlayer:setSourcePlayer(sourcePlayer)

          if mmlPlayer:loadMML(mml) then
            mmlPlayer:play()
            print("[MMLClient] Playing ensemble part for player: " .. playerId)
          end
        end
      end
    end
  end
end

-- 事件處理
local function OnServerCommand(module, command, args)
  if module == 'MMLMusic' and MMLClientRecvCommands[command] then
    MMLClientRecvCommands[command](args)
  end
end

Events.OnServerCommand.Add(OnServerCommand)

return MMLClientRecvCommands
