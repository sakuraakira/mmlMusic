---@diagnostic disable: assign-type-mismatch
-- MMLComposeUI.lua
-- MML 播放器 UI 介面
---@class MMLComposeUI: ISCollapsableWindow
---@field instrument string
---@field mmlPlayer MMLPlayer
---@field isPlaying boolean
---@field character IsoPlayer
---@field textArea1 ISTextEntryBox
---@field textArea2 ISTextEntryBox
---@field textArea3 ISTextEntryBox
---@field playButton ISButton
---@field stopButton ISButton
---@field validateButton ISButton
---@field clearButton ISButton
---@field progressBar ISPanel
---@field statusLabel ISLabel
---@field infoLabel ISLabel
---@field instrumentCombo ISComboBox
---@field labelInput ISLabel
---@field labelTrack2 ISLabel
---@field labelTrack3 ISLabel
---@field labelExample ISLabel
---@field labelInstrument ISLabel
---@field onPlay fun(self: MMLComposeUI): nil 播放按鈕回調
---@field onStop fun(self: MMLComposeUI): nil 停止按鈕
---@field render fun(self: MMLComposeUI): nil 繪製介面
---@field close fun(self: MMLComposeUI): nil 關閉視窗
---@field initialise fun(self: MMLComposeUI): nil 初始化元件
local MMLComposeUI = ISCollapsableWindow:derive("MMLComposeUI")

local MMLPlayer = require('MMLPlayer')

local WIDTH = 730
local HEIGHT = 580
local MAX_LEN = 1500
local function clampEntry(entry)
  local value = entry:getText() or ""
  if #value > MAX_LEN then
    local trimmed = value:sub(1, MAX_LEN)
    entry:setText(trimmed)
    return trimmed, true
  end
  return value
end

local function formatDurationMs(ms)
  ms = ms or 0
  local secs = ms / 1000
  local mins = math.floor(secs / 60)
  local rem = secs - mins * 60

  -- 顯示為 S.ss 秒
  return string.format("%.2fs", rem)
end

-- 儲存單例實例
local instance = nil

-- 新增：取得現有實例（不創建新的）
function MMLComposeUI.getExistingInstance()
  return instance
end

---@param character IsoPlayer 玩家角色
---@return ISCollapsableWindow
function MMLComposeUI.getInstance(character)
  if not instance then
    instance = MMLComposeUI:new("Piano", character)
  else
    -- 更新現有實例的資料
    instance.character = character
  end
  return instance
end

function MMLComposeUI:new(instrument, character)
  local x = getCore():getScreenWidth() / 2 - WIDTH / 2
  local y = getCore():getScreenHeight() / 2 - HEIGHT / 2
  ---@class MMLComposeUI
  local o = ISCollapsableWindow:new(x, y, WIDTH, HEIGHT)
  setmetatable(o, self)
  self.__index = self

  o.title = getText("UI_MMLPlayer_Title") or "MML Player"
  o.mmlPlayer = nil -- backwards-compat, 保留欄位（不再主要使用）
  o.mmlPlayers = {} -- 新：多播放器實例列表（按 tab 順序）
  o.isPlaying = false

  o.isInitialized = false -- 追蹤是否已初始化
  o.resizable = false

  o.character = character
  o.instrument = instrument or "Piano"
  o.tabControls = {
    melody = {},
    harmony = {},
    chord = {},
    graceNote = {},
    rootNote = {}
  }
  return o
end

function MMLComposeUI:addTab(name)
  local tabHost = self.nested
  local mainPanel = ISPanelJoypad:new(0, 75, self:getWidth(),
    400)
  mainPanel:initialise()
  mainPanel:instantiate()
  mainPanel:setAnchorRight(true)
  mainPanel:setAnchorLeft(true)
  mainPanel:setAnchorTop(true)
  mainPanel:setAnchorBottom(true)
  mainPanel:noBackground()
  mainPanel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
  mainPanel:setScrollChildren(true)
  mainPanel.onJoypadDown = MainOptions.onJoypadDownCurrentTab
  mainPanel.onGainJoypadFocus = MainOptions.onGainJoypadFocusCurrentTab
  mainPanel:addScrollBars()
  tabHost:addView(name, mainPanel)
  return mainPanel
end

