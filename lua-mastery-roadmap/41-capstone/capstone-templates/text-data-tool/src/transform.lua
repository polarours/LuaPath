-- transform.lua
-- Chain of transform functions
local M = {}

-- Registry of supported transforms
local transforms = {}

-- filter(pattern) — keep lines matching pattern
transforms.filter = function(params, lines)
  -- TODO: return only lines matching params.pattern
  -- use string:match(pattern)
end

-- trim() — remove leading/trailing whitespace
transforms.trim = function(params, lines)
  -- TODO: apply s:match("^%s*(.-)%s*$") to each line
end

-- upper() — convert to uppercase
transforms.upper = function(params, lines)
  -- TODO
end

-- replace(old, new) — replace all occurrences
transforms.replace = function(params, lines)
  -- TODO: use gsub
end

-- reverse() — reverse the order of lines
transforms.reverse = function(params, lines)
  -- TODO
end

M.transforms = transforms

-- Apply a list of transforms to lines
-- @param lines      array of strings
-- @param transforms list of {name, params}
-- @return           transformed lines (array of strings)
function M.apply(lines, transforms)
  -- TODO: iterate transforms in order, applying each
  -- for each t in transforms:
  --   local fn = M.transforms[t.name]
  --   if fn then lines = fn(t.params, lines)
  --   else error("unknown transform: " .. t.name)
  -- return lines
end

return M
