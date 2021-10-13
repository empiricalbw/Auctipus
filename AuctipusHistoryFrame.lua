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
    self.FullScanButton:SetScript("OnClick",
        function()
            Auctipus.History:FullScan()
        end)

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

    -- Plot.
    self.xyData = {top = {}, bottom = {}, dotPos = {}}
    for i, section in ipairs(self.Graph.Sections) do
        if i == 1 then
            section:SetPoint("TOPLEFT", self.Graph, "TOPLEFT", 5, -5)
        else
            section:SetPoint("TOP", self.Graph, "TOP", 0, -5)
            section:SetPoint("LEFT", self.Graph.Sections[i - 1], "RIGHT")
        end
        section:SetPoint("BOTTOM", 0, 5)
        section:SetWidth(18)
        section.TopQuad:SetColorTexture(0, 0.5, 0.1, 0.5)
        section.BottomQuad:SetColorTexture(0, 0.5, 0.1, 0.1)
        section.RedLine:SetColorTexture(0.718, 0.122, 0.133, 1)
        section.GreenLine:SetColorTexture(0, 0.631, 0.314, 1)
        section:Hide()
    end
    self.Graph.Dots.Top:ClearAllPoints()
    self.Graph.Dots.Top:Hide()
    self.Graph.Dots.Bottom:ClearAllPoints()
    self.Graph.Dots.Bottom:Hide()

    -- History bars.
    for i, hl in ipairs(self.Graph.HistoryHighlights) do
        hl:SetPoint("TOPLEFT", self.Graph, "TOPLEFT", 5 + ((i - 1)*18) - 9, -5)
        hl:SetPoint("BOTTOM", 0, 5)
        hl:SetWidth(18)
        hl:SetScript("OnEnter", function() self:OnEnterBar(i) end)
        hl:Hide()
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
    local x = 5 + (index - 1)*18
    if self.xyData.top[index] > 0 then
        self.MaxPrice:SetMoney(floor(self.xyData.top[index] + 0.5))
        self.MaxPrice:Show()
        self.Graph.Dots.Top:SetPoint("CENTER", self.Graph, "BOTTOMLEFT",
            x, self.xyData.tPos[index])
        self.Graph.Dots.Top:Show()
    else
        self.MaxPrice:Hide()
        self.Graph.Dots.Top:Hide()
    end
    if self.xyData.bottom[index] > 0 then
        self.MinPrice:SetMoney(floor(self.xyData.bottom[index] + 0.5))
        self.MinPrice:Show()
        self.Graph.Dots.Bottom:SetPoint("CENTER", self.Graph, "BOTTOMLEFT",
            x, self.xyData.bPos[index])
        self.Graph.Dots.Bottom:Show()
    else
        self.MinPrice:Hide()
        self.Graph.Dots.Bottom:Hide()
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
    self.results = Auctipus.History:Match(substring)
    if #self.results == 1 then
        self:SelectHistoryGroup(self.results[1])
    else
        self:UpdateHistoryGroups()
    end
end

function AuctipusHistoryFrame:SelectHistoryGroup(hg)
    self.selectedHistoryGroup = hg
    self:UpdateHistoryGroups()
    self:UpdateLineGraph()
    for i=#self.xyData.top, 1, -1 do
        if self.xyData.top[i] > 0 then
            self:OnEnterBar(i)
            break
        end
    end
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