function MMLComposeUI:addTabContainer(TabPanel, tabName)
  local container = ISPanel:new(0, 0, TabPanel:getWidth() - 20, TabPanel:getHeight() - 30)
  container:initialise()
  container:instantiate()
  container:setAnchorRight(true)
  container:setAnchorLeft(true)
  container:setAnchorTop(true)
  container:setAnchorBottom(true)
  container:noBackground()

  -- 輸入區標籤
  local padding = 10
  local buttonHeight = 25
  local labelInput = ISLabel:new(
    padding, padding, buttonHeight,
    getText("UI_MMLPlayer_InputLabel") or "Enter MML Code:",
    1, 1, 1, 1, UIFont.Medium, true
  )
  labelInput:initialise()
  container:addChild(labelInput)

  local textArea1 = ISTextEntryBox:new(
    "",
    padding,
    labelInput:getBottom() + 5,
    WIDTH - padding * 4,
    20
  )
  textArea1:initialise()
  textArea1:instantiate()
  textArea1.font = UIFont.Small
  textArea1:setMultipleLine(true)
  textArea1:setMaxLines(20)
  textArea1:setEditable(true)
  container:addChild(textArea1)

  local labelTrack2 = ISLabel:new(
    padding, textArea1:getBottom() + 4, buttonHeight,
    "Track 2:",
    1, 1, 1, 1, UIFont.Small, true
  )
  labelTrack2:initialise()
  container:addChild(labelTrack2)

  local textArea2 = ISTextEntryBox:new(
    "",
    padding,
    labelTrack2:getBottom() + 2,
    WIDTH - padding * 4,
    20
  )
  textArea2:initialise()
  textArea2:instantiate()
  textArea2.font = UIFont.Small
  textArea2:setMultipleLine(true)
  textArea2:setMaxLines(10)
  textArea2:setEditable(true)
  container:addChild(textArea2)

  local labelTrack3 = ISLabel:new(
    padding, textArea2:getBottom() + 4, buttonHeight,
    "Track 3:",
    1, 1, 1, 1, UIFont.Small, true
  )
  labelTrack3:initialise()
  container:addChild(labelTrack3)

  local textArea3 = ISTextEntryBox:new(
    "",
    padding,
    labelTrack3:getBottom() + 2,
    WIDTH - padding * 4,
    20
  )
  textArea3:initialise()
  textArea3:instantiate()
  textArea3.font = UIFont.Small
  textArea3:setMultipleLine(true)
  textArea3:setMaxLines(10)
  textArea3:setEditable(true)
  container:addChild(textArea3)

  local composeUI = self

  local labelInstrument = ISLabel:new(
    padding, textArea3:getBottom() + 5,
    buttonHeight,
    getText("UI_MMLPlayer_TryInstrument") or "Instrument:",
    1, 1, 1, 1, UIFont.Medium, true
  )
  labelInstrument:initialise()
  container:addChild(labelInstrument)

  local instrumentCombo = ISComboBox:new(
    padding + 140, textArea3:getBottom() + padding,
    140,
    buttonHeight,
    nil, nil
  )
  instrumentCombo:initialise()
  instrumentCombo:instantiate()
  instrumentCombo:addOption("Piano")
  instrumentCombo:addOption("Violin")
  instrumentCombo:addOption("GuitarDistortion")
  instrumentCombo:addOption("GuitarClean")
  instrumentCombo:addOption("GuitarSteel")
  instrumentCombo:addOption("BassFinger")
  instrumentCombo:addOption("Flute")
  instrumentCombo.selected = 1
  container:addChild(instrumentCombo)

  local infoLabel = ISLabel:new(
    padding,
    instrumentCombo:getBottom() + 5,
    buttonHeight,
    "",
    1, 1, 1, 1, UIFont.Small, true
  )
  infoLabel:initialise()
  container:addChild(infoLabel)

  -- 保存這個 tab 的所有控件引用
  self.tabControls[tabName] = {
    textArea1 = textArea1,
    textArea2 = textArea2,
    textArea3 = textArea3,
    infoLabel = infoLabel,
    instrumentCombo = instrumentCombo
  }

  -- 按鈕區

  local buttonY = infoLabel:getBottom() + 40 + padding
  local buttonWidth = 80
  local buttonSpacing = 20

  -- 驗證按鈕
  local validateButton = ISButton:new(
    buttonSpacing, buttonY,
    buttonWidth, buttonHeight,
    getText("UI_MMLPlayer_Validate") or "Validate",
    nil, function(button, ui)
      composeUI:onValidate(tabName)
    end
  )
  validateButton:initialise()
  validateButton:instantiate()
  validateButton.borderColor = { r = 1, g = 1, b = 1, a = 0.3 }
  container:addChild(validateButton)

  -- 清除按鈕
  local clearButton = ISButton:new(
    validateButton:getRight() + buttonSpacing, buttonY,
    buttonWidth, buttonHeight,
    getText("UI_MMLPlayer_Clear") or "Clear",
    nil, function(button, ui)
      composeUI:onClear(tabName)
    end
  )
  clearButton:initialise()
  clearButton:instantiate()
  clearButton.borderColor = { r = 1, g = 1, b = 1, a = 0.3 }
  container:addChild(clearButton)

  TabPanel:addChild(container)
