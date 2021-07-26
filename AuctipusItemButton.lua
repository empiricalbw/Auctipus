AuctipusItemButton = {}

function AuctipusItemButton:OnLoad()
    self:SetScript("OnEnter", function() self:OnEnter() end)
    self:SetScript("OnLeave", function() self:OnLeave() end)
    self.auctionGroup = nil
    self.link         = nil
    self.sellInfo     = nil
end

function AuctipusItemButton:SetAuctionGroup(auctionGroup)
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

function AuctipusItemButton:SetAuctionSellItem()
    local name, texture, count, quality = GetAuctionSellItemInfo()
    if name then
        self.sellInfo = {name, texture}
        self:SetNormalTexture(texture)
        self:SetCount(count)

        local color = ITEM_QUALITY_COLORS[quality]
        self.Name:SetText(name)
        self.Name:SetVertexColor(color.r, color.g, color.b)
        self.Name:Show()
    else
        self:Clear()
    end
end

function AuctipusItemButton:SetAuction(auction)
    self.link = auction.link
    self:SetNormalTexture(auction.texture)
    self:SetCount(auction.count)

    local color = ITEM_QUALITY_COLORS[auction.quality]
    self.Name:SetText(auction.name)
    self.Name:SetVertexColor(color.r, color.g, color.b)
    self.Name:Show()
end

function AuctipusItemButton:Clear()
    self.auctionGroup = nil
    self.link         = nil
    self.sellInfo     = nil
    self:SetNormalTexture(nil)
    self.Count:Hide()
    self.Name:Hide()
end

function AuctipusItemButton:SetCount(count)
    if count > 1 then
        self.Count:SetText(count)
        self.Count:Show()
    else
        self.Count:Hide()
    end
end

function AuctipusItemButton:OnEnter()
    if self.link then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
    elseif self.sellInfo then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetAuctionSellItem()
    end
end

function AuctipusItemButton:OnLeave()
    GameTooltip_Hide()
end
