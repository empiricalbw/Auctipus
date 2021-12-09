AuctipusOptionsFrame = {}

AUCTIPUS_OPTIONS = {
    version             = 1,
    showVendorPrice     = true,
}

function AuctipusOptionsFrame:OnLoad()
    self.name    = "Auctipus"
    self.refresh = AuctipusOptionsFrame.OnRefresh
    self.default = AuctipusOptionsFrame.OnDefault
    self.okay    = AuctipusOptionsFrame.OnClickOkay
    self.cancel  = AuctipusOptionsFrame.OnClickCanel
    InterfaceOptions_AddCategory(self)
end

function AuctipusOptionsFrame:OnRefresh()
    self.ShowVendorPriceCheckButton:SetChecked(AUCTIPUS_OPTIONS.showVendorPrice)
end

function AuctipusOptionsFrame:OnDefault()
    self.ShowVendorPriceCheckButton:SetChecked(true)
end

function AuctipusOptionsFrame:OnClickOkay()
    AUCTIPUS_OPTIONS.showVendorPrice =
        self.ShowVendorPriceCheckButton:GetChecked()
end

function AuctipusOptionsFrame:OnClickCancel()
end
