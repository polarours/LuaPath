-- Example 13: State Machine Patterns
-- Chapter: 07-advanced
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: table-based FSM, coroutine-based FSM, state transitions
-- Shows: traffic light, game character states, turnstile

local function main()
    print("=== State Machine Patterns ===\n")

    -- 1. Table-based FSM
    print("--- Traffic Light (Table FSM) ---")

    local function make_fsm(states, initial)
        local fsm = {
            state = initial,
            transitions = states,
        }

        function fsm:fire(event)
            local transition = self.transitions[self.state]
                and self.transitions[self.state][event]
            if transition then
                local old = self.state
                self.state = transition.target
                if transition.action then transition.action() end
                return true, old, self.state
            end
            return false
        end

        function fsm:status()
            return self.state
        end

        return fsm
    end

    local traffic_light = make_fsm({
        red    = { timeout = { target = "green",  action = function() print("  -> GREEN light") end } },
        green  = { timeout = { target = "yellow", action = function() print("  -> YELLOW light") end } },
        yellow = { timeout = { target = "red",    action = function() print("  -> RED light") end } },
    }, "red")

    for i = 1, 6 do
        traffic_light:fire("timeout")
    end

    -- 2. Game Character States
    print("\n--- Game Character (Table FSM) ---")

    local character = make_fsm({
        idle = {
            move    = { target = "running",  action = function() print("  [idle->running] started moving") end },
            attack  = { target = "attacking", action = function() print("  [idle->attacking] punching!") end },
        },
        running = {
            stop    = { target = "idle",     action = function() print("  [running->idle] stopped") end },
            attack  = { target = "attacking", action = function() print("  [running->attacking] kick!") end },
            hit     = { target = "hurt",     action = function() print("  [running->hurt] took damage!") end },
        },
        attacking = {
            done    = { target = "idle",     action = function() print("  [attacking->idle] combo done") end },
            hit     = { target = "hurt",     action = function() print("  [attacking->hurt] interrupted!") end },
        },
        hurt = {
            recover = { target = "idle",     action = function() print("  [hurt->idle] recovered") end },
        },
    }, "idle")

    print("state:", character:status())
    character:fire("move")
    print("state:", character:status())
    character:fire("attack")
    print("state:", character:status())
    character:fire("done")
    print("state:", character:status())
    character:fire("hit")
    print("state:", character:status())
    character:fire("recover")
    print("state:", character:status())

    -- Test invalid transition
    local ok = character:fire("move")
    print("valid move from idle:", ok)

    -- 3. Turnstile (Table FSM with guard conditions)
    print("\n--- Turnstile (Guard FSM) ---")

    local turnstile = make_fsm({
        locked = {
            coin  = { target = "unlocked", action = function() print("  -> Unlocked, insert coin") end },
            push  = { target = "locked",   action = function() print("  -> Denied, pay first!") end },
        },
        unlocked = {
            push  = { target = "locked",   action = function() print("  -> Passed through, relocking") end },
            coin  = { target = "unlocked",  action = function() print("  -> Extra coin ignored") end },
        },
    }, "locked")

    turnstile:fire("push")   -- denied
    turnstile:fire("coin")   -- unlock
    turnstile:fire("coin")   -- extra coin
    turnstile:fire("push")   -- pass through

    -- 4. Coroutine-based FSM
    print("\n--- Coroutine FSM (Generator) ---")

    local function traffic_coroutine()
        local phases = {
            { name = "red",    duration = 2 },
            { name = "green",  duration = 3 },
            { name = "yellow", duration = 1 },
        }
        while true do
            for _, phase in ipairs(phases) do
                print("  [" .. phase.name .. " for " .. phase.duration .. "s]")
                coroutine.yield(phase.name)
            end
        end
    end

    local co = coroutine.create(traffic_coroutine)
    for i = 1, 8 do
        local ok, state = coroutine.resume(co)
        if ok then
            print("  tick " .. i .. ": " .. state)
        end
    end

    -- 5. Coroutine FSM for game loop
    print("\n--- Coroutine FSM (Game Loop) ---")

    local function game_coroutine()
        local function wait(msg, ticks)
            for i = 1, ticks do
                coroutine.yield({ msg = msg, tick = i })
            end
        end

        -- Spawn sequence
        print("  [spawning enemies]")
        wait("spawn", 2)

        -- Wave sequence
        print("  [wave 1]")
        wait("fight", 3)

        -- Rest
        print("  [rest]")
        wait("rest", 1)

        -- Wave 2
        print("  [wave 2]")
        wait("fight", 2)

        -- Victory
        print("  [victory!]")
        wait("celebrate", 1)

        return "done"
    end

    local game_co = coroutine.create(game_coroutine)
    local tick = 0
    while coroutine.status(game_co) ~= "dead" do
        tick = tick + 1
        local ok, event = coroutine.resume(game_co)
        if ok and type(event) == "table" then
            print(string.format("  tick %2d: %-12s (%s)", tick, event.msg, event.msg))
        end
    end

    print("\n✓ State machine patterns complete!")
end

main()
