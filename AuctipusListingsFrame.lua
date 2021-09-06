AuctipusListingsFrame = {}

function AuctipusListingsFrame:OnLoad()
    -- Instantiate all the auction rows.
    for i, row in ipairs(self.ListingRows) do
        if i == 1 then
            row:SetPoint("TOPLEFT", self, "TOPLEFT", 230, -36)
            row:SetPoint("TOPRIGHT", self, "TOPRIGHT", -40, -36)
        else
            row:SetPoint("TOPLEFT", self.ListingRows[i-1], "BOTTOMLEFT", 0, -4)
            row:SetPoint("TOPRIGHT", self.ListingRows[i-1], "BOTTOMRIGHT", 0,
                         -4)
        end
        row.CurrentBid:SetMoney(100000)
        row.Buyout:SetMoney(100000)
    end

    -- Set scripts.
    self.CancelButton:SetScript("OnClick",
        function() self:CancelAuction() end)

    -- Scroll bars.
    self.ListingsScrollFrame:SetScript("OnVerticalScroll",
        function(self2, offset)
            FauxScrollFrame_OnVerticalScroll(self2, offset, 1,
                                             function()
                                                 self:UpdateListings()
                                             end)
        end)
    self.ListingsScrollFrame.ScrollBar.scrollStep = 1
    FauxScrollFrame_Update(self.ListingsScrollFrame, 0, #self.ListingRows, 1)

    -- Status text.
    self.StatusText:SetText("Note: Auctipus currently only displays the "..
                            "first 50 auctions you have created.")

    self:UpdateControls()
end

function AuctipusListingsFrame.AUCTION_OWNED_LIST_UPDATE()
    Auctipus.dbg("AUCTION_OWNED_LIST_UPDATE")
end

function AuctipusListingsFrame.AUCTION_HOUSE_SHOW()
    local self = AuctipusFrame.ListingsFrame
    self.aopage = APage.OpenOwnerPage(0, self)
end

function AuctipusListingsFrame:UpdateControls()
    self.CancelButton:SetEnabled(
        CanCancelAuction(GetSelectedAuctionItem("owner"))
        )
end

function AuctipusListingsFrame:PageUpdated(page)
    assert(page == self.aopage)
    self:UpdateControls()
    self:UpdateListings()
end

function AuctipusListingsFrame:PageClosed(page, forced)
    assert(forced)
    assert(page == self.aopage)
    self.aopage = nil
end

function AuctipusListingsFrame:SetSelection(index)
    self.aopage:SelectItem(
        FauxScrollFrame_GetOffset(self.ListingsScrollFrame) + index)
    self:UpdateControls()
    self:UpdateListings()
end

function AuctipusListingsFrame:CancelAuction()
    CancelAuction(self.aopage:GetSelectedItem())
end

function AuctipusListingsFrame:UpdateListings()
    FauxScrollFrame_Update(self.ListingsScrollFrame,
                           #self.aopage.auctions,
                           #self.ListingRows,
                           1)

    local offset    = FauxScrollFrame_GetOffset(self.ListingsScrollFrame)
    local selection = self.aopage:GetSelectedItem()
    for i, row in ipairs(self.ListingRows) do
        row:UnlockHighlight()

        local index = offset + i
        if index <= #self.aopage.auctions then
            local auction = self.aopage.auctions[index]
            row:SetAuction(auction)

            if selection == index then
                row:LockHighlight()
            end
            row:Enable()
        else
            row:SetAuction(nil)
            row:Disable()
        end
    end
end

TGEventManager.Register(AuctipusListingsFrame)
