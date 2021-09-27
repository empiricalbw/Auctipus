AuctipusBrowseFrame = {}

function AuctipusBrowseFrame:OnLoad()
    -- Variables.
    self.selectedAuctionGroup = nil
    self.selectedAuctions     = Auctipus.Set:New()
    self.purchasedAuctions    = Auctipus.Set:New()
    self.scan                 = nil
    self.auctionMenuRow       = nil

    -- Instantiate all the result rows.
    for i, row in ipairs(self.AuctionGroupRows) do
        if i == 1 then
            row:SetPoint("TOPLEFT", self.SearchBoxLabel, "BOTTOMLEFT", 16, -21)
        else
            row:SetPoint("TOPLEFT", self.AuctionGroupRows[i-1], "BOTTOMLEFT",
                         0, -6)
        end
        row:SetAuctionGroup(nil)
    end

    -- Instantiate all the auction rows.
    for i, row in ipairs(self.AuctionRows) do
        if i == 1 then
            row:SetPoint("TOPLEFT", self.AuctionGroupRows[1], "TOPRIGHT", 30, 0)
        else
            row:SetPoint("TOPLEFT", self.AuctionRows[i-1], "BOTTOMLEFT", 0, 0)
        end
        row:SetAuction(nil)
    end

    -- Edit boxes.
    Auctipus.UI.LinkEditBoxes(self)
    for i, e in ipairs(self.EditBoxes) do
        e:SetScript("OnEnterPressed", function() self:DoSearch() end)
    end

    -- Handle shift-clicking items into the search field.  We can't modify the
    -- return value of ChatEdit_InsertLink(); without modifying the return
    -- value you can't say you handled the event and therefore if the shift-
    -- click was from a stack in your inventory then that tries to split the
    -- stack.  So, we also hook ContainerFrameItemButton_OnModifiedClick() to
    -- hide the stack-splitting window if it opens up.
    hooksecurefunc("ChatEdit_InsertLink",
        function(link) self:OnChatEdit_InsertLink(link) end)
    hooksecurefunc("ContainerFrameItemButton_OnModifiedClick",
        function(f, button) self:OnContainerModifiedClick(f) end)

    -- Rarity dropdown.
    local config = {
        handler = function(index, selected)
                    self:OnRarityDropDownClick(index, selected)
                  end,
        width   = 100,
        rows    = #ITEM_QUALITY_COLORS - 2,
        anchor  = {point="TOPLEFT",
                   relativeTo=self.RarityDropDownButton,
                   relativePoint="BOTTOMLEFT",
                   dx=0,
                   dy=0,
                   },
        items   = {ALL},
    }
    for i=0, #ITEM_QUALITY_COLORS - 4 do
        table.insert(config.items, _G["ITEM_QUALITY"..i.."_DESC"])
    end
    self.RarityDropDownMenu = Auctipus.DropDown:New(config)
    self.RarityDropDownMenu:CheckOneItem(1)
    self.RarityDropDownButton.Button:SetScript("OnClick",
        function()
            self.RarityDropDownMenu:Toggle()
            self.CategoryDropDown:Hide()
        end)
    self.RarityDropDownButton.LabelWhite:SetText(config.items[1])

    -- Paths dropdown.
    local config = {
        handler = function(index, selected)
                    self:OnCategoryDropDownClick(index, selected)
                  end,
        width   = 250,
        rows    = 45,
        anchor  = {point="TOPLEFT",
                   relativeTo=self.CategoriesFrame,
                   relativePoint="BOTTOMLEFT",
                   dx=0,
                   dy=0,
                   },
        items   = {},
    }
    for i, p in ipairs(Auctipus.Paths.Generate()) do
        table.insert(config.items, p.name)
    end
    self.CategoryDropDown = Auctipus.CategoryMenu:New(config)
    self.CategoriesFrame.Button:SetScript("OnClick",
        function()
            self.CategoryDropDown:Toggle()
            self.RarityDropDownMenu:Hide()
        end)
    self.CategoriesFrame.LabelGold:SetText("Categories")

    -- Ignore dropdown.
    local config2 = {
        handler = function(index)
                    self:OnAuctionRowDropDownClick(index)
                  end,
        width   = 150,
        rows    = 3,
        items   = {"",
                   "Ignore Seller",
                   "Stop Ignoring Seller",
                   }
    }
    self.AuctionRowDropDown = Auctipus.DropDown:New(config2)
    self.AuctionRowDropDown:SetItemTitle(1)

    -- Search button.
    self.SearchButton:SetScript("OnClick", function() self:DoSearch() end)

    -- Smart select field.
    self.SmartSelect.Input:Init(0, 0,
        function(v) self:SelectOptimalAuctions(v) end)

    -- Buy button.
    local b = self.BuyButton
    b:SetScript("OnClick", function() self:DoBuy() end)
    b:Disable()

    -- Scroll bars.
    self.AuctionGroupScrollFrame:SetScript("OnVerticalScroll",
        function(self2, offset)
            FauxScrollFrame_OnVerticalScroll(self2, offset, 1,
                                             function()
                                                 self:UpdateAuctionGroups()
                                             end)
        end)
    self.AuctionGroupScrollFrame.ScrollBar.scrollStep = 1
    self:UpdateAuctionGroups()
    self.AuctionScrollFrame:SetScript("OnVerticalScroll",
        function(self2, offset)
            FauxScrollFrame_OnVerticalScroll(self2, offset, 1,
                                             function()
                                                 self:UpdateAuctions()
                                             end)
        end)
    self.AuctionScrollFrame.ScrollBar.scrollStep = 1
    self:UpdateAuctions()

    -- Sort labels.
    self.UnitCostSort.Text:SetJustifyH("RIGHT")
    self.BuyoutSort.Text:SetJustifyH("RIGHT")

    -- Status text.
    self.StatusText:SetText("Submit a search query.")
    self:HideBuyControls()

    -- Cleanup upon hiding.
    self:SetScript("OnHide", function() self:OnHide() end)
