-- services.lua
-- Service definitions for the process manager
return {
  {
    name       = "web",
    command    = "lua examples/web-server.lua",
    restart    = { max_retries = 5, backoff = "exponential" },
  },
  {
    name       = "cache",
    command    = "lua examples/cache-server.lua",
    restart    = { max_retries = 3, backoff = "linear", interval = 2 },
  }
}
