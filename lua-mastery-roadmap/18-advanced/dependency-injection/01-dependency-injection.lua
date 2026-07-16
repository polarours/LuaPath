--[[
  Example: Dependency Injection
  Chapter: Stage 18 — Advanced
  Difficulty: Advanced
  Lua Version: 5.4
  Demonstrates: IoC container, service registration, lifecycle management, circular detection
]]

local Container = {}
Container.__index = Container

function Container:new()
    local self = setmetatable({}, Container)
    self.services = {}
    self.singletons = {}
    self.resolving = {}
    return self
end

function Container:register(name, factory, lifecycle)
    self.services[name] = {
        factory = factory,
        lifecycle = lifecycle or "transient"
    }
end

function Container:registerInstance(name, instance)
    self.services[name] = nil
    self.singletons[name] = instance
end

function Container:resolve(name)
    if self.singletons[name] then
        return self.singletons[name]
    end

    local service = self.services[name]
    if not service then
        error("Service not registered: " .. tostring(name))
    end

    if self.resolving[name] then
        error("Circular dependency detected: " .. tostring(name))
    end

    self.resolving[name] = true
    local instance = service.factory(self)
    self.resolving[name] = nil

    if service.lifecycle == "singleton" then
        self.singletons[name] = instance
    end

    return instance
end

function Container:has(name)
    return self.services[name] ~= nil or self.singletons[name] ~= nil
end

function Container:reset()
    self.singletons = {}
end

-- Demo services
local function createLogger()
    return { log = function(self, msg) print("  [LOG] " .. msg) end }
end

local function createDatabase(container)
    local logger = container:resolve("logger")
    return {
        logger = logger,
        query = function(self, sql)
            self.logger:log("Executing: " .. sql)
            return { { id = 1, name = "result" } }
        end
    }
end

local function createUserService(container)
    local db = container:resolve("database")
    local logger = container:resolve("logger")
    return {
        db = db,
        logger = logger,
        getUser = function(self, id)
            self.logger:log("Getting user " .. id)
            return self.db:query("SELECT * FROM users WHERE id=" .. id)
        end
    }
end

-- Demo
local function main()
    print("=== Dependency Injection Demo ===\n")

    local container = Container:new()

    container:register("logger", createLogger, "singleton")
    container:register("database", createDatabase, "singleton")
    container:register("userService", createUserService, "transient")

    print("--- Resolving services ---")
    local logger = container:resolve("logger")
    logger:log("Logger initialized")

    local db = container:resolve("database")
    db:query("SELECT 1")

    local userService = container:resolve("userService")
    userService:getUser(42)

    print("\n--- Singleton check ---")
    local logger2 = container:resolve("logger")
    print("  Same logger instance:", logger == logger2)

    print("\n--- Transient check ---")
    local svc1 = container:resolve("userService")
    local svc2 = container:resolve("userService")
    print("  Different service instances:", svc1 ~= svc2)

    print("\n--- Container state ---")
    print("  Has logger:", container:has("logger"))
    print("  Has unknown:", container:has("unknown"))

    print("\n=== Dependency injection complete ===")
end

main()