end

function AuctipusBrowseFrame:HideBuyControls()
    self.SelectionInfo:Hide()
    self.SmartSelect:Hide()
    self.BuyButton:Hide()
end

function AuctipusBrowseFrame:ShowBuyControls()
    self.SelectionInfo:Show()
    self.SmartSelect:Show()
    self.BuyButton:Show()
end

function AuctipusBrowseFrame.AUCTION_HOUSE_CLOSED()
    local self = AuctipusFrame.BrowseFrame
    self:ClearSearch()
    self.CategoryDropDown:ClearSelection()
end

function AuctipusBrowseFrame:OnHide()
    self.CategoryDropDown:Hide()
    self.RarityDropDownMenu:Hide()
end

function AuctipusBrowseFrame:OnChatEdit_InsertLink(link)
    if link and self:IsVisible() then
        local name = Auctipus.Link.GetLinkName(link)
        self.SearchBox:SetText(name)
        self.CategoryDropDown:ClearSelection()
        self.MinLvlBox:SetText("")
        self.MaxLvlBox:SetText("")
        self.RarityDropDownMenu:CheckOneItem(1)
        self.RarityDropDownButton.LabelWhite:SetText(
            self.RarityDropDownMenu:GetItemText(1))
        self:DoSearch()
    end
end

function AuctipusBrowseFrame:OnContainerModifiedClick(f)
    if self:IsVisible() then
        StackSplitFrame:Hide()
    end
end

function AuctipusBrowseFrame:OnRarityDropDownClick(index, selected)
    self.RarityDropDownMenu:CheckOneItem(index)
    self.RarityDropDownMenu:Hide()
    self.RarityDropDownButton.LabelWhite:SetText(
        self.RarityDropDownMenu:GetItemText(index))
end

function AuctipusBrowseFrame:OnCategoryDropDownClick(index, selected)
    local classID, subClassID, invType = unpack(Auctipus.PATHS[index])
    if subClassID then
        -- If a subclass is selected, then we can only allow selections that
        -- are peers of the subclass or in parent nodes.
        for i, path in ipairs(Auctipus.PATHS) do
            if path[1] ~= classID then
                self.CategoryDropDown:SetItemEnabled(i, not selected)
            end
        end
    else
        -- If no subclass is selected, then we can allow any child node or any
        -- peer class.
        for i, path in ipairs(Auctipus.PATHS) do
            if path[1] ~= classID and path[2] ~= nil then
                self.CategoryDropDown:SetItemEnabled(i, not selected)
            end
        end
    end
end

function AuctipusBrowseFrame:ShowAuctionMenu(auctionRow)
    if self.auctionMenuRow == auctionRow then
        self:HideAuctionMenu()
        return
    end

    local seller  = auctionRow.auction.owner
    local ignored = auctionRow.auction:IsIgnored()
    self.AuctionRowDropDown:SetItemText(1, seller)
    self.AuctionRowDropDown:SetItemEnabled(2, not ignored)
    self.AuctionRowDropDown:SetItemEnabled(3, ignored)
    self.AuctionRowDropDown:Show({point         = "TOPLEFT",
                                  relativeTo    = auctionRow,
                                  relativePoint = "BOTTOMLEFT",
                                  dx            = 10,
                                  dy            = -5,
                                  })
    self.auctionMenuRow = auctionRow
