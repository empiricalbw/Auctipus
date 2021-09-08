AuctipusAuctionBidRow = {}

function AuctipusAuctionBidRow:OnLoad()
    self.auction = nil
end

function AuctipusAuctionBidRow:SetAuction(auction)
    self.auction = auction

    if auction then
        self.Owner.Text:SetText(auction.owner)
        self.BidPerItem:SetMoney(floor(auction.minUnitBid))
        self.BuyoutPerItem:SetMoney(floor(auction.unitPrice))
        self.CountFrame.Text:SetText("x "..auction.count.." =")
        self.BidPerItem:Show()
        self.BuyoutPerItem:Show()
        self.CountFrame:Show()
        self.BidTotal:SetMoney(auction.minBid)
        self.BuyoutTotal:SetMoney(auction.buyoutPrice)
        self:Show()
    else
        self:Hide()
    end
end
