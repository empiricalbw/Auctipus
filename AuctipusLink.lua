ALink = {}
ALink.__index = AAuction

local function SaneLink(l)
    -- Remove the uniqueID, linkLevel and specializationID fields from the link
    -- since they contain no information usable by the client but can vary for
    -- items that otherwise seem identical.  An example is "Dreadhawk's
    -- Schynbald of the Hunt" which has different uniqueIDs.
    if not l then
        return nil
    end
    return l:gsub(
        "(|Hitem:[^:]+:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*):[^:]*:%d+:%d*",
        "%1::70:")
end

local function LinkColor(l)
    local _, _, a, r, g, b = l:find("|c(..)(..)(..)(..)|H")
    a = tonumber(a, 16)
    r = tonumber(r, 16)
    g = tonumber(g, 16)
    b = tonumber(b, 16)
    return CreateColor(r / 255, g / 255, b / 255, a / 255)
end

local function LinkTexture(l)
    local _, _, itemId = l:find("|Hitem:(%d+):")
    itemId = tonumber(itemId, 10)
    local _, _, _, _, texture = GetItemInfoInstant(itemId)
    return texture
end

local function LinkName(l)
    local _, _, name = l:find("|h%[(.*)%]|h")
    return name
end

function ALink:New(l)
    local al = {
        link    = SaneLink(l),
        color   = LinkColor(l),
        texture = LinkTexture(l),
        name    = LinkName(l),
        uname   = nil,
    }
    al.uname = al.name:upper()
    setmetatable(al, self)

    return al
end

