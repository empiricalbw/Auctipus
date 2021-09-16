ACategoryMenu = ADropDown:_New()
ACategoryMenu.__index = ACategoryMenu

local RESET_FILTERS_HEIGHT = 16

function ACategoryMenu:Init(config)
    ADropDown.Init(self, config)

    for i, item in ipairs(self.items) do
        item.RadioOff:Show()
        item.disableCount = 0
    end

    self.frame:SetHeight(self.frame:GetHeight() + RESET_FILTERS_HEIGHT)
    self.items[1]:SetPoint("TOPLEFT", 12, -10 - RESET_FILTERS_HEIGHT)
    local f = CreateFrame("Button", nil, self.frame,
                          "AuctipusDropDownItemTemplate")
    self.resetButton = f
    f:SetHeight(RESET_FILTERS_HEIGHT)
    f:SetWidth(config.width * 3)
    f:SetPoint("TOPLEFT", 12, -8)
    f.LabelEnabled:SetText("Reset Filters")
    f.LabelEnabled:SetJustifyH("CENTER")
    f.LabelEnabled:SetJustifyV("MIDDLE")
    f.LabelDisabled:SetText("Reset Filters")
    f.LabelDisabled:SetJustifyH("CENTER")
    f.LabelDisabled:SetJustifyV("MIDDLE")
    f.LabelEnabled:Hide()
    f:Disable()
    f.RadioOn:Hide()
    f.RadioOff:Hide()
    f:SetScript("OnClick", function() self:ClearSelection() end)

    self.selection = ASet:New()
end

function ACategoryMenu:OnItemClick(index)
    local f = self.items[index]
    f.selected = not f.selected
    f.RadioOn:SetShown(f.selected)
    f.RadioOff:SetShown(not f.selected)
    if f.selected then
        self.selection:Insert(index)
    else
        self.selection:Remove(index)
    end

    if self.selection:Empty() then
        self.resetButton.LabelEnabled:Hide()
        self.resetButton.LabelDisabled:Show()
        self.resetButton:Disable()
    else
        self.resetButton.LabelEnabled:Show()
        self.resetButton.LabelDisabled:Hide()
        self.resetButton:Enable()
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
