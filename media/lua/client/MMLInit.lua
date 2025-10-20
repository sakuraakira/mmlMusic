-- MMLInit.lua
-- MML 系統客戶端初始化

-- 載入核心模組
local MMLPlayer = require('MMLPlayer')
local MMLContextMenu = require('MMLContextMenu')
local MMLComposeUI = require('MMLComposeUI')
local MMLInstrumentUI = require('MMLInstrumentUI')
local MMLScores = require('MMLScores')

-- ============================================================
-- 註冊物品右鍵選單
-- ============================================================

Events.OnPreFillInventoryObjectContextMenu.Add(MMLContextMenu.createMenu)

-- ============================================================
-- 註冊世界物品右鍵選單（鋼琴等）
-- ============================================================

Events.OnPreFillWorldObjectContextMenu.Add(MMLContextMenu.OnPreFillWorldObjectContextMenu)


local function applyMMLSelection(playerObj, item)
  if not playerObj or not item then return end
  if playerObj:isDead() then return end

  local fullType = item:getFullType()

  local sheet = MMLScores and MMLScores[fullType]
  if not sheet or type(sheet.mml) ~= "table" then
    print("No matching sheet for", tostring(fullType))
    return
  end

  local ui = MMLInstrumentUI.getExistingInstance and MMLInstrumentUI.getExistingInstance() or nil
  local isOpen = ui and
      ((ui.getIsVisible and ui:getIsVisible()) or (ui.isVisible and ui:isVisible()) or ui.visible == true)
  if not (ui and isOpen) then return end
  ui:setMML(sheet.mml)
end

Events.OnEquipPrimary.Add(function(playerObj, item)
  if isServer() then return end
  if item then
    applyMMLSelection(playerObj, item)
  end
end)
-- ============================================================
-- 調試指令和測試
-- ============================================================
-- 全域變數存儲 UI 實例，避免重複創建
local debugMMLPlayerUI = nil

local function OnKeyPressed(key)
  local player = getSpecificPlayer(0)

  if key == Keyboard.KEY_F11 then
    print("[MML Debug] Opening MML Player and testing example...")
    -- 如果已經有 UI 開著，先關閉
    if debugMMLPlayerUI then
      debugMMLPlayerUI:close()
      debugMMLPlayerUI = nil
    end

    -- 創建新的 MML 播放器 UI
    debugMMLPlayerUI = MMLComposeUI:new("Piano", player)
    debugMMLPlayerUI:initialise()
    debugMMLPlayerUI:addToUIManager()
    print("[MML Debug] UI created and initialized")
  end
end

Events.OnKeyPressed.Add(OnKeyPressed)

-- ============================================================
-- 顯示調試快捷鍵說明
-- ============================================================
print("[MML] MML system initialized successfully")
