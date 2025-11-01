-- MMLClientRecvCommands.lua
local MMLClientRecvCommands = {}
local MMLPlayer = require('MMLPlayer')
local TAPlayMMLFromInventory = require('TimedAction/TAPlayMMLFromInventory')

-- 接收MML 播放命令
MMLClientRecvCommands['ServerStartMML'] = function(args)
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
end

-- 接收停止命令
MMLClientRecvCommands['ServerStopMML'] = function(args)
  if MMLPlayer.activePlayers[args.sourceId] then
    MMLPlayer.activePlayers[args.sourceId]:stop()
  end
end

-- 接收果效
MMLClientRecvCommands['ServerAnswerRange'] = function(args)
  MMLPlayer.setRange(args.SoundRange)
end

MMLClientRecvCommands['ServerMusicBuff'] = function(args)
  local MMLMusicEffectHandler = require("MMLMusicEffectHandler")
  MMLMusicEffectHandler.receiveEffect(args)
end

-- 接收合奏準備狀態
MMLClientRecvCommands['ServerEnsembleReady'] = function(args)
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
  local playerId = getPlayer():getOnlineID()
  if args.sourceId == playerId then
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
  local player = getPlayer()
  local myId = player:getOnlineID()

  -- 預加載所有玩家的 MML Player
  local myMMLPlayer = nil
  local otherPlayers = {}
  local MMLInstrumentUI = require('MMLInstrumentUI')
  -- 1. 先預加載所有 MML（包括自己的）
  for playerId, assignment in pairs(args.assignments) do
    -- 停止之前的播放
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
          end
        end
      end
    end
  end

  -- 3. 最後通過 UI 播放自己的部分
  if myMMLPlayer then
    if args.sourceId == myId then
      local ui = MMLInstrumentUI.getExistingInstance()
      ui:onEnsemblePlay(myMMLPlayer.mml, true)
    else
      local queue = ISTimedActionQueue.getTimedActionQueue(player)
      local cur = queue.current
      if cur and cur.isReady then
        cur.isEnsemble = true
        cur:stop()
      end
      ui = MMLInstrumentUI.getInstance(player, player:getSecondaryHandItem())
      ui:show()
      ui:onEnsemblePlay(myMMLPlayer.mml, false)
    end
  end
  -- 統一開始播放（先播放其他玩家，最後播放自己以確保 UI 更新）
  for _, mmlPlayer in ipairs(otherPlayers) do
    mmlPlayer:play()
  end
end

-- 接收合奏停止指令
MMLClientRecvCommands['ServerEnsembleStop'] = function(args)
  local myPlayer = getPlayer()
  local myId = myPlayer:getOnlineID()
  -- 停止並清除所有活躍的 MMLPlayer 實例
  if MMLPlayer and type(MMLPlayer.activePlayers) == "table" then
    for id, player in pairs(MMLPlayer.activePlayers) do
      if player and type(player.stop) == "function" then
        local ok, err = pcall(function() player:stop() end)
      end
      -- 移除快取
      MMLPlayer.activePlayers[id] = nil

      if id == myId then
        local queue = ISTimedActionQueue.getTimedActionQueue(myPlayer)
        local cur = queue.current;
        if cur and cur.playing then
          cur:stop()
          local item = myPlayer:getSecondaryHandItem()
          ISTimedActionQueue.add(TAPlayMMLEnsemble:new(myPlayer, item))
          return
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
