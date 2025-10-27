require "ISUI/ISPanel"

---@class SheetIconSlot : ISPanelJoypad
local SheetIconSlot = ISPanel:derive("SheetIconSlot")

---comment
---@param x number
---@param y number
---@param size number
---@param hostUI ISCollapsableWindow
---@return ISPanel
function SheetIconSlot:new(x, y, size, hostUI)
  local o = ISPanel.new(self, x, y, size, size)
  o:initialise()
  o.anchorLeft = true; o.anchorTop = true
  o.background = true
  o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.25 }
  o.borderColor = { r = 0.8, g = 0.8, b = 0.8, a = 1 }
  o.iconItem = nil
  o.iconTex = nil
  o.tooltip = nil
  o.hostUI = hostUI
  o.hover = false
  return o
end

------------------------------------------------------------
-- 設定或清除當前顯示物品
------------------------------------------------------------
function SheetIconSlot:setItem(item)
  self.iconItem = item
  self.iconTex = item and item:getTex() or nil
  self:hideTooltip()
end

------------------------------------------------------------
-- 拖放時處理
------------------------------------------------------------
function SheetIconSlot:onMouseUp(x, y)
  if ISMouseDrag and ISMouseDrag.dragging and #ISMouseDrag.dragging > 0 then
    local items = {}
    for _, v in ipairs(ISMouseDrag.dragging) do
      if v.items then
        for i = 1, #v.items do table.insert(items, v.items[i]) end
      else
        table.insert(items, v)
      end
    end

    for _, item in ipairs(items) do
      local ft = item:getFullType() or ""
      if ft == "MMLSheet.SheetMusic" or ft:sub(1, 9) == "MMLSheet." then
        local player = getPlayer()
        ISTimedActionQueue.add(ISEquipWeaponAction:new(player, item, 20, true))
        ISMouseDrag.dragging = nil
        return true
      end
    end

    ISMouseDrag.dragging = nil
    return true
  end
  return ISPanel.onMouseUp(self, x, y)
end

------------------------------------------------------------
-- tooltip 顯示
------------------------------------------------------------
function SheetIconSlot:showTooltip()
  if self.tooltip or not self.iconItem then return end
  self.tooltip = ISToolTipInv:new(self.iconItem)
  self.tooltip:initialise()
  self.tooltip:addToUIManager()
  self.tooltip.followMouse = true
  self.tooltip:setVisible(true)
end

function SheetIconSlot:hideTooltip()
  if self.tooltip then
    self.tooltip:removeFromUIManager()
    self.tooltip = nil
  end
end

function SheetIconSlot:onMouseMove(dx, dy)
  ISPanel.onMouseMove(self, dx, dy)
  if self.iconItem then self:showTooltip() end
  self.hover = true
end

function SheetIconSlot:onMouseMoveOutside(dx, dy)
  ISPanel.onMouseMoveOutside(self, dx, dy)
  self:hideTooltip()
  self.hover = false
end

------------------------------------------------------------
-- 畫面
------------------------------------------------------------
function SheetIconSlot:prerender()
  ISPanel.prerender(self)
  if self.hover then
    self:drawRectBorder(0, 0, self.width, self.height, 1, 0.2, 1.0, 0.3, 1.0)
  else
    self:drawRectBorder(0, 0, self.width, self.height, 1, self.borderColor.r, self.borderColor.g, self.borderColor.b, 1)
  end

  if self.iconTex then
    self:drawTextureScaledAspect(self.iconTex, 4, 4, self.width - 8, self.height - 8, 1, 1, 1, 1)
  end
end

function SheetIconSlot:onRightMouseUp(x, y)
  if self.iconItem then
    local player = getPlayer()
    player:setPrimaryHandItem(nil)
  end
  self:setItem(nil)
  if self.hostUI and self.hostUI.clearMML then
    self.hostUI:clearMML()
  end
  return true
end

return SheetIconSlot
