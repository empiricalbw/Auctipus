ADropDown = {}
ADropDown.__index = ADropDown

AUCTIPUS_DROPDOWN_BACKDROP_INFO = {
    bgFile   = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile     = true,
    tileEdge = true,
    tileSize = 16,
    edgeSize = 16,
    insets   = {left = 4, right = 4, top = 4, bottom = 4},

    backdropBorderColor = TOOLTIP_DEFAULT_COLOR,
}

local ADD_INDEX = 1

function ADropDown:New(config)
    local dd = {}
    setmetatable(dd, self)

    local name = "ADropDownFrame"..ADD_INDEX
    ADD_INDEX  = ADD_INDEX + 1

    dd.frame = CreateFrame("Frame", name, UIParent,
                           "AuctipusDropDownListTemplate")
    dd.frame:SetWidth(12)
    dd.frame:SetHeight(20)
    dd.frame:SetPoint(config.anchor.point,
                      config.anchor.relativeTo,
                      config.anchor.relativePoint,
                      config.anchor.dx,
                      config.anchor.dy)
    dd.frame:Hide()

    local y       = -10
    local x       = 12
    local remRows = config.rows
    dd.items = {}
    for i, item in ipairs(config.items) do
        local f = CreateFrame("Button", nil, dd.frame,
                              "AuctipusDropDownItemTemplate")
        f:SetPoint("TOPLEFT", x, y)
        f:SetPoint("TOPRIGHT", dd.frame, "TOPLEFT", x + config.width - 12, y)
        f:SetText(item)
        f.Check:Hide()
        f.UnCheck:Show()
        f:SetScript("OnClick", function() dd:OnItemClick(i) end)
        y = y - f:GetHeight()

        table.insert(dd.items, f)

        remRows = remRows - 1
        if remRows == 0 then
            x = x + config.width
            y = -10
            remRows = config.rows
        end

        f.selected     = false
        f.disableCount = 0
    end

    local nrows = min(#config.items, config.rows)
    local ncols = ceil(#config.items / config.rows)
    dd.frame:SetHeight(dd.frame:GetHeight() + dd.items[1]:GetHeight()*nrows)
    dd.frame:SetWidth(dd.frame:GetWidth() + config.width*ncols)

    dd.selection = ASet:New()
    dd.handler   = config.handler

    table.insert(UIMenus, name)

    return dd
end

function ADropDown:Show()
    self.frame:Show()
end

function ADropDown:Hide()
    self.frame:Hide()
end

function ADropDown:Toggle()
    self.frame:SetShown(not self.frame:IsShown())
end

function ADropDown:OnItemClick(index)
    local f = self.items[index]
    f.selected = not f.selected
    f.Check:SetShown(f.selected)
    f.UnCheck:SetShown(not f.selected)
    if f.selected then
        self.selection:Insert(index)
    else
        self.selection:Remove(index)
    end
    if self.handler then
        self.handler:OnDropdownItemClick(index, f.selected)
    end
end

function ADropDown:GetSelection()
    return self.selection.orderedElems
end

function ADropDown:SetItemEnabled(index, enabled)
    if enabled then
        self:EnableItem(index)
    else
        self:DisableItem(index)
    end
end

function ADropDown:DisableItem(index)
    local f        = self.items[index]
    f.disableCount = f.disableCount + 1
    f:Disable()
end

function ADropDown:EnableItem(index)
    local f        = self.items[index]
    f.disableCount = max(f.disableCount - 1, 0)
    if f.disableCount == 0 then
        f:Enable()
    end
end
