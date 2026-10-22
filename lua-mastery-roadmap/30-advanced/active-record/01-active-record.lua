-- Active Record Pattern Implementation
-- Version: Lua 5.4
-- Stage 30: Advanced — Active Record

local ActiveRecord = {}
ActiveRecord.__index = ActiveRecord

-- Shared in-memory store (simulates a database)
local Store = { next_id = 1, records = {} }

function ActiveRecord.new(data)
    local self = setmetatable({}, ActiveRecord)
    self.id = nil
    self._dirty = {}
    self._errors = {}
    for k, v in pairs(data or {}) do
        self[k] = v
        self._dirty[k] = true
    end
    return self
end

function ActiveRecord:set(key, value)
    self[key] = value
    self._dirty[key] = true
end

function ActiveRecord:validate()
    self._errors = {}
    if not self.name or self.name == "" then
        table.insert(self._errors, "name is required")
    end
    if self.age and (type(self.age) ~= "number" or self.age < 0) then
        table.insert(self._errors, "age must be a non-negative number")
    end
    return #self._errors == 0
end

function ActiveRecord:save()
    if not self:validate() then
        return false, self._errors
    end
    if self.id then
        Store.records[self.id] = self
    else
        self.id = Store.next_id
        Store.next_id = Store.next_id + 1
        Store.records[self.id] = self
    end
    self._dirty = {}
    return true
end

function ActiveRecord:delete()
    if self.id and Store.records[self.id] then
        Store.records[self.id] = nil
        self.id = nil
        return true
    end
    return false
end

-- __tostring, not tostring: Lua's tostring() looks for the __tostring
-- metamethod. A plain method named "tostring" would never be called by it.
--
-- Metamethods are looked up with a raw access on the metatable, so the
-- subclass has to put __tostring in its own metatable -- it does not follow
-- the metatable's __index chain.
function ActiveRecord.__tostring(self)
    local parts = { string.format("id=%s", tostring(self.id)) }
    for k, v in pairs(self) do
        if k:sub(1, 1) ~= "_" and k ~= "id" then
            table.insert(parts, string.format("%s=%s", k, tostring(v)))
        end
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

function ActiveRecord.find(id)
    return Store.records[id]
end

function ActiveRecord.find_by(criteria)
    local results = {}
    for _, record in pairs(Store.records) do
        local match = true
        for k, v in pairs(criteria) do
            if record[k] ~= v then match = false; break end
        end
        if match then table.insert(results, record) end
    end
    return results
end

function ActiveRecord.count()
    local n = 0
    for _ in pairs(Store.records) do n = n + 1 end
    return n
end

-- Concrete model using the base class
local User = setmetatable({}, { __index = ActiveRecord })

-- Shared metatable for User instances. __tostring has to live here directly:
-- metamethod lookup is a raw get on the metatable and does not follow the
-- metatable's own __index chain.
local user_mt = { __index = User }
user_mt.__tostring = ActiveRecord.__tostring

function User.new(data)
    local self = ActiveRecord.new(data)
    setmetatable(self, user_mt)
    return self
end

-- Example usage
local function main()
    print("=== Active Record Demo ===\n")

    -- Create and save
    local alice = User.new({ name = "Alice", age = 30, email = "alice@example.com" })
    local ok, errs = alice:save()
    print("Save Alice:", ok, table.concat(errs or {}, ", "))
    print("  ->", tostring(alice))

    local bob = User.new({ name = "Bob", age = 25, email = "bob@example.com" })
    bob:save()
    print("Save Bob:", tostring(bob))

    -- Validation failure
    local bad = User.new({ name = "", age = -5 })
    ok, errs = bad:save()
    print("\nSave invalid:", ok)
    for _, e in ipairs(errs) do print("  Error:", e) end

    -- Find
    print("\nFind by ID:", tostring(User.find(1)))
    print("Find by name:", tostring(User.find_by({ name = "Bob" })[1]))
    print("Count:", User.count())

    -- Update
    alice:set("age", 31)
    alice:save()
    print("\nAfter update:", tostring(alice))

    -- Delete
    bob:delete()
    print("\nAfter deleting Bob, count:", User.count())
    print("Find Bob:", tostring(User.find(2)))
end

main()
