-- setup path to find the project src files
package.path = './src/?.lua;./src/?/init.lua;' .. package.path

local ssll = require('ssllabs')
-- define options for API call
local opts = {
  host = 'p.kokolor.es',
  publish = true,
  startNew = false
}

local function sleep(n)
  os.execute('sleep ' .. tonumber(n))
end

-- start new assessment for host 'httpbin.com' and publish the result on the public board
local resp = ssll.analyze(opts)

-- if status is not READY or ERROR
if resp.status ~= 'READY' and resp.status ~= 'ERROR' then
  -- check every 30s if assessment is ready or failed
  repeat
    -- get progress displayed per endpoint during assessment
    for _, v in ipairs(resp.endpoints) do
      print(string.format('%s progess: %d', v.ipAddress, v.progress))
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
 
