AuctipusHistoryGroupRow = {}

function AuctipusHistoryGroupRow:OnLoad()
    self.ItemButton:SetScript("OnClick", function() self:OnClick() end)
    self.ItemButton:SetScript("OnEnter", function() self:OnEnterItem() end)
    self.ItemButton:SetScript("OnLeave", function() self:OnLeaveItem() end)
    self:SetScript("OnClick", function() self:OnClick() end)
    self.historyGroup = nil
end

function AuctipusHistoryGroupRow:SetHistoryGroup(historyGroup)
    self.historyGroup = historyGroup

    self.ItemButton:SetMouseClickEnabled(historyGroup ~= nil)
    self.ItemButton:SetHistoryGroup(historyGroup)
end

function AuctipusHistoryGroupRow:OnClick()
    AuctipusFrame.HistoryFrame:SelectHistoryGroup(self.historyGroup)
end

function AuctipusHistoryGroupRow:OnEnterItem()
    self:LockHighlight()
    self.ItemButton:OnEnter()
end

function AuctipusHistoryGroupRow:OnLeaveItem()
    self.ItemButton:OnLeave()
    if (not self.historyGroup or
        AuctipusFrame.HistoryFrame.selectedHistoryGroup ~= self.historyGroup)
    then
        self:UnlockHighlight()
    end
end
