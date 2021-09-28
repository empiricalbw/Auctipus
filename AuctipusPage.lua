Auctipus.Page = {
    activePage = {
        ["list"]  = nil,
        ["owner"] = nil,
    },
    lastOrder = {
        ["list"]  = nil,
        ["owner"] = nil,
    }
}
Auctipus.Page.__index = Auctipus.Page
local APage = Auctipus.Page

local SORT_ORDER = {
    ["BUYOUT"] = {
        {key="seller",   reverse=false},
        {key="quantity", reverse=false},
        {key="buyout",   reverse=false},
    },
    ["UNITPRICE"] = {
        {key="seller",   reverse=false},
        {key="quantity", reverse=false},
        {key="buyout",   reverse=false},
        {key="unitprice",reverse=false},
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
local STATE_WAIT_PROCESS_NIL  = "STATE_WAIT_PROCESS_NIL"
local STATE_CLOSED            = "STATE_CLOSED"

function APage.IsSameQuery(q1, q2)
    if (q1.text:upper() ~= q2.text:upper() or
        q1.minLevel     ~= q2.minLevel or
        q1.maxLevel     ~= q2.maxLevel or
        q1.rarity       ~= q2.rarity or
        q1.usable       ~= q2.usable or
        #q1.filters     ~= #q2.filters)
    then
        return false
    end

    for i=1, #q1.filters do
        local f1 = q1.filters[i]
        local f2 = q2.filters[i]
        if (f1.classID       ~= f2.classID or
            f1.subClassID    ~= f2.subClassID or
            f1.inventoryType ~= f2.inventoryType)
        then
            return false
        end
    end

    return true
end

function APage.OpenListPage(q, page, order, handler)
    local ap = {category      = "list",
                state         = STATE_INITIAL,
                query         = q,
                order         = order,
                page          = page,
                handler       = handler,
                totalAuctions = nil,
                auctions      = nil,
                nilAuctions   = nil,
                lastPageSize  = 0,
                }
    setmetatable(ap, APage)

    APage.ForceClose("list")
    APage.activePage["list"] = ap
    ap:_TRANSITION(STATE_WAIT_START_QUERY)

    return ap
end

function APage.OpenOwnerPage(page, handler)
    local ap = {category      = "owner",
                state         = STATE_INITIAL,
                page          = page,
                handler       = handler,
                totalAuctions = nil,
                auctions      = nil,
                nilAuctions   = nil,
                lastPageSize  = 0,
                }
    setmetatable(ap, APage)

    APage.ForceClose("owner")
    APage.activePage["owner"] = ap
    ap:_TRANSITION(STATE_WAIT_START_QUERY)

    return ap
end

function APage:_TRANSITION(newState)
    Auctipus.dbg("APage ["..self.category.."]: "..self.state.." -> "..newState)
    self.state = newState
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

function APage:IsLoading()
    return self.auctions == nil
end

function APage.ForceClose(category)
    local p = APage.activePage[category]
    if p and p.state ~= STATE_CLOSED then
        Auctipus.dbg("Forcing "..category.." page closed.")
        APage.activePage[category]:ClosePage(true)
    end
end

function APage:ClosePage(forced)
    if self:IsActivePage() then
        self:SelectItem(0)
        APage.activePage[self.category] = nil

        local prevState = self.state
        self:_TRANSITION(STATE_CLOSED)

        if self.handler then
            self.handler:PageClosed(self, forced or false)
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

function APage:IsNilAuction(auction)
    return not auction.link or
       (self.category == "list" and not self.query.getAll and
        auction.owner == nil)
end

function APage:ProcessPage()
    local numAuctions, totalAuctions = GetNumAuctionItems(self.category)

    self.totalAuctions = totalAuctions
    self.auctions      = {}
    self.nilAuctions   = {}
    for i = 1, numAuctions do
        local auction = Auctipus.Auction:FromGetAuctionItemInfo(
            i, self.category)
        if self:IsNilAuction(auction) then
            table.insert(self.nilAuctions, auction)
        end
        table.insert(self.auctions, auction)
    end

    if #self.nilAuctions > 0 then
        self:_TRANSITION(STATE_WAIT_PROCESS_NIL)
    else
        self:_TRANSITION(STATE_WAIT_PAGE_UPDATE)
    end

    local delta = #self.auctions - self.lastPageSize
    self.lastPageSize = #self.auctions
    if self.handler then
        self.handler:PageUpdated(self, delta)
    else
        Auctipus.dbg("Page ["..self.category.."] processing complete:")
        self:Dump()
    end
end

function APage:ProcessNilAuctions()
    if #self.nilAuctions == 0 then
        return
    end

    self.nilAuctions = {}
    for i, a in ipairs(self.auctions) do
        if self:IsNilAuction(a) then
            local auction = Auctipus.Auction:FromGetAuctionItemInfo(
                a.pageIndex, self.category)
            if self:IsNilAuction(auction) then
                table.insert(self.nilAuctions, auction)
            end
            self.auctions[i] = auction
        end
    end

    if #self.nilAuctions == 0 then
        self:_TRANSITION(STATE_WAIT_PAGE_UPDATE)
    end

    local delta = #self.auctions - self.lastPageSize
    self.lastPageSize = #self.auctions
    if self.handler then
        self.handler:PageUpdated(self, delta)
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
                self:_TRANSITION(STATE_WAIT_PAGE_UPDATE)
                self:StartQuery()
            end
        elseif self.state == STATE_WAIT_PROCESS_PAGE then
            self:ProcessPage()
        elseif self.state == STATE_WAIT_PROCESS_NIL then
            self:ProcessNilAuctions()
        end
    end
end

function APage.AUCTION_ITEM_LIST_UPDATE()
    Auctipus.dbg("AUCTION_ITEM_LIST_UPDATE")
    local self = APage.activePage["list"]
    if self and (self.state == STATE_WAIT_PAGE_UPDATE or
                 self.state == STATE_WAIT_PROCESS_NIL)
    then
        self:_TRANSITION(STATE_WAIT_PROCESS_PAGE)
    end
end

function APage.AUCTION_OWNED_LIST_UPDATE()
    local self = APage.activePage["owner"]
    if self and (self.state == STATE_WAIT_PAGE_UPDATE or
                 self.state == STATE_WAIT_PROCESS_NIL)
    then
        self:_TRANSITION(STATE_WAIT_PROCESS_PAGE)
    end
end

function APage.AUCTION_HOUSE_CLOSED()
    APage.ForceClose("list")
    APage.ForceClose("owner")
end

function APage:Dump()
    for i, a in ipairs(self.auctions) do
        a:Print()
    end
end

Auctipus.EventManager.Register(APage)
