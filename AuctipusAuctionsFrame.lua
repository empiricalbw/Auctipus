-- GetAuctionSellItemInfo() returns the following:
--
--  name
--  texture
--  count
--  quality
--  canUse
--  vendorPrice
--  vendorPricePerUnit
--  maxSizeOfOneStack
--  totalCountInInventoy
--  itemID
--
-- PostAuction() takes the following:
--
--  bidPrice
--  buyoutPrice
--  duration (1=12h, 2=24h, 3=48h)
--  sizeOfStackToPost
--  numberOfStacksToPost
AuctipusAuctionsFrame = CreateFrame("Frame", nil, nil,
                                    "AuctipusAuctionsFrameMetaTemplate")
AuctipusAuctionsFrame.__index = AuctipusAuctionsFrame

local AUCTION_DURATION_STRINGS = {
    AUCTION_DURATION_ONE,
    AUCTION_DURATION_TWO,
    AUCTION_DURATION_THREE,
}

function AuctipusAuctionsFrame:OnLoad()
    setmetatable(self, AuctipusAuctionsFrame)

    -- Vars.
    self:ResetVars()

    -- Text.
    self.BuyoutPrice.Text:SetText(BUYOUT_PRICE.." |cff808080("..OPTIONAL..")|r")

    -- Scripts
    self:SetScript("OnShow", function() self:SetAuctionsTabShowing(true) end)
    self:SetScript("OnHide", function() self:SetAuctionsTabShowing(false) end)

    -- Edit boxes.
    AuctipusLinkEditBoxes(self)

    -- Duration buttons.
    self.selectedDuration = 1
    for i, b in ipairs(self.DurationButtons) do
        b.text:SetText(AUCTION_DURATION_STRINGS[i])
        b:SetChecked(i == self.selectedDuration)
        b:SetScript("OnClick",
                    function(f, button)
                        self:OnDurationButtonClick(i, button)
                    end)
    end

    -- Money boxes.
    MoneyInputFrame_SetPreviousFocus(self.BidPrice, self.BuyoutPrice.copper)
    MoneyInputFrame_SetNextFocus(self.BidPrice, self.BuyoutPrice.gold)
    MoneyInputFrame_SetPreviousFocus(self.BuyoutPrice, self.BidPrice.copper)
    MoneyInputFrame_SetNextFocus(self.BuyoutPrice, self.BidPrice.gold)

    -- Instantiate all the auction rows.
    for i, row in ipairs(self.AuctionRows) do
        if i == 1 then
            row:SetPoint("TOPLEFT", self, "TOPLEFT", 230, -36)
            row:SetPoint("TOPRIGHT", self, "TOPRIGHT", -40, -36)
        else
            row:SetPoint("TOPLEFT", self.AuctionRows[i-1], "BOTTOMLEFT", 0, -4)
            row:SetPoint("TOPRIGHT", self.AuctionRows[i-1], "BOTTOMRIGHT", 0,
                         -4)
        end
        row.CurrentBid:SetMoney(100000)
        row.Buyout:SetMoney(100000)
    end

    -- Set scripts.
    self.ItemButton:RegisterForDrag("LeftButton")
    self.ItemButton:SetScript("OnClick",
        function(f, button) self:OnItemButtonClick(button) end)
    self.ItemButton:SetScript("OnDragStart",
        function(f, button) self:OnItemButtonDrag(button) end)
    self.ItemButton:SetScript("OnReceiveDrag",
        function(f, button) self:OnItemButtonClick(button) end)
    self.StackSizeBox:SetScript("OnTextChanged",
        function() self:OnStackSizeBoxChanged() end)
    self.DecrementStackSizeButton:SetScript("OnClick",
        function(f, button) self:DecrementStackSize() end)
    self.IncrementStackSizeButton:SetScript("OnClick",
        function(f, button) self:IncrementStackSize() end)
    self.StackCountBox:SetScript("OnTextChanged",
        function() self:OnStackCountBoxChanged() end)
    self.DecrementStackCountButton:SetScript("OnClick",
        function(f, button) self:DecrementStackCount() end)
    self.IncrementStackCountButton:SetScript("OnClick",
        function(f, button) self:IncrementStackCount() end)
    MoneyInputFrame_SetOnValueChangedFunc(self.BidPrice,
        function() self:UpdateControls() end)
    MoneyInputFrame_SetOnValueChangedFunc(self.BuyoutPrice,
        function() self:UpdateControls() end)
    self.CreateButton:SetScript("OnClick",
        function() self:PostAuction() end)
    self.CancelButton:SetScript("OnClick",
        function() self:CancelAuction() end)

    -- Scroll bars.
    self.AuctionScrollFrame:SetScript("OnVerticalScroll",
        function(self2, offset)
            FauxScrollFrame_OnVerticalScroll(self2, offset, 1,
                                             function()
                                                 self:UpdateAuctions()
                                             end)
        end)
    self.AuctionScrollFrame.ScrollBar.scrollStep = 1
    FauxScrollFrame_Update(self.AuctionScrollFrame, 0, #self.AuctionRows, 1)

    self:UpdateControls()
end

function AuctipusAuctionsFrame:ResetVars()
    self.name              = nil
    self.count             = 0
    self.quality           = nil
    self.vendorUnitPrice   = 0
    self.stackCount        = 0
    self.maxStackSize      = 0
    self.invCount          = 0
    self.waitForNilAuction = false
end

function AuctipusAuctionsFrame:SetAuctionsTabShowing(showing)
    SetAuctionsTabShowing(showing)
end

function AuctipusAuctionsFrame:OnItemButtonClick(button)
    print("OnItemButtonClick")
    if CursorHasItem() then
        ClickAuctionSellItemButton(self.ItemButton, button)
        ClearCursor()
    else
        ClickAuctionSellItemButton(self.ItemButton, button)
    end
end

function AuctipusAuctionsFrame:OnItemButtonDrag(button)
    print("OnItemButtonDrag")
    ClickAuctionSellItemButton(self.ItemButton, button)
end

function AuctipusAuctionsFrame:OnDurationButtonClick(index, button)
    self.selectedDuration = index
    for i, b in ipairs(self.DurationButtons) do
        b:SetChecked(i == self.selectedDuration)
    end
    self:UpdateControls()
end

function AuctipusAuctionsFrame.AUCTION_OWNED_LIST_UPDATE()
    print("AUCTION_OWNED_LIST_UPDATE")
end

function AuctipusAuctionsFrame.AUCTION_MULTISELL_START(numAuctions)
    print("AUCTION_MULTISELL_START: ",numAuctions)
end

function AuctipusAuctionsFrame.AUCTION_MULTISELL_UPDATE(numCreated, numAuctions)
    print("AUCTION_MULTISELL_UPDATE: "..numCreated.." / "..numAuctions)
end

function AuctipusAuctionsFrame.AUCTION_MULTISELL_FAILURE()
    print("AUCTION_MULTISELL_FAILURE")
end

function AuctipusAuctionsFrame.AUCTION_HOUSE_SHOW()
    local self = AuctipusFrame.AuctionsFrame
    APage:OpenOwnerPage(0, self)
end

function AuctipusAuctionsFrame.NEW_AUCTION_UPDATE()
    local self = AuctipusFrame.AuctionsFrame
    self.ItemButton:SetAuctionSellItem()

    local name, _, count, quality, _, _, vendorUnitPrice, maxStackSize,
        invCount, _ = GetAuctionSellItemInfo()
    print("NEW_AUCTION_UPDATE: "..tostring(name).." "..count.." "..
          maxStackSize.." "..invCount)
    self.name            = name
    self.count           = count
    self.quality         = quality
    self.vendorUnitPrice = vendorUnitPrice
    self.stackCount      = 1
    self.maxStackSize    = maxStackSize
    self.invCount        = invCount
    MoneyInputFrame_ResetMoney(self.BidPrice)
    MoneyInputFrame_ResetMoney(self.BuyoutPrice)

    if self.waitForNilAuction and self.name == nil then
        self.waitForNilAuction = false
    end

    self:UpdateControls()
end

function AuctipusAuctionsFrame.CHAT_MSG_SYSTEM(msg)
    if msg == ERR_AUCTION_STARTED then
        Auctipus.info("Got auction created event.")
    end
end

function AuctipusAuctionsFrame:UpdateControls()
    if not self.waitForNilAuction and self.name then
        local units = self.count * self.stackCount

        self.ItemButton:SetCount(self.count)

        local c = TOOLTIP_DEFAULT_BACKGROUND_COLOR
        self.StackSizeBox:SetText(self.count)
        if self.maxStackSize > 1 then
            if units + self.stackCount <= self.invCount and
               self.count < self.maxStackSize then
                self.IncrementStackSizeButton:Enable()
            else
                self.IncrementStackSizeButton:Disable()
            end
            if self.count > 1 then
                self.DecrementStackSizeButton:Enable()
            else
                self.DecrementStackSizeButton:Disable()
            end
        else
            self.DecrementStackSizeButton:Disable()
            self.IncrementStackSizeButton:Disable()
        end

        if self.DecrementStackSizeButton:IsEnabled() or
           self.IncrementStackSizeButton:IsEnabled()
        then
            self.StackSizeBox:Enable()
            self.StackSizeBox:SetBackdropColor(c.r, c.g, c.b, 1)
            self.StackSizeBox:SetBackdropBorderColor(1, 1, 1, 1)
        else
            self.StackSizeBox:Disable()
            self.StackSizeBox:SetBackdropColor(0, 0, 0, 0)
            self.StackSizeBox:SetBackdropBorderColor(0, 0, 0, 0)
        end

        self.StackCountBox:SetText(self.stackCount)
        if units + self.count <= self.invCount then
            self.IncrementStackCountButton:Enable()
        else
            self.IncrementStackCountButton:Disable()
        end
        if self.stackCount > 1 then
            self.DecrementStackCountButton:Enable()
        else
            self.DecrementStackCountButton:Disable()
        end

        if self.IncrementStackCountButton:IsEnabled() or
           self.DecrementStackCountButton:IsEnabled()
        then
            self.StackCountBox:Enable()
            self.StackCountBox:SetBackdropColor(c.r, c.g, c.b, 1)
            self.StackCountBox:SetBackdropBorderColor(1, 1, 1, 1)
        else
            self.StackCountBox:Disable()
            self.StackCountBox:SetBackdropColor(0, 0, 0, 0)
            self.StackCountBox:SetBackdropBorderColor(0, 0, 0, 0)
        end

        self.VendorPrice:SetMoney(units * self.vendorUnitPrice)
        self.DepositPrice:SetMoney(self:GetDeposit())
        self.CreateButton:SetEnabled(self:ValidateAuction())
    else
        self.ItemButton.Name:Hide()
        self.StackSizeBox:Disable()
        self.StackSizeBox:SetBackdropColor(0, 0, 0, 0)
        self.StackSizeBox:SetBackdropBorderColor(0, 0, 0, 0)
        self.StackCountBox:Disable()
        self.StackCountBox:SetBackdropColor(0, 0, 0, 0)
        self.StackCountBox:SetBackdropBorderColor(0, 0, 0, 0)
        self.DecrementStackSizeButton:Disable()
        self.IncrementStackSizeButton:Disable()
        self.IncrementStackCountButton:Disable()
        self.DecrementStackCountButton:Disable()
        self.VendorPrice:SetMoney(0)
        self.DepositPrice:SetMoney(0)
        self.CreateButton:Disable()
    end

    self.CancelButton:SetEnabled(
        not self.waitForNilAuction and
        CanCancelAuction(GetSelectedAuctionItem("owner"))
        )
end

function AuctipusAuctionsFrame:GetDeposit()
    return GetAuctionDeposit(
        self.selectedDuration,
        MoneyInputFrame_GetCopper(self.BidPrice),
        MoneyInputFrame_GetCopper(self.BuyoutPrice),
        self.count,
        self.stackCount)
end

function AuctipusAuctionsFrame:ValidateAuction()
    local bidPrice = MoneyInputFrame_GetCopper(self.BidPrice)
    if bidPrice <= 0 then
        return false
    end

    local buyoutPrice = MoneyInputFrame_GetCopper(self.BuyoutPrice)
    if buyoutPrice > 0 and bidPrice > buyoutPrice then
        return false
    end

    if self:GetDeposit() > GetMoney() then
        return false
    end

    return true
end

function AuctipusAuctionsFrame:OnStackSizeBoxChanged()
    local newCount = self.StackSizeBox:GetNumber() or 0
    if newCount > self.maxStackSize then
        self.StackSizeBox:SetText(self.maxStackSize)
        return
    end
    if newCount * self.stackCount > self.invCount then
        newCount = floor(self.invCount / self.stackCount)
        self.StackSizeBox:SetText(newCount)
        return
    end

    self.count = newCount
    self:UpdateControls()
end

function AuctipusAuctionsFrame:DecrementStackSize()
    if self.count > 1 then
        self.count = self.count - 1
    end
    self:UpdateControls()
end

function AuctipusAuctionsFrame:IncrementStackSize()
    if self.count >= self.maxStackSize then
        return
    end
    if (self.count + 1) * self.stackCount > self.invCount then
        return
    end
    self.count = self.count + 1
    self:UpdateControls()
end

function AuctipusAuctionsFrame:OnStackCountBoxChanged()
end

function AuctipusAuctionsFrame:DecrementStackCount()
    if self.stackCount > 1 then
        self.stackCount = self.stackCount - 1
    end
    self:UpdateControls()
end

function AuctipusAuctionsFrame:IncrementStackCount()
    if self.count * (self.stackCount + 1) > self.invCount then
        return
    end
    self.stackCount = self.stackCount + 1
    self:UpdateControls()
end

function AuctipusAuctionsFrame:PostAuction()
    local bidPrice         = MoneyInputFrame_GetCopper(self.BidPrice)
    local buyoutPrice      = MoneyInputFrame_GetCopper(self.BuyoutPrice)
    self.waitForNilAuction = true
    PostAuction(bidPrice, buyoutPrice, self.selectedDuration, self.count,
                self.stackCount)
end

function AuctipusAuctionsFrame:PageOpened(page)
    self.aopage = page
end

function AuctipusAuctionsFrame:PageUpdated(page)
    assert(page == self.aopage)
    self:UpdateControls()
    self:UpdateAuctions()
end

function AuctipusAuctionsFrame:PageClosed(page)
    assert(page == self.aopage)
    self.aopage = nil
end

function AuctipusAuctionsFrame:SetSelection(index)
    self.aopage:SelectItem(
        FauxScrollFrame_GetOffset(self.AuctionScrollFrame) + index)
    self:UpdateControls()
    self:UpdateAuctions()
end

function AuctipusAuctionsFrame:CancelAuction()
    CancelAuction(self.aopage:GetSelectedItem())
end

function AuctipusAuctionsFrame:UpdateAuctions()
    FauxScrollFrame_Update(self.AuctionScrollFrame,
                           #self.aopage.auctions,
                           #self.AuctionRows,
                           1)

    local offset    = FauxScrollFrame_GetOffset(self.AuctionScrollFrame)
    local selection = self.aopage:GetSelectedItem()
    for i, row in ipairs(self.AuctionRows) do
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

TGEventManager.Register(AuctipusAuctionsFrame)
