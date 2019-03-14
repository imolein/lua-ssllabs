-- Start a new assessment and wait until it is finished

-- setup path to find the project src files
package.path = './src/?.lua;./src/?/init.lua;' .. package.path

local ssll = require('ssllabs')

local function sleep(n)
  os.execute('sleep ' .. tonumber(n))
end

local opts = {
  host = 'edolas.world',
  publish = true,
  startNew = true
}

-- start new assessment for host 'edolas.world' and publish the result on the public board
local resp, err, msg = ssll.analyze(opts)

if err then print(msg) end

-- if status is not READY or ERROR
if resp.status ~= 'READY' and resp.status ~= 'ERROR' then
  -- remove startNew option, to prevent assessment looping
  opts.startNew = false

  -- check every 30s if assessment is ready or failed
  repeat
    -- get progress displayed per endpoint during assessment
    for _, v in ipairs(resp.endpoints) do
      print(string.format('%s progess: %d%%', v.ipAddress, v.progress or 0))
    end
    sleep(30)
    resp = ssll.analyze(opts)
  until resp.status == 'READY' or resp.status == 'ERROR'
end

-- if failed, print the statusMessage
if resp.status == 'ERROR' then
  print(resp.statusMessage)
  os.exit(1)
end

-- print ip address of endpoint and it's grade
for _, v in ipairs(resp.endpoints) do
  print(string.format('%s grade: %s', v.ipAddress, v.grade))
end
