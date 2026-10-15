-- weather-stream.lua
-- Simulated weather data stream using the pipeline
-- 1. Create a source that yields temperature readings every 0.5s (simulated)
-- 2. Apply: filter(temp > -10), map({celsius = v, fahrenheit = v*9/5+32})
-- 3. Sink to bounded buffer, flush and print every 5 items
local pipeline  = require "src.pipeline"
local operators = require "src.operators"
local source    = require "src.source"
local sink      = require "src.sink"

-- Simulated temperature source
local temps = coroutine.create(function()
  for i = 1, 100 do
    coroutine.yield(i * 0.5 - 25)  -- temperatures from -25 to 24.5
    coroutine.yield()  -- simulate delay
  end
end)

local src = source.create(temps)
local p   = pipeline.Pipeline.new(src)
local s   = sink.bounded(5)

p:pipe(
  operators.filter(function(t) return t > -10 end),
  operators.map(function(t) return { celsius = t, fahrenheit = t * 9 / 5 + 32 } end),
  s
)

p:run()
print("Final buffer:", s:flush())
