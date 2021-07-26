AuctipusMoneyFrame = CreateFrame("Frame", nil, nil,
                                 "AuctipusMoneyFrameMetaTemplate")
AuctipusMoneyFrame.__index = AuctipusMoneyFrame

function AuctipusMoneyFrame:OnLoad(self)
    setmetatable(self, AuctipusMoneyFrame)

    local name             = self:GetName()
    self._CopperButton     = _G[name.."CopperButton"]
    self._SilverButton     = _G[name.."SilverButton"]
    self._GoldButton       = _G[name.."GoldButton"]
    self._CopperButtonText = _G[name.."CopperButtonText"]
    self._SilverButtonText = _G[name.."SilverButtonText"]
    self._GoldButtonText   = _G[name.."GoldButtonText"]
    self.small         = 1
    MoneyFrame_SetType(self, "AUCTION")
end

function AuctipusMoneyFrame:SetMoney(money)
    MoneyFrame_Update(self, money, true)
    local w = self._CopperButton:GetWidth() - 8
    self._CopperButton:SetWidth(w)
    self._SilverButton:SetWidth(w)
    self._GoldButton:SetWidth(w)

    if self._SilverButton:IsShown() then
        local copperText = self._CopperButtonText:GetText()
        if string.len(copperText) == 1 then
            self._CopperButtonText:SetText("0"..copperText)
        end
    end

    if self._GoldButton:IsShown() then
        local silverText = self._SilverButtonText:GetText()
        if string.len(silverText) == 1 then
            self._SilverButtonText:SetText("0"..silverText)
        end
    end
end
