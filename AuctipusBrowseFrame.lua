AuctipusBrowseFrame = CreateFrame("Frame", nil, nil,
                                  "AuctipusBrowseFrameMetaTemplate")
AuctipusBrowseFrame.__index = AuctipusBrowseFrame

function AuctipusBrowseFrame:OnLoad()
    setmetatable(self, AuctipusBrowseFrame)

    -- Variables.
    self.selectedAuctionGroup = nil
    self.selectedAuctions     = ASet:New()
    self.scan                 = nil

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
    AuctipusLinkEditBoxes(self)
    for i, e in ipairs(self.EditBoxes) do
        e:SetScript("OnEnterPressed", function() self:DoSearch() end)
    end

    -- Rarity dropdown.
    UIDropDownMenu_Initialize(self.RarityDropDown, function()
        local info         = UIDropDownMenu_CreateInfo()
        info.text          = ALL
        info.value         = -1
        info.func          = function(arg) self:HandleRarityClick(arg) end
        info.classicChecks = true
        UIDropDownMenu_AddButton(info)
        for i=0, #ITEM_QUALITY_COLORS - 4 do
            info.text    = _G["ITEM_QUALITY"..i.."_DESC"]
            info.value   = i
            info.func    = function(arg) self:HandleRarityClick(arg) end
            info.checked = nil
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(self.RarityDropDown, -1)
    UIDropDownMenu_SetWidth(self.RarityDropDown, 100)

    -- Paths dropdown.
    local config = {
        handler = self,
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
    for i, p in ipairs(AuctipusGenPaths()) do
        table.insert(config.items, p.name)
    end
    self.CategoryDropdown = ADropDown:New(config)
    self.CategoriesFrame.Button:SetScript("OnClick",
        function()
            self.CategoryDropdown:Toggle()
        end)
    self.CategoriesFrame.Label:SetText("Categories")

    -- Search button.
    self.SearchButton:SetScript("OnClick", function() self:DoSearch() end)

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

    -- Cleanup upon hiding.
    self:SetScript("OnHide", function() self:OnHide() end)
end

function AuctipusBrowseFrame.AUCTION_HOUSE_CLOSED()
    local self = AuctipusFrame.BrowseFrame
    self:ClearSearch()
end

function AuctipusBrowseFrame:OnHide()
    self.CategoryDropdown:Hide()
end

function AuctipusBrowseFrame:HandleRarityClick(info)
    UIDropDownMenu_SetSelectedValue(self.RarityDropDown, info.value)
end

function AuctipusBrowseFrame:OnDropdownItemClick(index, selected)
    local classID, subClassID, invType = unpack(AUCTIPUS_PATHS[index])
    if subClassID then
        -- If a subclass is selected, then we can only allow selections that
        -- are peers of the subclass or in parent nodes.
        for i, path in ipairs(AUCTIPUS_PATHS) do
            if path[1] ~= classID then
                self.CategoryDropdown:SetItemEnabled(i, not selected)
            end
        end
    else
        -- If no subclass is selected, then we can allow any child node or any
        -- peer class.
        for i, path in ipairs(AUCTIPUS_PATHS) do
            if path[1] ~= classID and path[2] ~= nil then
                self.CategoryDropdown:SetItemEnabled(i, not selected)
            end
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
        rarity     = UIDropDownMenu_GetSelectedValue(self.RarityDropDown),
        exactMatch = false,
        usable     = self.CanUseCheckButton:GetChecked(),
        filters    = {},
    }

    local selection = self.CategoryDropdown:GetSelection()
    for _, index in ipairs(selection) do
        local classID, subClassID, invType = unpack(AUCTIPUS_PATHS[index])
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
    self.scan = AScan:New({query}, self)
    self.SearchBox:ClearFocus()
    self.SearchButton:Disable()
    self.CategoryDropdown:Hide()
end

function AuctipusBrowseFrame:ScanProgress(scan, page, totalPages)
    self.StatusText:SetText("Searching ("..page.." / "..totalPages..")")
end

function AuctipusBrowseFrame:ScanComplete(scan)
    assert(self.scan == scan)
    AHistory:ScanComplete(scan)

    local auctionsPerSecond = #scan.auctions / scan.elapsedTime
    Auctipus.info("Scan complete.  Found "..#scan.auctions..
                  " total in "..scan.elapsedTime..
                  " seconds ("..auctionsPerSecond.." auctions/second)")
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

function AuctipusBrowseFrame:SelectAuctionGroup(auctionGroup)
    self.selectedAuctionGroup = auctionGroup
    self:ClearSearch()
end

function AuctipusBrowseFrame:UpdateAuctionGroups()
    local nauctionGroups
    if self.scan then
        nauctionGroups = #self.scan.auctionGroups
        if nauctionGroups > 0 then
            if #self.selectedAuctionGroup.unitPriceAuctions then
                self.StatusText:Hide()
            else
                self.StatusText:SetText("All results are bid-only auctions.")
                self.StatusText:Show()
            end
        else
            self.StatusText:SetText("No auctions found.")
            self.StatusText:Show()
        end
    else
        nauctionGroups = 0
        self.StatusText:SetText("Enter a search query.")
        self.StatusText:Show()
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
    local prevFirst = self.selectedAuctions:First()
    if self.selectedAuctions:Contains(auction) then
        self.selectedAuctions:Remove(auction)
    else
        self.selectedAuctions:Insert(auction)
    end
    self.selectedAuctions:Sort(AAuction.LTUnitPrice)
    self:UpdateAuctions()

    local first = self.selectedAuctions:First()
    if prevFirst ~= first then
        self.BuyButton:Disable()
        if first ~= nil then
            first.auctionGroup.searcher:FindAuction(first, self)
        end
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

            if auction.missing then
                row:SetAlpha(0.5)
                row:Disable()
            else
                row:SetAlpha(1)
                row:Enable()
                if self.selectedAuctions:Contains(auction) then
                    row:LockHighlight()
                end
            end
        else
            row:SetAuction(nil)
        end
    end
end

function AuctipusBrowseFrame:SearchPending(search)
    Auctipus.info("-------- Auction search now pending --------")
    self.BuyButton:Disable()
end

function AuctipusBrowseFrame:SearchSucceeded(search, page, index)
    Auctipus.info("-------- Found auction on page "..page.." at index "..index..
                  "--------")
    local fauction = self.selectedAuctions:First()
    local pauction = AAuction:FromGetAuctionItemInfo(index)
    Auctipus.info("Desired auction: "..fauction:ToString())
    Auctipus.info("Found auction:"..pauction:ToString())

    assert(search.targetAuction == self.selectedAuctions:First())
    self.BuyButton:Enable()
end

function AuctipusBrowseFrame:SearchAborted(search)
    Auctipus.info("-------- Auction search aborted --------")
    self:ClearSearch()
end

function AuctipusBrowseFrame:SearchFailed(search)
    Auctipus.info("-------- Auction not found. --------")

    assert(search.targetAuction == self.selectedAuctions:First())
    search.targetAuction.missing = true
    self.selectedAuctions:Pop()
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

    searcher:BuyoutAuction(self)
    auction.missing = true
    searcher:CancelFind()

    self:UpdateAuctions()
end

function AuctipusBrowseFrame:AuctionWon(searcher)
    local auction = self.selectedAuctions:Pop()
    auction.auctionGroup:RemoveItem(auction)
    self:UpdateAuctions()

    if not self.selectedAuctions:Empty() then
        searcher:FindAuction(self.selectedAuctions:First(), self)
    end
end

function AuctipusBrowseFrame:AuctionLost(searcher)
    self.selectedAuctions:Pop()
    self:UpdateAuctions()

    if not self.selectedAuctions:Empty() then
        searcher:FindAuction(self.selectedAuctions:First(), self)
    end
end

TGEventManager.Register(AuctipusBrowseFrame)
