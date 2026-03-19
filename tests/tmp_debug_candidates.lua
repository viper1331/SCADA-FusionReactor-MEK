local IoDevices = dofile('io/devices.lua')

local periphMap = {
  monitor_0 = {
    getSize = function() return 80, 40 end,
    setCursorPos = function() end,
    write = function() end,
    clear = function() end,
    setTextColor = function() end,
    setBackgroundColor = function() end,
  },
  tm_display_0 = {
    getSize = function() return 192, 108 end,
    fillRect = function() end,
    drawText = function() end,
    sync = function() end,
  },
}
local fakePeripheral = { getNames = function() return { 'monitor_0', 'tm_display_0'} end }
local function getTypeOf(name)
  if name == 'monitor_0' then return 'monitor' end
  if name == 'tm_display_0' then return 'tm_display' end
  return 'unknown'
end
local function safePeripheral(name) return periphMap[name] end
local candidates, diag = IoDevices.getMonitorCandidates(fakePeripheral, getTypeOf, safePeripheral, nil)
print('count', #candidates)
for i, c in ipairs(candidates) do
  print(i, c.name, c.backend, c.w, c.h)
end
print('diag', textutils.serialize(diag))
