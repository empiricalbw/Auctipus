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

local STATE_INITIAL           = "STATE_INITIAL"
local STATE_WAIT_START_QUERY  = "STATE_WAIT_START_QUERY"
local STATE_WAIT_PAGE_UPDATE  = "STATE_WAIT_PAGE_UPDATE"
local STATE_WAIT_PROCESS_PAGE = "STATE_WAIT_PROCESS_PAGE"
local STATE_CLOSED            = "STATE_CLOSED"

function APage:_TRANSITION(newState)
    Auctipus.dbg("APage ["..self.category.."]: "..self.state.." -> "..newState)
    self.state = newState
end

function APage:OpenListPage(q, page, order, handler)
    local ap = {category      = "list",
                state         = STATE_INITIAL,
                query         = q,
                order         = order,
                page          = page,
                handler       = handler,
                totalAuctions = nil,
                auctions      = nil,
                nilAuctions   = nil,
                }
    setmetatable(ap, self)

    APage.ForceClose("list")
    APage.activePage["list"] = ap
    ap:_TRANSITION(STATE_WAIT_START_QUERY)
end

function APage:OpenOwnerPage(page, handler)
    local ap = {category      = "owner",
                state         = STATE_INITIAL,
                page          = page,
                handler       = handler,
                totalAuctions = nil,
                auctions      = nil,
                nilAuctions   = nil,
                }
    setmetatable(ap, self)

    APage.ForceClose("owner")
    APage.activePage["owner"] = ap
    ap:_TRANSITION(STATE_WAIT_START_QUERY)
end

function APage:IsAHBusy()
    local canQuery, canQueryAll = CanSendAuctionQuery()
    if self.category == "list" and self.query.getAll then
        return not (canQuery and canQueryAll)
    end
    return not canQuery
end

function APage:IsActivePage()
    return self == APage.activePage[self.category]
end

function APage.ForceClose(category)
    local p = APage.activePage[category]
    if p and p.state ~= STATE_CLOSED then
        Auctipus.dbg("Forcing "..category.." page closed.")
        APage.activePage[category]:ClosePage()
    end
end

function APage:ClosePage()
    if self:IsActivePage() then
        self:SelectItem(0)
        APage.activePage[self.category] = nil

        self:_TRANSITION(STATE_CLOSED)
        if self.handler then
            self.handler:PageClosed(self)
        end
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

function APage:SelectItem(index)
    assert(self:IsActivePage())
    SetSelectedAuctionItem(self.category, index)
end

function APage:GetSelectedItem()
    assert(self:IsActivePage())
    return GetSelectedAuctionItem(self.category)
end

function APage:OnUpdate()
    for i, self in pairs(APage.activePage) do
        if self.state == STATE_WAIT_START_QUERY then
            if not self:IsAHBusy() then
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
    local self = APage.activePage["list"]
    if self then
        self:_TRANSITION(STATE_WAIT_PROCESS_PAGE)
    end
end

function APage.AUCTION_OWNED_LIST_UPDATE()
    local self = APage.activePage["owner"]
    if self then
        self:_TRANSITION(STATE_WAIT_PROCESS_PAGE)
    end
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
