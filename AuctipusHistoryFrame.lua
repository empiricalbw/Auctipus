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
    AuctipusLinkEditBoxes(self)
    self.SearchBox:SetScript("OnTextChanged",
        function() self:OnSearchTextChanged() end)

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
    for i, bar in ipairs(self.HistoryBars) do
        bar:SetPoint("LEFT", self.Graph, "LEFT", 5 + ((i-1)*18), 0)
        bar:SetPoint("TOP", self.Graph, "TOP", 0, -4)
        bar:SetPoint("BOTTOM", self.Graph, "BOTTOM", 0, 4)
        bar:SetWidth(16)
        bar.Top:SetVertexColor(0, 0.6, 0, 0.85)
        bar.Middle:SetVertexColor(0, 0.6, 0, 0.85)
        bar.Bottom:SetVertexColor(0, 0.6, 0, 0.85)
        bar:Hide()
    end

    -- Money frames.
    MoneyFrame_SetType(self.MinPrice, "STATIC")
    MoneyFrame_SetType(self.MaxPrice, "STATIC")
    self.MinPrice:Hide()
    self.MaxPrice:Hide()
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

function AuctipusHistoryFrame:OnSearchTextChanged()
    self:FilterResults(self.SearchBox:GetText())
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
    local firstDay  = today - #self.HistoryBars + 1
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
    for _, b in ipairs(self.HistoryBars) do
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
        print(minBuyout, maxBuyout, buySpan)
        while pos <= #hg.history do
            local info   = hg.history[pos]
            local b      = self.HistoryBars[info[1] - firstDay + 1]
            local bottom = ((info[2] - minBuyout) / buySpan) * gheight + 4
            local top    = ((info[3] - minBuyout) / buySpan) * gheight + 12
            b:SetPoint("BOTTOM", self.Graph, "BOTTOM", 0, bottom)
            b:SetPoint("TOP", self.Graph, "BOTTOM", 0, top)
            b:Show()
            pos = pos + 1

            print(info[1], info[2], info[3], bottom, top)
        end
        self.MinPrice:Show()
        self.MaxPrice:Show()
        MoneyFrame_Update(self.MinPrice, minBuyout, true)
        MoneyFrame_Update(self.MaxPrice, maxBuyout)
    else
        self.MinPrice:Hide()
        self.MaxPrice:Hide()
    end
end

TGEventManager.Register(AuctipusHistoryFrame)
