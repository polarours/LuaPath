--[[
  Example: Observer Pattern
  Chapter: Stage 20 — Advanced
  Difficulty: Advanced
  Lua Version: 5.4
  Demonstrates: Observable subject, multiple observers, weak references, event filtering
]]

local Observable = {}
Observable.__index = Observable

function Observable:new()
    local self = setmetatable({}, Observable)
    self.observers = {}
    self.weakObservers = {}
    return self
end

function Observable:subscribe(observer, filter)
    local id = #self.observers + 1
    self.observers[id] = { observer = observer, filter = filter }
    return id
end

function Observable:subscribeWeak(observer, filter)
    local id = #self.weakObservers + 1
    self.weakObservers[id] = { observer = setmetatable({}, { __mode = "v" }), filter = filter }
    self.weakObservers[id].observer.ref = observer
    return id
end

function Observable:unsubscribe(id)
    self.observers[id] = nil
    self.weakObservers[id] = nil
end

function Observable:notify(event, data)
    for id, entry in pairs(self.observers) do
        if not entry.filter or entry.filter(event, data) then
            entry.observer:onEvent(event, data)
        end
    end

    for id, entry in pairs(self.weakObservers) do
        if entry.observer.ref then
            if not entry.filter or entry.filter(event, data) then
                entry.observer.ref:onEvent(event, data)
            end
        else
            self.weakObservers[id] = nil
        end
    end
end

-- Concrete Observers
local Logger = {}
Logger.__index = Logger

function Logger:new(name)
    return setmetatable({ name = name }, Logger)
end

function Logger:onEvent(event, data)
    print(string.format("  [%s] Event: %s | Data: %s", self.name, event, tostring(data)))
end

local AlertObserver = {}
AlertObserver.__index = AlertObserver

function AlertObserver:new(threshold)
    return setmetatable({ threshold = threshold, alerts = {} }, AlertObserver)
end

function AlertObserver:onEvent(event, data)
    if type(data) == "number" and data > self.threshold then
        self.alerts[#self.alerts + 1] = { event = event, data = data }
        print(string.format("  [ALERT] %s exceeded threshold: %s > %s", event, data, self.threshold))
    end
end

local Counter = {}
Counter.__index = Counter

function Counter:new()
    return setmetatable({ counts = {} }, Counter)
end

function Counter:onEvent(event, data)
    self.counts[event] = (self.counts[event] or 0) + 1
end

function Counter:report()
    print("  Event counts:")
    for event, count in pairs(self.counts) do
        print(string.format("    %s: %d", event, count))
    end
end

-- Demo
local function main()
    print("=== Observer Pattern Demo ===\n")

    local subject = Observable:new()
    local logger1 = Logger:new("logger-1")
    local logger2 = Logger:new("logger-2")
    local alerter = AlertObserver:new(80)
    local counter = Counter:new()

    print("--- Subscribe observers ---")
    local id1 = subject:subscribe(logger1)
    local id2 = subject:subscribe(logger2)
    local id3 = subject:subscribe(alerter, function(event, data)
        return event == "temperature"
    end)
    local id4 = subject:subscribe(counter)

    print("\n--- Notify events ---")
    subject:notify("temperature", 75)
    subject:notify("humidity", 45)
    subject:notify("temperature", 95)
    subject:notify("pressure", 1013)

    print("\n--- Counter report ---")
    counter:report()

    print("\n--- Unsubscribe logger2 ---")
    subject:unsubscribe(id2)
    subject:notify("temperature", 82)

    print("\n--- Weak reference demo ---")
    local tempData = { value = 88 }
    subject:subscribeWeak(logger1)
    subject:notify("temperature", tempData.value)
    tempData = nil
    collectgarbage()
    print("  Weak observer notified (before GC collects)")

    print("\n--- Alert history ---")
    print("  Alerts triggered:", #alerter.alerts)

    print("\n=== Observer pattern complete ===")
end

main()

return Observable
