AEventManager = {}

local function starts_with(str, start)
    return str:sub(1, #start) == start
end

function AEventManager.Initialize()
    AEventManager.eventListeners  = {}
    AEventManager.updateListeners = {}
    AEventManager.cleuListeners   = {}

    -- A dummy frame to get us the events we are interested in.
    AEventManager.aeFrame = CreateFrame("Frame")
    AEventManager.aeFrame:SetScript("OnEvent", AEventManager.OnEvent)
    AEventManager.aeFrame:SetScript("OnUpdate", AEventManager.OnUpdate)
end

function AEventManager.Register(obj)
    -- All keys in obj that are completely uppercase are assumed to be event
    -- handler static methods.  If an "OnUpdate" method exists, it is also
    -- registered and assumed to be a static method.
    for k in pairs(obj) do
        if string.upper(k) == k then
            if not starts_with(k, "_") then
                AEventManager.aeFrame:RegisterEvent(k)
                if AEventManager.eventListeners[k] == nil then
                    AEventManager.eventListeners[k] = {}
                end
                table.insert(AEventManager.eventListeners[k], obj)
            end
        end
    end

    if obj["OnUpdate"] ~= nil then
        table.insert(AEventManager.updateListeners, obj)
    end
end

function AEventManager.OnEvent(frame, event, ...)
    for _, l in ipairs(AEventManager.eventListeners[event]) do
        l[event](...)
    end
end

function AEventManager.OnUpdate()
    for _, ul in ipairs(AEventManager.updateListeners) do
        ul.OnUpdate()
    end
end

AEventManager.Initialize()
