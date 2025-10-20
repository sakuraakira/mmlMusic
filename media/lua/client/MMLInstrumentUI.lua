---@diagnostic disable: inject-field
-- MMLInstrumentUI.lua
-- UI 介面
---@class MMLInstrumentUI: ISCollapsableWindow
---@field show fun(self: MMLInstrumentUI): nil 顯示視窗
---@field hide fun(self: MMLInstrumentUI): nil 隱藏視窗（不移除）
---@field instrument string
---@field isPlaying boolean
---@field character IsoPlayer
---@field playButton ISButton
---@field stopButton ISButton
---@field progressBar ISPanel
---@field statusLabel ISLabel
---@field TAPlay TAPlayMMLFromInventory|TAPlayMMLFromWorld
---@field isInitialized boolean
---@field facing string
---@field upperSidePianoObject IsoObject
---@field hasSeat boolean
local MMLInstrumentUI = ISCollapsableWindow:derive("MMLInstrumentUI")


local TAPlayMMLFromInventory = require('TimedAction/TAPlayMMLFromInventory')
local TAPlayMMLFromWorld = require('TimedAction/TAPlayMMLFromWorld')
local PlayerItemToMMLInstrument = require('MMLInstrument')
local MMLScores = require('MMLScores')
local WIDTH = 650
local HEIGHT = 580

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
      instance.title = getText("UI_MMLPlayer_Play") .. item:getName()
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
    instance.title = getText("UI_MMLPlayer_Play") .. instrument
    instance.facing = facing
    instance.upperSidePianoObject = upperSidePianoObject
    instance.hasSeat = hasSeat
  else
    -- 更新現有實例的資料
    instance.character = character
    if instrument then
      instance.instrument = instrument or "Piano"
      instance.title = getText("UI_MMLPlayer_Play") .. instrument
      instance.facing = facing
      instance.upperSidePianoObject = upperSidePianoObject
      instance.hasSeat = hasSeat
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
    o.title = getText("UI_MMLPlayer_Play") .. item:getName()
  end
  o.TAPlay = nil
  o.isPlaying = false
  o.character = character
  o.isInitialized = false -- 追蹤是否已初始化
  o.mml = nil
  return o
end

