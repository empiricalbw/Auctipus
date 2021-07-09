APage = {}
APage.__index = APage

local pendingPage = nil
local openPage    = nil
local lastOrder   = nil

local SORT_ORDER = {
    ["BUYOUT"] = {
        {key="seller",   reverse=false},
        {key="quantity", reverse=false},
        {key="buyout",   reverse=false},
    },
    ["QUALITY"] = {
        {key="duration", reverse=false},
        {key="bid",      reverse=false},
        {key="quantity", reverse=true},
        {key="buyout",   reverse=false},
        {key="name",     reverse=false},
        {key="level",    reverse=true},
        {key="quality",  reverse=false},
    },
    ["DURATION"] = {
    	{key="quantity", reverse = true},
    	{key="bid",      reverse = false},
    	{key="name",     reverse = false},
    	{key="level",    reverse = true},
    	{key="quality",  reverse = false},
    	{key="status",   reverse = false},
    	{key="duration", reverse = false},
    },
}

local function IsAHBusy()
    local canQuery, canQueryAll = CanSendAuctionQuery()
    return not canQuery
end

function APage:OpenPage(q, page, order, handler)
    if openPage ~= nil then
        Auctipus.dbg("Forcing previous page closed.")
        openPage:ClosePage()
    end

    assert(pendingPage == nil)
    local ap = {query         = q,
                order         = order,
                page          = page,
                handler       = handler,
                totalAuctions = nil,
                auctions      = nil,
                nilAuctions   = nil,
                gotListUpdate = false,
                closed        = false,
                }
    setmetatable(ap, self)

    pendingPage = ap
end

function APage:ClosePage()
    if self == pendingPage then
        pendingPage = nil
    end
    if self == openPage then
        openPage = nil
    end

    self.closed = true
end

function APage:ConfigureSortOrder()
    if lastOrder ~= self.order then
        SortAuctionClearSort("list")
        for i, s in ipairs(SORT_ORDER[self.order]) do
            SortAuctionSetSort("list", s.key, s.reverse)
        end
        lastOrder = self.order
    end
end

function APage:StartQuery()
    self:ConfigureSortOrder()

    local q = self.query
    QueryAuctionItems(q.text, q.minLevel, q.maxLevel, self.page, q.usable,
                      q.rarity, q.getAll, q.exactMatch, q.filters)
end

function APage:ProcessPage()
    local numAuctions, totalAuctions = GetNumAuctionItems("list")

    self.gotListUpdate = false
    self.totalAuctions = totalAuctions
    self.auctions      = {}
    self.nilAuctions   = {}
    for i = 1, numAuctions do
        local auction = AAuction:FromGetAuctionItemInfo(i)
        if auction.owner == nil or auction.link == nil then
            table.insert(self.nilAuctions, auction)
        end
        table.insert(self.auctions, auction)
    end

    if self.handler then
        self.handler:PageUpdated(self)
    else
        Auctipus.dbg("Page processing complete:")
        self:Dump()
    end
end

function APage.OnUpdate()
    if pendingPage and not IsAHBusy() then
        openPage    = pendingPage
        pendingPage = nil
        if openPage.handler then
            openPage.handler:PageOpened(openPage)
        end
        openPage:StartQuery()
    elseif openPage and openPage.gotListUpdate then
        openPage:ProcessPage()
    end
end

function APage.AUCTION_ITEM_LIST_UPDATE()
    -- Defer to the next OnUpdate handler so that we batch multiple list into a
    -- single page scan.
    if openPage then
        openPage.gotListUpdate = true
    end
end

function APage.AUCTION_HOUSE_CLOSED()
    openPage = nil
    if pendingPage then
        local p = pendingPage
        pendingPage = nil
    end
end

function APage:Dump()
    for i, a in ipairs(self.auctions) do
        a:Print()
    end
end

TGEventManager.Register(APage)
