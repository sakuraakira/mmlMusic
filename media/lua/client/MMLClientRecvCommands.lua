-- MMLClientRecvCommands.lua
local MMLClientRecvCommands = {}
local MMLPlayer = require('MMLPlayer')
local TAPlayMMLFromInventory = require('TimedAction/TAPlayMMLFromInventory')

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

  local playerId = getPlayer():getOnlineID()
  if args.sourceId == playerId then
    print("[MMLClient] Canceling own ensemble preparation, no action needed.")
    return
  end

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
  print("[MMLClient] Received ensemble start command count ", tostring(#args.assignments))

  local player = getPlayer()
  local myId = player:getOnlineID()

  -- 預加載所有玩家的 MML Player
  local myMMLPlayer = nil
  local otherPlayers = {}

  -- 1. 先預加載所有 MML（包括自己的）
  for playerId, assignment in pairs(args.assignments) do
    -- 停止之前的播放
    print("[MMLClient] Preloading MML for player: ", tostring(playerId))
    if MMLPlayer.activePlayers[playerId] then
      MMLPlayer.activePlayers[playerId]:stop()
    end
    local mml = table.concat(assignment.mmlParts, ",")

    if playerId == myId then
      -- 預加載自己的
      myMMLPlayer = {
        mml = mml,
        instrument = assignment.instrument
      }
    else
      -- 預加載其他玩家的
      local sourcePlayer = getPlayerByOnlineID(playerId)

      if sourcePlayer then
        local distance = player:DistTo(sourcePlayer:getX(), sourcePlayer:getY())
        local maxRange = MMLPlayer.getRange()

        if distance <= maxRange + 10 then
          -- 創建並預加載播放器
          local mmlPlayer = MMLPlayer:new(assignment.instrument, true)
          mmlPlayer:setSourcePlayer(sourcePlayer)

          if mmlPlayer:loadMML(mml) then
            table.insert(otherPlayers, mmlPlayer)
            print("[MMLClient] Preloaded ensemble part for player: " .. playerId)
          end
        end
      end
    end
  end


  -- 3. 最後通過 UI 播放自己的部分
  if myMMLPlayer then
    print("[MMLClient] Playing my ensemble part")

    local MMLInstrumentUI = require('MMLInstrumentUI')
    local ui = MMLInstrumentUI.getExistingInstance() or nil
    local isOpen = ui and
        ((ui.getIsVisible and ui:getIsVisible()) or (ui.isVisible and ui:isVisible()) or ui.visible == true)
    if (ui and isOpen) then
      print("[MMLClient] EnsemblePla for player: ", tostring(playerId))
      ui:onEnsemblePlay(myMMLPlayer.mml)
    else
      print("[MMLClient] TAPlayMMLFromInventory for player: ", tostring(playerId))
      ISTimedActionQueue.clear(player)
      ISTimedActionQueue.add(TAPlayMMLFromInventory:new(player, myMMLPlayer.instrument, myMMLPlayer.mml, false))
    end
  end
  -- 統一開始播放（先播放其他玩家，最後播放自己以確保 UI 更新）
  for _, mmlPlayer in ipairs(otherPlayers) do
    mmlPlayer:play()
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
