AOwnerPage = {}
AOwnerPage.__index = AOwnerPage

local pendingPage = nil
local openPage    = nil
local lastOrder   = nil

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

local function IsAHBusy()
    local canQuery, canQueryAll = CanSendAuctionQuery()
    return not canQuery
end

function AOwnerPage:OpenPage(page, handler)
    if openPage ~= nil then
        Auctipus.info("Forcing previous owner page closed.")
        openPage:ClosePage()
    end

    assert(pendingPage == nil)
    local ap = {page          = page,
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

function AOwnerPage:ClosePage()
    if self == pendingPage then
        pendingPage = nil
    end
    if self == openPage then
        openPage = nil
    end

    self.closed = true
end

function AOwnerPage:ConfigureSortOrder()
    SortAuctionClearSort("owner")
    for i, s in ipairs(SORT_ORDER["DURATION"]) do
        SortAuctionSetSort("owner", s.key, s.reverse)
    end
end

function AOwnerPage:StartQuery()
    self:ConfigureSortOrder()
    GetOwnerAuctionItems()
end

function AOwnerPage:ProcessPage()
    local numAuctions, totalAuctions = GetNumAuctionItems("owner")
    Auctipus.info("Num owner auctions: "..numAuctions)

    self.gotListUpdate = false
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
    if ahOpen and pendingPage and not IsAHBusy() then
        openPage    = pendingPage
        pendingPage = nil
        if openPage.handler then
            openPage.handler:PageOpened(openPage)
        end
        Auctipus.info("Page opened "..openPage.page)
        openPage:StartQuery()
    elseif openPage and openPage.gotListUpdate then
        openPage:ProcessPage()
    end
end

function AOwnerPage.AUCTION_HOUSE_SHOW()
    ahOpen = true
end

function AOwnerPage.AUCTION_OWNED_LIST_UPDATE()
    -- Defer to the next OnUpdate handler so that we batch multiple list into a
    -- single page scan.
    if openPage then
        openPage.gotListUpdate = true
    end
end

function AOwnerPage.AUCTION_HOUSE_CLOSED()
    openPage = nil
    ahOpen   = false
    if pendingPage then
        local p = pendingPage
        pendingPage = nil
    end
end

function AOwnerPage:Dump()
    for i, a in ipairs(self.auctions) do
        a:Print()
    end
end

TGEventManager.Register(AOwnerPage)
