APage = {
    activePage = {
        ["list"]  = nil,
        ["owner"] = nil,
    },
    lastOrder = {
        ["list"]  = nil,
        ["owner"] = nil,
    }
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
    Auctipus.dbg("APage ["..self.category.."]: "..self.state.." -> "..newState)
    self.state = newState
end

function APage:OpenListPage(q, page, order, handler)
    if APage.activePage["list"] then
        Auctipus.dbg("Forcing previous list page closed.")
        APage.activePage["list"]:ClosePage()
    end

    local ap = {category      = "list",
                state         = STATE_WAIT_START_QUERY,
                query         = q,
                order         = order,
                page          = page,
                handler       = handler,
                totalAuctions = nil,
                auctions      = nil,
                nilAuctions   = nil,
                }
    setmetatable(ap, self)

    APage.activePage["list"] = ap
end

function APage:OpenOwnerPage(page, handler)
    if APage.activePage["owner"] then
        Auctipus.dbg("Forcing previous owner page closed.")
        APage.activePage["owner"]:ClosePage()
    end

    local ap = {category      = "owner",
                state         = STATE_WAIT_START_QUERY,
                page          = page,
                handler       = handler,
                totalAuctions = nil,
                auctions      = nil,
                nilAuctions   = nil,
                }
    setmetatable(ap, self)

    APage.activePage["owner"] = ap
end

function APage:IsActivePage()
    return self == APage.activePage[self.category]
end

function APage:ClosePage()
    if self:IsActivePage() then
        APage.activePage[self.category] = nil
    end

    self:_TRANSITION(STATE_CLOSED)
    if self.handler then
        self.handler:PageClosed(self)
    end
end

function APage:StartQuery()
    if APage.lastOrder[self.category] ~= self.order then
        Auctipus.dbg("Updating query sort order...")
        SortAuctionClearSort(self.category)
        for i, s in ipairs(SORT_ORDER[self.order]) do
            SortAuctionSetSort(self.category, s.key, s.reverse)
        end
        APage.lastOrder[self.category] = self.order
    end

    if self.category == "list" then
        Auctipus.dbg("Querying page "..self.page.."...")
        local q = self.query
        QueryAuctionItems(q.text, q.minLevel, q.maxLevel, self.page, q.usable,
                          q.rarity, q.getAll, q.exactMatch, q.filters)
    elseif self.category == "owner" then
        GetOwnerAuctionItems()
    end
end

function APage:ProcessPage()
    local numAuctions, totalAuctions = GetNumAuctionItems(self.category)

    self.totalAuctions = totalAuctions
    self.auctions      = {}
    self.nilAuctions   = {}
    for i = 1, numAuctions do
        local auction = AAuction:FromGetAuctionItemInfo(i, self.category)
        if auction.owner == nil or auction.link == nil then
            table.insert(self.nilAuctions, auction)
        end
        table.insert(self.auctions, auction)
    end

    if self.handler then
        self.handler:PageUpdated(self)
    else
        Auctipus.dbg("Page ["..self.category.."] processing complete:")
        self:Dump()
    end
end

function APage:OnUpdate()
    for i, self in pairs(APage.activePage) do
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
end

function APage.AUCTION_ITEM_LIST_UPDATE()
    -- Defer to the next OnUpdate handler so that we batch multiple list into a
    -- single page scan.
    local self = APage.activePage["list"]
    if not self then
        return
    end

    self:_TRANSITION(STATE_WAIT_PROCESS_PAGE)
end

function APage.AUCTION_OWNED_LIST_UPDATE()
    -- Defer to the next OnUpdate handler so that we batch multiple list into a
    -- single page scan.
    local self = APage.activePage["owner"]
    if not self then
        return
    end

    self:_TRANSITION(STATE_WAIT_PROCESS_PAGE)
end

function APage.AUCTION_HOUSE_CLOSED()
    for i, self in pairs(APage.activePage) do
        self:ClosePage()
    end
end

function APage:Dump()
    for i, a in ipairs(self.auctions) do
        a:Print()
    end
end

TGEventManager.Register(APage)
