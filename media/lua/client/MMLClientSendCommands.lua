-- MMLClientSendCommands.lua
local MMLClientSendCommands = {}

function SendMMLClientCommand(commandName, args)
  sendClientCommand('MMLMusic', commandName, args)
end

-- 發送開始播放 MML
MMLClientSendCommands.sendStartMML = function(sourceId, instrument, mmlString, position)
  if not isClient() then return end

  SendMMLClientCommand('ClientStartMML', {
    sourceId = sourceId,
    instrument = instrument,
    mml = mmlString,
    x = position.x,
    y = position.y,
    z = position.z
  })

  print(string.format("[MMLClient] Sent MML to server (length: %d chars)", #mmlString))
end

-- 發送停止播放
MMLClientSendCommands.sendStopMML = function(sourceId)
  if not isClient() then return end

  SendMMLClientCommand('ClientStopMML', {
    sourceId = sourceId
  })

  print("[MMLClient] Sent stop command to server")
end

-- 請求音效範圍設定
MMLClientSendCommands.sendAskRange = function()
  if not isClient() then return end

  SendMMLClientCommand('ClientAskRange', {})
end

-- 發送合奏準備狀態
MMLClientSendCommands.sendEnsembleReady = function(sourceId, playerName, instrument, position)
  if not isClient() then return end

  SendMMLClientCommand('ClientEnsembleReady', {
    sourceId = sourceId,
    playerName = playerName,
    instrument = instrument,
    x = position.x,
    y = position.y,
    z = position.z
  })

  print("[MMLClient] Sent ensemble ready to server")
end

-- 發送取消合奏準備狀態
MMLClientSendCommands.sendEnsembleCancel = function(sourceId, position)
  if not isClient() then return end

  SendMMLClientCommand('ClientEnsembleCancel', {
    sourceId = sourceId,
    x = position.x,
    y = position.y,
    z = position.z
  })

  print("[MMLClient] Sent ensemble cancel to server")
end

-- 發送合奏開始指令
MMLClientSendCommands.sendEnsembleStart = function(assignments, position)
  if not isClient() then return end

  SendMMLClientCommand('ClientEnsembleStart', {
    assignments = assignments,
    x = position.x,
    y = position.y,
    z = position.z
  })

  print("[MMLClient] Sent ensemble start to server")
end

-- 發送合奏停止指令
MMLClientSendCommands.sendEnsembleStop = function(position)
  if not isClient() then return end

  SendMMLClientCommand('ClientEnsembleStop', {
    x = position.x,
    y = position.y,
    z = position.z
  })

  print("[MMLClient] Sent ensemble stop to server")
end


--發送buff效果改變
MMLClientSendCommands.sendMusicBuff = function(character, changes)
  if not isClient() then return end

  SendMMLClientCommand('ClientMusicBuff', {
    sourceId = character:getOnlineID(),
    args = changes
  })

  print("[MMLClient] Sent MusicBuff to server")
end

return MMLClientSendCommands
