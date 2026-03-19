local IoDevices = dofile('io/devices.lua')
local info = debug.getinfo(IoDevices.getMonitorCandidates, 'S')
print('source', info and info.source)
print('linedefined', info and info.linedefined)
