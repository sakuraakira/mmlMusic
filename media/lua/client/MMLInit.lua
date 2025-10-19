-- MMLInit.lua
-- MML 系統客戶端初始化

-- 載入核心模組
local MMLPlayer = require('MMLPlayer')
local MMLParser = require('MMLParser')
local MMLContextMenu = require('MMLContextMenu')
local MMLClientRecvCommands = require('MMLClientRecvCommands')
local MMLPlayerUI = require('MMLPlayerUI')

-- ============================================================
-- 註冊物品右鍵選單
-- ============================================================
local function OnPreFillInventoryObjectContextMenu(playerIndex, context, items)
  MMLContextMenu.createMenu(playerIndex, context, items)
end

Events.OnPreFillInventoryObjectContextMenu.Add(OnPreFillInventoryObjectContextMenu)

-- ============================================================
-- 註冊世界物品右鍵選單（鋼琴等）
-- ============================================================
local function OnPreFillWorldObjectContextMenu(playerIndex, context, worldobjects, test)
  -- 可以在這裡添加「使用 MML 播放器」選項
  -- 例如：在鋼琴右鍵選單中添加「打開 MML 編輯器」
end

Events.OnPreFillWorldObjectContextMenu.Add(OnPreFillWorldObjectContextMenu)

-- ============================================================
-- 玩家死亡時停止播放
-- ============================================================
local function OnPlayerDeath(player)
  local playerId = player:getOnlineID()
  if MMLPlayer.activePlayers[playerId] then
    MMLPlayer.activePlayers[playerId]:stop()
    print("[MML] Stopped playback due to player death")
  end
end

Events.OnPlayerDeath.Add(OnPlayerDeath)


-- ============================================================
-- 調試指令和測試
-- ============================================================
-- 全域變數存儲 UI 實例，避免重複創建
local debugMMLPlayerUI = nil

local function OnKeyPressed(key)
  -- F11 - 停止所有 MML 播放
  if key == Keyboard.KEY_F11 then
    MMLPlayer.stopAll()
    print("[MML Debug] Stopped all playback (F11)")

    -- 如果有 UI 開著，也關閉
    if debugMMLPlayerUI then
      debugMMLPlayerUI:close()
      debugMMLPlayerUI = nil
    end
  end

  -- F12 - 開啟 MML 播放器並測試範例
  if key == Keyboard.KEY_F12 then
    print("[MML Debug] ========================================")
    print("[MML Debug] Opening MML Player and testing example...")
    print("[MML Debug] ========================================")

    -- 如果已經有 UI 開著，先關閉
    if debugMMLPlayerUI then
      debugMMLPlayerUI:close()
      debugMMLPlayerUI = nil
    end

    -- 創建新的 MML 播放器 UI
    debugMMLPlayerUI = MMLPlayerUI:new("Piano", player)
    debugMMLPlayerUI:initialise()
    debugMMLPlayerUI:addToUIManager()

    print("[MML Debug] UI created and initialized")

    -- 等待 UI 完全初始化後載入範例
    -- 使用 OnPostRender 延遲執行
    local loadExampleFunc = nil
    loadExampleFunc = function()
      if debugMMLPlayerUI and debugMMLPlayerUI.textArea then
        -- 載入範例樂曲（小星星）
        local exampleMML = "T120 L4 O4 CCGGAAG2 FFEEDDC2 GGFFEED2 GGFFEED2 CCGGAAG2 FFEEDDC2"
        debugMMLPlayerUI.textArea:setText(exampleMML)
        print("[MML Debug] Example loaded: " .. exampleMML)

        -- 再延遲一幀後自動播放
        local autoPlayFunc = nil
        autoPlayFunc = function()
          if debugMMLPlayerUI then
            debugMMLPlayerUI:onPlay()
            print("[MML Debug] Auto-play started!")
            print("[MML Debug] ========================================")
          end
          Events.OnPostRender.Remove(autoPlayFunc)
        end
        Events.OnPostRender.Add(autoPlayFunc)

        Events.OnPostRender.Remove(loadExampleFunc)
      end
    end
    Events.OnPostRender.Add(loadExampleFunc)
  end
end

Events.OnKeyPressed.Add(OnKeyPressed)

-- ============================================================
-- 顯示調試快捷鍵說明
-- ============================================================
print("[MML] MML system initialized successfully")
