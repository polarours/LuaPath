--[[
  Example: Template Engine
  Chapter: Stage 8 — Intermediate
  Difficulty: Intermediate
  Lua Version: 5.1+
  Demonstrates: Pattern matching, string manipulation, template parsing
]]

local template = {}

local function resolve_var(name, context)
  local val = context
  for part in name:gmatch("[^%.]+") do
    if type(val) ~= "table" then return nil end
    val = val[part]
  end
  return val
end

local function process_conditionals(text, context)
  local result = text
  while true do
    local s, e, cond = result:find("{%%if%s+([^}]+)%%}")
    if not s then break end
    local inner = result:sub(e + 1)
    local es, ee = inner:find("{%%end%%}")
    if not es then break end
    local body = inner:sub(1, es - 1)
    local var_name = cond:match("^%s*(.-)%s*$")
    local val = resolve_var(var_name, context)
    local if_part, else_part = body:match("(.+){%%else%%}(.+)")
    local replacement
    if if_part and else_part then
      replacement = val and if_part or else_part
    else
      replacement = val and body or ""
    end
    result = result:sub(1, s - 1) .. replacement .. inner:sub(ee + 1)
  end
  return result
end

local function process_loops(text, context)
  local result = text
  while true do
    local s, e, var, coll_name = result:find("{%%for%s+(%w+)%s+in%s+(%w+)%%}")
    if not s then break end
    local inner = result:sub(e + 1)
    local es, ee = inner:find("{%%end%%}")
    if not es then break end
    local body = inner:sub(1, es - 1)
    local collection = resolve_var(coll_name, context)
    local replacement = ""
    if type(collection) == "table" then
      local parts = {}
      for i, item in ipairs(collection) do
        local loop_ctx = setmetatable({ [var] = item, i = i }, { __index = context })
        local loop_body = body:gsub("{{(.-)}}", function(name)
          local v = resolve_var(name, loop_ctx)
          return tostring(v or "")
        end)
        table.insert(parts, loop_body)
      end
      replacement = table.concat(parts)
    end
    result = result:sub(1, s - 1) .. replacement .. inner:sub(ee + 1)
  end
  return result
end

function template.render(tpl, context)
  local text = tpl
  text = process_conditionals(text, context)
  text = process_loops(text, context)
  text = text:gsub("{{(.-)}}", function(name)
    local val = resolve_var(name, context)
    return tostring(val or "")
  end)
  return text
end

-- Test cases
local function main()
  local tpl1 = "Hello {{name}}! You are {{age}} years old."
  local out1 = template.render(tpl1, { name = "Alice", age = 30 })
  print("Template 1:\n" .. out1)

  local tpl2 = "Status: {%if active%}Active{%else%}Inactive{%end%}"
  print("\nTemplate 2 (active):\n" .. template.render(tpl2, { active = true }))
  print("\nTemplate 2 (inactive):\n" .. template.render(tpl2, { active = false }))

  local tpl3 = "Items:\n{%for item in items%}{{i}}. {{item}}\n{%end%}"
  local out3 = template.render(tpl3, { items = {"Lua", "Python", "Go"} })
  print("\nTemplate 3:\n" .. out3)

  local tpl4 = "{%if missing%}exists{%else%}not found{%end%}"
  print("\nTemplate 4 (missing var):\n" .. template.render(tpl4, {}))

  print("\n[OK] Template engine working")
end

main()
