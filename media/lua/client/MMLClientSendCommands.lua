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

return MMLClientSendCommands
