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
--
--  Global error strings relevant to creating an auction:
--
--  ERR_AUCTION_BAG = "You cannot sell a non-empty bag."
--  ERR_AUCTION_BOUND_ITEM = "You cannot sell a soulbound item."
--  ERR_AUCTION_CONJURED_ITEM = "You cannot auction a conjured item."
--  ERR_AUCTION_ENOUGH_ITEMS = "You do not have enough items."
--  ERR_AUCTION_EQUIPPED_BAG = "You cannot sell an equipped bag."
--  ERR_AUCTION_EXPIRED_S = "Your auction of %s has expired."
--  ERR_AUCTION_LIMITED_DURATION_ITEM =
--      "You cannot auction items with a limited duration."
--  ERR_AUCTION_LOOT_ITEM = "You cannot auction a lootable item."
--  ERR_AUCTION_QUEST_ITEM = "You cannot sell a quest item."
--  ERR_AUCTION_REMOVED = "Auction cancelled."
--  ERR_AUCTION_REMOVED_S = "Your auction of %s has been cancelled by the seller."
--  ERR_AUCTION_REPAIR_ITEM = "You must repair that item before you auction it."
--  ERR_AUCTION_SOLD_S = "A buyer has been found for your auction of %s."
--  ERR_AUCTION_STARTED = "Auction created."
--  ERR_AUCTION_USED_CHARGES = "You cannot auction an item with used charges"
--  ERR_AUCTION_WRAPPED_ITEM = "You cannot auction a wrapped item."
AuctipusAuctionsFrame = {}

AUCTIPUS_CREATE_DEFAULTS = {
    perUnit = true,
    duration = 1,
}

local AUCTION_DURATION_STRINGS = {
    AUCTION_DURATION_ONE,
    AUCTION_DURATION_TWO,
    AUCTION_DURATION_THREE,
}

function AuctipusAuctionsFrame:ProcessSavedVars()
    self.PerUnitCheck:SetChecked(AUCTIPUS_CREATE_DEFAULTS.perUnit)

    AUCTIPUS_CREATE_DEFAULTS.duration = AUCTIPUS_CREATE_DEFAULTS.duration or 1
    for i, b in ipairs(self.DurationButtons) do
        b:SetChecked(i == AUCTIPUS_CREATE_DEFAULTS.duration)
    end
end

function AuctipusAuctionsFrame:OnLoad()
    -- Vars.
    self:ResetVars()

    -- Text.
    self.BidPrice.Text:SetText("Starting Price Per Unit")
    self.BuyoutPrice.Text:SetText("Buyout Price Per Unit |cff808080("..
                                  OPTIONAL..")|r")

    -- Scripts
    self:SetScript("OnShow", function() self:SetAuctionsTabShowing(true) end)
    self:SetScript("OnHide", function() self:SetAuctionsTabShowing(false) end)

    -- Edit boxes.
    Auctipus.UI.LinkEditBoxes(self)
    self.StackSizeBox:Disable()
    self.StackCountBox:Disable()

    -- Duration buttons.
    for i, b in ipairs(self.DurationButtons) do
        b.text:SetText(AUCTION_DURATION_STRINGS[i])
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

    -- Instantiate all the auction bid preview rows.
    for i, row in ipairs(self.AuctionBidRows) do
        if i == 1 then
            row:SetPoint("TOPLEFT", self, "TOPLEFT", 230, -36)
            row:SetPoint("TOPRIGHT", self, "TOPRIGHT", -40, -36)
        else
            row:SetPoint("TOPLEFT", self.AuctionBidRows[i-1], "BOTTOMLEFT", 0,
                         -4)
            row:SetPoint("TOPRIGHT", self.AuctionBidRows[i-1], "BOTTOMRIGHT", 0,
                         -4)
        end
        row.BuyoutPerItem:SetMoney(100000)
        row.BuyoutTotal:SetMoney(100000)
    end

    -- Set scripts.
    self.ItemButton:RegisterForDrag("LeftButton")
    self.ItemButton:SetScript("OnClick",
        function(f, button) self:OnItemButtonClick(button) end)
    self.ItemButton:SetScript("OnDragStart",
        function(f, button) self:OnItemButtonDrag(button) end)
    self.ItemButton:SetScript("OnReceiveDrag",
        function(f, button) self:OnItemButtonClick(button) end)
        --[[
    self.StackSizeBox:SetScript("OnTextChanged",
        function() self:OnStackSizeBoxChanged() end)
        ]]
    self.DecrementStackSizeButton:SetScript("OnClick",
        function(f, button) self:DecrementStackSize() end)
    self.IncrementStackSizeButton:SetScript("OnClick",
        function(f, button) self:IncrementStackSize() end)
    --[[
    self.StackCountBox:SetScript("OnTextChanged",
        function() self:OnStackCountBoxChanged() end)
        ]]
    self.DecrementStackCountButton:SetScript("OnClick",
        function(f, button) self:DecrementStackCount() end)
    self.IncrementStackCountButton:SetScript("OnClick",
        function(f, button) self:IncrementStackCount() end)
    self.PerUnitCheck:SetScript("OnClick",
        function(f, button) self:TogglePerUnitCheck() end)
    MoneyInputFrame_SetOnValueChangedFunc(self.BidPrice,
        function() self:UpdateControls() end)
    MoneyInputFrame_SetOnValueChangedFunc(self.BuyoutPrice,
        function() self:UpdateControls() end)
    self.CreateButton:SetScript("OnClick",
        function() self:PostAuction() end)

    -- Scroll bars.
    self.AuctionBidsScrollFrame:SetScript("OnVerticalScroll",
        function(self2, offset)
            FauxScrollFrame_OnVerticalScroll(self2, offset, 1,
                                             function()
                                                 self:UpdateComparables()
                                             end)
        end)
    self.AuctionBidsScrollFrame.ScrollBar.scrollStep = 1

    self:UpdateControls()
    self:UpdateComparables()
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
    Auctipus.dbg("OnItemButtonClick")
    if CursorHasItem() then
        ClickAuctionSellItemButton(self.ItemButton, button)
        ClearCursor()
    else
        ClickAuctionSellItemButton(self.ItemButton, button)
    end