function AuctipusHistoryFrame:UpdateLineGraph()
    local hg = self.selectedHistoryGroup
    if not hg then
        return
    end

    -- Find the starting index, pos, and the high end of the buyout range.
    local today     = Auctipus.History:GetServerDay()
    local firstDay  = today - #self.Graph.Sections
    local maxBuyout = 0
    local pos       = nil
    for i, info in ipairs(hg.history) do
        if info[1] >= firstDay then
            pos       = pos or i
            maxBuyout = max(maxBuyout, info[3])
        end
    end
    if maxBuyout > 10000 then
        maxBuyout = ceil(maxBuyout / 10000) * 10000
    elseif maxBuyout > 100 then
        maxBuyout = ceil(maxBuyout / 100) * 100
    end

    -- Hide all sections to begin with.
    for _, section in ipairs(self.Graph.Sections) do
        section:Hide()
    end

    -- If no data was found, bail early.
    self.xyData.top    = {}
    self.xyData.bottom = {}
    self.xyData.tPos   = {}
    self.xyData.bPos   = {}
    if pos == nil then
        self.MinPrice:Hide()
        self.MaxPrice:Hide()
        self.Graph.MinPrice:Hide()
        self.Graph.MaxPrice:Hide()
        self.Graph.Dots.Top:Hide()
        self.Graph.Dots.Bottom:Hide()
        for i, hl in ipairs(self.Graph.HistoryHighlights) do
            hl:Hide()
        end
        return
    end

    -- Calculate the buyout span.  For now, this just reduces to the maxBuyout
    -- value, but in the future we might want to be able to narrow the y-axis.
    local minBuyout = 0
    local buySpan   = maxBuyout - minBuyout
    if buySpan == 0 then
        minBuyout = minBuyout - 1
        maxBuyout = maxBuyout + 1
        buySpan   = 2
    end

    -- Build the sparse x-y data.
    local bData     = self.xyData.bottom
    local tData     = self.xyData.top
    local bPos      = self.xyData.bPos
    local tPos      = self.xyData.tPos
    local lastIndex = #hg.history
    local gheight   = self.Graph:GetHeight() - 8
    while pos <= lastIndex do
        local info   = hg.history[pos]
        local index  = info[1] - firstDay + 1
        bData[index] = info[2]
        tData[index] = info[3]
        bPos[index]  = ((info[2] - minBuyout) / buySpan) * gheight + 4
        tPos[index]  = ((info[3] - minBuyout) / buySpan) * gheight + 4
        pos          = pos + 1
    end
    self.xyData.top    = tData
    self.xyData.bottom = bData
    self.xyData.tPos   = tPos
    self.xyData.bPos   = bPos

    -- Set which points are mouseover-able.
    for i, hl in ipairs(self.Graph.HistoryHighlights) do
        hl:SetShown(bData[i] ~= nil)
    end

    -- Fill in the nil data.
    local lastBottom = nil
    local lastTop   = nil
    for i=1, #self.Graph.Sections + 1 do
        if bData[i] == nil then
            if lastBottom ~= nil then
                bData[i] = -abs(bData[lastBottom])
                bPos[i]  = -abs(bPos[lastBottom])
            end
        else
            lastBottom = i
        end

        if tData[i] == nil then
            if lastTop ~= nil then
                tData[i] = -abs(tData[lastTop])
                tPos[i]  = -abs(tPos[lastTop])
            end
        else
            lastTop = i
        end
    end
    lastBottom = nil
    lastTop    = nil
    for i=#self.Graph.Sections + 1, 1, -1 do
        if bData[i] == nil then
            if lastBottom ~= nil then
                bData[i] = -abs(bData[lastBottom])
                bPos[i]  = -abs(bPos[lastBottom])
            end
        else
            lastBottom = i
        end

        if tData[i] == nil then
            if lastTop ~= nil then
                tData[i] = -abs(tData[lastTop])
                tPos[i]  = -abs(tPos[lastTop])
            end
        else
            lastTop = i
        end
    end

    -- Set the graph sections up.
    for x, section in ipairs(self.Graph.Sections) do
        local b0   = abs(self.xyData.bPos[x])
        local b1   = abs(self.xyData.bPos[x + 1])
        local t0   = abs(self.xyData.tPos[x])
        local t1   = abs(self.xyData.tPos[x + 1])
        local bmin = min(b0, b1)
        local tmax = max(t0, t1)

        if b0 == t0 and b1 == t1 then
            section.TopQuad:Hide()
            section.RedLine:Hide()
            section.GreenLine:SetStartPoint("TOPLEFT", section.BottomQuad, 0,
                                            b0 - bmin)
            section.GreenLine:SetEndPoint("TOPRIGHT", section.BottomQuad, 0,
                                          b1 - bmin)
        else
            section.TopQuad:Show()
            section.RedLine:Show()
            section.TopQuad:SetPoint("TOP", self.Graph, "BOTTOM", 0, tmax)
            section.TopQuad:SetPoint("BOTTOM", self.Graph, "BOTTOM", 0, bmin)
            section.TopQuad:SetVertexOffset(UPPER_LEFT_VERTEX,  0, t0 - tmax)
            section.TopQuad:SetVertexOffset(LOWER_LEFT_VERTEX,  0, b0 - bmin)
            section.TopQuad:SetVertexOffset(UPPER_RIGHT_VERTEX, 0, t1 - tmax)
            section.TopQuad:SetVertexOffset(LOWER_RIGHT_VERTEX, 0, b1 - bmin)
            section.GreenLine:SetStartPoint("TOPLEFT", section.TopQuad, 0,
                                            t0 - tmax)
            section.GreenLine:SetEndPoint("TOPRIGHT", section.TopQuad, 0,
                                          t1 - tmax)
            section.RedLine:SetStartPoint("TOPLEFT", section.BottomQuad, 0,
                                          b0 - bmin)
            section.RedLine:SetEndPoint("TOPRIGHT", section.BottomQuad, 0,
                                        b1 - bmin)
        end
        section.BottomQuad:SetPoint("TOP", self.Graph, "BOTTOM", 0, bmin)
        section.BottomQuad:SetVertexOffset(UPPER_LEFT_VERTEX,  0, b0 - bmin)
        section.BottomQuad:SetVertexOffset(UPPER_RIGHT_VERTEX, 0, b1 - bmin)

        if bData[x] < 0 or bData[x + 1] < 0 then
            section.RedLine:Hide()
            section.GreenLine:Hide()
            section.TopQuad:SetColorTexture(0, 0.5, 0.1, 0.1)
        else
            section.GreenLine:Show()
            section.TopQuad:SetColorTexture(0, 0.5, 0.1, 0.5)
        end

        section:Show()
    end

    -- And Y-axis labels.
    self.Graph.MinPrice:Show()
    self.Graph.MaxPrice:Show()
    self.Graph.MinPrice:SetMoney(minBuyout)
    self.Graph.MaxPrice:SetMoney(maxBuyout)
end

Auctipus.EventManager.Register(AuctipusHistoryFrame)