end

function MMLComposeUI:initialise()
  -- 如果已經初始化過，只顯示視窗
  if self.isInitialized then
    self:setVisible(true)
    self:bringToTop()
    return
  end

  -- 標記為已初始化
  self.isInitialized = true
  ISCollapsableWindow.initialise(self)
  ISCollapsableWindow.createChildren(self)

  -- === 創建標籤頁容器 ===
  local th = self:titleBarHeight()
  self.nested = ISTabPanel:new(10, th + 10, self.width - 20, 380)
  self.nested:initialise()
  self.nested:instantiate()
  self.nested:setAnchorLeft(true)
  self.nested:setAnchorRight(true)
  self.nested:setAnchorTop(true)
  self.nested:setAnchorBottom(true)
  self:addChild(self.nested)

  local padding = 10
  local buttonHeight = 25

  -- === 分頁 1：Main ===
  self.MelodyTab = self:addTab(getText("UI_MMLPlayer_melody") or "Melody")
  self:addTabContainer(self.MelodyTab, "melody")

  self.HarmonyTab = self:addTab(getText("UI_MMLPlayer_harmony") or "Harmony")
  self:addTabContainer(self.HarmonyTab, "harmony")

  self.ChordTab = self:addTab(getText("UI_MMLPlayer_chord") or "Chord")
  self:addTabContainer(self.ChordTab, "chord")

  self.graceNoteTab = self:addTab(getText("UI_MMLPlayer_graceNote") or "Grace Note")
  self:addTabContainer(self.graceNoteTab, "graceNote")

  self.rootNoteTab = self:addTab(getText("UI_MMLPlayer_rootNote") or "Root Note")
  self:addTabContainer(self.rootNoteTab, "rootNote")

  -- 按鈕區
  local buttonY = self.nested:getBottom() + padding
  local buttonWidth = 80
  local buttonSpacing = 10

  -- 播放按鈕
  self.playButton = ISButton:new(
    padding, buttonY, buttonWidth, buttonHeight,
    getText("UI_MMLPlayer_Try") or "Try",
    self, MMLComposeUI.onPlay
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
    self, MMLComposeUI.onStop
  )
  self.stopButton:initialise()
  self.stopButton:instantiate()
  self.stopButton.borderColor = { r = 1, g = 1, b = 1, a = 0.3 }
  self.stopButton.enable = false
  self:addChild(self.stopButton)


  -- 進度條背景
  self.progressBar = ISPanel:new(
    padding,
    buttonY + buttonHeight + padding,
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


  self:setResizable(false)
  self:addToUIManager()
end

function MMLComposeUI:onPlay()
  -- 停止並清空先前所有播放器
  if self.mmlPlayers and #self.mmlPlayers > 0 then
    for _, p in ipairs(self.mmlPlayers) do
      if p and p.stop then p:stop() end
    end
  end
  self.mmlPlayers = {}

  local tabNames = { "melody", "harmony", "chord", "graceNote", "rootNote" }
  local anyPlayed = false
  local playedCount = 0

  for _, tabName in ipairs(tabNames) do
    local controls = self.tabControls[tabName]
    if controls then
      local mml1 = clampEntry(controls.textArea1)
      local mml2 = clampEntry(controls.textArea2)
      local mml3 = clampEntry(controls.textArea3)
      -- 若此 tab 全空則跳過
      if not (mml1 == "" and mml2 == "" and mml3 == "") then
        local instr = controls.instrumentCombo and controls.instrumentCombo:getSelectedText() or "Piano"
        local player = MMLPlayer:new(instr, true)
        local combined = string.format("%s,%s,%s", mml1, mml2, mml3)
        local ok = player:loadMML(combined)
        if not ok then
          controls.infoLabel:setName(getText("UI_MMLPlayer_ParseError") or "Parse error")
        else
          if player:play() then
            table.insert(self.mmlPlayers, player)
            anyPlayed = true
            playedCount = playedCount + 1
            controls.infoLabel:setName(getText("UI_MMLPlayer_Playing") or "Playing")
          else
            controls.infoLabel:setName(getText("UI_MMLPlayer_PlayFailed") or "Play failed")
          end
        end
      end
    end
  end

  if anyPlayed then
    self.isPlaying = true
    self.playButton.enable = false
    self.stopButton.enable = true
    self.statusLabel:setName(string.format("%s (%d)", getText("UI_MMLPlayer_Playing") or "Playing", playedCount))
  else
    self.isPlaying = false
    self.playButton.enable = true
    self.stopButton.enable = false
    self.statusLabel:setName(getText("UI_MMLPlayer_EmptyInput") or "Please enter MML code")
  end
end

function MMLComposeUI:onStop()
  if self.mmlPlayers then
    for _, p in ipairs(self.mmlPlayers) do
      if p and p.stop then p:stop() end
    end
  end
  -- 保留舊欄位兼容性
  if self.mmlPlayer and self.mmlPlayer.stop then
    self.mmlPlayer:stop()
  end
  self.mmlPlayers = {}
  self.isPlaying = false
  self.statusLabel:setName(getText("UI_MMLPlayer_Stopped") or "Stopped")
  self.playButton.enable = true
  self.stopButton.enable = false
end

function MMLComposeUI:render()
  ISCollapsableWindow.render(self)

  -- 繪製進度條
  -- 使用第一個播放器的進度（若存在）
  local primary = nil
  if self.mmlPlayers and #self.mmlPlayers > 0 then
    primary = self.mmlPlayers[1]
  elseif self.mmlPlayer then
    primary = self.mmlPlayer
  end
  if primary and self.isPlaying then
    local progress = primary:getProgress()
    local barWidth = (self.progressBar.width - 4) * progress

    self:drawRect(
      self.progressBar.x + 2,
      self.progressBar.y + 2,
      barWidth,
      self.progressBar.height - 4,
      1.0, 0.3, 0.7, 0.3
    )
  end
end

function MMLComposeUI:show()
  if not self.isInitialized then
    self:initialise()
  end
  self:setVisible(true)
  self:bringToTop()
end

function MMLComposeUI:close()
  self:setVisible(false)
end

-- 清除指定 tab 的內容
function MMLComposeUI:onClear(tabName)
  local controls = self.tabControls[tabName]
  if not controls then
    print("ERROR: No controls found for tab:", tabName)
    return
  end

  controls.textArea1:setText("")
  controls.textArea2:setText("")
  controls.textArea3:setText("")
  controls.infoLabel:setName("")
end

-- 驗證指定 tab 的內容
function MMLComposeUI:onValidate(tabName)
  local controls = self.tabControls[tabName]
  if not controls then
    print("ERROR: No controls found for tab:", tabName)
    return
  end

  local mml1 = clampEntry(controls.textArea1)
  local mml2 = clampEntry(controls.textArea2)
  local mml3 = clampEntry(controls.textArea3)

  if mml1 == "" and mml2 == "" and mml3 == "" then
    controls.infoLabel:setName(getText("UI_MMLPlayer_EmptyInput") or "Please enter MML code")
    return
  end

  local tmpPlayer = MMLPlayer:new(self.instrument, true)
  local results = tmpPlayer:parseTracks({ mml1, mml2, mml3 })

  local totalNotes = 0
  local maxDuration = 0
  local anyError = false
  local lines = {}

  for i, res in ipairs(results) do
    if res.ok then
      totalNotes = totalNotes + (res.notes or 0)
      if res.duration and res.duration > maxDuration then maxDuration = res.duration end
      local durStr = formatDurationMs(res.duration or 0)
      table.insert(lines, string.format("Track %d: OK %d , %s", i, res.notes or 0, durStr))
    else
      anyError = true
      table.insert(lines, string.format("Track %d: ERROR %s", i, res.err or "parse error"))
    end
  end

  if anyError then
    local msg = table.concat(lines, " | ")
    controls.infoLabel:setName(msg)
  else
    local msg = string.format("Valid: %d notes, %s | %s",
      totalNotes, formatDurationMs((maxDuration or 0)), table.concat(lines, " | "))
    controls.infoLabel:setName(msg)
  end
end

return MMLComposeUI
