Auctipus.DropDown = {}
Auctipus.DropDown.__index = Auctipus.DropDown
local ADropDown = Auctipus.DropDown

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
local ADD_BUTTON_POOL = {}
local TEMPLATE_BUTTON = CreateFrame("Button", nil, UIParent,
                                    "AuctipusDropDownItemTemplate")

local function AllocButton(parent)
    local f
    if #ADD_BUTTON_POOL > 0 then
        f = table.remove(ADD_BUTTON_POOL)
        f:SetParent(parent)
        f:Show()
        return f
    end

    f = CreateFrame("Button", nil, parent, "AuctipusDropDownItemTemplate")
    local b = f.XButton
    b.Texture:SetAlpha(0.5)
    b:SetScript("OnEnter", function() b.Texture:SetAlpha(1) end)
    b:SetScript("OnLeave", function() b.Texture:SetAlpha(0.5) end)
    return f
end

local function FreeButton(b)
    b:ClearAllPoints()
    b:Hide()
    b:SetParent(UIParent)
    table.insert(ADD_BUTTON_POOL, b)
end

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
    self.items = {}
    self:ReInit(config)

    table.insert(UIMenus, name)
end

function ADropDown:ReInit(config)
    while #self.items > 0 do
        FreeButton(table.remove(self.items))
    end

    self.frame:Hide()
    self.frame:SetWidth(12)
    self.frame:SetHeight(20)

    if config.anchor then
        assert(config.anchor.relativeTo ~= nil)
        self.frame:ClearAllPoints()
        self.frame:SetPoint(config.anchor.point,
                            config.anchor.relativeTo,
                            config.anchor.relativePoint,
                            config.anchor.dx,
                            config.anchor.dy)
    end

    local fwidth = config.width or 32
    if fwidth <= 32 then
        for _, s in ipairs(config.items) do
            TEMPLATE_BUTTON.LabelEnabled:SetText(s)
            fwidth = max(fwidth,
                TEMPLATE_BUTTON.LabelEnabled:GetUnboundedStringWidth() + 32)
        end
    end

    local y       = -10
    local x       = 12
    local remRows = config.rows
    for i, item in ipairs(config.items) do
        local f = AllocButton(self.frame)
        f.XButton:SetShown(config.xhandler ~= nil)
        f.XButton:SetScript("OnClick", function() self:OnXClick(i) end)
        table.insert(self.items, f)

        f:SetWidth(fwidth)
        if i == 1 then
            f:SetPoint("TOPLEFT", x, y)
        elseif (i % config.rows) == 1 then
            f:SetPoint("TOPLEFT", self.items[i - config.rows], "TOPRIGHT")
        else
            f:SetPoint("TOPLEFT", self.items[i - 1], "BOTTOMLEFT")
        end
        self:SetItemText(i, item)
        f.LabelDisabled:Hide()
        f:SetScript("OnClick", function() self:OnItemClick(i) end)
        y = y - f:GetHeight()

        remRows = remRows - 1
        if remRows == 0 then
            x = x + fwidth
            y = -10
            remRows = config.rows
        end

        f.selected = false
    end

    local nrows = min(#config.items, config.rows)
    if nrows > 0 then
        self.frame:SetHeight(self.frame:GetHeight() +
                             self.items[1]:GetHeight()*nrows)
    end

    local ncols = ceil(#config.items / config.rows)
    if ncols > 0 then
        self.frame:SetWidth(self.frame:GetWidth() + fwidth*ncols)
    end

    self.handler  = config.handler
    self.xhandler = config.xhandler
end

function ADropDown:Show(anchor)
    if anchor then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(anchor.point,
                            anchor.relativeTo,
                            anchor.relativePoint,
                            anchor.dx,
                            anchor.dy)
    end
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
        self.handler(index, f.selected)
    end
end

function ADropDown:OnXClick(index)
    assert(self.xhandler)
    self.xhandler(index)
end

function ADropDown:SetItemTitle(index)
    local f = self.items[index]
    self:DisableItem(index)
    f.LabelDisabled:SetFontObject(GameFontNormalSmall)
end

function ADropDown:SetItemText(index, text)
    local f = self.items[index]
    f.LabelEnabled:SetText(text)
    f.LabelDisabled:SetText(text)
end

function ADropDown:GetItemText(index)
    local f = self.items[index]
    return f.LabelEnabled:GetText()
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
    self.items[index].LabelEnabled:Hide()
    self.items[index].LabelDisabled:Show()
    self.items[index].XButton:Hide()
end

function ADropDown:EnableItem(index)
    self.items[index]:Enable()
    self.items[index].LabelEnabled:Show()
    self.items[index].LabelDisabled:Hide()
    self.items[index].XButton:SetShown(self.xhandler ~= nil)
end

function ADropDown:CheckOneItem(index)
    for i, item in ipairs(self.items) do
        item.CheckMark:SetShown(i == index)
    end
end

function ADropDown:GetFirstCheckIndex()
    for i, item in ipairs(self.items) do
        if item.CheckMark:IsShown() then
            return i
        end
    end

    error("No items selected!")
end
