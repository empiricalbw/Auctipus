AuctipusItemButtonMixin = {}

function AuctipusItemButtonMixin:OnLoad()
    self:SetScript("OnEnter", function() self:OnEnter() end)
    self:SetScript("OnLeave", function() self:OnLeave() end)
    self.auctionGroup = nil
    self.link         = nil
    self.sellInfo     = nil
    self.count        = nil
    self._is_auctipus = true
end

function AuctipusItemButtonMixin:SetAuctionGroup(auctionGroup)
    self.auctionGroup = auctionGroup

    self.Count:Hide()
    if auctionGroup then
        self.link = auctionGroup.link
        self:SetNormalTexture(auctionGroup.texture)

        local color = ITEM_QUALITY_COLORS[auctionGroup.quality]
        self.Name:SetText(auctionGroup.name)
        self.Name:SetVertexColor(color.r, color.g, color.b)
        self.Name:Show()
    else
        self:Clear()
    end
end

function AuctipusItemButtonMixin:SetAuctionSellItem()
    local name, texture, count, quality = GetAuctionSellItemInfo()
    if name then
        self.sellInfo = {name, texture}
        self:SetNormalTexture(texture)
        self:SetCount(count)

        local color = ITEM_QUALITY_COLORS[quality]
        self.Name:SetText(name)
        if color then
            self.Name:SetVertexColor(color.r, color.g, color.b)
        end
        self.Name:Show()
    else
        self:Clear()
    end
end

function AuctipusItemButtonMixin:SetAuction(auction)
    self.link = auction.link
    self:SetNormalTexture(auction.texture)
    self:SetCount(auction.count)

    local color = ITEM_QUALITY_COLORS[auction.quality]
    self.Name:SetText(auction.name)
    if color then
        self.Name:SetVertexColor(color.r, color.g, color.b)
    end
    self.Name:Show()
end

function AuctipusItemButtonMixin:SetHistoryGroup(historyGroup)
    self.historyGroup = historyGroup

    self.Count:Hide()
    if historyGroup then
        self.link = historyGroup.link
        self:SetNormalTexture(historyGroup.texture)

        local color = historyGroup.color
        self.Name:SetText(historyGroup.name)
        self.Name:SetVertexColor(color.r, color.g, color.b)
        self.Name:Show()
    else
        self:Clear()
    end
end

function AuctipusItemButtonMixin:Clear()
    self.auctionGroup = nil
    self.link         = nil
    self.sellInfo     = nil
    self.count        = nil
    self:SetNormalTexture(nil)
    self.Count:Hide()
    self.Name:Hide()
end

function AuctipusItemButtonMixin:SetCount(count)
    if count > 1 then
        self.Count:SetText(count)
        self.Count:Show()
    else
        self.Count:Hide()
    end
    self.count = count
end

function AuctipusItemButtonMixin:UpdateTooltip()
    if self.link then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        if IsModifiedClick("DRESSUP") then
            ShowInspectCursor()
        else
            ResetCursor()
        end
    elseif self.sellInfo then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetAuctionSellItem()
        ResetCursor()
    else
        ResetCursor()
    end
end

function AuctipusItemButtonMixin:OnEnter()
    self:UpdateTooltip()
end

function AuctipusItemButtonMixin:OnLeave()
    GameTooltip_Hide()
end
