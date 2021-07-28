AOwnerPage = {
    activePage = nil,
}
AOwnerPage.__index = AOwnerPage

local SORT_ORDER = {
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

local STATE_WAIT_START_QUERY  = 1
local STATE_WAIT_PAGE_UPDATE  = 2
local STATE_WAIT_PROCESS_PAGE = 3
local STATE_CLOSED            = 4

local function IsAHBusy()
    local canQuery, canQueryAll = CanSendAuctionQuery()
    return not canQuery
end

function AOwnerPage:OpenPage(page, handler)
    if AOwnerPage.activePage then
        Auctipus.info("Forcing previous owner page closed.")
        AOwnerPage.activePage:ClosePage()
    end

    local ap = {state         = STATE_WAIT_START_QUERY,
                page          = page,
                handler       = handler,
                totalAuctions = nil,
                auctions      = nil,
                nilAuctions   = nil,
                }
    setmetatable(ap, self)

    AOwnerPage.activePage = ap
end

function AOwnerPage:IsActivePage()
    return self == AOwnerPage.activePage
end

function AOwnerPage:ClosePage()
    if self:IsActivePage() then
        AOwnerPage.activePage = nil
    end

    self.state = STATE_CLOSED
    if self.handler then
        self.handler:PageClosed(self)
    end
end

function AOwnerPage:StartQuery()
    SortAuctionClearSort("owner")
    for i, s in ipairs(SORT_ORDER["DURATION"]) do
        SortAuctionSetSort("owner", s.key, s.reverse)
    end

    GetOwnerAuctionItems()
end

function AOwnerPage:ProcessPage()
    local numAuctions, totalAuctions = GetNumAuctionItems("owner")

    self.totalAuctions = totalAuctions
    self.auctions      = {}
    self.nilAuctions   = {}
    for i = 1, numAuctions do
        local auction = AAuction:FromGetAuctionItemInfo(i, "owner")
        if auction.owner == nil or auction.link == nil then
            table.insert(self.nilAuctions, auction)
        end
        table.insert(self.auctions, auction)
    end

    if self.handler then
        self.handler:PageUpdated(self)
    else
        Auctipus.info("Owner page processing complete:")
        self:Dump()
    end
end

function AOwnerPage.OnUpdate()
    local self = AOwnerPage.activePage
    if not self then
        return
    end

    if self.state == STATE_WAIT_START_QUERY then
        if not IsAHBusy() then
            if self.handler then
                self.handler:PageOpened(self)
            end

            self.state = STATE_WAIT_PAGE_UPDATE
            self:StartQuery()
        end
    elseif self.state == STATE_WAIT_PROCESS_PAGE then
        self.state = STATE_WAIT_PAGE_UPDATE
        self:ProcessPage()
    end
end

function AOwnerPage.AUCTION_OWNED_LIST_UPDATE()
    -- Defer to the next OnUpdate handler so that we batch multiple list into a
    -- single page scan.
    local self = AOwnerPage.activePage
    if not self then
        return
    end

    self.state = STATE_WAIT_PROCESS_PAGE
end

function AOwnerPage.AUCTION_HOUSE_CLOSED()
    local self = AOwnerPage.activePage
    if not self then
        return
    end

    self:ClosePage()
end

function AOwnerPage:Dump()
    for i, a in ipairs(self.auctions) do
        a:Print()
    end
end

TGEventManager.Register(AOwnerPage)
