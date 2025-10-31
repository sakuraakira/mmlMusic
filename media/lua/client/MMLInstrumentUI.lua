---@diagnostic disable: inject-field
-- MMLInstrumentUI.lua
-- UI 介面
---@class MMLInstrumentUI: ISCollapsableWindow
---@field show fun(self: MMLInstrumentUI): nil 顯示視窗
---@field hide fun(self: MMLInstrumentUI): nil 隱藏視窗（不移除）
---@field TAPlay TAPlayMMLFromInventory|TAPlayMMLFromWorld
---@field facing string
---@field upperSidePianoObject IsoObject
---@field hasSeat boolean
local MMLInstrumentUI = ISCollapsableWindow:derive("MMLInstrumentUI")

local MMLPlayer = require('MMLPlayer')
local TAPlayMMLFromInventory = require('TimedAction/TAPlayMMLFromInventory')
local TAPlayMMLFromWorld = require('TimedAction/TAPlayMMLFromWorld')
local PlayerItemToMMLInstrument = require('MMLInstrument')
local MMLScores = require('MMLScores')
local SheetIconSlot = require('IconSlot')
local WIDTH = 600
local HEIGHT = 470 -- 增加高度以容納 Tab

-- 儲存單例實例
local instance = nil

-- 新增：取得現有實例（不創建新的）
function MMLInstrumentUI.getExistingInstance()
  return instance
end

---@param character IsoPlayer 玩家角色
---@param item InventoryItem 樂器物品
---@return ISCollapsableWindow
function MMLInstrumentUI.getInstance(character, item)
  if not instance then
    instance = MMLInstrumentUI:new(character, item)
    instance.facing = nil
    instance.upperSidePianoObject = nil
    instance.hasSeat = nil
  else
    -- 更新現有實例的資料
    instance.character = character
    if item then
      instance.instrument = PlayerItemToMMLInstrument[item:getFullType()] or "Piano"
      instance.title = getText("UI_MML_Play") .. item:getName()
      instance.item = item
      instance.facing = nil
      instance.upperSidePianoObject = nil
      instance.hasSeat = nil
    end
  end
  return instance
end

function MMLInstrumentUI.getInstanceFromWorld(character, instrument, upperSidePianoObject, facing, hasSeat)
  if not instance then
    instance = MMLInstrumentUI:new(character, nil)
    instance.instrument = instrument or "Piano"
    instance.title = getText("UI_MML_Play") .. instrument
    instance.facing = facing
    instance.upperSidePianoObject = upperSidePianoObject
    instance.hasSeat = hasSeat
    instance.item = nil
  else
    -- 更新現有實例的資料
    instance.character = character
    if instrument then
      instance.instrument = instrument or "Piano"
      instance.title = getText("UI_MML_Play") .. instrument
      instance.facing = facing
      instance.upperSidePianoObject = upperSidePianoObject
      instance.hasSeat = hasSeat
      instance.item = nil
    end
  end
  return instance
end

---@param character IsoPlayer 玩家角色
---@param item InventoryItem 樂器物品
---@return ISCollapsableWindow
function MMLInstrumentUI:new(character, item)
  local x = getCore():getScreenWidth() / 2 - WIDTH / 2
  local y = getCore():getScreenHeight() / 2 - HEIGHT / 2
  ---@class MMLInstrumentUI
  local o = ISCollapsableWindow:new(x, y, WIDTH, HEIGHT)
  setmetatable(o, self)
  self.__index = self

  if item ~= nil then
    o.instrument = PlayerItemToMMLInstrument[item:getFullType()] or "Piano"
    o.title = getText("UI_MML_Play") .. item:getName()
    o.item = item
  end
  o.TAPlay = nil
  o.isPlaying = false
  o.isEnsemble = false
  o.character = character
  o.isInitialized = false -- 追蹤是否已初始化
  o.mml = nil
  -- 用於追蹤合奏頁面動態新增的 UI 控件（Label/ComboBox）
  o.ensembleControls = {}
  return o
end

-- Checkbox 變更回調函數
function MMLInstrumentUI:onTrackCheckboxChanged(index, selected)
  -- 更新勾選狀態
  if index == 1 then
    self.selectedTracks.melody = selected
  elseif index == 2 then
    self.selectedTracks.harmony = selected
  elseif index == 3 then
    self.selectedTracks.accompaniment = selected
  elseif index == 4 then
    self.selectedTracks.orchestra = selected
  elseif index == 5 then
    self.selectedTracks.bassline = selected
  end
