AuctipusHistoryGroupRowMixin = {}

function AuctipusHistoryGroupRowMixin:OnLoad()
    self.ItemButton:SetScript("OnClick", function() self:OnClick() end)
    self.ItemButton:SetScript("OnEnter", function() self:OnEnterItem() end)
    self.ItemButton:SetScript("OnLeave", function() self:OnLeaveItem() end)
    self:SetScript("OnClick", function() self:OnClick() end)
    self.historyGroup = nil
end

function AuctipusHistoryGroupRowMixin:SetHistoryGroup(historyGroup)
    self.historyGroup = historyGroup

    self.ItemButton:SetMouseClickEnabled(historyGroup ~= nil)
    self.ItemButton:SetHistoryGroup(historyGroup)
end

function AuctipusHistoryGroupRowMixin:OnClick()
    AuctipusFrame.HistoryFrame:SelectHistoryGroup(self.historyGroup)
end

function AuctipusHistoryGroupRowMixin:OnEnterItem()
    self:LockHighlight()
    self.ItemButton:OnEnter()
end

function AuctipusHistoryGroupRowMixin:OnLeaveItem()
    self.ItemButton:OnLeave()
    if (not self.historyGroup or
        AuctipusFrame.HistoryFrame.selectedHistoryGroup ~= self.historyGroup)
    then
        self:UnlockHighlight()
    end
end
