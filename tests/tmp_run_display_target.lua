local modules = {
  'tests/display_backend.lua',
  'tests/display_selection_preference.lua',
  'tests/monitor_backend_bridge.lua',
}
local failed = false
local function fail(code, msg)
  failed = true
  print('FAIL['..tostring(code)..'] '..tostring(msg))
end
local function ok(msg)
  print('OK '..tostring(msg))
end
for _, path in ipairs(modules) do
  local mod = dofile(path)
  mod.run({
    fail = fail,
    ok = ok,
    toPath = function(p) return p end,
  })
end
if failed then error('TARGET_TESTS_FAILED', 0) end
print('TARGET_TESTS_OK')
