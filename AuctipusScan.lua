AuctipusScan = {
    -- Scan state.
    state       = nil,
    query       = {text       = nil,
                   minLevel   = nil,
                   maxLevel   = nil,
                   usable     = nil,
                   rarity     = nil,
                   exactMatch = nil,
                   filterData = nil,
                   },
    pageIndex   = nil,
    pageScans   = nil,
    nbatchItems = nil,
    batchItems  = nil,
    items       = nil,
    waitTime    = nil,
    scanTime    = nil,
    elapsedTime = nil,
}

local STATE_IDLE               = 0
local STATE_QUERY_PENDING      = 1
local STATE_QUERY_ACTIVE       = 2
local STATE_QUERY_COMPLETE     = 3
local STATE_PAGE_SCAN_COMPLETE = 4
local STATE_PAGE_WAIT_RESCAN   = 5

local MAX_PAGE_SIZE = 50

local function TableAppend(t1, t2)
    for i=1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
end

function AuctipusScan.IsAHBusy()
    local canQuery, canQueryAll = CanSendAuctionQuery()
    return not canQuery
end

function AuctipusScan.GetAuctionItemInfo(index)
    local name, texture, count, quality, canUse, level, levelColHeader, minBid,
        minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName,
        owner, ownerFullName, saleStatus, itemId, hasAllInfo =
            GetAuctionItemInfo("list", index)

    return {name           = name,
            texture        = texture,
            count          = count,
            quality        = quality,
            canUse         = canUse,
            level          = level,
            levelColHeader = levelColHeader,
            minBid         = minBid,
            minIncrement   = minIncrement,
            buyoutPrice    = buyoutPrice,
            bidAmount      = bidAmount,
            highBidder     = highBidder,
            bidderFullName = bidderFullName,
            owner          = owner,
            ownerFullName  = ownerFullName,
            saleStatus     = saleStatus,
            itemId         = itemId,
            hasAllInfo     = hasAllInfo,
            link           = GetAuctionItemLink("list", index)
            }
end

function AuctipusScan.ADDON_LOADED(addOnName)
    if addOnName ~= "Auctipus" then
        return
    end

    -- Set our initial state.
    AuctipusScan.state = STATE_IDLE
end

function AuctipusScan.AUCTION_HOUSE_SHOW()
    assert(not AuctipusScan.IsAHBusy())
    AuctipusScan.DumpSortOrder()
end

function AuctipusScan.DoSearch()
    -- The default query.
    --AuctipusScan.query.minLevel = 10
    --AuctipusScan.query.maxLevel = 19
    --AuctipusScan.query.rarity   = 3
    AuctipusScan.query.text = AuctipusFrameSearchBox:GetText()
    AuctipusScan.state      = STATE_QUERY_PENDING
end

function AuctipusScan.OnUpdate()
    if AuctipusScan.state == STATE_QUERY_PENDING then
        if not AuctipusScan.IsAHBusy() then
            SortAuctionClearSort("list")
            AuctipusScan.position = 0
            AuctipusScan.items    = {}
            AuctipusScan.scanTime = GetTime()
            AuctipusScan.StartPageQuery(0)
        end
    elseif AuctipusScan.state == STATE_QUERY_COMPLETE then
        local numBatchAuctions, totalAuctions = GetNumAuctionItems("list")

        AuctipusScan.ntotalItems = totalAuctions
        AuctipusScan.nbatchItems = numBatchAuctions
        AuctipusScan.batchItems  = {}

        local numNilOwners = 0
        for i = 1, AuctipusScan.nbatchItems do
            local info = AuctipusScan.GetAuctionItemInfo(i)
            if info.owner == nil then
                numNilOwners = numNilOwners + 1
            end
            AuctipusScan.batchItems[i] = info
        end

        Auctipus.dbg("Found "..numNilOwners.." items with nil owner.")

        if numNilOwners > 0 and AuctipusScan.pageScans < 5 then
            Auctipus.dbg("Delaying for rescan...")
            AuctipusScan.state    = STATE_PAGE_WAIT_RESCAN
            AuctipusScan.waitTime = GetTime()
            return
        end

        AuctipusScan.state = STATE_PAGE_SCAN_COMPLETE
    elseif AuctipusScan.state == STATE_PAGE_SCAN_COMPLETE then
        if not AuctipusScan.IsAHBusy() then
            TableAppend(AuctipusScan.items, AuctipusScan.batchItems)

            if AuctipusScan.pageIndex ==
                floor(AuctipusScan.ntotalItems / MAX_PAGE_SIZE) + 1
            then
                AuctipusScan.elapsedTime = GetTime() - AuctipusScan.scanTime
                AuctipusScan.state       = STATE_IDLE
                Auctipus.ScanComplete()
            else
                AuctipusScan.StartPageQuery(AuctipusScan.pageIndex + 1)
            end
        end
    elseif AuctipusScan.state == STATE_PAGE_WAIT_RESCAN then
        if GetTime() - AuctipusScan.waitTime > 5 then
            AuctipusScan.pageScans = AuctipusScan.pageScans + 1
            AuctipusScan.state     = STATE_QUERY_COMPLETE
        end
    end
end

function AuctipusScan.StartPageQuery(page)
    local q = AuctipusScan.query
    Auctipus.dbg("Submitting query for page "..page.."...")
    AuctipusScan.pageIndex = page
    AuctipusScan.state     = STATE_QUERY_ACTIVE
    QueryAuctionItems(q.text, q.minLevel, q.maxLevel, page, q.usable, q.rarity,
                      false, q.exactMatch, q.filterData)
end

function AuctipusScan.AUCTION_ITEM_LIST_UPDATE()
    Auctipus.dbg("AUCTION_ITEM_LIST_UPDATE")
    AuctipusScan.pageScans = 0
    AuctipusScan.state     = STATE_QUERY_COMPLETE
end

function AuctipusScan.AUCTION_HOUSE_CLOSED()
    AuctipusScan.scanState = STATE_IDLE
end

function AuctipusScan.DumpSortOrder()
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

TGEventManager.Register(AuctipusScan)
