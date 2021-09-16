AuctipusAuctionRowMixin = {}

function AuctipusAuctionRowMixin:OnLoad()
    self:SetScript("OnClick", function(frame, button) self:OnClick(button) end)
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    self.DisabledButton:SetScript("OnClick",
        function(frame, button) self:OnDisabledClick(button) end)
    self.DisabledButton:RegisterForClicks("RightButtonUp")
    self.auction = nil
end

function AuctipusAuctionRowMixin:SetAuction(auction)
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

function AuctipusAuctionRowMixin:OnClick(button)
    if button == "LeftButton" then
        if IsShiftKeyDown() then
            AuctipusFrame.BrowseFrame:ToggleAuctionSelection(self.auction)
        else
            AuctipusFrame.BrowseFrame:SetAuctionSelection(self.auction)
        end
    elseif button == "RightButton" then
        AuctipusFrame.BrowseFrame:ShowAuctionMenu(self)
    end
end

function AuctipusAuctionRowMixin:OnDisabledClick(button)
    assert(button == "RightButton")
    AuctipusFrame.BrowseFrame:ShowAuctionMenu(self)
end

function AuctipusAuctionRowMixin:DisableRow()
    self:SetAlpha(0.5)
    self:Disable()
    self.DisabledButton:Show()
end

function AuctipusAuctionRowMixin:EnableRow()
    self.DisabledButton:Hide()
    self:SetAlpha(1)
    self:Enable()
end
