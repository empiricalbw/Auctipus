APage = {
    activePage = nil,
    lastOrder  = nil,
}
APage.__index = APage

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

local STATE_WAIT_START_QUERY  = "STATE_WAIT_START_QUERY"
local STATE_WAIT_PAGE_UPDATE  = "STATE_WAIT_PAGE_UPDATE"
local STATE_WAIT_PROCESS_PAGE = "STATE_WAIT_PROCESS_PAGE"
local STATE_CLOSED            = "STATE_CLOSED"

local function IsAHBusy()
    local canQuery, canQueryAll = CanSendAuctionQuery()
    return not canQuery
end

function APage:_TRANSITION(newState)
    Auctipus.dbg("APage: "..self.state.." -> "..newState)
    self.state = newState
end

function APage:OpenPage(q, page, order, handler)
    if APage.activePage then
        Auctipus.dbg("Forcing previous page closed.")
        APage.activePage:ClosePage()
    end

    local ap = {state         = STATE_WAIT_START_QUERY,
                query         = q,
                order         = order,
                page          = page,
                handler       = handler,
                totalAuctions = nil,
                auctions      = nil,
                nilAuctions   = nil,
                }
    setmetatable(ap, self)

    APage.activePage = ap
end

function APage:IsActivePage()
    return self == APage.activePage
end

function APage:ClosePage()
    if self:IsActivePage() then
        APage.activePage = nil
    end

    self:_TRANSITION(STATE_CLOSED)
    if self.handler then
        self.handler:PageClosed(self)
    end
end

function APage:StartQuery()
    if APage.lastOrder ~= self.order then
        Auctipus.dbg("Updating query sort order...")
        SortAuctionClearSort("list")
        for i, s in ipairs(SORT_ORDER[self.order]) do
            SortAuctionSetSort("list", s.key, s.reverse)
        end
        APage.lastOrder = self.order
    end

    Auctipus.dbg("Querying page "..self.page.."...")
    local q = self.query
    QueryAuctionItems(q.text, q.minLevel, q.maxLevel, self.page, q.usable,
                      q.rarity, q.getAll, q.exactMatch, q.filters)
end

function APage:ProcessPage()
    local numAuctions, totalAuctions = GetNumAuctionItems("list")

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
    local self = APage.activePage
    if not self then
        return
    end

    if self.state == STATE_WAIT_START_QUERY then
        if not IsAHBusy() then
            if self.handler then
                self.handler:PageOpened(self)
            end

            self:_TRANSITION(STATE_WAIT_PAGE_UPDATE)
            self:StartQuery()
        end
    elseif self.state == STATE_WAIT_PROCESS_PAGE then
        self:_TRANSITION(STATE_WAIT_PAGE_UPDATE)
        self:ProcessPage()
    end
end

function APage.AUCTION_ITEM_LIST_UPDATE()
    -- Defer to the next OnUpdate handler so that we batch multiple list into a
    -- single page scan.
    Auctipus.dbg("AUCTION_ITEM_LIST_UPDATE")
    local self = APage.activePage
    if not self then
        return
    end

    self:_TRANSITION(STATE_WAIT_PROCESS_PAGE)
end

function APage.AUCTION_HOUSE_CLOSED()
    local self = APage.activePage
    if not self then
        return
    end

    self:ClosePage()
end

function APage:Dump()
    for i, a in ipairs(self.auctions) do
        a:Print()
    end
end

TGEventManager.Register(APage)