end

function MMLInstrumentUI:initialise()
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

  local th = self:titleBarHeight()
  local padding = 10

  -- 創建 Tab 面板
  self.tabPanel = ISTabPanel:new(padding, th + padding, self.width - padding * 2, 320)
  self.tabPanel:initialise()
  self.tabPanel:instantiate()
  self.tabPanel.target = self
  self.tabPanel.onActivateView = MMLInstrumentUI.onActivateView
  self.tabPanel:setAnchorLeft(true)
  self.tabPanel:setAnchorRight(true)
  self.tabPanel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
  self:addChild(self.tabPanel)

  -- 創建第一個 Tab：樂器演奏
  self.playTab = ISPanel:new(0, 0, self.tabPanel.width, self.tabPanel.height - 30)
  self.playTab:initialise()
  self.playTab:instantiate()
  self.playTab:noBackground()
  self.tabPanel:addView(getText("UI_MML_Play") or "Play", self.playTab)
  self:initPlayTab()

  -- 創建第二個 Tab：合奏
  if isClient() then
    self.ensembleTab = ISPanel:new(0, 0, self.tabPanel.width, self.tabPanel.height - 30)
    self.ensembleTab:initialise()
    self.ensembleTab:instantiate()
    self.ensembleTab:noBackground()
    self.tabPanel:addView(getText("UI_MML_Ensemble") or "Ensemble", self.ensembleTab)
    self:initEnsembleTab()
  end

  -- 按鈕區
  local buttonY = self.tabPanel:getBottom() + padding * 2
  local buttonWidth = 80
  local buttonHeight = 25
  -- 播放按鈕
  self.playButton = ISButton:new(
    padding, buttonY, buttonWidth, buttonHeight,
    getText("UI_MML_Play") or "Play",
    self, MMLInstrumentUI.onPlay
  )
  self.playButton:initialise()
  self.playButton:instantiate()
  self.playButton.borderColor = { r = 1, g = 1, b = 1, a = 0.3 }
  self:addChild(self.playButton)

  -- 停止按鈕
  self.stopButton = ISButton:new(
    self.playButton:getRight() + padding * 2, buttonY,
    buttonWidth, buttonHeight,
    getText("UI_MML_Stop") or "Stop",
    self, MMLInstrumentUI.onStop
  )
  self.stopButton:initialise()
  self.stopButton:instantiate()
  self.stopButton.borderColor = { r = 1, g = 1, b = 1, a = 0.3 }
  self.stopButton.enable = false
  self:addChild(self.stopButton)

  -- 進度條背景
  self.progressBar = ISPanel:new(
    padding,
    self.playButton:getBottom() + padding,
    self.playTab.width - padding * 2,
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
    getText("UI_MML_NoSheet") or "No Sheet (You can equip a sheet to primary hand)",
    1, 1, 1, 1, UIFont.Small, true
  )
  self.statusLabel:initialise()
  self:addChild(self.statusLabel)

  self:setResizable(false)
  self:addToUIManager()
end

function MMLInstrumentUI:initPlayTab()
  local padding = 10
  local buttonHeight = 25

  -- 輸入區標籤
  self.labelInput = ISLabel:new(
    padding, padding, buttonHeight,
    getText("UI_MML_UsedSheet") or "Used Sheet:",
    1, 1, 1, 1, UIFont.Medium, true
  )
  self.labelInput:initialise()
  self.playTab:addChild(self.labelInput)

  self.iconSlot = SheetIconSlot:new(padding, self.labelInput:getBottom() + 5, 48, self)
  self.playTab:addChild(self.iconSlot)

  self.labelInput2 = ISLabel:new(
    padding * 3 + 48,
    self.labelInput:getBottom() + 29,
    buttonHeight,
    "",
    1, 1, 1, 1, UIFont.Small, true
  )
  self.labelInput2:initialise()
  self.playTab:addChild(self.labelInput2)

  -- 選擇演奏樂譜標籤
  self.labelSelectTracks = ISLabel:new(
    padding,
    self.iconSlot:getBottom() + padding + 5,
    buttonHeight,
    getText("UI_MML_SelectTracks") or "Select Tracks to Play:",
    1, 1, 1, 1, UIFont.Medium, true
  )
  self.labelSelectTracks:initialise()
  self.playTab:addChild(self.labelSelectTracks)

  -- 創建 TickBox (可複選的 checkbox 群組)
  self.trackCheckbox = ISTickBox:new(
    padding + 10, -- 稍微縮排
    self.labelSelectTracks:getBottom() + 5,
    200,
    20 * 5, -- 5個選項的高度
    "",
    self,
    self.onTrackCheckboxChanged
  )
  self.trackCheckbox:initialise()
  self.trackCheckbox:instantiate()
  self.playTab:addChild(self.trackCheckbox)

  -- 儲存勾選狀態（方便後續使用）
  self.selectedTracks = {
    melody = true,
    harmony = false,
    accompaniment = false,
    orchestra = false,
    bassline = false
  }
