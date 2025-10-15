-- MMLPlayerUI.lua
-- MML 播放器 UI 介面
local MMLPlayerUI = ISCollapsableWindow:derive("MMLPlayerUI")
local MMLPlayer = require('MMLPlayer')
local MMLParser = require('MMLParser')

local WIDTH = 650
local HEIGHT = 550

function MMLPlayerUI:new(instrument)
  local x = getCore():getScreenWidth() / 2 - WIDTH / 2
  local y = getCore():getScreenHeight() / 2 - HEIGHT / 2
  local o = ISCollapsableWindow:new(x, y, WIDTH, HEIGHT)
  setmetatable(o, self)
  self.__index = self

  o.instrument = instrument or "Piano"
  o.title = "MML Player - " .. o.instrument
  o.mmlPlayer = nil
  o.isPlaying = false

  return o
end

function MMLPlayerUI:initialise()
  ISCollapsableWindow.initialise(self)
  ISCollapsableWindow.createChildren(self)

  local th = self:titleBarHeight()
  local padding = 10
  local buttonHeight = 25

  -- 輸入區標籤
  self.labelInput = ISLabel:new(
    padding, th + padding, buttonHeight,
    getText("UI_MMLPlayer_InputLabel") or "Enter MML Code:",
    1, 1, 1, 1, UIFont.Medium, true
  )
  self.labelInput:initialise()
  self:addChild(self.labelInput)

  self.textArea1 = ISTextEntryBox:new(
    "",
    padding,
    self.labelInput:getBottom() + 5,
    WIDTH - padding * 2,
    120
  )
  self.textArea1:initialise()
  self.textArea1:instantiate()
  self.textArea1.font = UIFont.Small
  self.textArea1:setMultipleLine(true)
  self.textArea1:setMaxLines(20)
  self.textArea1:setEditable(true)
  self:addChild(self.textArea1)

  self.labelTrack2 = ISLabel:new(
    padding, self.textArea1:getBottom() + 4, buttonHeight,
    "Track 2:",
    1, 1, 1, 1, UIFont.Small, true
  )
  self.labelTrack2:initialise()
  self:addChild(self.labelTrack2)

  self.textArea2 = ISTextEntryBox:new(
    "",
    padding,
    self.labelTrack2:getBottom() + 2,
    WIDTH - padding * 2,
    80
  )
  self.textArea2:initialise()
  self.textArea2:instantiate()
  self.textArea2.font = UIFont.Small
  self.textArea2:setMultipleLine(true)
  self.textArea2:setMaxLines(10)
  self.textArea2:setEditable(true)
  self:addChild(self.textArea2)

  self.labelTrack3 = ISLabel:new(
    padding, self.textArea2:getBottom() + 4, buttonHeight,
    "Track 3:",
    1, 1, 1, 1, UIFont.Small, true
  )
  self.labelTrack3:initialise()
  self:addChild(self.labelTrack3)

  self.textArea3 = ISTextEntryBox:new(
    "",
    padding,
    self.labelTrack3:getBottom() + 2,
    WIDTH - padding * 2,
    80
  )
  self.textArea3:initialise()
  self.textArea3:instantiate()
  self.textArea3.font = UIFont.Small
  self.textArea3:setMultipleLine(true)
  self.textArea3:setMaxLines(10)
  self.textArea3:setEditable(true)
  self:addChild(self.textArea3)

  -- 範例標籤（位置改為依 textArea3 底部）
  local exampleText = "Example: Track1 T120 L4CDEFG | Track2 L4 EGBEBEBEGA | Track3 L2 CCCC"
  self.labelExample = ISLabel:new(
    padding, self.textArea3:getBottom() + padding, buttonHeight,
    exampleText,
    0.7, 0.7, 0.7, 1, UIFont.Small, true
  )
  self.labelExample:initialise()
  self:addChild(self.labelExample)

  -- 按鈕區
  local buttonY = self.labelExample:getBottom() + padding
  local buttonWidth = 80
  local buttonSpacing = 10

  -- 播放按鈕
  self.playButton = ISButton:new(
    padding, buttonY, buttonWidth, buttonHeight,
    getText("UI_MMLPlayer_Play") or "Play",
    self, MMLPlayerUI.onPlay
  )
  self.playButton:initialise()
  self.playButton:instantiate()
  self.playButton.borderColor = { r = 1, g = 1, b = 1, a = 0.3 }
  self:addChild(self.playButton)

  -- 停止按鈕
  self.stopButton = ISButton:new(
    self.playButton:getRight() + buttonSpacing, buttonY,
    buttonWidth, buttonHeight,
    getText("UI_MMLPlayer_Stop") or "Stop",
    self, MMLPlayerUI.onStop
  )
  self.stopButton:initialise()
  self.stopButton:instantiate()
  self.stopButton.borderColor = { r = 1, g = 1, b = 1, a = 0.3 }
  self.stopButton.enable = false
  self:addChild(self.stopButton)

  -- 驗證按鈕
  self.validateButton = ISButton:new(
    self.stopButton:getRight() + buttonSpacing, buttonY,
    buttonWidth, buttonHeight,
    getText("UI_MMLPlayer_Validate") or "Validate",
    self, MMLPlayerUI.onValidate
  )
  self.validateButton:initialise()
  self.validateButton:instantiate()
  self.validateButton.borderColor = { r = 1, g = 1, b = 1, a = 0.3 }
  self:addChild(self.validateButton)

  -- 清除按鈕
  self.clearButton = ISButton:new(
    self.validateButton:getRight() + buttonSpacing, buttonY,
    buttonWidth, buttonHeight,
    getText("UI_MMLPlayer_Clear") or "Clear",
    self, MMLPlayerUI.onClear
  )
  self.clearButton:initialise()
  self.clearButton:instantiate()
  self.clearButton.borderColor = { r = 1, g = 1, b = 1, a = 0.3 }
  self:addChild(self.clearButton)

  -- 範例樂曲按鈕
  self.exampleButton = ISButton:new(
    self.clearButton:getRight() + buttonSpacing, buttonY,
    100, buttonHeight,
    getText("UI_MMLPlayer_LoadExample") or "Load Example",
    self, MMLPlayerUI.onLoadExample
  )
  self.exampleButton:initialise()
  self.exampleButton:instantiate()
  self.exampleButton.borderColor = { r = 1, g = 1, b = 1, a = 0.3 }
  self:addChild(self.exampleButton)

  -- 進度條背景
  self.progressBar = ISPanel:new(
    padding,
    self.playButton:getBottom() + padding,
    WIDTH - padding * 2,
    20
  )
  self.progressBar:initialise()
  self.progressBar:instantiate()
  self.progressBar.backgroundColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 }
  self:addChild(self.progressBar)

  -- 狀態標籤
  self.statusLabel = ISLabel:new(
    padding,
    self.progressBar:getBottom() + 5,
    buttonHeight,
    getText("UI_MMLPlayer_Ready") or "Ready",
    1, 1, 1, 1, UIFont.Small, true
  )
  self.statusLabel:initialise()
  self:addChild(self.statusLabel)

  -- 資訊標籤（音符數、時長等）
  self.infoLabel = ISLabel:new(
    padding,
    self.statusLabel:getBottom() + 5,
    buttonHeight,
    "",
    0.7, 0.7, 0.7, 1, UIFont.Small, true
  )
  self.infoLabel:initialise()
  self:addChild(self.infoLabel)

  -- 預設 MML：放在 track1（其他兩軌預設空）
  self.textArea1:setText("T120 L4 O4 C D E F G A B O5 C")
  self.textArea2:setText("")
  self.textArea3:setText("")

  self:setResizable(false)
  self:addToUIManager()