end

function AuctipusBrowseFrame:HideAuctionMenu()
    self.auctionMenuRow = nil
    self.AuctionRowDropDown:Hide()
end

function AuctipusBrowseFrame:OnAuctionRowDropDownClick(index)
    local seller = self.AuctionRowDropDown:GetItemText(1)
    AUCTIPUS_IGNORED_SELLERS[seller] = (index == 2) or nil
    self:HideAuctionMenu()
    self:AvailableAuctionsChanged()

    local prevFirst = self.selectedAuctions:First()
    local removed   = {}
    for a, _ in pairs(self.selectedAuctions.elems) do
        if a.owner == seller then
            table.insert(removed, a)
        end
    end
    for i, a in pairs(removed) do
        self.selectedAuctions:Remove(a)
    end
    self:UpdateAuctions()

    local first = self.selectedAuctions:First()
    if prevFirst ~= first then
        self.BuyButton:Disable()
        if first ~= nil then
            first.auctionGroup.searcher:FindAuction(first, self)
        end
    end
end

function AuctipusBrowseFrame:ClearScan()
    self.selectedAuctionGroup = nil
    self.scan = nil
    self:ClearSearch()
end

function AuctipusBrowseFrame:ClearSearch()
    self.selectedAuctions:Clear()
    self.purchasedAuctions:Clear()
    self.BuyButton:Disable()
    self:UpdateAuctionGroups()
    self:UpdateAuctions()
end

function AuctipusBrowseFrame:DoSearch()
    if not self.SearchButton:IsEnabled() then
        return
    end

    local query = {
        text       = self.SearchBox:GetText(),
        minLevel   = self.MinLvlBox:GetNumber(),
        maxLevel   = self.MaxLvlBox:GetNumber(),
        rarity     = self.RarityDropDownMenu:GetFirstCheckIndex() - 2,
        exactMatch = false,
        usable     = self.CanUseCheckButton:GetChecked(),
        filters    = {},
    }

    local selection = self.CategoryDropDown:GetSelection()
    for _, index in ipairs(selection) do
        local classID, subClassID, invType = unpack(Auctipus.PATHS[index])
        local filter = {
            classID       = classID,
            subClassID    = subClassID,
            inventoryType = invType,
        }
        table.insert(query.filters, filter)
    end

    self:ClearScan()

    self.StatusText:SetText("Searching...")
    self.StatusText:Show()
    self:HideBuyControls()
    self.scan = Auctipus.Scan:New({query}, self)
    for i, e in ipairs(self.EditBoxes) do
        e:ClearFocus()
    end
    self.SearchButton:Disable()
    self.CategoryDropDown:Hide()
    self.RarityDropDownMenu:Hide()
end

function AuctipusBrowseFrame:ScanProgress(scan, page, totalPages)
    self.StatusText:SetText("Searching ("..page.." / "..totalPages..")")
end

