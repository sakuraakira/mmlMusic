-- MMLContextMenu.lua
-- 樂器物品的右鍵選單
local MMLContextMenu = {}
local TAPlayMMLFromInventory = require('TimedAction/TAPlayMMLFromInventory')
local MMLInstrumentUI = require('MMLInstrumentUI') -- 新增：用來打開 UI
local PlayerItemToMMLInstrument = require('MMLInstrument')
-- ============================================================
-- 創建選單
-- ============================================================
function MMLContextMenu.createMenu(playerIndex, context, items)
  local player = getSpecificPlayer(playerIndex)

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
      MMLContextMenu.onOpenMMLPlayerUI,
      item
    )
    return
  end
end

-- 新增：按下「演奏」時開啟 UI，預設填入物品的 MML 與建議樂器（顯示名稱）
function MMLContextMenu.onOpenMMLPlayerUI(player, item)
  if player:getPrimaryHandItem() ~= item then
    ISTimedActionQueue.add(ISEquipWeaponAction:new(player, item, 50, true))
  end

  -- 建立並初始化 UI
  local ui = MMLInstrumentUI.getInstance(player, item)
  ui:show()
end

-- ============================================================
-- 播放樂譜
-- ============================================================
function MMLContextMenu.onPlayMusicSheet(player, item)
  -- 確保物品在背包中
  if not player:getInventory():contains(item) then
    player:Say(getText("Tooltip_ItemNotInInventory"))
    return
  end

  -- 停止當前動作
  ISTimedActionQueue.clear(player)

  -- 添加播放動作
  ISTimedActionQueue.add(TAPlayMMLFromInventory:new(player, item))

  print("[MMLContextMenu] Added play action to queue")
end

return MMLContextMenu