end

function MMLInstrumentUI:initEnsembleTab()
  local padding = 10
  local buttonHeight = 25

  -- 輸入區標籤
  self.ensembleLabelInput = ISLabel:new(
    padding, padding, buttonHeight,
    getText("UI_MML_UsedSheet") or "Enter MML:",
    1, 1, 1, 1, UIFont.Medium, true
  )
  self.ensembleLabelInput:initialise()
  self.ensembleTab:addChild(self.ensembleLabelInput)

  self.ensembleIconSlot = SheetIconSlot:new(padding, self.ensembleLabelInput:getBottom() + 5, 48, self)
  self.ensembleTab:addChild(self.ensembleIconSlot)

  self.ensembleLabelInput2 = ISLabel:new(
    padding * 3 + 48,
    self.ensembleLabelInput:getBottom() + 29,
    buttonHeight,
    "",
    1, 1, 1, 1, UIFont.Small, true
  )
  self.ensembleLabelInput2:initialise()
  self.ensembleTab:addChild(self.ensembleLabelInput2)

  -- 合奏分配標籤
  self.ensembleLabelAssignment = ISLabel:new(
    padding,
    self.ensembleLabelInput2:getBottom() + padding + 5,
    buttonHeight,
    getText("UI_MML_EnsembleAssignment") or "Track Assignment:",
    1, 1, 1, 1, UIFont.Medium, true
  )
  self.ensembleLabelAssignment:initialise()
  self.ensembleTab:addChild(self.ensembleLabelAssignment)
end

function MMLInstrumentUI.onActivateView(target, tabPanel)
  local view = tabPanel:getActiveView()
  local name = tabPanel.activeView and tabPanel.activeView.name
  if view == target.playTab then
    if target.playButton.setTitle then
      target.playButton:setTitle(getText("UI_MML_Play") or "Play")
    else
      target.playButton.title = getText("UI_MML_Play") or "Play"
    end
    target.playButton.onclick = MMLInstrumentUI.onPlay
  elseif view == target.ensembleTab then
    if target.playButton.setTitle then
      target.playButton:setTitle(getText("UI_MML_Ensemble") or "Ensemble")
    else
      target.playButton.title = getText("UI_MML_Ensemble") or "Ensemble"
    end
    target.playButton.onclick = MMLInstrumentUI.onEnsemble
  end
end

-- 更新合奏玩家列表
function MMLInstrumentUI:updateEnsemblePlayers()
  if not self.ensembleComboBoxes then
    return
  end

  -- 獲取準備合奏的玩家列表
  local MMLEnsembleManager = require("MMLEnsembleManager")
  local ensemblePlayers = MMLEnsembleManager.getEnsemblePlayers()

  -- 添加自己（如果不在列表中）
  local myId = self.character:getOnlineID()
  local myName = self.character:getDisplayName()
  local foundSelf = false

  for _, player in ipairs(ensemblePlayers) do
    if player.id == myId then
      foundSelf = true
      break
    end
  end

  if not foundSelf then
    table.insert(ensemblePlayers, {
      id = myId,
      name = myName,
      instrument = self.instrument or "Piano"
    })
  end

  -- 更新所有 ComboBox
  for trackName, comboBox in pairs(self.ensembleComboBoxes) do
    comboBox:clear()
    comboBox:addOption(getText("UI_MML_None") or "None")

    for _, player in ipairs(ensemblePlayers) do
      comboBox:addOption(player.name .. " (" .. player.instrument .. ")")
    end
  end
end

