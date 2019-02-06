-- Start assessments for multiple host and wait until all are finished

-- setup path to find the project src files
package.path = './src/?.lua;./src/?/init.lua;' .. package.path

local ssll = require('ssllabs')

-- hosts to check
local hosts = {
  'edolas.world',
  'blog.kokolor.es'
}

local checks = {}
local finished = {}

local function sleep(n)
  os.execute('sleep ' .. tonumber(n))
end

-- creates coroutine per host, which calls the analyze() API endpoint
-- and add them to the checks table
local function check(opts)
  table.insert(checks, coroutine.create(function()
    local resp, err, msg = ssll.analyze(opts)

    opts.startNew = nil

    while true do
      if err then return err, msg end

      coroutine.yield(resp)

      resp, err, msg = ssll.analyze(opts)
    end
  end))
end

-- runs each coroutine in checks table
local function run()
  while true do
    local noc = #checks

    if noc == 0 then break end

    for i = 1, noc do
      local _, resp = coroutine.resume(checks[i])

      -- if assessment is finished, add the result table to the finished
      -- table with the host as key
      if resp.status == 'READY' or resp.status == 'ERROR' then
        finished[resp.host] = resp
        table.remove(checks, i)
        print(resp.host .. ' assessment finished!')

        break
      end

      print(resp.host .. ' in progress...')
    end

    sleep(10)
  end
end

-- calls the check function for each host
for _, h in ipairs(hosts) do
  check ({ host = h, publish = true, startNew = true })
end

-- run it
run()

-- print grade for each host and it's endpoints
for k, v in pairs(finished) do
  for _, e in ipairs(v.endpoints) do
    print(k, e.ipAddress, e.grade)
  end
end