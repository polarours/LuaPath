--[[
  Project:    Prototype-Based Entity Model
  Difficulty: Stage B (Intermediate)
  Demonstrates: Prototype inheritance via metatables, read-only overlays,
                set-based tags, clone/merge/equals on entity objects
]]
-- Lua Version: 5.4

local Entity = {}
Entity.__index = Entity

function Entity.new(id, name, etype, tags)
    local self = setmetatable({}, Entity)
    self.id   = id
    self.name = name
    self.type = etype
    self.tags = {}
    if tags then
        for _, t in ipairs(tags) do self.tags[t] = true end
    end
    return self
end

function Entity:has_tag(tag)
    return self.tags[tag] == true
end

function Entity:add_tag(tag)
    self.tags[tag] = true
end

function Entity:clone()
    local copy = setmetatable({}, getmetatable(self))
    for k, v in pairs(self) do
        if k == "tags" then
            copy.tags = {}
            for t, _ in pairs(v) do copy.tags[t] = true end
        else
            copy[k] = v
        end
    end
    return copy
end

function Entity:merge(other)
    for k, v in pairs(other) do
        if k == "tags" then
            for t, _ in pairs(v) do self.tags[t] = true end
        else
            self[k] = v
        end
    end
    return self
end

function Entity:equals(other)
    if self.id ~= other.id or self.name ~= other.name or self.type ~= other.type then
        return false
    end
    for t, _ in pairs(self.tags) do
        if not other.tags[t] then return false end
    end
    for t, _ in pairs(other.tags) do
        if not self.tags[t] then return false end
    end
    return true
end

-- Read-only overlay: proxy delegates reads to entity, blocks all writes
local MUTATING = { add_tag = true }

local function ReadOnly_new(entity)
    local proxy = {}
    local mt = {
        __index = function(_, k)
            if MUTATING[k] then
                return function() error("attempt to write to read-only entity", 2) end
            end
            return rawget(Entity, k) or entity[k]
        end,
        __newindex = function(_, _, _)
            error("attempt to write to read-only entity", 2)
        end,
    }
    return setmetatable(proxy, mt)
end

-- Demo
local function main()
    local player = Entity.new(1, "Hero", "character", { "playable", "mobile" })
    print("Created:  " .. player.name .. " [" .. player.type .. "]")

    local copy = player:clone()
    copy.name = "Clone Hero"
    print("Cloned:   " .. copy.name .. " (original: " .. player.name .. ")")

    local npc = Entity.new(2, "Merchant", "npc", { "shop", "mobile" })
    player:merge(npc)
    print("Merged:   " .. player.name .. " tags:")
    for t, _ in pairs(player.tags) do print("  - " .. t) end

    print("Equal?    " .. tostring(player:equals(copy)))

    local frozen = ReadOnly_new(player)
    print("Read-only name: " .. frozen.name)
    print("Has shop tag?   " .. tostring(frozen:has_tag("shop")))

    local ok, err = pcall(function() frozen.name = "Hacked" end)
    if not ok then print("Blocked:  " .. err) end

    ok, err = pcall(function() frozen:add_tag("cheat") end)
    if not ok then print("Blocked:  " .. err) end
end

main()
