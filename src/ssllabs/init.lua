--- Lua module for the Qualys SSL Labs Server Test
--
-- @author imo
-- @copyright 2018
-- @license MIT
-- @module ssllabs

local requests = require('requests')
local ssllabs = {
  _VERSION      = 'lua-ssllabs 0.1',
  _DESCRIPTION  = 'Lua module for the Qualys SSL Labs Server Test',
  _URL          = 'https://git.kokolor.es/imo/lua-ssllabs',
  _LICENCE      = [[
  MIT Licence
  
  Copyright (c) 2018 Sebastian Huebner

  Permission is hereby granted, free of charge, to any person obtaining a
  copy of this software and associated documentation files (the "Software"),
  to deal in the Software without restriction, including without limitation
  the rights to use, copy, modify, merge, publish, distribute, sublicense,
  and/or sell copies of the Software, and to permit persons to whom the Software
  is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.
  ]]
  }

-- Private functions

local function convert_bool_values(tbl)
  if not tbl then return end
  
  local converted = {}
  
  for k, v in pairs(tbl) do
    if type(v) == 'boolean' then
      if tostring(v) == 'true' then
        converted[k] = 'on'
      elseif tostring(v) == 'false' then
        converted[k] = 'off'
      end
    else
      converted[k] = v
    end
  end
  
  return converted
end

local function build_query(api, path, payload)
  if not payload then return api .. path end
  
  local query = api .. path .. '?'
  
  for k, v in pairs(payload) do
    query = query .. k .. '=' .. v .. '&'
  end
  
  return query:sub(1,-2)
end

local function api_request(path, payload)
  local api_url = 'https://api.dev.ssllabs.com/api/v3/'
  --local api_url = 'https://api.ssllabs.com/api/v3/'
  local r_url = build_query(api_url, path, convert_bool_values(payload))
  local resp
  
  if path == 'getRootCertsRaw' then
    resp = requests.get(r_url)
  else
    resp = requests.get(r_url).json()
  end
  
  return resp
end

-- Public function

--- Check availability of the SSL Labs servers
-- and some other data like software version. Implements the [info API call](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#check-ssl-labs-availability)
-- @treturn table [Info table](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#info)
-- @usage local info = ssllabs.info()
function ssllabs.info()
  return api_request('info')
end

--- Invoke assessment and check progress.
-- This call is used to initiate an assessment, or to retrieve the status of an assessment in progress or in the cache.  Implements the [analyze API call](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#invoke-assessment-and-check-progress)
-- @tab opts options table with arguments
-- @string opts.host hostname
-- @tparam[opt='off'] ?string|boolean opts.publish if set to `'on'` or `true` the result will be published ont he public result boards.
-- @tparam[opt='off'] ?string|boolean opts.startNew if set to `'on'` or `true` a new assessment is started. However, if there's already an assessment in progress, its status is delivered instead.
-- @tparam[opt='on'] ?string|boolean opts.fromCache if set to `'on'` or `true` cached assessment reports will be returned.
-- @number[opt] opts.maxAge maximum report age, in hours, if retrieving from cache (`fromCache` parameter set).
-- @string[opt='done'] opts.all by default this call results only summaries of individual endpoints. If this parameter is set to `on`, full information will be returned. If set to `done`, full information will be returned only if the assessment is complete (status is `READY` or `ERROR`).
-- @tparam[opt='off'] ?string|boolean opts.ignoreMismatch set to `on` to proceed with assessments even when the server certificate doesn't match the assessment hostname. Please note that this parameter is ignored if a cached report is returned.
-- @treturn table [Host table](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#host)
-- @usage local result = ssllabs.analyze({
--   host = 'example.com',
--   fromCache = true,
--   maxAge = 36
-- })
function ssllabs.analyze(opts)
  if not opts.host then return nil, "host required!" end
  
  local payload = {
    host = opts.host,
    publish = opts.publish or 'off',
    startNew = opts.startNew or 'off',
    fromCache = opts.fromCache or 'on',
    maxAge = opts.maxAge,
    all = opts.all or 'done',
    ignoreMismatch = opts.ignorMismatch or 'off'
  }
  
  return api_request('analyze', payload)
end

--- Retrieve detailed endpoint information.
-- This call is used to retrieve detailed endpoint information. Implements the [getEndpointData API call](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#retrieve-detailed-endpoint-information)
-- @tab opts options table with arguments
-- @string opts.host hostname
-- @string opts.s endpoint IP address
-- @tparam[opt='off'] ?string|boolean opts.fromCache
-- @treturn table [Endpoint table](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#endpoint)
-- @usage local ep_data = ssllabs.get_endpoint_data()
function ssllabs.get_endpoint_data(opts)
  if not opts.host or not opts.s then
    return nil, "host and endpoint IP address required!"
  end
  
  local payload = {
    host = opts.host,
    s = opts.s,
    fromCache = opts.fromCache or 'off'
  }
  
  return api_request('getEndpointData', payload)
end

--- Retrieve known status codes.
-- @treturn table [StatusCode table](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#statuscodes)
-- @usage local code = ssllabs.get_status_codes()
function ssllabs.get_status_codes()
  return api_request('getStatusCodes')
end

--- Retrieve root certificates.
-- @treturn string This call returns the root certificates used for trust validation.
-- @usage local certs = ssllabs.get_root_certs_raw()
function ssllabs.get_root_certs_raw()
  local resp = api_request('getRootCertsRaw')
  return resp.text
end

return ssllabs