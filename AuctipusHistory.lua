AHistory = {}
AHistory.__index = AHistory

AUCTIPUS_ITEM_HISTORY_DB = {}
AUCTIPUS_ITEM_HISTORY = nil

local function GetServerDay()
    local serverTime = GetServerTime()
    return floor(serverTime / (60*60*24))
end

function AHistory.PLAYER_ENTERING_WORLD()
    local rf = GetRealmName()..":"..UnitFactionGroup("player")
    local ih = AUCTIPUS_ITEM_HISTORY_DB[rf] or {}
    AUCTIPUS_ITEM_HISTORY = ih
    AUCTIPUS_ITEM_HISTORY_DB[rf] = ih

    SlashCmdList["AuctipusScan"] = function() AHistory:FullScan() end
    SLASH_AuctipusScan1 = "/auctipusscan"
end

function AHistory:FullScan()
    Auctipus.info("Initiating full scan...")
    self.scan = AScan:New({{getAll=true}}, self)
end

function AHistory:ScanComplete(scan)
    local serverDay = GetServerDay()

    for i, ag in ipairs(scan.auctionGroups) do
        if #ag.unitPriceAuctions == 0 then
            print("Item "..ag.link.." has no buyout.")
        else
            ag:SortByBuyout()
            local hg = AUCTIPUS_ITEM_HISTORY[ag.link] or {}
            local minUnitBuyout = ag.unitPriceAuctions[1].unitPrice
            if #hg > 0 and hg[#hg][1] == serverDay then
                local elem = hg[#hg]
                elem[2] = min(elem[2], minUnitBuyout)
                elem[3] = max(elem[3], minUnitBuyout)
            else
                table.insert(hg, {serverDay, minUnitBuyout, minUnitBuyout})
            end
            AUCTIPUS_ITEM_HISTORY[ag.link] = hg
        end
    end

    Auctipus.info("Full scan complete.")
end

function AHistory:ScanAborted(scan)
    Auctipus.info("Scan aborted.")
end

TGEventManager.Register(AHistory)
