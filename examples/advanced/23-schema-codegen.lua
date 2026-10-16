-- Example 26: Schema Validator Code Generation
-- Chapter: 15-advanced-metaprogramming
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Case study for Chapter 15: turn a declarative schema into a specialized
-- validator function at load time, then compare it against a generic
-- (interpreted) validator on the same corpus.
--
-- Demonstrates: string-building code generation, load()/loadstring(),
-- the correctness guard (generated code must agree with the reference),
-- and measuring the codegen payoff instead of assuming it.

-- 5.1 uses loadstring(); 5.2+ folded it into load()
local load_chunk = loadstring or load

--------------------------------------------------------------------------------
-- The schema: what a config record must look like
--------------------------------------------------------------------------------

local schema = {
  { field = "id",     type = "number",  required = true },
  { field = "name",   type = "string",  required = true },
  { field = "score",  type = "number",  required = false },
  { field = "tags",   type = "table",   required = false },
}

--------------------------------------------------------------------------------
-- Reference implementation: walk the schema on every call
--------------------------------------------------------------------------------

local function validate_generic(record, spec)
  for i = 1, #spec do
    local rule = spec[i]
    local value = record[rule.field]
    if value == nil then
      if rule.required then
        return false, rule.field .. " is required"
      end
    elseif type(value) ~= rule.type then
      return false, rule.field .. " must be a " .. rule.type
    end
  end
  return true
end

--------------------------------------------------------------------------------
-- Metaprogrammed implementation: build the source, then load it once
--------------------------------------------------------------------------------

local function generate_validator_source(spec)
  local lines = {}
  lines[#lines + 1] = "-- generated validator"
  lines[#lines + 1] = "return function(record)"
  lines[#lines + 1] = "  local v"

  for i = 1, #spec do
    local rule = spec[i]
    local field, ftype = rule.field, rule.type

    -- Hoist the access: one table lookup per field, not one per rule clause
    lines[#lines + 1] = string.format("  v = record[%q]", field)

    if rule.required then
      -- Pre-render the message once, at generation time
      lines[#lines + 1] = string.format(
        "  if v == nil then return false, %q end", field .. " is required"
      )
    end

    lines[#lines + 1] = string.format(
      "  if v ~= nil and type(v) ~= %q then return false, %q end",
      ftype, field .. " must be a " .. ftype
    )
  end

  lines[#lines + 1] = "  return true"
  lines[#lines + 1] = "end"
  return table.concat(lines, "\n")
end

local function compile_validator(spec)
  local source = generate_validator_source(spec)
  local chunk, err = load_chunk(source, "=generated_validator")
  if not chunk then
    error("code generation failed: " .. tostring(err))
  end
  return chunk(), source
end

local validate_generated, generated_source = compile_validator(schema)

--------------------------------------------------------------------------------
-- Show the generated code -- this is the artifact the case study is about
--------------------------------------------------------------------------------

print("Generated validator source")
print("--------------------------")
print(generated_source)
print()

--------------------------------------------------------------------------------
-- Correctness guard: agree with the reference on every record
--------------------------------------------------------------------------------

local corpus = {
  { id = 1,   name = "alpha",   score = 9.5,  tags = { "x" } },
  { id = 2,   name = "beta" },
  { id = 3,   name = "gamma",   score = 1.0,  tags = {} },
  { id = 4 },                                  -- missing required fields
  { id = "5", name = "epsilon" },              -- id is a string
  { id = 6,   name = 42 },                     -- name is a number
  { id = 7,   name = "eta",     score = "hi" },-- score is a string
  { id = 8,   name = "theta",   tags = "no" }, -- tags is a string
}

local mismatches = 0
for i = 1, #corpus do
  local rec = corpus[i]
  local ok_g, err_g = validate_generic(rec, schema)
  local ok_n, err_n = validate_generated(rec)

  if ok_g ~= ok_n or err_g ~= err_n then
    mismatches = mismatches + 1
    print(string.format(
      "MISMATCH on record %d: generic=(%s, %s) generated=(%s, %s)",
      i, tostring(ok_g), tostring(err_g), tostring(ok_n), tostring(err_n)
    ))
  end
end

print(string.format("Correctness: %d/%d records agree with the reference validator",
  #corpus - mismatches, #corpus))
print(string.format("             %d mismatches", mismatches))
print()

if mismatches > 0 then
  print("CASE STUDY FAILED: generated validator disagrees with the reference")
  os.exit(1)
end

--------------------------------------------------------------------------------
-- Measure: is the generated code actually faster?
--------------------------------------------------------------------------------

local ITERATIONS = 150000
local valid_record = { id = 99, name = "measured", score = 3.25, tags = {} }

local function bench(fn)
  local start = os.clock()
  for _ = 1, ITERATIONS do
    for i = 1, #corpus do
      fn(corpus[i])
    end
  end
  return os.clock() - start
end

-- Warm up both paths before timing
bench(function(r) return validate_generic(r, schema) end)
bench(function(r) return validate_generated(r) end)

local generic_time  = bench(function(r) return validate_generic(r, schema) end)
local generated_time = bench(function(r) return validate_generated(r) end)

local total_calls = ITERATIONS * #corpus

print("Timing")
print("------")
print(string.format("calls per validator: %d", total_calls))
print(string.format("generic (schema walk):  %.4f s", generic_time))
print(string.format("generated (specialized): %.4f s", generated_time))
if generated_time > 0 then
  print(string.format("ratio (generic / generated): %.2fx", generic_time / generated_time))
end
print()

--------------------------------------------------------------------------------
-- Show the payoff on a successful validation (the hot path, no errors)
--------------------------------------------------------------------------------

local ok, err = validate_generated(valid_record)
assert(ok, "valid record should pass: " .. tostring(err))
print("Sample verdict:", ok, err)
print()
print("CASE STUDY OK")
