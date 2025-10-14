-- MMLContextMenu.lua
-- 樂譜物品的右鍵選單
local MMLContextMenu = {}
local TAPlayMMLFromInventory = require('TimedAction/TAPlayMMLFromInventory')
local BardTrait = require('BardTrait')

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

  -- 檢查是否是樂譜物品
  local itemType = item:getFullType()
  if not itemType:match("MusicSheet") and not itemType:match("MMLSheet") then
    return
  end

  -- 檢查是否有 Bard 特質（如果啟用特質系統）
  if BardTrait.getInstance().enabled and not player:HasTrait(BardTrait.getTraitType()) then
    -- 沒有音樂家特質，顯示灰色選項
    local option = context:addOption(
      getText("ContextMenu_PlayMusicSheet"),
      nil, nil
    )
    option.notAvailable = true
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip:setName(getText("ContextMenu_RequireTrait"))
    tooltip.description = getText("ContextMenu_RequireMusicianTrait")
    option.toolTip = tooltip
    return
  end

  -- 檢查 MML 資料
  local mml = item:getModData().mml
  if not mml or mml == "" then
    -- 沒有 MML 資料
    local option = context:addOption(
      getText("ContextMenu_PlayMusicSheet"),
      nil, nil
    )
    option.notAvailable = true
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip:setName(getText("ContextMenu_NoMusic"))
    tooltip.description = getText("ContextMenu_MusicSheetEmpty")
    option.toolTip = tooltip
    return
  end

  -- 添加「播放樂譜」選項
  context:addOption(
    getText("ContextMenu_PlayMusicSheet"),
    player,
    MMLContextMenu.onPlayMusicSheet,
    item
  )

  -- 添加「查看資訊」選項（可選）
  context:addOption(
    getText("ContextMenu_ViewSheetInfo"),
    player,
    MMLContextMenu.onViewSheetInfo,
    item
  )
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

-- ============================================================
-- 查看樂譜資訊
-- ============================================================
function MMLContextMenu.onViewSheetInfo(player, item)
  local instrument = item:getModData().instrument or "Unknown"
  local mml = item:getModData().mml or ""
  local title = item:getName()

  -- 計算音符數量和時長（簡化版）
  local noteCount = 0
  for _ in mml:gmatch("[CDEFGAB]") do
    noteCount = noteCount + 1
  end

  -- 顯示資訊（使用遊戲的對話框）
  local text = string.format(
    "%s\n\n%s: %s\n%s: %d\n%s: %d %s",
    title,
    getText("UI_MusicSheet_Instrument"), instrument,
    getText("UI_MusicSheet_Notes"), noteCount,
    getText("UI_MusicSheet_Length"), #mml, getText("UI_Characters")
  )

  player:Say(text)

  -- 或者可以創建一個自定義的資訊視窗
  -- local modal = ISMusicSheetInfoModal:new(...)
  -- modal:initialise()
  -- modal:addToUIManager()
end

return MMLContextMenu
