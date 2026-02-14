-- CallbackHandler-1.0 - Event callback registration and dispatching
-- License: Public Domain / CC0

local MAJOR, MINOR = "CallbackHandler-1.0", 7
local CallbackHandler = LibStub:NewLibrary(MAJOR, MINOR)
if not CallbackHandler then return end

local meta = { __index = function(tbl, key) tbl[key] = {} return tbl[key] end }

function CallbackHandler:New(target, RegisterName, UnregisterName, UnregisterAllName)
    RegisterName      = RegisterName      or "RegisterCallback"
    UnregisterName    = UnregisterName    or "UnregisterCallback"
    UnregisterAllName = UnregisterAllName or "UnregisterAllCallbacks"

    local events = setmetatable({}, meta)
    local registry = { recurse = 0 }

    target[RegisterName] = function(self, eventname, method, ...)
        if type(eventname) ~= "string" then
            error("Usage: " .. RegisterName .. "(eventname, method[, arg])", 2)
        end
        method = method or eventname
        if type(method) == "string" then
            if type(self) ~= "table" then
                error("Usage: " .. RegisterName .. "(eventname, method): self must be a table", 2)
            end
            events[eventname][self] = { self[method], select("#", ...) > 0 and { ... } or nil, self }
        elseif type(method) == "function" then
            events[eventname][self] = { method, select("#", ...) > 0 and { ... } or nil }
        end
        if registry.OnUsed then
            registry:OnUsed(target, eventname)
        end
    end

    target[UnregisterName] = function(self, eventname)
        if not rawget(events, eventname) then return end
        events[eventname][self] = nil
        if not next(events[eventname]) and registry.OnUnused then
            registry:OnUnused(target, eventname)
        end
    end

    target[UnregisterAllName] = function(self)
        for eventname, callbacks in pairs(events) do
            callbacks[self] = nil
            if not next(callbacks) and registry.OnUnused then
                registry:OnUnused(target, eventname)
            end
        end
    end

    function registry:Fire(eventname, ...)
        if not rawget(events, eventname) or not next(events[eventname]) then return end
        local oldrecurse = registry.recurse
        registry.recurse = oldrecurse + 1
        for obj, info in pairs(events[eventname]) do
            local func = info[1]
            local args = info[2]
            local selfArg = info[3]
            if selfArg then
                if args then
                    func(selfArg, unpack(args))
                else
                    func(selfArg, ...)
                end
            else
                if args then
                    func(unpack(args))
                else
                    func(...)
                end
            end
        end
        registry.recurse = oldrecurse
    end

    target.Fire = registry.Fire

    return registry
end
