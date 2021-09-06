ACategoryMenu = ADropDown:_New()
ACategoryMenu.__index = ACategoryMenu

function ACategoryMenu:Init(config)
    ADropDown.Init(self, config)

    for i, item in ipairs(self.items) do
        item.UnCheck:Show()
        item.disableCount = 0
    end

    self.selection = ASet:New()
end

function ACategoryMenu:OnItemClick(index)
    local f = self.items[index]
    f.selected = not f.selected
    f.Check:SetShown(f.selected)
    f.UnCheck:SetShown(not f.selected)
    if f.selected then
        self.selection:Insert(index)
    else
        self.selection:Remove(index)
    end

    ADropDown.OnItemClick(self, index)
end

function ACategoryMenu:GetSelection()
    return self.selection.orderedElems
end

function ACategoryMenu:ClearSelection()
    while not self.selection:Empty() do
        self:OnItemClick(self.selection:First())
    end
end

function ACategoryMenu:DisableItem(index)
    local f        = self.items[index]
    f.disableCount = f.disableCount + 1
    ADropDown.DisableItem(self, index)
end

function ACategoryMenu:EnableItem(index)
    local f        = self.items[index]
    f.disableCount = max(f.disableCount - 1, 0)
    if f.disableCount == 0 then
        ADropDown.EnableItem(self, index)
    end
end
