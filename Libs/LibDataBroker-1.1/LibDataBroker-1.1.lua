-- LibDataBroker-1.1 - Data object registry for LDB display addons
-- License: Public Domain / CC0

local MAJOR, MINOR = "LibDataBroker-1.1", 4
local lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
lib.attributestorage = lib.attributestorage or {}
lib.namestorage      = lib.namestorage or {}
lib.proxystorage     = lib.proxystorage or {}

local attributestorage = lib.attributestorage
local namestorage      = lib.namestorage
local proxystorage     = lib.proxystorage
local callbacks        = lib.callbacks

function lib:DataObjectIterator()
    return pairs(proxystorage)
end

function lib:GetDataObjectByName(name)
    return proxystorage[name]
end

function lib:GetNameByDataObject(dataobj)
    return namestorage[dataobj]
end

local domt = {
    __index = function(self, key)
        return attributestorage[self] and attributestorage[self][key]
    end,
    __newindex = function(self, key, value)
        if not attributestorage[self] then attributestorage[self] = {} end
        attributestorage[self][key] = value
        local name = namestorage[self]
        if name then
            callbacks:Fire("LibDataBroker_AttributeChanged", name, key, value, self)
            callbacks:Fire("LibDataBroker_AttributeChanged_" .. name, name, key, value, self)
            callbacks:Fire("LibDataBroker_AttributeChanged_" .. name .. "_" .. key, name, key, value, self)
            callbacks:Fire("LibDataBroker_AttributeChanged__" .. key, name, key, value, self)
        end
    end,
}

function lib:NewDataObject(name, dataobj)
    if proxystorage[name] then return proxystorage[name] end

    local proxy = setmetatable({}, domt)
    attributestorage[proxy] = {}
    namestorage[proxy] = name
    proxystorage[name] = proxy

    if dataobj then
        for k, v in pairs(dataobj) do
            proxy[k] = v
        end
    end

    callbacks:Fire("LibDataBroker_DataObjectCreated", name, proxy)
    return proxy
end
