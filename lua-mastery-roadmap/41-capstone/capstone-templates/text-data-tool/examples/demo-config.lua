-- demo-config.lua
-- Example config for text-data-tool
return {
  transforms = {
    { name = "filter",  params = { pattern = "ERROR|WARN" } },
    { name = "trim" },
    { name = "upper" },
  }
}
