-- source.lua
local M = {}

-- Create an async source from a coroutine function
-- The coroutine function yields values: co:yield(value)
function M.create(coro_fn)
  -- TODO: wrap in a Source object with :pull() method
  -- :pull() resumes the coroutine and returns the yielded value
  -- returns nil when coroutine is dead
end

return M
