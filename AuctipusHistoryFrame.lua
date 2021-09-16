AuctipusHistoryFrame = {}

function AuctipusHistoryFrame:OnLoad()
    -- Variables.
    self.results = {}
    self.selectedResult = nil

    -- Instantiate all the result rows.
    for i, row in ipairs(self.HistoryGroupRows) do
        if i == 1 then
            row:SetPoint("TOPLEFT", self.SearchBoxLabel, "BOTTOMLEFT", 16, -21)
        else
            row:SetPoint("TOPLEFT", self.HistoryGroupRows[i-1], "BOTTOMLEFT",
                         0, -6)
        end
    end

    -- Search box.
    Auctipus.UI.LinkEditBoxes(self)
    self.SearchBox:SetScript("OnTextChanged",
        function() self:OnSearchTextChanged() end)

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

    -- Full scan button.
    self.FullScanButton:SetScript("OnClick", function() AHistory:FullScan() end)

    -- Scroll bars.
    self.HistoryGroupScrollFrame:SetScript("OnVerticalScroll",
        function(self2, offset)
            FauxScrollFrame_OnVerticalScroll(self2, offset, 1,
                                             function()
                                                 self:UpdateHistoryGroups()
                                             end)
        end)
    self.HistoryGroupScrollFrame.ScrollBar.scrollStep = 1
    self:UpdateHistoryGroups()

    -- History bars.
    self.buyoutSpan = {}
    for i, bar in ipairs(self.Graph.HistoryBars) do
        bar:SetPoint("LEFT", self.Graph, "LEFT", 5 + ((i-1)*18), 0)
        bar:SetPoint("TOP", self.Graph, "TOP", 0, -4)
        bar:SetPoint("BOTTOM", self.Graph, "BOTTOM", 0, 4)
        bar:SetWidth(16)
        bar.Top:SetVertexColor(0, 0.6, 0, 0.85)
        bar.Middle:SetVertexColor(0, 0.6, 0, 0.85)
        bar.Bottom:SetVertexColor(0, 0.6, 0, 0.85)
        bar:Hide()
    end
    for i, hl in ipairs(self.Graph.HistoryHighlights) do
        table.insert(self.buyoutSpan, nil)
        hl:SetPoint("LEFT", self.Graph, "LEFT", 4 + ((i-1)*18), 0)
        hl:SetPoint("TOP", self.Graph, "TOP", 0, -4)
        hl:SetPoint("BOTTOM", self.Graph, "BOTTOM", 0, 4)
        hl:SetWidth(18)
        hl:SetScript("OnEnter", function() self:OnEnterBar(i) end)
        hl:Show()
    end

    -- Money frames.
    self.Graph.MinPrice:Hide()
    self.Graph.MaxPrice:Hide()
end

function AuctipusHistoryFrame.OnUpdate()
    local self = AuctipusFrame.HistoryFrame
    local canQuery, canQueryAll = CanSendAuctionQuery()
    if canQuery and canQueryAll then
        self.FullScanButton:Enable()
    else
        self.FullScanButton:Disable()
    end
end

function AuctipusHistoryFrame:OnEnterBar(index)
    local span = self.buyoutSpan[index]
    if span then
        self.MinPrice:SetMoney(floor(span[1] + 0.5))
        self.MaxPrice:SetMoney(floor(span[2] + 0.5))
    end
end

function AuctipusHistoryFrame:OnSearchTextChanged()
    self:FilterResults(self.SearchBox:GetText())
end

function AuctipusHistoryFrame:OnChatEdit_InsertLink(link)
    if link and self:IsVisible() then
        local name = Auctipus.Link.GetLinkName(link)
        self.SearchBox:SetText(name)
        self.SearchBox:ClearFocus()
        self:FilterResults(name)
    end
end

function AuctipusHistoryFrame:OnContainerModifiedClick(f)
    if self:IsVisible() then
        StackSplitFrame:Hide()
    end
end

function AuctipusHistoryFrame:FilterResults(substring)
    self.results = AHistory:Match(substring)
    if #self.results == 1 then
        self:SelectHistoryGroup(self.results[1])
    else
        self:UpdateHistoryGroups()
    end
end

function AuctipusHistoryFrame:SelectHistoryGroup(hg)
    self.selectedHistoryGroup = hg
    self:UpdateHistoryGroups()
    self:UpdateGraph()
end

function AuctipusHistoryFrame:UpdateHistoryGroups()
    FauxScrollFrame_Update(self.HistoryGroupScrollFrame,
                           #self.results,
                           #self.HistoryGroupRows,
                           1)

    local offset = FauxScrollFrame_GetOffset(self.HistoryGroupScrollFrame)
    for i, row in ipairs(self.HistoryGroupRows) do
        row:UnlockHighlight()

        local index = offset + i
        if index <= #self.results then
            local historyGroup = self.results[index]
            row:SetHistoryGroup(historyGroup)

            if historyGroup == self.selectedHistoryGroup then
                row:LockHighlight()
            end
            row:Enable()
        else
            row:SetHistoryGroup(nil)
            row:Disable()
        end
    end
end

function AuctipusHistoryFrame:UpdateGraph()
    local hg = self.selectedHistoryGroup
    if not hg then
        return
    end

    local today     = AHistory:GetServerDay()
    local firstDay  = today - #self.Graph.HistoryBars + 1
    local minBuyout = 100000000000
    local maxBuyout = 0
    local pos       = nil
    for i, info in ipairs(hg.history) do
        if info[1] >= firstDay then
            pos       = pos or i
            minBuyout = min(minBuyout, info[2])
            maxBuyout = max(maxBuyout, info[3])
        end
    end
    minBuyout = 0
    if maxBuyout > 10000 then
        maxBuyout = ceil(maxBuyout / 10000) * 10000
    elseif maxBuyout > 100 then
        maxBuyout = ceil(maxBuyout / 100) * 100
    end
    for _, b in ipairs(self.Graph.HistoryBars) do
        b:Hide()
    end
    if pos ~= nil then
        local gheight = self.Graph:GetHeight() - 16
        local buySpan = maxBuyout - minBuyout
        if buySpan == 0 then
            minBuyout = minBuyout - 1
            maxBuyout = maxBuyout + 1
            buySpan   = 2
        end
        while pos <= #hg.history do
            local info   = hg.history[pos]
            local index  = info[1] - firstDay + 1
            local b      = self.Graph.HistoryBars[index]
            local bottom = ((info[2] - minBuyout) / buySpan) * gheight + 4
            local top    = ((info[3] - minBuyout) / buySpan) * gheight + 12
            b:SetPoint("BOTTOM", self.Graph, "BOTTOM", 0, bottom)
            b:SetPoint("TOP", self.Graph, "BOTTOM", 0, top)
            b:Show()
            pos = pos + 1

            self.buyoutSpan[index] = {info[2], info[3]}
        end
        self.Graph.MinPrice:Show()
        self.Graph.MaxPrice:Show()
        self.Graph.MinPrice:SetMoney(minBuyout)
        self.Graph.MaxPrice:SetMoney(maxBuyout)
    else
        self.Graph.MinPrice:Hide()
        self.Graph.MaxPrice:Hide()
    end
end

Auctipus.EventManager.Register(AuctipusHistoryFrame)
