AuctipusAuctionGroupRow = CreateFrame("Button", nil, nil,
                                      "AuctipusAuctionGroupRowMetaTemplate")
AuctipusAuctionGroupRow.__index = AuctipusAuctionGroupRow

function AuctipusAuctionGroupRow:OnLoad()
    setmetatable(self, AuctipusAuctionGroupRow)
    self.ItemButton:SetScript("OnClick", function() self:OnClick() end)
    self.ItemButton:SetScript("OnEnter", function() self:OnEnterItem() end)
    self.ItemButton:SetScript("OnLeave", function() self:OnLeaveItem() end)
    self:SetScript("OnClick", function() self:OnClick() end)
    self:SetScript("OnEnter", function() self:OnEnter() end)
    self:SetScript("OnLeave", function() self:OnLeave() end)
    self:SetScript("OnEvent", function() self:OnEvent() end)
    self:RegisterEvent("MODIFIER_STATE_CHANGED")
    self.auctionGroup = nil
    self.hovering     = false
end

function AuctipusAuctionGroupRow:SetAuctionGroup(auctionGroup)
    self.auctionGroup = auctionGroup

    if auctionGroup then
        if (auctionGroup.levelColHeader == "REQ_LEVEL_ABBR" and 
            auctionGroup.level > UnitLevel("player"))
        then
            self.Level:SetText(RED_FONT_COLOR_CODE..auctionGroup.level..
                               FONT_COLOR_CODE_CLOSE)
        else
            self.Level:SetText(auctionGroup.level)
        end
        self.Level:Show()
        if #auctionGroup.unitPriceAuctions > 0 then
            self.MinBuyoutPerItem:SetMoney(
                floor(auctionGroup.unitPriceAuctions[1].unitPrice))
            self.MinBuyoutPerItem:Show()
        else
            self.MinBuyoutPerItem:Hide()
        end
        self.ItemButton:SetMouseClickEnabled(true)
    else
        self.Level:Hide()
        self.MinBuyoutPerItem:Hide()
        self.ItemButton:SetMouseClickEnabled(false)
    end

    self.ItemButton:SetAuctionGroup(auctionGroup)
end

function AuctipusAuctionGroupRow:OnClick()
    if IsModifiedClick("DRESSUP") then
        AuctipusFrame.BrowseFrame:DressupAuctionGroup(self.auctionGroup)
    else
        AuctipusFrame.BrowseFrame:SelectAuctionGroup(self.auctionGroup)
    end
end

function AuctipusAuctionGroupRow:OnEnter()
    self.hovering = true
    if IsModifiedClick("DRESSUP") then
        ShowInspectCursor()
    else
        ResetCursor()
    end
end

function AuctipusAuctionGroupRow:OnLeave()
    ResetCursor()
    self.hovering = false
end

function AuctipusAuctionGroupRow:OnEvent()
    if self.hovering then
        self:OnEnter()
    end
end

function AuctipusAuctionGroupRow:OnEnterItem()
    self:LockHighlight()
    self.ItemButton:OnEnter()
end

function AuctipusAuctionGroupRow:OnLeaveItem()
    self.ItemButton:OnLeave()
    if (not self.auctionGroup or
        AuctipusFrame.BrowseFrame.selectedAuctionGroup ~= self.auctionGroup)
    then
        self:UnlockHighlight()
    end
end
