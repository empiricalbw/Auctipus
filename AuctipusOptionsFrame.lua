AuctipusOptionsFrame = {}

AUCTIPUS_OPTIONS = {
    version             = 2,
    showVendorPrice     = true,
    showDisenchantInfo  = true,
}

function AuctipusOptionsFrame:ProcessSavedVars()
    if AUCTIPUS_OPTIONS.version == 1 then
        AUCTIPUS_OPTIONS.showDisenchantInfo = true
    end
    AUCTIPUS_OPTIONS.version = 2
end

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
    self.ShowDisenchantInfoCheckButton:SetChecked(AUCTIPUS_OPTIONS.showDisenchantInfo)
end

function AuctipusOptionsFrame:OnDefault()
    self.ShowVendorPriceCheckButton:SetChecked(true)
    self.ShowDisenchantInfoCheckButton:SetChecked(true)
end

function AuctipusOptionsFrame:OnClickOkay()
    AUCTIPUS_OPTIONS.showVendorPrice =
        self.ShowVendorPriceCheckButton:GetChecked()
    AUCTIPUS_OPTIONS.showDisenchantInfo =
        self.ShowDisenchantInfoCheckButton:GetChecked()
end

function AuctipusOptionsFrame:OnClickCancel()
end
