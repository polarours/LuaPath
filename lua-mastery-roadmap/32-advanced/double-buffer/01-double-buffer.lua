-- Double Buffer Pattern Implementation
-- Version: Lua 5.4
-- Stage 32: Advanced — Double Buffer

local DoubleBuffer = {}
DoubleBuffer.__index = DoubleBuffer

function DoubleBuffer.new()
    local self = setmetatable({}, DoubleBuffer)
    self._buffers = { {}, {} }
    self._front = 1    -- read index
    self._back = 2     -- write index
    self._swap_count = 0
    return self
end

function DoubleBuffer:get_front()
    return self._buffers[self._front]
end

function DoubleBuffer:get_back()
    return self._buffers[self._back]
end

function DoubleBuffer:set(key, value)
    self._buffers[self._back][key] = value
end

function DoubleBuffer:get(key)
    return self._buffers[self._front][key]
end

function DoubleBuffer:clear_back()
    self._buffers[self._back] = {}
end

function DoubleBuffer:swap()
    self._front, self._back = self._back, self._front
    self._swap_count = self._swap_count + 1
    return self._swap_count
end

function DoubleBuffer:swap_and_clear()
    self:swap()
    self._buffers[self._back] = {}
end

function DoubleBuffer:swap_count()
    return self._swap_count
end

function DoubleBuffer:snapshot()
    local snap = {}
    for k, v in pairs(self._buffers[self._front]) do snap[k] = v end
    return snap
end

-- Game state buffer example
local GameState = {}
GameState.__index = GameState

function GameState.new()
    local self = setmetatable({}, GameState)
    self._db = DoubleBuffer.new()
    return self
end

function GameState:stage(name, data)
    self._db:set("stage", name)
    if data then for k, v in pairs(data) do self._db:set(k, v) end end
end

function GameState:commit()
    self._db:swap_and_clear()
end

function GameState:get(key)
    return self._db:get(key)
end

function GameState:get_all()
    return self._db:snapshot()
end

function GameState:commit_count()
    return self._db:swap_count()
end

-- Renderer: reads from front buffer
local Renderer = {}
Renderer.__index = Renderer

function Renderer.new(game_state)
    return setmetatable({ gs = game_state }, Renderer)
end

function Renderer:render()
    local state = self.gs:get_all()
    print("  [Renderer] Rendering frame:")
    for k, v in pairs(state) do print(string.format("    %s = %s", k, tostring(v))) end
end

-- Example usage
local function main()
    print("=== Double Buffer Demo ===\n")

    -- Demo 1: Basic double buffer
    local buf = DoubleBuffer.new()

    print("--- Writing to back buffer ---")
    buf:set("x", 10)
    buf:set("y", 20)
    buf:set("label", "point_a")
    print("  Front (before swap):", buf:get("x"), buf:get("y"))
    buf:swap()
    print("  Front (after swap):", buf:get("x"), buf:get("y"), buf:get("label"))
    buf:set("x", 99)
    print("  Front (write to new back):", buf:get("x"))
    print("  Back (new value):", buf:get_back().x)

    -- Demo 2: Game state with commits
    print("\n=== Game State Demo ===\n")
    local game = GameState.new()
    local renderer = Renderer.new(game)

    game:stage("title_screen", { fps = 60, players = 0 })
    game:commit()
    renderer:render()

    game:stage("level_1", { fps = 120, players = 2, health = 100 })
    game:commit()
    renderer:render()

    game:stage("game_over", { fps = 30, players = 0 })
    renderer:render()  -- still shows level_1
    game:commit()
    renderer:render()  -- now shows game_over

    print("\nTotal commits:", game:commit_count())
end

main()
