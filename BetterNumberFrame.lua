BetterNumberFrameMixin = {}

function BetterNumberFrameMixin:OnLoad()
    self.NumberBox:SetScript("OnEnterPressed",
        function() self:OnEnterPressed() end)
    self.NumberBox:SetScript("OnEscapePressed",
        function() self:OnEscapePressed() end)
    self.NumberBox:SetScript("OnTextChanged",
        function() self:OnTextChanged() end)
    self.NumberBox:SetScript("OnEditFocusLost",
        function() self:OnEditFocusLost() end)
    self.NumberBox:SetScript("OnEditFocusGained",
        function() self:OnEditFocusGained() end)
    self.DecrementButton:SetScript("OnClick",
        function() self:OnDecrementClicked() end)
    self.IncrementButton:SetScript("OnClick",
        function() self:OnIncrementClicked() end)
end

function BetterNumberFrameMixin:Init(minVal, maxVal, handler)
    assert(minVal <= maxVal)
    self.minVal  = minVal
    self.maxVal  = maxVal
    self.handler = handler
end

function BetterNumberFrameMixin:SetMin(v)
    assert(v <= self.maxVal)
    self.minVal = v
end

function BetterNumberFrameMixin:SetMax(v)
    assert(v >= self.minVal)
    self.maxVal = v
end

function BetterNumberFrameMixin:SetValue(v)
    assert(self.minVal <= v and v <= self.maxVal)
    self.NumberBox:ClearFocus()
    self.NumberBox:SetText(v)
end

function BetterNumberFrameMixin:OnDecrementClicked()
    local v = self.NumberBox:GetNumber()
    if v > self.minVal then
        v = v - 1
        self:SetValue(v)
        if self.handler then
            self.handler(v)
        end
    end
end

function BetterNumberFrameMixin:OnIncrementClicked()
    local v = self.NumberBox:GetNumber()
    if v < self.maxVal then
        v = v + 1
        self:SetValue(v)
        if self.handler then
            self.handler(v)
        end
    end
end

function BetterNumberFrameMixin:OnEnterPressed()
    self.NumberBox:ClearFocus()
    if self.handler then
        local v0 = self.NumberBox:GetNumber()
        local v  = max(self.minVal, v0)
        v        = min(self.maxVal, v)
        if v ~= v0 then
            self:SetValue(v)
        end
        self.handler(v)
    end
end

function BetterNumberFrameMixin:OnEscapePressed()
    self.NumberBox:ClearFocus()
end

function BetterNumberFrameMixin:OnTextChanged()
end

function BetterNumberFrameMixin:OnEditFocusLost()
    self.NumberBox:HighlightText(0, 0)
end

function BetterNumberFrameMixin:OnEditFocusGained()
    self.NumberBox:HighlightText()
end
