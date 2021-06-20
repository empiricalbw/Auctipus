Auctipus = {
    log_level = 1,
    log       = TGLog:new(1, true),
}

function Auctipus.dbg(...)
    local timestamp = GetTime()
    Auctipus.log:log(
        Auctipus.log_level,
        "[", timestamp, "] ",
        LIGHTYELLOW_FONT_COLOR_CODE.."Auctipus: "..FONT_COLOR_CODE_CLOSE,
        ...)
end

function Auctipus.ADDON_LOADED(addOnName)
    if addOnName ~= "Auctipus" then
        return
    end

    -- Disable the Blizzard auction house frames.
    UIParent:UnregisterEvent("AUCTION_HOUSE_SHOW")
    UIParent:UnregisterEvent("AUCTION_HOUSE_CLOSED")
    UIParent:UnregisterEvent("AUCTION_HOUSE_DISABLED")

    -- Set scripts.
    local f = AuctipusFrame
    local e = AuctipusFrameSearchBox
    f:SetScript("OnHide", Auctipus.OnHide)
    e:SetScript("OnEnterPressed", AuctipusScan.DoSearch)
    e:SetScript("OnEscapePressed", function() e:ClearFocus() end)

    -- Make it so that the frame will close when we hit Escape.
    table.insert(UISpecialFrames, AuctipusFrame:GetName())
end

function Auctipus.AUCTION_HOUSE_SHOW()
    Auctipus.dbg("AUCTION_HOUSE_SHOW")

    AuctipusFrame:Show()
    AuctipusFrameSearchBox:SetFocus()
end

function Auctipus.AUCTION_HOUSE_CLOSED()
    Auctipus.dbg("AUCTION_HOUSE_CLOSED")
    AuctipusFrame:Hide()
end

function Auctipus.OnHide()
    CloseAuctionHouse()
end

function Auctipus.AUCTION_HOUSE_DISABLED()
    Auctipus.dbg("AUCTION_HOUSE_DISABLED")
end

function Auctipus.ScanComplete()
    local itemsPerSecond = #AuctipusScan.items/AuctipusScan.elapsedTime
    Auctipus.dbg("Scan complete.  Found "..#AuctipusScan.items.." total in "..
                 AuctipusScan.elapsedTime.." seconds ("..itemsPerSecond..
                 " items/second)")

    AuctipusFrameResult1:SetNormalTexture(AuctipusScan.items[1].texture)
end

TGEventManager.Register(Auctipus)
