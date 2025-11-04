-- MMLContextMenu.lua
-- 樂器物品的右鍵選單
local MMLContextMenu = {}
local MMLInstrumentUI = require('MMLInstrumentUI') -- 新增：用來打開 UI
local MMLComposeUI = require('MMLComposeUI')       -- 新增：用來打開作曲 UIElement
local PlayerItemToMMLInstrument = require('MMLInstrument')
local MMLWorldItemInfo = require('MMLWorldItemInfo')
-- ============================================================
-- 創建選單
-- ============================================================
function MMLContextMenu.createMenu(playerIndex, context, items)
  local player = getPlayer()

  -- 獲取物品
  local item
  if type(items) == 'table' and items[1] then
    if type(items[1]) == 'table' then
      item = items[1].items[1]
    else
      item = items[1]
    end
  end

  if not item then return end

  local itemType = item:getFullType()

  -- 如果物品類型在 PlayerItemToMMLInstrument 表裡，加入「演奏」選項（開啟 UI）
  if PlayerItemToMMLInstrument[itemType] then
    context:addOption(
      getText("UI_ContextMenu_PlayMusicSheet") or "Play",
      player,
      MMLContextMenu.onOpenMMLInstrumentUI,
      item
    )
    if isClient() then
      context:addOption(
        getText("UI_ContextMenu_PrepareEnsemble") or "Prepare An ensemble",
        player,
        MMLContextMenu.onPrepareEnsemble,
        item
      )
    end
    return
  elseif itemType:sub(1, 9) == "MMLSheet." then
    -- 檢查玩家背包是否有「筆」類物品（簡單用 fullType 名稱包含 Pen/Pencil 判斷）
    local function playerHasPen(p)
      if not p or not p:getInventory() then return false end
      local invItems = p:getInventory():getItems()
      for i = 0, invItems:size() - 1 do
        local it = invItems:get(i)
        if it and it:getFullType() then
          local ft = it:getFullType()
          if ft:find("Pen") or ft:find("Pencil") then
            return true
          end
        end
      end
      return false
    end

    local hasPen = playerHasPen(player)
    if hasPen then
      context:addOption(
        getText("UI_ContextMenu_EditMusicSheet") or "Edit",
        player,
        MMLContextMenu.onOpenMMLComposeUI,
        item
      )
    else
      local label = getText("UI_ContextMenu_EditMusicSheetNoPen") or "Edit (need a pen)"
      local option = context:addOption(label, player, nil, item)
      option.notAvailable = true
    end
    return
  end
end

-- 按下「演奏」時開啟 UI
---comment
---@param player IsoPlayer
---@param item InventoryItem
function MMLContextMenu.onOpenMMLInstrumentUI(player, item)
  if player:getSecondaryHandItem() ~= item then
    ISTimedActionQueue.add(ISEquipWeaponAction:new(player, item, 50, false))
  end
  local ui = MMLInstrumentUI.getInstance(player, item)
  ui:show()
end

-- 按下「作曲」時開啟 UI
function MMLContextMenu.onOpenMMLComposeUI(player, item)
  if player:getPrimaryHandItem() ~= item then
    ISTimedActionQueue.add(ISEquipWeaponAction:new(player, item, 50, true))
  end
  -- 建立並初始化 UI
  local ui = MMLComposeUI.getInstance(player, item)
  ui:show()
end

-- 按下「準備合奏」
function MMLContextMenu.onPrepareEnsemble(player, item)
  if player:getPrimaryHandItem() ~= nil then
    player:setPrimaryHandItem(nil)
  end
  if player:getSecondaryHandItem() ~= item then
    ISTimedActionQueue.add(ISEquipWeaponAction:new(player, item, 50, false))
  end
  TAPlayMMLEnsemble = require("TimedAction/TAPlayMMLEnsemble")
  ISTimedActionQueue.add(TAPlayMMLEnsemble:new(player, item))
end

-- ============================================================
-- 註冊世界物品右鍵選單（鋼琴等）
-- ============================================================
local function getWestSquare(square)
  return getWorld():getCell():getGridSquare(square:getX() - 1, square:getY(), square:getZ())
end

-- IsoSquare has a getS() function that can return nil for no apparent reason
local function getSouthSquare(square)
  return getWorld():getCell():getGridSquare(square:getX(), square:getY() - 1, square:getZ())
end

local function getPianoUpperSide(pianoSquare, actionInfo)
  local upperPianoSquare
  if actionInfo.facing == 'south' and actionInfo.side == 'right' then
    upperPianoSquare = getWestSquare(pianoSquare)
  elseif actionInfo.facing == 'east' and actionInfo.side == 'left' then
    upperPianoSquare = getSouthSquare(pianoSquare)
  else
    upperPianoSquare = pianoSquare
  end
  local upperSidePianoObject = nil
  for i = 0, upperPianoSquare:getObjects():size() - 1 do
    local object = upperPianoSquare:getObjects():get(i)
    if actionInfo.upperSide == object:getSprite():getName() then
      upperSidePianoObject = object
    end
  end
  return upperSidePianoObject
end

local SeatSpriteName = {
  ["recreational_01_10"] = true,
  ["recreational_01_11"] = true,
  ["recreational_01_14"] = true,
  ["recreational_01_15"] = true,
}
local function hasSeat(squareFacingPiano)
  for i = 0, squareFacingPiano:getObjects():size() - 1 do
    local object = squareFacingPiano:getObjects():get(i)
    local spriteName = object:getSprite():getName()
    if SeatSpriteName[spriteName] then
      return true
    end
  end
  return false
end

local function onPlayPiano(worldobjects, player, square, actionInfo)
  local upperSidePianoObject = getPianoUpperSide(square, actionInfo)
  if upperSidePianoObject == nil then
    return nil
  end
  -- it's alright, this square is working with getS() and getE(), very consistant API, no problem here
  local squareFacingPiano = actionInfo.facing == "south" and upperSidePianoObject:getSquare():getS()
      or upperSidePianoObject:getSquare():getE()
  ISTimedActionQueue.add(ISWalkToTimedAction:new(player, squareFacingPiano))

  local ui = MMLInstrumentUI.getInstanceFromWorld(player, actionInfo.instrument, upperSidePianoObject, actionInfo.facing,
    hasSeat(squareFacingPiano))
  ui:show()
end

function MMLContextMenu.OnPreFillWorldObjectContextMenu(playerIndex, context, worldobjects, test)
  local addedContext = {}
  local player = getPlayer()
  for _, worldobject in ipairs(worldobjects) do
    local square = worldobject:getSquare()
    for i = 0, square:getObjects():size() - 1 do
      local item = square:getObjects():get(i)
      -- some items, like the "Premium Technologies Radio" when on the ground, don't have a sprite
      if item:getSprite() ~= nil then
        local spriteName = item:getSprite():getName()
        if MMLWorldItemInfo[spriteName] ~= nil then
          -- for some unknown reason the pianos are listed twice so we filter the duplicate
          if addedContext[item:getWorldObjectIndex()] == nil then
            addedContext[item:getWorldObjectIndex()] = true
            context:addOption(getText("UI_ContextMenu_PlayPiano") or "Play piano", worldobjects,
              onPlayPiano,
              player, square, MMLWorldItemInfo[spriteName])
          end
        end
      end
    end
  end
end

return MMLContextMenu
