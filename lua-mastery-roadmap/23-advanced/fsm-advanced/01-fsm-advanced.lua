--[[
  Example: FSM Advanced
  Stage: 23
  Difficulty: Advanced
  Lua Version: 5.1+
  Demonstrates: hierarchical FSM, history states, transition guards
]]

local HierarchicalFSM = {}
HierarchicalFSM.__index = HierarchicalFSM

function HierarchicalFSM.new(name)
    return setmetatable({
        name = name or "HFSM", _states = {}, _current = nil,
        _history = {}, _transitions = {},
    }, HierarchicalFSM)
end

function HierarchicalFSM:add_state(name, opts)
    opts = opts or {}
    self._states[name] = {
        name = name, parent = opts.parent, initial = opts.initial,
        children = {}, on_entry = opts.on_entry, on_exit = opts.on_exit,
    }
    if opts.parent and self._states[opts.parent] then
        table.insert(self._states[opts.parent].children, name)
    end
    return self
end

function HierarchicalFSM:add_transition(from, to, event, opts)
    opts = opts or {}
    if not self._transitions[from] then self._transitions[from] = {} end
    self._transitions[from][event] = { target = to, guard = opts.guard, action = opts.action }
    return self
end

function HierarchicalFSM:set_initial(state_name)
    if not self._states[state_name] then error("State '" .. state_name .. "' not found") end
    self:_enter(state_name)
    return self
end

function HierarchicalFSM:_enter(state_name)
    local s = self._states[state_name]
    self._current = state_name
    if s.on_entry then s.on_entry(s) end
    print(string.format("[%s] Entered: %s", self.name, state_name))
    if s.initial then self._history[state_name] = s.initial; self:_enter(s.initial) end
end

function HierarchicalFSM:_exit(state_name)
    local s = self._states[state_name]
    if s.children and #s.children > 0 and self._current ~= state_name then
        local child = self._current
        while self._states[child] and self._states[child].parent == state_name do
            self:_exit(child)
            child = self._states[child] and self._states[child].parent
        end
    end
    if s.on_exit then s.on_exit(s) end
    print(string.format("[%s] Exited: %s", self.name, state_name))
end

function HierarchicalFSM:_is_ancestor(potential_ancestor, state_name)
    local cur = state_name
    while cur do
        if cur == potential_ancestor then return true end
        cur = self._states[cur] and self._states[cur].parent
    end
    return false
end

function HierarchicalFSM:fire(event, context)
    context = context or {}
    local transitions = self._transitions[self._current]
    if not transitions or not transitions[event] then
        print(string.format("[%s] No transition for '%s' in '%s'", self.name, event, self._current))
        return false
    end
    local t = transitions[event]
    if t.guard and not t.guard(context) then
        print(string.format("[%s] Guard rejected: %s --%s--> %s", self.name, self._current, event, t.target))
        return false
    end
    local old_state, new_state = self._current, t.target
    if not self:_is_ancestor(new_state, old_state) then self:_exit(old_state) end
    if t.action then t.action(context) end
    print(string.format("[%s] %s --%s--> %s", self.name, old_state, event, new_state))
    self:_enter(new_state)
    return true
end

function HierarchicalFSM:current() return self._current end
function HierarchicalFSM:get_history(state_name) return self._history[state_name] end

function main()
    print("=== Hierarchical FSM: Media Player ===\n")
    local player = HierarchicalFSM.new("MediaPlayer")
    player:add_state("Stopped", {
        on_entry = function() print("  [!] Player stopped") end,
        on_exit  = function() print("  [!] Leaving stopped") end,
    })
    player:add_state("Playing", {
        initial = "Playing_Buffering",
        on_entry = function() print("  [!] Playback started") end,
        on_exit  = function() print("  [!] Playback paused/stopped") end,
    })
    player:add_state("Playing_Buffering", {
        parent = "Playing",
        on_entry = function() print("  [!] Buffering data...") end,
        on_exit  = function() print("  [!] Buffer ready") end,
    })
    player:add_state("Playing_Normal", {
        parent = "Playing",
        on_entry = function() print("  [!] Now playing normally") end,
        on_exit  = function() print("  [!] Stopping normal play") end,
    })
    player:add_state("Paused", {
        on_entry = function() print("  [!] Player paused") end,
        on_exit  = function() print("  [!] Resuming from pause") end,
    })
    player:add_transition("Stopped", "Playing", "play")
    player:add_transition("Playing_Buffering", "Playing_Normal", "buffer_done", {
        guard = function(ctx) return ctx.buffer_ready == true end,
    })
    player:add_transition("Playing_Normal", "Paused", "pause")
    player:add_transition("Paused", "Playing_Normal", "resume")
    player:add_transition("Playing_Normal", "Stopped", "stop")
    player:add_transition("Paused", "Stopped", "stop")
    player:set_initial("Stopped")

    print("--- Start playback ---")
    player:fire("play")
    player:fire("buffer_done", { buffer_ready = false })
    player:fire("buffer_done", { buffer_ready = true })
    print("\n--- Pause and resume ---")
    player:fire("pause"); print("  Current: " .. player:current())
    player:fire("resume"); print("  Current: " .. player:current())
    print("\n--- Stop and restart ---")
    player:fire("stop"); print("  Current: " .. player:current())
    player:fire("play")
    print("\n--- Check history ---")
    player:fire("pause"); player:fire("stop")
    print("  Playing history: " .. tostring(player:get_history("Playing")))
    print("\n=== Done ===")
end

main()