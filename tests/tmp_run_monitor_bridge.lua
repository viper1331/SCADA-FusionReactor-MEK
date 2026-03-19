local mod = dofile('tests/monitor_backend_bridge.lua')
local failed = false
local function fail(code, msg)
  failed = true
  print('FAIL['..tostring(code)..'] '..tostring(msg))
end
local function ok(msg)
  print('OK '..tostring(msg))
end
mod.run({
  fail = fail,
  ok = ok,
  toPath = function(p) return p end,
})
if failed then error('TEST_FAILED', 0) end
print('TEST_DONE_OK')
