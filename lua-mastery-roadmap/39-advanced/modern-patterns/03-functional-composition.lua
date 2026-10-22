#!/usr/bin/env lua
-- Stage 39: Modern Patterns - Functional Composition
-- Function composition and currying
-- Lua Version: 5.1+
--
-- Demonstrates: function composition, pipelines, partial application, currying, short-circuit validation

-- ---------------------------------------------------------------------------
-- Combinators
-- ---------------------------------------------------------------------------

--- Compose functions right to left: `compose(f, g)(x)` is `f(g(x))`.
-- With three functions the argument order is the reverse of the run order:
-- `compose(f, g, h)(x)` is `f(g(h(x)))`, so `h` runs first.
-- @param ... the functions to compose, applied from right to left
-- @return function a function of one argument
local function compose(...)
  local funcs = { ... }
  return function(x)
    local result = x
    for i = #funcs, 1, -1 do
      result = funcs[i](result)
    end
    return result
  end
end

--- Build a left to right pipeline: `pipe(f, g)(x)` is `g(f(x))`.
-- This is the mirror image of `compose`: `pipe(f, g)` is `compose(g, f)`.
-- @param ... the stages of the pipeline, applied in the order given
-- @return function a function of one argument
local function pipe(...)
  local stages = { ... }
  return function(x)
    local result = x
    for i = 1, #stages do
      result = stages[i](result)
    end
    return result
  end
end

--- Curry a two-argument function so its arguments arrive one at a time.
-- `curry2(fn)(a)` returns a function of the second argument, and calling it
-- with `b` runs `fn(a, b)`: the first argument is captured, not passed on.
-- @param fn a function taking exactly two arguments
-- @return function a function of one argument returning a function of the other
local function curry2(fn)
  return function(a)
    return function(b)
      return fn(a, b)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Building blocks
-- ---------------------------------------------------------------------------