end

function MMLPlayerUI:onPlay()
  local mml1 = self.textArea1:getText() or ""
  local mml2 = self.textArea2:getText() or ""
  local mml3 = self.textArea3:getText() or ""

  if mml1 == "" and mml2 == "" and mml3 == "" then
    self.statusLabel:setName(getText("UI_MMLPlayer_EmptyInput") or "Please enter MML code")
    return
  end

  -- 停止之前的播放
  if self.mmlPlayer then
    self.mmlPlayer:stop()
  end

  -- 創建新的播放器
  self.mmlPlayer = MMLPlayer:new(self.instrument)

  -- 組合為單一字串（以逗號區分 track）
  local combined = string.format("%s,%s,%s", mml1, mml2, mml3)

  -- 修正：使用正確的 API，讓 2/3 軌共享第 1 軌的 T(tempo)
  local ok = self.mmlPlayer:loadMML(combined)

  -- 顯示合併後結果（方便使用者查看）
  self.infoLabel:setName(self.mmlPlayer:getMMLString() or "")

  if not ok then
    self.statusLabel:setName(getText("UI_MMLPlayer_ParseError") or "Parse error")
    self.playButton.enable = true
    self.stopButton.enable = false
    return
  end

  if self.mmlPlayer:play() then
    self.isPlaying = true
    self.statusLabel:setName(getText("UI_MMLPlayer_Playing") or "Playing...")
    self.playButton.enable = false
    self.stopButton.enable = true
  else
    self.statusLabel:setName(getText("UI_MMLPlayer_PlayFailed") or "Play failed")
  end
end

function MMLPlayerUI:onStop()
  if self.mmlPlayer then
    self.mmlPlayer:stop()
    self.isPlaying = false
    self.statusLabel:setName(getText("UI_MMLPlayer_Stopped") or "Stopped")
    self.playButton.enable = true
    self.stopButton.enable = false
  end
end