-- ComboBox 變更回調
function MMLInstrumentUI:onEnsembleAssignmentChanged(comboBox)
  local selectedIndex = comboBox.selected
  local trackName = comboBox.trackName

  if selectedIndex == 1 then
    -- "None" 選項
    self.ensembleAssignments[trackName] = nil
  else
    -- 玩家選項
    self.ensembleAssignments[trackName] = comboBox:getOptionText(selectedIndex)
  end
end

function MMLInstrumentUI:setMML(mml, item)
  self.mml = mml

  -- 更新演奏頁面
  if self.labelInput2 then
    self.labelInput2:setName(item:getName())
    self.iconSlot:setItem(item)
  end
  if self.ensembleLabelInput2 then
    self.ensembleLabelInput2:setName(item:getName())
    self.ensembleIconSlot:setItem(item)
  end

  local trackNames = { "melody", "harmony", "accompaniment", "orchestra", "bassline" }
  local trackDisplayNames = {
    getText("UI_MML_melody") or "Melody",
    getText("UI_MML_harmony") or "Harmony",
    getText("UI_MML_accompaniment") or "Accompaniment",
    getText("UI_MML_orchestra") or "Orchestra",
    getText("UI_MML_bassline") or "Bassline"
  }
  if self.trackCheckbox then
    local anyTrackAvailable = false
    self.trackCheckbox:clearOptions()
    for i, trackName in ipairs(trackNames) do
      local hasContent = false

      if self.mml[trackName] then
        local track = self.mml[trackName]
        if (track.mml1 and track.mml1 ~= "") or
            (track.mml2 and track.mml2 ~= "") or
            (track.mml3 and track.mml3 ~= "") then
          hasContent = true
          anyTrackAvailable = true
        end
      end
      local optionName = trackDisplayNames[i]
      if hasContent then
        self.trackCheckbox:addOption(optionName)
      end
      self.selectedTracks[trackName] = false
    end

    -- 如果沒有任何軌道可用,顯示警告
    if not anyTrackAvailable then
      self.statusLabel:setName(getText("UI_MML_NoTracksAvailable") or "No tracks available in this sheet")
    else
      self.statusLabel:setName(getText("UI_MML_Ready") or "Ready")
    end
  end
  if self.ensembleTab then
    -- 先清除舊的動態控件，避免重複堆疊
    self:clearEnsembleAssignmentsUI()

    -- 創建 5 個 ComboBox
    local padding = 10
    local buttonHeight = 25
    self.ensembleComboBoxes = {}
    self.ensembleAssignments = {}
    local yPos = self.ensembleLabelAssignment:getBottom() + 10

    for i, trackName in ipairs(trackNames) do
      local hasContent = false
      if self.mml[trackName] then
        local track = self.mml[trackName]
        if (track.mml1 and track.mml1 ~= "") or
            (track.mml2 and track.mml2 ~= "") or
            (track.mml3 and track.mml3 ~= "") then
          hasContent = true
        end
      end

      if hasContent then
        -- Label
        local label = ISLabel:new(
          padding + 10, yPos, buttonHeight,
          (trackDisplayNames[i] .. ":"), 1, 1, 1, 1, UIFont.Small, true
        )
        label:initialise()
        self.ensembleTab:addChild(label)
        table.insert(self.ensembleControls, label)

        -- ComboBox
        local comboBox = ISComboBox:new(
          padding + 120, yPos - 2, 200, buttonHeight,
          self, self.onEnsembleAssignmentChanged
        )
        comboBox:initialise()
        comboBox:instantiate()
        comboBox.trackName = trackName
        self.ensembleTab:addChild(comboBox)
        table.insert(self.ensembleControls, comboBox)

        self.ensembleComboBoxes[trackName] = comboBox
        self.ensembleAssignments[trackName] = nil

        yPos = yPos + 30
      end
    end

    -- 更新合奏玩家列表
    self:updateEnsemblePlayers()
  end
end

function MMLInstrumentUI:clearMML()
  self.mml = nil
  self.statusLabel:setName(getText("UI_MML_NoSheet") or "No Sheet (You can equip a sheet to primary hand)")
  -- 清除演奏頁面
  if self.labelInput2 then
    self.labelInput2:setName("")
    self.iconSlot:setItem(nil)
  end
  if self.ensembleLabelInput2 then
    self.ensembleLabelInput2:setName("")
    self.ensembleIconSlot:setItem(nil)
  end
  if self.trackCheckbox then
    self.trackCheckbox:clearOptions()
    self.selectedTracks.accompaniment = false
    self.selectedTracks.bassline = false
    self.selectedTracks.harmony = false
    self.selectedTracks.melody = false
    self.selectedTracks.orchestra = false
  end
  -- 移除合奏頁面的所有動態控件
  self:clearEnsembleAssignmentsUI()
