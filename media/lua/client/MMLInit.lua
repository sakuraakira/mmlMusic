-- MMLInit.lua
-- 載入核心模組
local MMLContextMenu = require('MMLContextMenu')
local MMLInstrumentUI = require('MMLInstrumentUI')
local MMLScores = require('MMLScores')
local MMLMusicSkill = require('MMLMusicSkill')
local PlayerItemToMMLInstrument = require('MMLInstrument')


-- 在遊戲啟動初期註冊 Perk，確保其他腳本呼叫 addXP/getLevel 時 Perk 已存在
Events.OnGameBoot.Add(MMLMusicSkill.registerPerk)

-- ================================
-- 註冊物品右鍵選單
-- ================================

Events.OnPreFillInventoryObjectContextMenu.Add(MMLContextMenu.createMenu)

-- ================================
-- 註冊世界物品右鍵選單（鋼琴等）
-- ================================

Events.OnPreFillWorldObjectContextMenu.Add(MMLContextMenu.OnPreFillWorldObjectContextMenu)


local function applyMMLSelection(playerObj, item)
  if not playerObj or not item then return end

  local ui = MMLInstrumentUI.getExistingInstance and MMLInstrumentUI.getExistingInstance() or nil

  -- 更安全的 isOpen 檢查：避免嘗試呼叫非函式欄位（會導致 "tried to call nil"）
  local isOpen = false
  if ui then
    if type(ui.getIsVisible) == "function" then
      isOpen = ui:getIsVisible()
    elseif type(ui.isVisible) == "function" then
      isOpen = ui:isVisible()
    else
      isOpen = (ui.isVisible == true) or (ui.visible == true)
    end
  end
  if not (ui and isOpen) then return end

  local fullType = item:getFullType()
  print("item type:", fullType)
  if fullType == "MMLSheet.SheetMusic" then
    local mmlData = item:getModData().mml
    if not mmlData or type(mmlData) ~= "table" then
      ui:clearMML()
      print("No MML data found in item", tostring(fullType))
      return
    end
    ui:setMML(mmlData, item)
    return
  elseif fullType:sub(1, 9) == "MMLSheet." then
    local sheet = nil
    -- 優先用 MMLScores API
    if MMLScores and type(MMLScores.get) == "function" then
      sheet = MMLScores.get(fullType)
    end

    if not sheet or type(sheet.mml) ~= "table" then
      ui:clearMML()
      print("No matching sheet for", tostring(fullType))
      return
    end
    ui:setMML(sheet.mml, item)
    return
  end
  ui:clearMML()
end

Events.OnEquipPrimary.Add(function(playerObj, item)
  if isServer() then return end
  local me = getPlayer()
  if playerObj ~= me then return end

  if item then
    applyMMLSelection(playerObj, item)
  end
end)

Events.OnEquipSecondary.Add(function(playerObj, item)
  if isServer() then return end
  local me = getPlayer()
  if playerObj ~= me then return end
  if item and PlayerItemToMMLInstrument[item:getFullType()] then
    local ui = MMLInstrumentUI.getExistingInstance and MMLInstrumentUI.getExistingInstance() or nil
    local isOpen = ui and
        ((ui.getIsVisible and ui:getIsVisible()) or (ui.isVisible and ui:isVisible()) or ui.visible == true)
    if not (ui and isOpen) then return end
    MMLInstrumentUI.getInstance(playerObj, item)
  end
end)

print("[MML] MML system initialized successfully")
