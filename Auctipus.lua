Auctipus.AddOn = {}

UIPanelWindows["AuctipusFrame"] = {
    area                = "doublewide",
    pushable            = 8,
    xoffset             = 16,
    yoffset             = 12,
    bottomClampOverride = 140+12,
    width               = 840,
}

function Auctipus.AddOn.ADDON_LOADED(addOnName)
    if addOnName ~= "Auctipus" then
        return
    end

    -- Saved variables.
    AuctipusFrame.AuctionsFrame:ProcessSavedVars()
    AHistory.ProcessSavedVars()

    -- Slash.
    SlashCmdList["AUCTIPUS"] = Auctipus.AddOn.OnSlash
    SLASH_AUCTIPUS1          = "/auctipus"

    -- Disable the Blizzard auction house frames.
    UIParent:UnregisterEvent("AUCTION_HOUSE_SHOW")
    UIParent:UnregisterEvent("AUCTION_HOUSE_CLOSED")
    UIParent:UnregisterEvent("AUCTION_HOUSE_DISABLED")

    -- Tabs.
    PanelTemplates_SetNumTabs(AuctipusFrame, #AuctipusFrame.Tabs)
    PanelTemplates_DisableTab(AuctipusFrame, 1)
    PanelTemplates_DisableTab(AuctipusFrame, 2)
    PanelTemplates_DisableTab(AuctipusFrame, 3)
    PanelTemplates_SetTab(AuctipusFrame, 4)

    -- Set scripts.
    AuctipusFrame:SetScript("OnShow", Auctipus.AddOn.OnShow)
    AuctipusFrame:SetScript("OnHide", Auctipus.AddOn.OnHide)
    for i, tab in ipairs(AuctipusFrame.Tabs) do
        tab:SetScript("OnClick", function() Auctipus.AddOn.SelectTab(i) end)
    end

    -- Make it so that the frame will close when we hit Escape.
    table.insert(UISpecialFrames, AuctipusFrame:GetName())
end

function Auctipus.AddOn.AUCTION_HOUSE_SHOW()
    Auctipus.dbg("AUCTION_HOUSE_SHOW")

    PanelTemplates_EnableTab(AuctipusFrame, 1)
    PanelTemplates_EnableTab(AuctipusFrame, 2)
    PanelTemplates_EnableTab(AuctipusFrame, 3)
    ShowUIPanel(AuctipusFrame)
    PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN)
    Auctipus.AddOn.SelectTab(1)
    Auctipus.AddOn.DumpSortOrder()
end

function Auctipus.AddOn.OnSlash()
    ShowUIPanel(AuctipusFrame)
    Auctipus.AddOn.SelectTab(4)
end

function Auctipus.AddOn.AUCTION_HOUSE_CLOSED()
    Auctipus.dbg("AUCTION_HOUSE_CLOSED")
    HideUIPanel(AuctipusFrame)
    PanelTemplates_DisableTab(AuctipusFrame, 1)
    PanelTemplates_DisableTab(AuctipusFrame, 2)
    PanelTemplates_DisableTab(AuctipusFrame, 3)
    PanelTemplates_SetTab(AuctipusFrame, 4)
end

function Auctipus.AddOn.OnShow()
    SetUpSideDressUpFrame(AuctipusFrame, 840, 1020, "TOPLEFT", "TOPRIGHT", -2,
                          -28)
end

function Auctipus.AddOn.OnHide()
    CloseAuctionHouse()
end

function Auctipus.AddOn.AUCTION_HOUSE_DISABLED()
    Auctipus.dbg("AUCTION_HOUSE_DISABLED")
end

function Auctipus.AddOn.SelectTab(index)
    PanelTemplates_SetTab(AuctipusFrame, index)
    AuctipusFrame.BrowseFrame:Hide()
    AuctipusFrame.AuctionsFrame:Hide()
    AuctipusFrame.ListingsFrame:Hide()
    AuctipusFrame.HistoryFrame:Hide()
    local f = GetCurrentKeyBoardFocus()
    if f then
        f:ClearFocus()
    end
    if index == 1 then
        AuctipusFrame.BrowseFrame:Show()
        if AuctipusFrame.BrowseFrame.SearchBox:GetText() == "" then
            AuctipusFrame.BrowseFrame.SearchBox:SetFocus()
        end
    elseif index == 2 then
        AuctipusFrame.AuctionsFrame:Show()
    elseif index == 3 then
        AuctipusFrame.ListingsFrame:Show()
    elseif index == 4 then
        AuctipusFrame.HistoryFrame:Show()
        if AuctipusFrame.HistoryFrame.SearchBox:GetText() == "" then
            AuctipusFrame.HistoryFrame.SearchBox:SetFocus()
        end
    end
end

function Auctipus.AddOn.DumpSortOrder()
    local i = 0
    while true do
        i = i + 1
        local sort, reversed = GetAuctionSort("list", i)
        if sort == nil then
            break
        end
        
        if reversed then
            reversed = " (reversed)"
        else
            reversed = ""
        end
        Auctipus.dbg("Sort: "..sort..reversed)
    end
end

AEventManager.Register(Auctipus.AddOn)
