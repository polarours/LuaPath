-- Event Sourcing Implementation
-- Version: Lua 5.4
-- Stage 36: Advanced — Event Sourcing

local EventStore = {}
EventStore.__index = EventStore

function EventStore.new()
    return setmetatable({ events = {}, subscribers = {} }, EventStore)
end
function EventStore:append(event_type, data, aggregate_id)
    local event = {
        id = #self.events + 1, type = event_type, data = data,
        aggregate_id = aggregate_id, timestamp = os.time(),
        metadata = { version = #self.events + 1 }
    }
    table.insert(self.events, event)
    for _, cb in ipairs(self.subscribers) do cb(event) end
    return event
end

function EventStore:get_events(aggregate_id)
    if not aggregate_id then return self.events end
    local out = {}
    for _, e in ipairs(self.events) do
        if e.aggregate_id == aggregate_id then table.insert(out, e) end
    end
    return out
end

function EventStore:get_events_since(version)
    local out = {}
    for _, e in ipairs(self.events) do
        if e.metadata.version > version then table.insert(out, e) end
    end
    return out
end

function EventStore:subscribe(cb) table.insert(self.subscribers, cb) end
function EventStore:size() return #self.events end

local BankAccount = {}
BankAccount.__index = BankAccount

function BankAccount.new(store, id)
    return setmetatable({ store = store, id = id, balance = 0, history = {} }, BankAccount)
end

function BankAccount:load()
    self.balance, self.history = 0, {}
    for _, e in ipairs(self.store:get_events(self.id)) do self:_apply(e) end
end

function BankAccount:deposit(amount)
    if amount <= 0 then return false end
    self:_apply(self.store:append("Deposited", { amount = amount }, self.id))
    return true
end

function BankAccount:withdraw(amount)
    if amount <= 0 or amount > self.balance then return false end
    self:_apply(self.store:append("Withdrawn", { amount = amount }, self.id))
    return true
end

function BankAccount:transfer(to_id, amount)
    if amount > self.balance then return false end
    self:_apply(self.store:append("TransferOut", { to = to_id, amount = amount }, self.id))
    self.store:append("TransferIn", { from = self.id, amount = amount }, to_id)
    return true
end

function BankAccount:_apply(e)
    local t = e.type
    if t == "Deposited" or t == "TransferIn" then
        self.balance = self.balance + e.data.amount
    elseif t == "Withdrawn" or t == "TransferOut" then
        self.balance = self.balance - e.data.amount
    end
    table.insert(self.history, e)
end

local Projection = {}
Projection.__index = Projection
function Projection.new(store)
    local self = setmetatable({ accounts = {} }, Projection)
    store:subscribe(function(e) self:on_event(e) end)
    return self
end

function Projection:on_event(e)
    local a = self.accounts[e.aggregate_id]
    if not a then a = { balance = 0, txn_count = 0 }; self.accounts[e.aggregate_id] = a end
    a.txn_count = a.txn_count + 1
    if e.type == "Deposited" or e.type == "TransferIn" then
        a.balance = a.balance + e.data.amount
    elseif e.type == "Withdrawn" or e.type == "TransferOut" then
        a.balance = a.balance - e.data.amount
    end
end
function Projection:summary()
    print("  Account Projection:")
    for id, a in pairs(self.accounts) do
        print(string.format("    %s: balance=$%d, txns=%d", id, a.balance, a.txn_count))
    end
end

local function main()
    print("=== Event Sourcing Demo ===\n")
    local store = EventStore.new()
    local proj = Projection.new(store)

    local alice = BankAccount.new(store, "acc-Alice")
    local bob = BankAccount.new(store, "acc-Bob")

    alice:deposit(1000)
    bob:deposit(500)
    alice:withdraw(200)
    alice:transfer("acc-Bob", 300)

    print("--- Operations ---")
    print("  Alice deposited $1000, withdrew $200, transferred $300 to Bob")
    print("  Bob deposited $500")

    print("\n--- Replay from Event Store ---")
    alice:load(); bob:load()
    print(string.format("  Alice (replayed): $%d", alice.balance))
    print(string.format("  Bob (replayed):   $%d", bob.balance))

    print("\n--- Projection State ---")
    proj:summary()

    print("\n--- Event Log ---")
    for _, e in ipairs(store:get_events()) do
        print(string.format("  #%d [%s] agg=%s amount=$%s",
            e.id, e.type, e.aggregate_id, e.data.amount or ""))
    end

    print("\n--- Temporal Query: After 2 events ---")
    local bal = 0
    for i, e in ipairs(store:get_events_since(0)) do
        if i > 2 then break end
        if e.type == "Deposited" then bal = bal + e.data.amount
        elseif e.type == "Withdrawn" then bal = bal - e.data.amount end
    end
    print(string.format("  Simulated balance: $%d", bal))
    print(string.format("\n  Total events: %d", store:size()))
    print("\n=== Event Sourcing Complete ===")
end

main()
