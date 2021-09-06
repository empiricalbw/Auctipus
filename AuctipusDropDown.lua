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

function ADropDown:_New()
    local dd = {}
    setmetatable(dd, self)
    return dd
end

function ADropDown:New(config)
    local dd = self:_New()
    dd:Init(config)
    return dd
end

function ADropDown:Init(config)
    local name = "ADropDownFrame"..ADD_INDEX
    ADD_INDEX  = ADD_INDEX + 1

    self.frame = CreateFrame("Frame", name, UIParent,
                           "AuctipusDropDownListTemplate")
    self.frame:SetWidth(12)
    self.frame:SetHeight(20)
    self.frame:SetPoint(config.anchor.point,
                      config.anchor.relativeTo,
                      config.anchor.relativePoint,
                      config.anchor.dx,
                      config.anchor.dy)
    self.frame:Hide()

    local y       = -10
    local x       = 12
    local remRows = config.rows
    self.items = {}
    for i, item in ipairs(config.items) do
        local f = CreateFrame("Button", nil, self.frame,
                              "AuctipusDropDownItemTemplate")
        f:SetPoint("TOPLEFT", x, y)
        f:SetPoint("TOPRIGHT", self.frame, "TOPLEFT", x + config.width - 12, y)
        f:SetText(item)
        f.Check:Hide()
        f.UnCheck:Hide()
        f:SetScript("OnClick", function() self:OnItemClick(i) end)
        y = y - f:GetHeight()

        table.insert(self.items, f)

        remRows = remRows - 1
        if remRows == 0 then
            x = x + config.width
            y = -10
            remRows = config.rows
        end

        f.selected     = false
    end

    local nrows = min(#config.items, config.rows)
    local ncols = ceil(#config.items / config.rows)
    self.frame:SetHeight(self.frame:GetHeight() +
                         self.items[1]:GetHeight()*nrows)
    self.frame:SetWidth(self.frame:GetWidth() + config.width*ncols)

    self.handler   = config.handler

    table.insert(UIMenus, name)
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
    if self.handler then
        self.handler:OnDropdownItemClick(index, f.selected)
    end
end

function ADropDown:SetItemEnabled(index, enabled)
    if enabled then
        self:EnableItem(index)
    else
        self:DisableItem(index)
    end
end

function ADropDown:DisableItem(index)
    self.items[index]:Disable()
end

function ADropDown:EnableItem(index)
    self.items[index]:Enable()
end
