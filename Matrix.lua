Matrix = {}
Matrix.__index = Matrix

function Matrix:New(auctions)
    local m = {}
    setmetatable(m, self)
    m:Init(auctions)
    return m
end

function Matrix:Init(auctions)
    self.auctions = {}
    self.max_j    = 0
    self.max_opt  = 0
    for _, a in ipairs(auctions) do
        if a:IsBuyable() then
            self.max_j = self.max_j + a.count
            table.insert(self.auctions, a)
        end
    end
    self.max_i = #self.auctions
    self.m     = {}
    for i=1, self.max_j * self.max_i do
        self.m[i] = 0
    end
end

function Matrix:Set(i, j, val)
    assert(1 <= i and i <= self.max_i)
    assert(1 <= j and j <= self.max_j)
    self.m[(i - 1)*self.max_j + j] = val
end

function Matrix:Get(i, j)
    assert(0 <= i and i <= self.max_i)
    assert(j <= self.max_j)
    if j < 1 then
        return 0
    elseif i == 0 then
        return math.huge
    end
    return self.m[(i - 1)*self.max_j + j]
end

function Matrix:Optimize(max_j)
    max_j = min(max_j, self.max_j)
    for i=1, self.max_i do
        for j=self.max_opt + 1, max_j do
            self:Set(i, j, math.min(
                self:Get(i - 1, j),
                self:Get(i - 1, j - self.auctions[i].count) +
                    self.auctions[i].buyoutPrice))
        end
    end
    self.max_opt = max(self.max_opt, max_j)
end

function Matrix:_GetElems(i, j, results)
    if i == 0 then
        return
    elseif self:Get(i, j) < self:Get(i - 1, j) then
        results[#results + 1] = self.auctions[i]
        self:_GetElems(i - 1, math.max(j - self.auctions[i].count, 0), results)
    else
        self:_GetElems(i - 1, j, results)
    end
end

function Matrix:GetElems(j)
    if j < 1 or j > self.max_j then
        return nil
    end

    local cost = self:Get(self.max_i, j)
    while j < self.max_j and self:Get(self.max_i, j + 1) == cost do
        j = j + 1
    end

    local results = {}
    self:_GetElems(self.max_i, j, results)
    return results
end