end

function AuctipusAuctionsFrame:OnItemButtonDrag(button)
    Auctipus.dbg("OnItemButtonDrag")
    ClickAuctionSellItemButton(self.ItemButton, button)
end

function AuctipusAuctionsFrame:OnDurationButtonClick(index, button)
    AUCTIPUS_CREATE_DEFAULTS.duration = index
    for i, b in ipairs(self.DurationButtons) do
        b:SetChecked(i == AUCTIPUS_CREATE_DEFAULTS.duration)
    end
    self:UpdateControls()
end

function AuctipusAuctionsFrame.AUCTION_MULTISELL_START(numAuctions)
    Auctipus.dbg("AUCTION_MULTISELL_START: ", numAuctions)
end

function AuctipusAuctionsFrame.AUCTION_MULTISELL_UPDATE(numCreated, numAuctions)
    Auctipus.dbg("AUCTION_MULTISELL_UPDATE: "..numCreated.." / "..numAuctions)
end

function AuctipusAuctionsFrame.AUCTION_MULTISELL_FAILURE()
    Auctipus.dbg("AUCTION_MULTISELL_FAILURE")
end

function AuctipusAuctionsFrame.NEW_AUCTION_UPDATE()
    local self = AuctipusFrame.AuctionsFrame
    self.ItemButton:SetAuctionSellItem()

    local name, _, count, quality, _, _, vendorUnitPrice, maxStackSize,
        invCount, _ = GetAuctionSellItemInfo()
    Auctipus.dbg("NEW_AUCTION_UPDATE: "..tostring(name).." "..count.." "..
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

    if name ~= nil then
        self.aopage = APage.OpenListPage({text = name, exactMatch = true}, 0,
                                         "UNITPRICE", self)
    elseif self.aopage then
        self.aopage:ClosePage()
        self.aopage = nil
    end

    self:UpdateComparables()
    self:UpdateControls()
end

function AuctipusAuctionsFrame.CHAT_MSG_SYSTEM(msg)
    if msg == ERR_AUCTION_STARTED then
        Auctipus.dbg("Got auction created event.")
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
            --[[
            self.StackSizeBox:Enable()
            self.StackSizeBox:SetBackdropColor(c.r, c.g, c.b, 1)
            self.StackSizeBox:SetBackdropBorderColor(1, 1, 1, 1)
            ]]
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
            --[[
            self.StackCountBox:Enable()
            self.StackCountBox:SetBackdropColor(c.r, c.g, c.b, 1)
            self.StackCountBox:SetBackdropBorderColor(1, 1, 1, 1)
            ]]
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
end

function AuctipusAuctionsFrame:GetDeposit()
    return GetAuctionDeposit(
        AUCTIPUS_CREATE_DEFAULTS.duration,
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

--[[
function AuctipusAuctionsFrame:OnStackSizeBoxChanged()
    local newCount = self.StackSizeBox:GetNumber() or 0
    if newCount > self.maxStackSize then
        newCount = 
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
]]

function AuctipusAuctionsFrame:DecrementStackSize()
    if self.count > 1 then
        self.count = self.count - 1
        if not self.PerUnitCheck:GetChecked() then
            local ratio = self.count / (self.count + 1)
            self:SetBidPrice(floor(self:GetBidPrice() * ratio))
            self:SetBuyoutPrice(floor(self:GetBuyoutPrice() * ratio))
        end
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
    if not self.PerUnitCheck:GetChecked() then
        local ratio = self.count / (self.count - 1)
        self:SetBidPrice(floor(self:GetBidPrice() * ratio))
        self:SetBuyoutPrice(floor(self:GetBuyoutPrice() * ratio))
    end
    self:UpdateControls()
end

--[[
function AuctipusAuctionsFrame:OnStackCountBoxChanged()
    local newStackCount = self.StackCountBox:GetNumber() or 0
    if self.count * newStackCount > self.invCount then
        newStackCount = floor(self.invCount / self.count)
        self.StackCountBox:SetText(newStackCount)
        return
    end

    self.stackCount = newStackCount
    self:UpdateControls()
end
]]

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
    local bidPrice    = MoneyInputFrame_GetCopper(self.BidPrice)
    local buyoutPrice = MoneyInputFrame_GetCopper(self.BuyoutPrice)
    local perUnit     = self.PerUnitCheck:GetChecked()
    if perUnit then
        bidPrice    = bidPrice * self.count
        buyoutPrice = buyoutPrice * self.count
    end

    self.waitForNilAuction = true
    PostAuction(bidPrice, buyoutPrice, AUCTIPUS_CREATE_DEFAULTS.duration,
                self.count, self.stackCount)
end

function AuctipusAuctionsFrame:PageUpdated(page)
    assert(page == self.aopage)
    self:UpdateComparables()
end

function AuctipusAuctionsFrame:PageClosed(page, forced)
    assert(page == self.aopage)
end

function AuctipusAuctionsFrame:GetBidPrice()
    return MoneyInputFrame_GetCopper(self.BidPrice)
end

function AuctipusAuctionsFrame:GetBuyoutPrice()
    return MoneyInputFrame_GetCopper(self.BuyoutPrice)
end

function AuctipusAuctionsFrame:SetBidPrice(copper)
    MoneyInputFrame_SetCopper(self.BidPrice, copper)
end

function AuctipusAuctionsFrame:SetBuyoutPrice(copper)
    MoneyInputFrame_SetCopper(self.BuyoutPrice, copper)
end

function AuctipusAuctionsFrame:TogglePerUnitCheck()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    local perUnit = self.PerUnitCheck:GetChecked()
    AUCTIPUS_CREATE_DEFAULTS.perUnit = perUnit
    if perUnit then
        local stackBidPrice    = self:GetBidPrice()
        local stackBuyoutPrice = self:GetBuyoutPrice()
        self:SetBidPrice(floor(stackBidPrice / self.count))
        self:SetBuyoutPrice(floor(stackBuyoutPrice / self.count))
        self.BidPrice.Text:SetText("Starting Price Per Unit")
        self.BuyoutPrice.Text:SetText("Buyout Price Per Unit |cff808080("..
                                      OPTIONAL..")|r")
    else
        local unitBidPrice    = self:GetBidPrice()
        local unitBuyoutPrice = self:GetBuyoutPrice()
        self:SetBidPrice(unitBidPrice * self.count)
        self:SetBuyoutPrice(unitBuyoutPrice * self.count)
        self.BidPrice.Text:SetText("Starting Price Per Stack")
        self.BuyoutPrice.Text:SetText("Buyout Price Per Stack |cff808080("..
                                      OPTIONAL..")|r")
    end
end

function AuctipusAuctionsFrame:UpdateComparables()
    local nauctions
    if self.aopage then
        if self.aopage.auctions then
            nauctions = #self.aopage.auctions
            if nauctions > 0 then
                local lowAuction = self.aopage.auctions[1]
                local perUnit    = self.PerUnitCheck:GetChecked()
                if MoneyInputFrame_GetCopper(self.BidPrice) == 0 then
                    if perUnit then
                        self:SetBidPrice(floor(lowAuction.minUnitBid) - 1)
                    else
                        self:SetBidPrice(
                            floor(lowAuction.minUnitBid * self.count) - 1)
                    end
                end
                if MoneyInputFrame_GetCopper(self.BuyoutPrice) == 0 then
                    if perUnit then
                        self:SetBuyoutPrice(floor(lowAuction.unitPrice) - 1)
                    else
                        self:SetBuyoutPrice(
                            floor(lowAuction.unitPrice * self.count) - 1)
                    end
                end
                self.StatusText:Hide()
            else
                self.StatusText:SetText("No auctions found.")
                self.StatusText:Show()
            end
        else
            nauctions = 0
            self.StatusText:SetText("Searching...")
            self.StatusText:Show()
        end
    else
        nauctions = 0
        self.StatusText:SetText("Select item to auction.")
        self.StatusText:Show()
    end

    FauxScrollFrame_Update(self.AuctionBidsScrollFrame, nauctions,
                           #self.AuctionBidRows, 1)

    local offset = FauxScrollFrame_GetOffset(self.AuctionBidsScrollFrame)
    for i, row in ipairs(self.AuctionBidRows) do
        row:UnlockHighlight()

        local index = offset + i
        if index <= nauctions then
            local auction = self.aopage.auctions[index]
            row:SetAuction(auction)
            row:Enable()
        else
            row:SetAuction(nil)
            row:Disable()
        end
    end
end

Auctipus.EventManager.Register(AuctipusAuctionsFrame)