--- Remove leading and trailing whitespace.
-- @param s the string to trim
-- @return string the trimmed string
local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Split a string on a plain separator.
-- The separator comes first so that `curry2(split)` can fix it once.
-- @param sep the separator, matched literally rather than as a pattern
-- @param s the string to split
-- @return table the pieces, in order
local function split(sep, s)
  if sep == "" then
    return { s }
  end
  local pieces = {}
  local start = 1
  while true do
    local at = s:find(sep, start, true)
    if not at then
      pieces[#pieces + 1] = s:sub(start)
      break
    end
    pieces[#pieces + 1] = s:sub(start, at - 1)
    start = at + #sep
  end
  return pieces
end

--- Convert a string to a number, or to false when it is not numeric.
-- The `false` is deliberate: `tonumber` returns nil for bad input, and a nil
-- inside a list punches a hole in it, which makes `#list` and `ipairs`
-- unreliable. A sentinel keeps the list dense.
-- @param s the string to convert
-- @return number|false the number, or false if the string is not numeric
local function to_number(s)
  return tonumber(s) or false
end

--- Report whether a value is a number.
-- @param v the value to test
-- @return boolean whether the value is a number
local function is_number(v)
  return type(v) == "number"
end

--- Map a function over a list.
-- @param fn the function to apply to each element
-- @param list the list to map
-- @return table a new list holding the results
local function map(fn, list)
  local out = {}
  for i = 1, #list do
    out[i] = fn(list[i])
  end
  return out
end

--- Keep only the elements a predicate accepts.
-- @param pred the predicate to test each element with
-- @param list the list to filter
-- @return table a new list holding the accepted elements
local function filter(pred, list)
  local out = {}
  for i = 1, #list do
    if pred(list[i]) then
      out[#out + 1] = list[i]
    end
  end
  return out
end

--- Fold a list into a single value.
-- @param fn a function of (accumulator, element) returning the next accumulator
-- @param init the initial accumulator
-- @param list the list to fold
-- @return any the final accumulator
local function fold(fn, init, list)
  local acc = init
  for i = 1, #list do
    acc = fn(acc, list[i])
  end
  return acc
end

--- Add two numbers.
-- @param a the first number
-- @param b the second number
-- @return number the sum
local function add(a, b)
  return a + b
end

-- ---------------------------------------------------------------------------
-- Use 1: a text pipeline, read left to right
-- ---------------------------------------------------------------------------

-- Currying fixes the separator once, so the stage below is a plain unary
-- function and the pipeline reads like a shell pipeline.
local split_on_comma = curry2(split)(",")

-- trim -> split -> map to numbers -> keep the numbers -> sum them.
-- Written with the combinators, the same work would be five nested loops.
local total_of = pipe(
  trim,
  split_on_comma,
  function(pieces) return map(to_number, pieces) end,
  function(values) return filter(is_number, values) end,
  function(values) return fold(add, 0, values) end
)

-- ---------------------------------------------------------------------------
-- Use 2: a validation chain, read right to left
-- ---------------------------------------------------------------------------

-- Each predicate counts its own calls, so the assertions can prove that a
-- failing check stopped the chain instead of letting every predicate run.
local ran = { stock = 0, positive = 0, whole = 0 }

--- Report whether an order can be shipped.
-- @param order the order record
-- @return boolean whether the item is in stock
local function is_in_stock(order)
  ran.stock = ran.stock + 1
  return order.in_stock == true
end

--- Report whether an order carries a usable price.
-- @param order the order record
-- @return boolean whether the price is a positive number
local function is_positive_price(order)
  ran.positive = ran.positive + 1
  return type(order.price) == "number" and order.price > 0
end

--- Report whether an order carries a whole-number price.
-- @param order the order record
-- @return boolean whether the price is a whole number
local function is_whole_price(order)
  ran.whole = ran.whole + 1
  return type(order.price) == "number" and order.price == math.floor(order.price)
end

--- Build a check that rejects an order the predicate refuses.
-- A failing check replaces the order with a failure record. The checks that
-- run after it see the failure record and pass it along untouched, so the
-- first failure wins and the later predicates are never evaluated.
-- @param predicate the predicate the order must satisfy
-- @param message the message to report when it does not
-- @return function a check taking an order and returning an order or a failure record
local function require_that(predicate, message)
  return function(order)
    if order.error then
      return order
    end
    if predicate(order) then
      return order
    end
    return { error = message }
  end
end

-- `compose` applies the rightmost check first, so the checks below are
-- written in reverse run order: stock, then the two price checks.
local validate_order = compose(
  require_that(is_whole_price, "price must be a whole number"),
  require_that(is_positive_price, "price must be positive"),
  require_that(is_in_stock, "item must be in stock")
)

-- The same chain, left to right: the checks now appear in the order they run.
local validate_order_readable = pipe(
  require_that(is_in_stock, "item must be in stock"),
  require_that(is_positive_price, "price must be positive"),
  require_that(is_whole_price, "price must be a whole number")
)

-- The same checks in yet another order: the price is judged before the stock.
local validate_price_first = compose(
  require_that(is_in_stock, "item must be in stock"),
  require_that(is_whole_price, "price must be a whole number"),
  require_that(is_positive_price, "price must be positive")
)

-- ---------------------------------------------------------------------------
-- Checks
-- ---------------------------------------------------------------------------

--- Double a number.
-- @param x the number to double
-- @return number the doubled number
local function double(x)
  return x * 2
end

--- Add one to a number.
-- @param x the number to increment
-- @return number the incremented number
local function increment(x)
  return x + 1
end

--- Negate a number.
-- @param x the number to negate
-- @return number the negated number
local function negate(x)
  return -x
end

-- compose runs the rightmost function first.
assert(compose(double, increment)(5) == 12)
assert(compose(double, increment, negate)(5) == -8)

-- pipe runs the leftmost stage first: the same stages read the other way.
assert(pipe(double, increment)(5) == 11)
assert(pipe(double, increment, negate)(5) == -11)

-- The two combinators are one pipeline read in opposite directions.
assert(pipe(double, increment, negate)(5) == compose(negate, increment, double)(5))

-- Currying captures the first argument and hands back a function of the second.
assert(curry2(add)(2)(3) == 5)
assert(table.concat(curry2(split)(",")("a,b,c"), "|") == "a|b|c")

-- The text pipeline: trim, split, map to numbers, filter, sum.
assert(total_of("  10, 20, x, 30, 40  ") == 100)
assert(total_of("1, 2, 3") == 6)
assert(total_of("7") == 7)
assert(total_of("  ") == 0)
-- The non-numeric piece is dropped; the decimal one is a number and stays.
assert(total_of("1, nope, 2, 3.5") == 6.5)

-- The validation chain stops at the first failure and reports that message.
ran.stock, ran.positive, ran.whole = 0, 0, 0
local outcome = validate_order({ item = "widget", price = 10, in_stock = false })
assert(outcome.error == "item must be in stock")
assert(ran.stock == 1)
assert(ran.positive == 0)
assert(ran.whole == 0)

-- The next failure down the chain is reported once the earlier one passes.
ran.stock, ran.positive, ran.whole = 0, 0, 0
outcome = validate_order({ item = "widget", price = -1, in_stock = true })
assert(outcome.error == "price must be positive")
assert(ran.stock == 1)
assert(ran.positive == 1)
assert(ran.whole == 0)

ran.stock, ran.positive, ran.whole = 0, 0, 0
outcome = validate_order({ item = "widget", price = 2.5, in_stock = true })
assert(outcome.error == "price must be a whole number")
assert(ran.stock == 1)
assert(ran.positive == 1)
assert(ran.whole == 1)

-- An order that passes every check comes back unchanged.
ran.stock, ran.positive, ran.whole = 0, 0, 0
local good_order = { item = "widget", price = 10, in_stock = true }
outcome = validate_order(good_order)
assert(outcome.error == nil)
assert(outcome.item == "widget")
assert(ran.stock == 1 and ran.positive == 1 and ran.whole == 1)

-- The order of the checks decides which message comes back.
local bad_order = { item = "widget", price = -5, in_stock = false }
assert(validate_order(bad_order).error == "item must be in stock")
assert(validate_price_first(bad_order).error == "price must be positive")

-- The left to right spelling of the same chain behaves identically.
assert(validate_order_readable(bad_order).error == validate_order(bad_order).error)

print("✓ functional-composition tests passed")
