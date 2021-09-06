AuctipusAuctionRow = {}

function AuctipusAuctionRow:OnLoad()
    self:SetScript("OnClick", function(frame, button) self:OnClick(button) end)
    self.auction = nil
end

function AuctipusAuctionRow:SetAuction(auction)
    self.auction = auction

    if auction then
        self.Owner.Text:SetText(auction.owner)
        if auction.auctionGroup.maxCount == 1 then
            self.BuyoutPerItem:Hide()
            self.CountFrame:Hide()
        else
            self.BuyoutPerItem:SetMoney(floor(auction.unitPrice))
            self.CountFrame.Text:SetText("x "..auction.count.." =")
            self.BuyoutPerItem:Show()
            self.CountFrame:Show()
        end
        self.BuyoutTotal:SetMoney(auction.buyoutPrice)
        self:Show()
    else
        self:Hide()
    end
end

function AuctipusAuctionRow:OnClick(button)
    if button == "LeftButton" then
        if IsShiftKeyDown() then
            AuctipusFrame.BrowseFrame:ToggleAuctionSelection(self.auction)
        else
            AuctipusFrame.BrowseFrame:SetAuctionSelection(self.auction)
        end
    end
end
