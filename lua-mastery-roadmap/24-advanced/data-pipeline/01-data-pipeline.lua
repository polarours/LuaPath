-- Example: Data Pipeline
-- Stage: 24
-- Difficulty: Advanced
-- Lua Version: 5.1+
-- Demonstrates: pipeline composition, map/filter/reduce, lazy evaluation

local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline.new(data)
    return setmetatable({ _source = data, _ops = {} }, Pipeline)
end

function Pipeline:map(fn)
    self._ops[#self._ops + 1] = { t = "map", fn = fn }
    return self
end

function Pipeline:filter(fn)
    self._ops[#self._ops + 1] = { t = "filter", fn = fn }
    return self
end

function Pipeline:flat_map(fn)
    self._ops[#self._ops + 1] = { t = "flat_map", fn = fn }
    return self
end

function Pipeline:take(n)
    self._ops[#self._ops + 1] = { t = "take", n = n }
    return self
end

function Pipeline:_run(finalize)
    local count = 0
    local result = {}
    for _, item in ipairs(self._source) do
        local cur, ok = item, true
        for _, op in ipairs(self._ops) do
            if op.t == "filter" then
                if not op.fn(cur) then ok = false; break end
            elseif op.t == "map" then
                cur = op.fn(cur)
            elseif op.t == "flat_map" then
                for _, v in ipairs(op.fn(cur)) do result[#result + 1] = v end
                ok = false; break
            elseif op.t == "take" then
                -- handled after finalize
            end
        end
        if ok then
            count = count + 1
            result[count] = cur
        end
    end
    -- apply take after collecting
    for _, op in ipairs(self._ops) do
        if op.t == "take" then
            local trimmed = {}
            for i = 1, math.min(op.n, #result) do trimmed[i] = result[i] end
            result = trimmed
        end
    end
    return finalize and finalize(result) or result
end

function Pipeline:reduce(fn, init)
    return self:_run(function(data)
        local acc = init
        for _, v in ipairs(data) do acc = fn(acc, v) end
        return acc
    end)
end

function Pipeline:collect() return self:_run() end

-- Demo: Order processing pipeline
local orders = {
    { id = 1, customer = "Alice",   status = "completed", amount = 50.0,  items = 2 },
    { id = 2, customer = "Bob",     status = "pending",   amount = 120.0, items = 5 },
    { id = 3, customer = "Charlie", status = "completed", amount = 75.5,  items = 3 },
    { id = 4, customer = "Diana",   status = "cancelled", amount = 30.0,  items = 1 },
    { id = 5, customer = "Eve",     status = "completed", amount = 200.0, items = 8 },
    { id = 6, customer = "Frank",   status = "pending",   amount = 95.0,  items = 4 },
    { id = 7, customer = "Grace",   status = "completed", amount = 45.0,  items = 2 },
    { id = 8, customer = "Heidi",   status = "cancelled", amount = 60.0,  items = 3 },
}

local function main()
    -- Completed orders total
    local total = Pipeline.new(orders)
        :filter(function(o) return o.status == "completed" end)
        :reduce(function(s, o) return s + o.amount end, 0)
    print(string.format("Completed orders total: $%.2f", total))

    -- Summary stats for completed orders
    local s = Pipeline.new(orders)
        :filter(function(o) return o.status == "completed" end)
        :reduce(function(a, o)
            a.count = a.count + 1
            a.items = a.items + o.items
            a.amount = a.amount + o.amount
            return a
        end, { count = 0, items = 0, amount = 0 })
    print(string.format("  Orders: %d, Avg items: %.1f, Avg amount: $%.2f",
        s.count, s.items / s.count, s.amount / s.count))

    -- Top 3 orders over $50
    local top = Pipeline.new(orders)
        :map(function(o) return { name = o.customer, amount = o.amount } end)
        :filter(function(o) return o.amount > 50 end)
        :take(3)
        :collect()
    print("\nTop 3 orders over $50:")
    for i, o in ipairs(top) do
        print(string.format("  %d. %s — $%.2f", i, o.name, o.amount))
    end

    -- Flat map: item labels for completed orders
    local labels = Pipeline.new(orders)
        :filter(function(o) return o.status == "completed" end)
        :flat_map(function(o)
            local t = {}
            for i = 1, o.items do t[i] = string.format("%s#%d", o.customer, i) end
            return t
        end)
        :take(10)
        :collect()
    print("\nItem labels (first 10):")
    for _, l in ipairs(labels) do io.write("  " .. l) end
    print()
end

main()
