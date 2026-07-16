--[[
  Example: Schema Validator
  Chapter: Stage 17 — Advanced
  Difficulty: Advanced
  Lua Version: 5.4
  Demonstrates: Recursive validation, type checking, nested schema definitions
]]

local Validator = {}
Validator.__index = Validator

function Validator:new()
    local self = setmetatable({}, Validator)
    self.errors = {}
    return self
end

local typeCheckers = {}

local function addTypeError(self, path, expected, got)
    self.errors[#self.errors + 1] = { path = path, message = "Expected " .. expected .. ", got " .. got }
end

typeCheckers.string = function(self, value, path)
    if type(value) ~= "string" then addTypeError(self, path, "string", type(value)) end
end
typeCheckers.number = function(self, value, path)
    if type(value) ~= "number" then addTypeError(self, path, "number", type(value)) end
end
typeCheckers.boolean = function(self, value, path)
    if type(value) ~= "boolean" then addTypeError(self, path, "boolean", type(value)) end
end
typeCheckers.integer = function(self, value, path)
    if type(value) ~= "number" or value ~= math.floor(value) then addTypeError(self, path, "integer", type(value)) end
end

typeCheckers.array = function(self, value, path, itemSchema)
    if type(value) ~= "table" then addTypeError(self, path, "array", type(value)); return end
    for i, item in ipairs(value) do self:validateItem(item, itemSchema, path .. "[" .. i .. "]") end
end

typeCheckers.object = function(self, value, path, nestedSchema)
    if type(value) ~= "table" then addTypeError(self, path, "object", type(value)); return end
    self:validateObject(value, nestedSchema, path)
end

function Validator:validateItem(value, schema, path)
    if schema.type and typeCheckers[schema.type] then
        if schema.type == "array" then
            typeCheckers.array(self, value, path, schema.items or {})
        elseif schema.type == "object" then
            typeCheckers.object(self, value, path, schema.properties or {})
        else
            typeCheckers[schema.type](self, value, path)
        end
    end
end

function Validator:validateObject(data, schema, path)
    path = path or "root"
    if not self.errors then self.errors = {} end
    for field, rules in pairs(schema) do
        local fp = path .. "." .. field
        local value = data[field]
        if rules.required and value == nil then
            self.errors[#self.errors + 1] = { path = fp, message = "Required field missing" }
        elseif value ~= nil then
            self:validateItem(value, rules, fp)
            if rules.enum then
                local found = false
                for _, v in ipairs(rules.enum) do
                    if v == value then found = true; break end
                end
                if not found then
                    self.errors[#self.errors + 1] = { path = fp, message = "Value not in enum: " .. tostring(value) }
                end
            end
            if rules.min and type(value) == "number" and value < rules.min then
                self.errors[#self.errors + 1] = { path = fp, message = "Below min: " .. value .. " < " .. rules.min }
            end
            if rules.max and type(value) == "number" and value > rules.max then
                self.errors[#self.errors + 1] = { path = fp, message = "Above max: " .. value .. " > " .. rules.max }
            end
        end
    end
end

function Validator:validate(data, schema)
    self.errors = {}
    self:validateObject(data, schema)
    return #self.errors == 0, self.errors
end

-- Demo
local function main()
    print("=== Schema Validator Demo ===\n")
    local userSchema = {
        name    = { type = "string", required = true },
        age     = { type = "integer", required = true, min = 0, max = 150 },
        email   = { type = "string", required = true },
        role    = { type = "string", enum = { "admin", "user", "guest" } },
        address = {
            type = "object",
            properties = {
                street = { type = "string", required = true },
                city   = { type = "string", required = true },
                zip    = { type = "string" },
            }
        },
        tags = { type = "array", items = { type = "string" } }
    }
    local validUser = {
        name = "Alice", age = 30, email = "alice@example.com", role = "admin",
        address = { street = "123 Main St", city = "Springfield", zip = "62701" },
        tags = { "dev", "ops" }
    }
    local invalidUser = {
        name = 123, age = -5, email = "bob@example.com", role = "superuser",
        address = { street = "456 Oak Ave" }, tags = { "dev", 42, "ops" }
    }
    print("--- Valid User ---")
    local ok1, errs1 = Validator:new():validate(validUser, userSchema)
    print("  Valid:", ok1)
    if errs1 then for _, e in ipairs(errs1) do print("  Error:", e.path, e.message) end end
    print("\n--- Invalid User ---")
    local ok2, errs2 = Validator:new():validate(invalidUser, userSchema)
    print("  Valid:", ok2)
    if errs2 then for _, e in ipairs(errs2) do print("  Error:", e.path, e.message) end end
    print("\n=== Schema validation complete ===")
end

main()