end

function MMLInstrumentUI:show()
  -- 顯示視窗
  if not self.isInitialized then
    self:initialise()
  end
  self:setVisible(true)
  self:bringToTop()
  if self.character and self.character:getPrimaryHandItem() then
    local item = self.character:getPrimaryHandItem()
    local fullType = item:getFullType()
    if fullType == "MMLSheet.SheetMusic" then
      local mmlData = item:getModData().mml
      if not mmlData or type(mmlData) ~= "table" then
        self:clearMML()
        return
      end
      self:setMML(mmlData, item)
    elseif string.sub(fullType, 1, 9) == "MMLSheet." then
      local sheet = MMLScores and MMLScores.get(fullType)
      if not sheet or type(sheet.mml) ~= "table" then
        self:clearMML()
        return
      end
      self:setMML(sheet.mml, item)
    else
      self:clearMML()
    end
  end
end

function MMLInstrumentUI:hide()
  -- 隱藏視窗（不移除）
  self:setVisible(false)
end

function MMLInstrumentUI:onPlay()
  if not self.mml then
    self.statusLabel:setName(getText("UI_MML_NoSheet") or "No Sheet")
    return
  end

  -- 檢查是否有其他玩家正在演奏
  if MMLPlayer and MMLPlayer.activePlayers and #MMLPlayer.activePlayers > 0 then
    self.character:Say(getText("UI_MML_WaitForOthers") or
      "Someone is already playing, please wait for them to finish.")
    return
  end

  if self.item ~= nil and self.character:getSecondaryHandItem() ~= self.item then
    ISTimedActionQueue.add(ISEquipWeaponAction:new(self.character, self.item, 50, false))
  end

  local trackNames = { "melody", "harmony", "accompaniment", "orchestra", "bassline" }
  local allTracks = {}
  -- 遍歷所有勾選的軌道
  for i, trackName in ipairs(trackNames) do
    if self.selectedTracks[trackName] and self.mml[trackName] then
      table.insert(allTracks, {
        mml1 = self.mml[trackName].mml1 or "",
        mml2 = self.mml[trackName].mml2 or "",
        mml3 = self.mml[trackName].mml3 or ""
      })
    end
  end

  -- 檢查是否有任何內容
  if #allTracks == 0 then
    self.statusLabel:setName(getText("UI_MML_NoTrackSelected") or "Please select at least one track")
    return
  end

  -- 合併所有軌道的 mml1, mml2, mml3
  local combined_mml1 = {}
  local combined_mml2 = {}
  local combined_mml3 = {}

  for _, track in ipairs(allTracks) do
    if track.mml1 ~= "" then
      table.insert(combined_mml1, track.mml1)
    end
    if track.mml2 ~= "" then
      table.insert(combined_mml2, track.mml2)
    end
    if track.mml3 ~= "" then
      table.insert(combined_mml3, track.mml3)
    end
  end

  local mml1 = table.concat(combined_mml1, ",")
  local mml2 = table.concat(combined_mml2, ",")
  local mml3 = table.concat(combined_mml3, ",")

  if mml1 == "" and mml2 == "" and mml3 == "" then
    self.statusLabel:setName(getText("UI_MML_NoTracksAvailable") or "No tracks available")
    return
  end

  local combined = string.format("%s,%s,%s", mml1, mml2, mml3)

  -- Use world TA if there is a world instrument object (covers Piano/GrandPiano)
  if self.upperSidePianoObject then
    local squareFacingPiano = self.facing == "south" and self.upperSidePianoObject:getSquare():getS()
        or self.upperSidePianoObject:getSquare():getE()
    ISTimedActionQueue.add(ISWalkToTimedAction:new(self.character, squareFacingPiano))

    self.TAPlay = TAPlayMMLFromWorld:new(
      self.character, self.instrument,
      self.upperSidePianoObject, self.facing, self.hasSeat, combined, true
    )
  else
    self.TAPlay = TAPlayMMLFromInventory:new(self.character, self.instrument, combined, true)
  end

  self.TAPlay.onComplete = function()
    self:onPlaybackComplete()
  end

  ISTimedActionQueue.add(self.TAPlay)

  self.isPlaying = true
  self.isEnsemble = false
  self.statusLabel:setName(getText("UI_MML_Playing") or "Playing...")
  self.playButton.enable = false
  self.stopButton.enable = true
