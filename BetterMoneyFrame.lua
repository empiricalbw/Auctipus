BetterMoneyFrameMixin = {}

local BMF_STYLES = {
    ["normal"] = {
        copperMinDigits = 1,
        silverMinDigits = 1,
        hideZeroes      = true,
        collapse        = false,
    },

    ["fixed"] = {
        copperMinDigits = 2,
        silverMinDigits = 2,
        hideZeroes      = false,
        collapse        = false,
    },

    ["fixed_collapsed"] = {
        copperMinDigits = 2,
        silverMinDigits = 2,
        hideZeroes      = false,
        collapse        = true,
    },
}

function BetterMoneyFrameMixin:OnLoad()
    self.style                  = BMF_STYLES[self.style or "normal"]
    self.defaultCopperIconWidth = self.CopperIcon:GetWidth()
    self.defaultCopperTextWidth = self.CopperText:GetWidth()
    self.defaultSilverIconWidth = self.SilverIcon:GetWidth()
    self.defaultSilverTextWidth = self.SilverText:GetWidth()
    self.copperCollapsed        = false
    self.silverCollapsed        = false
    self:SetMoney(0)
end

function BetterMoneyFrameMixin:SetMoney(money)
    self.money = money
    local copper = (money % 100)
    money = floor(money / 100)
    local silver = (money % 100)
    money = floor(money / 100)
    local gold = money

    local copperText = ""..copper
    local silverText = ""..silver
    local goldText   = ""..gold
    if self.money >= 10000 then
        while silverText:len() < self.style.silverMinDigits do
            silverText = "0"..silverText
        end
    end
    if self.money >= 100 then
        while copperText:len() < self.style.copperMinDigits do
            copperText = "0"..copperText
        end
    end

    local copperWidth
    if copper == 0 and self.money > 0 and self.style.hideZeroes then
        self:CollapseCopper()
        copperWidth = 0
    else
        self:ExpandCopper()
        self.CopperText:SetText(copperText)
        copperWidth = 29
    end

    local silverWidth
    if silver == 0 then
        if self.money > 100 then
            if self.style.hideZeroes then
                self:CollapseSilver()
                silverWidth = 0
            else
                self:ExpandSilver()
                self.SilverText:SetText(silverText)
                silverWidth = 29
            end
        else
            self:HideSilver()
            silverWidth = 0
        end
    else
        self:ExpandSilver()
        self.SilverText:SetText(silverText)
        silverWidth = 29
    end

    local goldWidth
    if gold > 0 then
        self.GoldText:SetText(gold)
        self.GoldText:Show()
        self.GoldIcon:Show()
        goldWidth = 12 + self.GoldText:GetUnboundedStringWidth()
    else
        self.GoldText:Hide()
        self.GoldIcon:Hide()
        goldWidth = 0
    end

    if self.style.collapse then
        self:SetWidth(copperWidth + silverWidth + goldWidth)
    end
end

function BetterMoneyFrameMixin:HideCopper()
    self.CopperText:Hide()
    self.CopperIcon:Hide()
end

function BetterMoneyFrameMixin:CollapseCopper()
    if not self.copperCollapsed then
        self.CopperIcon:AdjustPointsOffset(29, 0)
        self:HideCopper()
        self.copperCollapsed = true
    end
end

function BetterMoneyFrameMixin:ExpandCopper()
    if self.copperCollapsed then
        self.CopperIcon:AdjustPointsOffset(-29, 0)
        self.copperCollapsed = false
    end
    self.CopperText:Show()
    self.CopperIcon:Show()
end

function BetterMoneyFrameMixin:HideSilver()
    self.SilverText:Hide()
    self.SilverIcon:Hide()
end

function BetterMoneyFrameMixin:CollapseSilver()
    if not self.silverCollapsed then
        self.SilverIcon:AdjustPointsOffset(29, 0)
        self:HideSilver()
        self.silverCollapsed = true
    end
end

function BetterMoneyFrameMixin:ExpandSilver()
    if self.silverCollapsed then
        self.SilverIcon:AdjustPointsOffset(-29, 0)
        self.silverCollapsed = false
    end
    self.SilverText:Show()
    self.SilverIcon:Show()
end
