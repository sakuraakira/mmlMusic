-- MMLInstrumentUI.lua
-- UI 介面
---@class MMLInstrumentUI: ISCollapsableWindow
---@field show fun(self: MMLInstrumentUI): nil 顯示視窗
---@field hide fun(self: MMLInstrumentUI): nil 隱藏視窗（不移除）
---@field instrument string
---@field isPlaying boolean
---@field character IsoPlayer
---@field textArea1 ISTextEntryBox
---@field textArea2 ISTextEntryBox
---@field textArea3 ISTextEntryBox
---@field playButton ISButton
---@field stopButton ISButton
---@field progressBar ISPanel
---@field statusLabel ISLabel
---@field infoLabel ISLabel
local MMLInstrumentUI = ISCollapsableWindow:derive("MMLInstrumentUI")


local TAPlayMMLFromInventory = require('TimedAction/TAPlayMMLFromInventory')
local PlayerItemToMMLInstrument = require('MMLInstrument')
local WIDTH = 650
local HEIGHT = 580

-- 儲存單例實例
local instance = nil


---@param character IsoPlayer 玩家角色
---@param item InventoryItem 樂器物品
---@return ISCollapsableWindow
function MMLInstrumentUI.getInstance(character, item)
  if not instance then
    instance = MMLInstrumentUI:new(character, item)
  else
    -- 更新現有實例的資料
    instance.character = character
    if item then
      instance.instrument = PlayerItemToMMLInstrument[item:getFullType()] or "Piano"
      instance.title = getText("UI_MMLPlayer_Play") .. item:getName()
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

  o.instrument = PlayerItemToMMLInstrument[item:getFullType()] or "Piano"
  o.title = getText("UI_MMLPlayer_Play") .. item:getName()
  o.TAPlay = nil
  o.isPlaying = false
  o.character = character
  o.isInitialized = false -- 追蹤是否已初始化
  return o
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

  -- 按鈕區
  local buttonY = self.textArea3:getBottom() + padding
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
  self.textArea1:setText("T120L4O4CDEFGAB>CDEFGAB")
  self.textArea2:setText("")
  self.textArea3:setText("")

  self:setResizable(false)

  -- 只有第一次初始化才加入 UIManager
  self:addToUIManager()
end

function MMLInstrumentUI:show()
  -- 顯示視窗
  if not self.isInitialized then
    self:initialise()
  end
  self:setVisible(true)
  self:bringToTop()
end

function MMLInstrumentUI:hide()
  -- 隱藏視窗（不移除）
  self:setVisible(false)
end

function MMLInstrumentUI:onPlay()
  local mml1 = self.textArea1:getText() or ""
  local mml2 = self.textArea2:getText() or ""
  local mml3 = self.textArea3:getText() or ""

  if mml1 == "" and mml2 == "" and mml3 == "" then
    self.statusLabel:setName(getText("UI_MMLPlayer_EmptyInput") or "Please enter MML code")
    return
  end

  -- 組合為單一字串（以逗號區分 track）
  local combined = string.format("%s,%s,%s", mml1, mml2, mml3)
  -- 創建新的播放器
  self.TAPlay = TAPlayMMLFromInventory:new(self.character, self.instrument, combined)
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
