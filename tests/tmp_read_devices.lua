local h=fs.open('io/devices.lua','r')
if not h then print('open failed') return end
for i=1,30 do
  local line=h.readLine()
  if not line then break end
  print(i..':'..line)
end
h.close()
