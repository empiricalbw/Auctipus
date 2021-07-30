AHistory = {}
AHistory.__index = AHistory

AUCTIPUS_ITEM_HISTORY_DB = {}
AUCTIPUS_ITEM_HISTORY = nil

local LOCAL_DB = {}

function AHistory.PLAYER_ENTERING_WORLD()
    local rf = GetRealmName()..":"..UnitFactionGroup("player")
    local ih = AUCTIPUS_ITEM_HISTORY_DB[rf] or {}
    AUCTIPUS_ITEM_HISTORY = ih
    AUCTIPUS_ITEM_HISTORY_DB[rf] = ih
    AHistory:ProcessDB()
end

function AHistory:GetServerDay()
    local serverTime = GetServerTime()
    return floor(serverTime / (60*60*24))
end

function AHistory:FullScan()
    Auctipus.info("Initiating full scan...")
    self.scan = AScan:New({{getAll=true}}, self)
end

function AHistory:ScanComplete(scan)
    local serverDay = self:GetServerDay()

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

    self:ProcessDB()

    Auctipus.info("Full scan complete.")
end

function AHistory:ScanAborted(scan)
    Auctipus.info("Scan aborted.")
end

function AHistory:ProcessDB()
    local newDB = {}
    for link, history in pairs(AUCTIPUS_ITEM_HISTORY) do
        local l = ALink:New(link)
        l.history = history
        table.insert(newDB, l)
    end
    LOCAL_DB = newDB
end

function AHistory:Match(substring)
    local s = substring:upper()
    local match = {}

    if substring:len() >= 2 then
        for i = 1, #LOCAL_DB do
            local elem = LOCAL_DB[i]
            if elem.uname:find(s, 1, true) then
                table.insert(match, elem)
            end
        end
    end

    return match
end

TGEventManager.Register(AHistory)