function AuctipusBrowseFrame:ScanComplete(scan)
    assert(self.scan == scan)
    Auctipus.History:ScanComplete(scan)

    local auctionsPerSecond = #scan.auctions / scan.elapsedTime
    Auctipus.info("Scan complete.  Found "..#scan.auctions..
                  " total in "..string.format("%.2f", scan.elapsedTime)..
                  " seconds ("..string.format("%.2f", auctionsPerSecond)..
                  " auctions/second)")
    Auctipus.info("Found "..#scan.auctionGroups.." unique groups.")

    self.SearchButton:Enable()
 
    for i, ag in ipairs(scan.auctionGroups) do
        ag:SortByBuyout()
    end

    local auctionGroup = nil
    if #scan.auctionGroups > 0 then
        auctionGroup = scan.auctionGroups[1]
    end
    self:SelectAuctionGroup(auctionGroup)
end

function AuctipusBrowseFrame:ScanAborted(scan)
    assert(self.scan == scan)
    self.scan = nil
    self.SearchButton:Enable()
end

function AuctipusBrowseFrame:DressupAuctionGroup(auctionGroup)
    DressUpItemLink(auctionGroup.link)
end

function AuctipusBrowseFrame:SelectAuctionGroup(auctionGroup)
    if self.selectedAuctionGroup then
        Auctipus.dbg("Resetting searcher...")
        self.selectedAuctionGroup.searcher:Reset()
    end

    self.selectedAuctionGroup = auctionGroup

    if auctionGroup then
        self.SmartSelect.Input:SetMax(auctionGroup.buyableCount)
        self.SmartSelect.Input:SetValue(0)
    end
    self:ClearSearch()
end

function AuctipusBrowseFrame:UpdateAuctionGroups()
    local nauctionGroups
    if self.scan then
        nauctionGroups = #self.scan.auctionGroups
        if nauctionGroups > 0 then
            if #self.selectedAuctionGroup.unitPriceAuctions then
                self.StatusText:Hide()
                self:ShowBuyControls()
            else
                self.StatusText:SetText("All results are bid-only auctions.")
                self.StatusText:Show()
                self:HideBuyControls()
            end
        else
            self.StatusText:SetText("No auctions found.")
            self.StatusText:Show()
            self:HideBuyControls()
        end
    else
        nauctionGroups = 0
        self.StatusText:SetText("Enter a search query.")
        self.StatusText:Show()
        self:HideBuyControls()
    end

    FauxScrollFrame_Update(self.AuctionGroupScrollFrame, nauctionGroups,
                           #self.AuctionGroupRows, 1)

    local offset = FauxScrollFrame_GetOffset(self.AuctionGroupScrollFrame)
    for i, row in ipairs(self.AuctionGroupRows) do
        row:UnlockHighlight()

        local index = offset + i
        if index <= nauctionGroups then
            local auctionGroup = self.scan.auctionGroups[index]
            row:SetAuctionGroup(auctionGroup)

            if auctionGroup == self.selectedAuctionGroup then
                row:LockHighlight()
            end
            row:Enable()
        else
            row:SetAuctionGroup(nil)
            row:Disable()
        end
    end
end

function AuctipusBrowseFrame:SetAuctionSelection(auction)
    self.selectedAuctions:Clear()
    self:ToggleAuctionSelection(auction)
end

function AuctipusBrowseFrame:ToggleAuctionSelection(auction)
    self:HideAuctionMenu()
    local prevFirst = self.selectedAuctions:First()
    if self.selectedAuctions:Contains(auction) then
        self.selectedAuctions:Remove(auction)
    else
        self.selectedAuctions:Insert(auction)
    end
    self.selectedAuctions:Sort(Auctipus.Auction.LTUnitPrice)
    self:UpdateAuctions()

    local first = self.selectedAuctions:First()
    if prevFirst ~= first then
        self.BuyButton:Disable()
        if first ~= nil then
            first.auctionGroup.searcher:FindAuction(first, self)
        end
    end
end

function AuctipusBrowseFrame:SelectOptimalAuctions(n)
    local ag = self.selectedAuctionGroup
    if not ag then
        return
    end

    if not ag.matrix then
        ag.matrix = Auctipus.Matrix:New(ag.unitPriceAuctions)
    end

    self.selectedAuctions:Clear()
    if n > 0 then
        ag.matrix:Optimize(n)
        local auctions = ag.matrix:GetElems(n)
        if not auctions then
            Auctipus.info("Not enough auctions to satisfy demand.")
        else
            for _, a in ipairs(auctions) do
                self.selectedAuctions:Insert(a)
            end
            self.selectedAuctions:Sort(Auctipus.Auction.LTUnitPrice)
        end
    end

    self:UpdateAuctions()

    local first = self.selectedAuctions:First()
    self.BuyButton:Disable()
    if first ~= nil then
        first.auctionGroup.searcher:FindAuction(first, self)
    end
end

function AuctipusBrowseFrame:UpdateAuctions()
    local nauctions
    local auctionGroup = self.selectedAuctionGroup
    if auctionGroup then
        nauctions = #auctionGroup.unitPriceAuctions
    else
        nauctions = 0
    end

    FauxScrollFrame_Update(self.AuctionScrollFrame, nauctions,
                           #self.AuctionRows, 1)

    local offset = FauxScrollFrame_GetOffset(self.AuctionScrollFrame)
    for i, row in ipairs(self.AuctionRows) do
        row:UnlockHighlight()

        local index = offset + i
        if index <= nauctions then
            local auction = auctionGroup.unitPriceAuctions[index]
            row:SetAuction(auction)

            if not auction:IsBuyable() then
                row:DisableRow()
            else
                row:EnableRow()
                if self.selectedAuctions:Contains(auction) then
                    row:LockHighlight()
                end
            end
        else
            row:SetAuction(nil)
        end
    end

    local nselectedAuctions = 0
    local selectedBuyout    = 0
    for a, _ in pairs(self.selectedAuctions.elems) do
        nselectedAuctions = nselectedAuctions + a.count
        selectedBuyout    = selectedBuyout + a.buyoutPrice
    end

    local npurchasedAuctions = 0
    local purchasedBuyout    = 0
    for a, _ in pairs(self.purchasedAuctions.elems) do
        npurchasedAuctions = npurchasedAuctions + a.count
        purchasedBuyout    = purchasedBuyout + a.buyoutPrice
    end

    self.SelectionInfo.SelectedBuyoutCost:SetMoney(selectedBuyout)
    self.SelectionInfo.SelectedCountFrame.Text:SetText(
        "x "..nselectedAuctions.." =")
    if nselectedAuctions > 0 then
        self.SelectionInfo.SelectedUnitCost:SetMoney(
            floor(selectedBuyout / nselectedAuctions))
    else
        self.SelectionInfo.SelectedUnitCost:SetMoney(0)
    end

    self.SelectionInfo.PurchasedBuyoutCost:SetMoney(purchasedBuyout)
    self.SelectionInfo.PurchasedCountFrame.Text:SetText(
        "x "..npurchasedAuctions.." =")
    if npurchasedAuctions > 0 then
        self.SelectionInfo.PurchasedUnitCost:SetMoney(
            floor(purchasedBuyout / npurchasedAuctions))
    else
        self.SelectionInfo.PurchasedUnitCost:SetMoney(0)
    end
end

function AuctipusBrowseFrame:SearchPending(search)
    Auctipus.dbg("-------- Auction search now pending --------")
    self.BuyButton:Disable()
end

function AuctipusBrowseFrame:SearchSucceeded(search, page, index)
    Auctipus.dbg("-------- Found auction on page "..page.." at index "..index..
                 "--------")
    local fauction = self.selectedAuctions:First()
    local pauction = Auctipus.Auction:FromGetAuctionItemInfo(index)
    Auctipus.dbg("Desired auction: "..fauction:ToString())
    Auctipus.dbg("Found auction:"..pauction:ToString())

    assert(search.targetAuction == self.selectedAuctions:First())
    self.BuyButton:Enable()
end

function AuctipusBrowseFrame:SearchAborted(search)
    Auctipus.dbg("-------- Auction search aborted --------")
    self:ClearSearch()
end

function AuctipusBrowseFrame:SearchFailed(search)
    Auctipus.info("-------- Auction not found. --------")

    assert(search.targetAuction == self.selectedAuctions:First())
    search.targetAuction.missing = true
    self.selectedAuctions:Pop()
    self:AvailableAuctionsChanged()
    self:UpdateAuctions()

    if not self.selectedAuctions:Empty() then
        local first = self.selectedAuctions:First()
        first.auctionGroup.searcher:FindAuction(first, self)
    end
end

function AuctipusBrowseFrame:DoBuy()
    assert(not self.selectedAuctions:Empty())

    local auction  = self.selectedAuctions:First()
    local searcher = auction.auctionGroup.searcher
    assert(auction:Matches(searcher.targetAuction))
    Auctipus.info("Buying: "..auction:ToString())
    self.BuyButton:Disable()

    auction.missing = true
    self:UpdateAuctions()

    searcher:BuyoutAuction(self)
end

function AuctipusBrowseFrame:AuctionWon(searcher)
    local auction = self.selectedAuctions:Pop()
    local ag      = auction.auctionGroup
    self.purchasedAuctions:Insert(auction)
    ag:RemoveItem(auction)
    self:AvailableAuctionsChanged()
    self:UpdateAuctions()

    if not self.selectedAuctions:Empty() then
        searcher:FindAuction(self.selectedAuctions:First(), self)
    end
end

function AuctipusBrowseFrame:AuctionLost(searcher)
    local a = self.selectedAuctions:Pop()
    assert(a.missing == true)
    self:AvailableAuctionsChanged()
    self:UpdateAuctions()

    if not self.selectedAuctions:Empty() then
        searcher:FindAuction(self.selectedAuctions:First(), self)
    end
end

function AuctipusBrowseFrame:AvailableAuctionsChanged()
    local ag = self.selectedAuctionGroup
    if ag then
        ag.matrix = nil
        ag:RecomputeBuyableCount()
        self.SmartSelect.Input:SetMax(ag.buyableCount)
    end
end

Auctipus.EventManager.Register(AuctipusBrowseFrame)