-- 新增：將毫秒格式化為可讀時間字串
local function formatDurationMs(ms)
  ms = ms or 0
  local secs = ms / 1000
  local mins = math.floor(secs / 60)
  local rem = secs - mins * 60
  if mins > 0 then
    -- 顯示為 M:SS.ss
    return string.format("%d:%05.2f", mins, rem)
  else
    -- 顯示為 S.ss 秒
    return string.format("%.2fs", rem)
  end
end

function MMLPlayerUI:onValidate()
  local mml1 = self.textArea1:getText() or ""
  local mml2 = self.textArea2:getText() or ""
  local mml3 = self.textArea3:getText() or ""

  MMLPlayer:debugValidateTriple(mml1, mml2, mml3)

  if mml1 == "" and mml2 == "" and mml3 == "" then
    self.statusLabel:setName(getText("UI_MMLPlayer_EmptyInput") or "Please enter MML code")
    return
  end

  -- 使用 MMLPlayer helper 解析三軌（不啟動播放）
  local tmpPlayer = MMLPlayer:new(self.instrument)
  local results = tmpPlayer:parseTracks({ mml1, mml2, mml3 })

  local totalNotes = 0
  local maxDuration = 0
  local anyError = false
  local lines = {}

  for i, res in ipairs(results) do
    if res.ok then
      totalNotes = totalNotes + (res.notes or 0)
      if res.duration and res.duration > maxDuration then maxDuration = res.duration end
      -- 使用 formatDurationMs 把毫秒轉成可讀播放長度字串
      local durStr = formatDurationMs(res.duration or 0)
      table.insert(lines, string.format("Track %d: OK %d , %s", i, res.notes or 0, durStr))
    else
      anyError = true
      table.insert(lines, string.format("Track %d: ERROR %s", i, res.err or "parse error"))
    end
  end

  if anyError then
    self.statusLabel:setName(getText("UI_MMLPlayer_InvalidSyntax") or "One or more tracks failed to parse")
    self.infoLabel:setName(table.concat(lines, " | "))
  else
    self.statusLabel:setName(string.format("Valid: %d notes, %.2fs", totalNotes, (maxDuration or 0) / 1000))
    self.infoLabel:setName(table.concat(lines, " | "))
  end
end

function MMLPlayerUI:onClear()
  self.textArea1:setText("")
  self.textArea2:setText("")
  self.textArea3:setText("")
  self.statusLabel:setName(getText("UI_MMLPlayer_Ready") or "Ready")
  self.infoLabel:setName("")
  if self.mmlPlayer then
    self.mmlPlayer:stop()
    self.isPlaying = false
    self.playButton.enable = true
    self.stopButton.enable = false
  end
end

function MMLPlayerUI:onLoadExample()
  -- 三軌示範：主旋律、和聲、低音
  local ex1 = "T120 L4 O4 CCGGAAG2 FFEEDDC2"
  local ex2 = "T120 L8 O5 E E D C E E D C"
  local ex3 = "T120 L2 O3 C C C C"
  self.textArea1:setText(ex1)
  self.textArea2:setText(ex2)
  self.textArea3:setText(ex3)
  self.statusLabel:setName(getText("UI_MMLPlayer_ExampleLoaded") or "Example loaded")
end

function MMLPlayerUI:prerender()
  ISCollapsableWindow.prerender(self)

  -- 檢查播放狀態
  if self.mmlPlayer and not self.mmlPlayer:isPlayingMusic() and self.isPlaying then
    -- 播放結束
    self.isPlaying = false
    self.statusLabel:setName(getText("UI_MMLPlayer_Finished") or "Finished")
    self.playButton.enable = true
    self.stopButton.enable = false
  end
end

function MMLPlayerUI:render()
  ISCollapsableWindow.render(self)

  -- 繪製進度條
  if self.mmlPlayer and self.isPlaying then
    local progress = self.mmlPlayer:getProgress()
    local barWidth = (self.progressBar.width - 4) * progress

    self:drawRect(
      self.progressBar.x + 2,
      self.progressBar.y + 2,
      barWidth,
      self.progressBar.height - 4,
      1.0, 0.3, 0.7, 0.3
    )

    -- 顯示剩餘時間
    local remaining = self.mmlPlayer:getRemainingTime()
    self.infoLabel:setName(
      string.format("Progress: %.0f%% | Remaining: %.1fs",
        progress * 100, remaining)
    )
  end
end

function MMLPlayerUI:close()
  if self.mmlPlayer then
    self.mmlPlayer:stop()
  end
  ISCollapsableWindow.close(self)
  self:removeFromUIManager()
end

function MMLPlayerUI:setMMLPlayer(mmlPlayer)
  self.mmlPlayer = mmlPlayer
  if mmlPlayer then
    self.isPlaying = mmlPlayer:isPlayingMusic()
  end
end

return MMLPlayerUI