end

-- 新增：播放完成時的回調
function MMLInstrumentUI:onPlaybackComplete()
  self.isPlaying = false
  self.statusLabel:setName(getText("UI_MML_Finished") or "Finished")
  self.playButton.enable = true
  self.stopButton.enable = false
end

function MMLInstrumentUI:onStop()
  ISTimedActionQueue.clear(self.character)

  self.isPlaying = false
  self.statusLabel:setName(getText("UI_MML_Stopped") or "Stopped")
  self.playButton.enable = true
  self.stopButton.enable = false

  if isClient() and self.isEnsemble then
    -- 發送停止合奏指令
    local MMLClientSendCommands = require('MMLClientSendCommands')
    MMLClientSendCommands.sendEnsembleStop({
      x = self.character:getX(),
      y = self.character:getY(),
      z = self.character:getZ()
    })
  end
end

function MMLInstrumentUI:render()
  ISCollapsableWindow.render(self)

  -- 繪製演奏頁面進度條
  if self.isPlaying and self.TAPlay and self.progressBar then
    if self.TAPlay:isPlaying() then
      local progress = self.TAPlay:getProgress()
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
end

function MMLInstrumentUI:close()
  -- 只是隱藏視窗，不移除
  self:hide()
end

-- 清理函數（在模組卸載或遊戲退出時呼叫）
function MMLInstrumentUI.cleanup()
  if instance then
    instance:removeFromUIManager()
    instance = nil
  end
end

-- 新增：合奏功能
function MMLInstrumentUI:onEnsemble()
  if not self.mml then
    self.statusLabel:setName(getText("UI_MML_NoSheet") or "No Sheet")
    return
  end

  -- 檢查是否有其他玩家正在演奏
  if MMLPlayer and MMLPlayer.activePlayers and #MMLPlayer.activePlayers > 0 then
    self.character:Say(getText("UI_MML_WaitForOthers") or
      "Someone is already playing, please wait for them to finish.")
    return
  end

  -- 準備合奏指令資料
  local ensembleData = {
    assignments = {}
  }

  local trackNames = { "melody", "harmony", "accompaniment", "orchestra", "bassline" }
  local MMLEnsembleManager = require("MMLEnsembleManager")
  local ensemblePlayers = MMLEnsembleManager.getEnsemblePlayers()

  -- 添加自己到玩家列表
  local myId = self.character:getOnlineID()
  local myName = self.character:getDisplayName()
  local myInstrument = self.instrument or "Piano"

  local playerMap = {}
  playerMap[myName .. " (" .. myInstrument .. ")"] = {
    id = myId,
    instrument = myInstrument
  }

  for _, player in ipairs(ensemblePlayers) do
    playerMap[player.name .. " (" .. player.instrument .. ")"] = {
      id = player.id,
      instrument = player.instrument
    }
  end

  -- 遍歷所有軌道分配
  for _, trackName in ipairs(trackNames) do
    local comboBox = self.ensembleComboBoxes[trackName]
    if comboBox and comboBox.selected > 1 then -- 不是 "None"
      local selectedText = comboBox:getOptionText(comboBox.selected)
      local playerInfo = playerMap[selectedText]

      if playerInfo and self.mml[trackName] then
        local track = self.mml[trackName]
        local mmlParts = {}

        if track.mml1 and track.mml1 ~= "" then
          table.insert(mmlParts, track.mml1)
        end
        if track.mml2 and track.mml2 ~= "" then
          table.insert(mmlParts, track.mml2)
        end
        if track.mml3 and track.mml3 ~= "" then
          table.insert(mmlParts, track.mml3)
        end

        if #mmlParts > 0 then
          local mmlString = table.concat(mmlParts, ",")

          if not ensembleData.assignments[playerInfo.id] then
            ensembleData.assignments[playerInfo.id] = {
              instrument = playerInfo.instrument,
              mmlParts = {}
            }
          end

          table.insert(ensembleData.assignments[playerInfo.id].mmlParts, mmlString)
        end
      end
    end
  end

  -- 檢查是否有分配
  local hasAssignments = false
  for _ in pairs(ensembleData.assignments) do
    hasAssignments = true
    break
  end

  if not hasAssignments then
    self.statusLabel:setName(getText("UI_MML_NoAssignments") or "Please assign tracks to players")
    return
  end

  -- 發送合奏開始指令
  if isClient() then
    local MMLClientSendCommands = require('MMLClientSendCommands')
    MMLClientSendCommands.sendEnsembleStart(
      ensembleData.assignments,
      {
        x = self.character:getX(),
        y = self.character:getY(),
        z = self.character:getZ()
      }
    )
  end

  print("[MMLInstrumentUI] Ensemble started")
