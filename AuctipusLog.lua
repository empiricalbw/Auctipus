Auctipus.Log = {}
Auctipus.Log.__index = Auctipus.Log

function Auctipus.Log:new(...)
    local log = {}
    setmetatable(log, self)
    log:Log(...)
    return log
end

function Auctipus.Log:Log(min_level, echo_level)
    -- Creates a Log object which filters all log messages whose level is below
    -- the Log object's minimum level.
    self.lines      = {}
    self.min_level  = min_level
    self.echo_level = echo_level
end

function Auctipus.Log:clear()
    self.lines = {}
end

function Auctipus.Log:log(level, ...)
    if level < min(self.min_level, self.echo_level) then
        return
    end

    local args = {n = select("#", ...), ...}
    local msg = ""
    for i=1, args.n do
        msg = msg..tostring(args[i])
    end

    if level >= self.min_level then
        table.insert(self.lines, msg)
    end

    if level >= self.echo_level then
        print(msg)
    end
end

function Auctipus.Log:dump()
    for _, msg in ipairs(self.lines) do
        print(msg)
    end
end

-- Global logging methods for all of Auctipus.
Auctipus.log = Auctipus.Log:new(1, 2)

function Auctipus._log(lvl, ...)
    local timestamp = GetTime()
    Auctipus.log:log(
        lvl, "[", timestamp, "] ",
        LIGHTYELLOW_FONT_COLOR_CODE.."Auctipus: "..FONT_COLOR_CODE_CLOSE,
        ...)
end

function Auctipus.dbg(...)
    Auctipus._log(1, ...)
end

function Auctipus.info(...)
    Auctipus._log(2, ...)
end