-- Checkbox 變更回調函數
function MMLInstrumentUI:onTrackCheckboxChanged(index, selected)
  -- 更新勾選狀態
  if index == 1 then
    self.selectedTracks.melody = selected
    print("Melody: " .. tostring(selected))
  elseif index == 2 then
    self.selectedTracks.harmony = selected
    print("Harmony: " .. tostring(selected))
  elseif index == 3 then
    self.selectedTracks.chord = selected
    print("Chord: " .. tostring(selected))
  elseif index == 4 then
    self.selectedTracks.graceNote = selected
    print("Grace Note: " .. tostring(selected))
  elseif index == 5 then
    self.selectedTracks.rootNote = selected
    print("Root Note: " .. tostring(selected))
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
  local buttonHeight = 25

  -- 輸入區標籤
  self.labelInput = ISLabel:new(
    padding, th + padding, buttonHeight,
    getText("UI_MMLPlayer_UsedSheet") or "Enter MML:",
    1, 1, 1, 1, UIFont.Medium, true
  )
  self.labelInput:initialise()
  self:addChild(self.labelInput)

  self.labelInput2 = ISLabel:new(
    padding,
    self.labelInput:getBottom() + 5,
    buttonHeight,
    getText("UI_MMLPlayer_NoSheet") or "No Sheet (You can equip a sheet to primary hand)",
    1, 1, 1, 1, UIFont.Small, true
  )
  self.labelInput2:initialise()
  self:addChild(self.labelInput2)

  -- 選擇演奏樂譜標籤
  self.labelSelectTracks = ISLabel:new(
    padding,
    self.labelInput2:getBottom() + padding + 5,
    buttonHeight,
    getText("UI_MMLPlayer_SelectTracks") or "Select Tracks to Play:",
    1, 1, 1, 1, UIFont.Medium, true
  )
  self.labelSelectTracks:initialise()
  self:addChild(self.labelSelectTracks)

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

  -- 添加 5 個選項
  self.trackCheckbox:addOption(getText("UI_MMLPlayer_melody") or "Melody", nil)
  self.trackCheckbox:addOption(getText("UI_MMLPlayer_harmony") or "Harmony", nil)
  self.trackCheckbox:addOption(getText("UI_MMLPlayer_chord") or "Chord", nil)
  self.trackCheckbox:addOption(getText("UI_MMLPlayer_graceNote") or "Grace Note", nil)
  self.trackCheckbox:addOption(getText("UI_MMLPlayer_rootNote") or "Root Note", nil)

  -- 設定初始狀態（預設全部勾選）
  self.trackCheckbox:setSelected(1, true)  -- Melody
  self.trackCheckbox:setSelected(2, false) -- Harmony
  self.trackCheckbox:setSelected(3, false) -- Chord
  self.trackCheckbox:setSelected(4, false) -- Grace Note
  self.trackCheckbox:setSelected(5, false) -- Root Note
  self:addChild(self.trackCheckbox)

  -- 儲存勾選狀態（方便後續使用）
  self.selectedTracks = {
    melody = true,
    harmony = false,
    chord = false,
    graceNote = false,
    rootNote = false
  }

  -- 按鈕區
  local buttonY = self.trackCheckbox:getBottom() + padding
  local buttonWidth = 80
  local buttonSpacing = 10

  -- 播放按鈕
  self.playButton = ISButton:new(
    padding, buttonY, buttonWidth, buttonHeight,
    getText("UI_MMLPlayer_Play") or "Play",
    self, MMLInstrumentUI.onPlay
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


  self.mml =
      self:setResizable(false)

  -- 只有第一次初始化才加入 UIManager
  self:addToUIManager()
end

function MMLInstrumentUI:setMML(mml, name)
  self.mml = mml
  if not self.trackCheckbox then
    return
  end
  self.labelInput2:setName(name)
  local trackNames = { "melody", "harmony", "chord", "graceNote", "rootNote" }
  local trackDisplayNames = {
    getText("UI_MMLPlayer_melody") or "Melody",
    getText("UI_MMLPlayer_harmony") or "Harmony",
    getText("UI_MMLPlayer_chord") or "Chord",
    getText("UI_MMLPlayer_graceNote") or "Grace Note",
    getText("UI_MMLPlayer_rootNote") or "Root Note"
  }
  local anyTrackAvailable = false

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
      self.trackCheckbox:disableOption(optionName, false)
    else
      self.trackCheckbox:disableOption(optionName, true)
    end
    self.trackCheckbox:setSelected(i, false)
    self.selectedTracks[trackName] = false
  end

  -- 如果沒有任何軌道可用,顯示警告
  if not anyTrackAvailable then
    self.statusLabel:setName(getText("UI_MMLPlayer_NoTracksAvailable") or "No tracks available in this sheet")
    self.playButton.enable = false
  else
    self.statusLabel:setName(getText("UI_MMLPlayer_Ready") or "Ready")
    self.playButton.enable = true
  end
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
    if string.sub(fullType, 1, 9) == "MMLSheet." then
      local sheet = MMLScores and MMLScores[fullType]
      if not sheet or type(sheet.mml) ~= "table" then
        print("No matching sheet for", tostring(fullType))
        return
      end
      self:setMML(sheet.mml, item:getName())
    end
  end
end

function MMLInstrumentUI:hide()
  -- 隱藏視窗（不移除）
  self:setVisible(false)
end

function MMLInstrumentUI:onPlay()
  local trackNames = { "melody", "harmony", "chord", "graceNote", "rootNote" }
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
    self.statusLabel:setName(getText("UI_MMLPlayer_NoTrackSelected") or "Please select at least one track")
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
    self.statusLabel:setName(getText("UI_MMLPlayer_EmptyInput") or "Please enter MML code")
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
      self.upperSidePianoObject, self.facing, self.hasSeat, combined
    )
  else
    self.TAPlay = TAPlayMMLFromInventory:new(self.character, self.instrument, combined)
  end

  self.TAPlay.onComplete = function()
    self:onPlaybackComplete()
  end

  ISTimedActionQueue.add(self.TAPlay)

  self.isPlaying = true
  self.statusLabel:setName(getText("UI_MMLPlayer_Playing") or "Playing...")
  self.playButton.enable = false
  self.stopButton.enable = true
end

-- 新增：播放完成時的回調
function MMLInstrumentUI:onPlaybackComplete()
  self.isPlaying = false
  self.statusLabel:setName(getText("UI_MMLPlayer_Finished") or "Finished")
  self.playButton.enable = true
  self.stopButton.enable = false
end

function MMLInstrumentUI:onStop()
  ISTimedActionQueue.clear(self.character)

  self.isPlaying = false
  self.statusLabel:setName(getText("UI_MMLPlayer_Stopped") or "Stopped")
  self.playButton.enable = true
  self.stopButton.enable = false
end

function MMLInstrumentUI:render()
  ISCollapsableWindow.render(self)
  -- 繪製進度條
  if self.isPlaying and self.TAPlay then
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

return MMLInstrumentUI