end

-- 新增：執行合奏播放
function MMLInstrumentUI:onEnsemblePlay(mml, isMain)
  if not mml or mml == "" then
    return
  end

  -- 直接移動物品到副手，不使用 TimedAction 以避免聲音誤差
  if self.item ~= nil and self.character:getSecondaryHandItem() ~= self.item then
    self.character:setSecondaryHandItem(self.item)
  end

  -- Use world TA if there is a world instrument object (covers Piano/GrandPiano)
  local myInstrument = self.instrument or "Piano"

  if self.upperSidePianoObject then
    self.TAPlay = TAPlayMMLFromWorld:new(
      self.character, myInstrument,
      self.upperSidePianoObject, self.facing, self.hasSeat, mml, false
    )
  else
    self.TAPlay = TAPlayMMLFromInventory:new(self.character, myInstrument, mml, false)
  end

  self.TAPlay.onComplete = function()
    self:onPlaybackComplete()
  end
  self.isPlaying = true
  self.isEnsemble = true
  self.statusLabel:setName(getText("UI_MML_Playing") or "Playing...")
  self.playButton.enable = false
  if isMain then
    self.stopButton.enable = true
  else
    self.stopButton.enable = false
  end
  ISTimedActionQueue.add(self.TAPlay)
end

-- 移除合奏頁面動態建立的控件並重置狀態
function MMLInstrumentUI:clearEnsembleAssignmentsUI()
  -- 移除所有先前動態新增的 Label/ComboBox
  if self.ensembleControls then
    for _, ctrl in ipairs(self.ensembleControls) do
      if ctrl and ctrl.parent then
        ctrl.parent:removeChild(ctrl)
      end
    end
  end
  -- 重置追蹤與資料
  self.ensembleControls = {}
  self.ensembleComboBoxes = nil
  self.ensembleAssignments = {}
end

-- 拖放物品處理
function MMLInstrumentUI:onMouseUp(x, y)
  local handled = false
  if ISMouseDrag and ISMouseDrag.dragging and #ISMouseDrag.dragging > 0 then
    -- 一般情況 dragging 會是「實際物品陣列」或「堆疊的包裝」，這裡逐一攤平
    local droppedItems = {}
    for _, v in ipairs(ISMouseDrag.dragging) do
      if type(v) == "table" and v.items then
        -- 來自堆疊（inventory pane 堆疊）時 v.items[1] 是可見項，其餘是實際物品
        for i = 1, #v.items do table.insert(droppedItems, v.items[i]) end
      else
        table.insert(droppedItems, v)
      end
    end

    -- 篩選或直接處理
    for _, item in ipairs(droppedItems) do
      local fullType = item:getFullType() -- 例如 "Base.RippedSheetsDirty"
      if fullType == "MMLSheet.SheetMusic" then
        local md = item:getModData() or {}
        local mmlData = md.mml
        if not mmlData or type(mmlData) ~= "table" then
          self:clearMML()
          print("No MML data found in item", tostring(fullType))
        end
        self:setMML(mmlData, item)
        break
      end

      if fullType:sub(1, 9) == "MMLSheet." then
        local sheet = nil
        -- 優先：MMLScores API
        if MMLScores and type(MMLScores.get) == "function" then
          sheet = MMLScores.get(fullType)
        end
        if sheet then
          local mmlData = sheet.mml
          if mmlData and type(mmlData) == "table" then
            self:setMML(mmlData, item)
            break
          end
        end
      end
    end
    handled = true
  end

  -- 清掉拖拽（避免殘留），並讓父類處理其餘邏輯
  if handled then
    ISMouseDrag.dragging = nil
    return true
  end
  return ISCollapsableWindow.onMouseUp(self, x, y)
end

return MMLInstrumentUI
