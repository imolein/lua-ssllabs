package.path = './src/?.lua;./src/?/init.lua;' .. package.path
local ssll = require('ssllabs')
local inspect = require('inspect')

local opts = {
  host = 'p.kokolor.es',
  publish = true,
  startNew = true
}

local resp, err, msg = ssll.get_root_certs_raw()
if err then print(err, msg) end
print(inspect(resp), resp.status)

local Class = {}

function Class:new(a)
  return self
end

Class:new()