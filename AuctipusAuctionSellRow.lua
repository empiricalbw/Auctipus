AuctipusAuctionSellRow = {}

local AUCTION_DURATION = {
    AUCTION_TIME_LEFT1,
    AUCTION_TIME_LEFT2,
    AUCTION_TIME_LEFT3,
    AUCTION_TIME_LEFT4,
}

local AUCTION_STATUS_UNSOLD = 0
local AUCTION_STATUS_SOLD   = 1

function AuctipusAuctionSellRow:OnLoad()
    self.ItemButton:SetHeight(self:GetHeight())
    self.ItemButton:SetWidth(self:GetHeight())
end

function AuctipusAuctionSellRow:OnClick()
    AuctipusFrame.AuctionsFrame:SetSelection(self:GetID())
end

function AuctipusAuctionSellRow:SetAuction(auction)
    local durationText

    if auction then
        self.ItemButton:SetAuction(auction)
        if auction.saleStatus == AUCTION_STATUS_SOLD then
            durationText = "Sold"
        else
            durationText = AUCTION_DURATION[auction.duration]
        end
        self.Duration:SetText(durationText)

        local bidder = auction.bidderFullName or auction.highBidder
        if not bidder then
            bidder = RED_FONT_COLOR_CODE..NO_BIDS..FONT_COLOR_CODE_CLOSE
        end
        self.HighBidder:SetText(bidder)
        self.CurrentBid:SetMoney(max(auction.minBid, auction.bidAmount))
        self.Buyout:SetMoney(auction.buyoutPrice)
        self.Duration:Show()
        self.HighBidder:Show()
        self.CurrentBid:Show()
        self.Buyout:Show()
    else
        self.ItemButton:Clear()
        self.Duration:Hide()
        self.HighBidder:Hide()
        self.CurrentBid:Hide()
        self.Buyout:Hide()
    end
end
