--- Lua module for the Qualys SSL Labs Server Test
--
-- @author Sebastian Huebner
-- @copyright 2019
-- @license MIT
-- @module ssllabs

local requests = require('requests')

local ssllabs = {
  _VERSION      = 'lua-ssllabs 0.2-0',
  _DESCRIPTION  = 'Lua module for the Qualys SSL Labs Server Test',
  _URL          = 'https://git.kokolor.es/imo/lua-ssllabs',
  _LICENCE      = 'MIT'
}

local API = 'https://api.ssllabs.com/api/v3/'
local ERRORS = {
  ['400'] = 'Invocation error (invalid Parameters)',
  ['429'] = 'Request rate to high',
  ['500'] = 'Internal Error',
  ['503'] = 'Service not availabke',
  ['529'] = 'Service is overloaded'
}
local DEFAULTS = {
  publish = false,
  startNew = false,
  fromCache = false,
  maxAge = nil,
  all = nil,
  ignoreMismatch = false
}


-- Private functions --

-- check the given options
local function check_options(pl)
  if not pl.host or pl.host == '' then
    return nil, 'host required.'
  elseif pl.startNew and pl.fromCache then
    return nil, 'fromCache cannot be used at the same time as startNew.'
  elseif pl.maxAge and not pl.fromCache then
    return nil, 'maxAge expects fromCache parameter to be true.'
  end

  return pl
end

-- since you can give the option values as string
-- OR boolean, we have to check and change them
local function bool_to_parameter(pl)
  local converted = {}

  for k, v in pairs(pl) do
    if type(v) == 'boolean' then
      converted[k] = v and 'on' or 'off'
    else
      converted[k] = v
    end
  end

  return converted
end

-- the function, which make the request
local function api_request(path, payload)
  payload = payload and bool_to_parameter(payload)

  local resp

  resp = requests.get({ url = API .. path, params = payload })

  if resp.status_code ~= 200 then
    return nil, resp.status_code, ERRORS[tostring(resp.status_code)]
  end

  if resp.headers['content-type']:find('application/json', nil, true) then
    local jresp = resp.json()

    if jresp.errors then
      return nil, 400, string.format('Invocation Error - API returned: %s', jresp.errors.message)
    end

    return jresp
  else
    return resp.text
  end
end


-- Public functions --

--- Check availability of the SSL Labs servers
-- and some other data like software version. Implements the [info API call](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#check-ssl-labs-availability)
-- @treturn ?table|nil [Info table](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#info) / In case of error nil
-- @treturn number error status code
-- @treturn string error status message
-- @usage local info = ssllabs.info()
function ssllabs.info()
  return api_request('info')
end

--- Invoke assessment and check progress.
-- This call is used to initiate an assessment, or to retrieve the status of an assessment in progress or in the cache.  Implements the [analyze API call](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#invoke-assessment-and-check-progress)
-- @tab opts options table with arguments
-- @string opts.host hostname
-- @bool[opt=false] opts.publish if set to `'on'` or `true` the result will be published on the public result boards.
-- @bool[opt=false] opts.startNew if set to `'on'` or `true` a new assessment is started. However, if there's already an assessment in progress, its status is delivered instead.
-- @bool[opt=true] opts.fromCache if set to `'on'` or `true` cached assessment reports will be returned.
-- @number[opt=10] opts.maxAge maximum report age, in hours, if retrieving from cache (`fromCache` parameter set).
-- @string[opt='done'] opts.all by default this call results only summaries of individual endpoints. If this parameter is set to `on`, full information will be returned. If set to `done`, full information will be returned only if the assessment is complete (status is `READY` or `ERROR`).
-- @bool[opt=false] opts.ignoreMismatch set to `on` to proceed with assessments even when the server certificate doesn't match the assessment hostname. Please note that this parameter is ignored if a cached report is returned.
-- @treturn ?table|nil [Host table](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#host)
-- @treturn ?nil|number error status code
-- @treturn ?nil|string error status message
-- @usage local result = ssllabs.analyze({
--   host = 'example.com',
--   fromCache = true,
--   maxAge = 36
-- })
function ssllabs.analyze(opts)
  setmetatable(opts, { __index = DEFAULTS })

  local payload = {
    host = opts.host,
    publish = opts.publish,
    startNew = opts.startNew,
    fromCache = opts.fromCache,
    maxAge = opts.maxAge,
    all = opts.all,
    ignoreMismatch = opts.ignoreMismatch
  }

  check_options(payload)

  return api_request('analyze', assert(check_options(payload)))
end

--- Retrieve cached assessment report.
-- Short for `ssllabs.analyze({host = host, fromCache = true})`.
-- @string host hostname
-- @number[opt] maxAge maximum report age, in hours, if retrieving from cache (`fromCache` parameter set).
-- @treturn ?table|nil [Host table](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#host)
-- @treturn ?nil|number error status code
-- @treturn ?nil|string error status message
-- @usage local result = ssllabs.from_cache('example.com', 36)
function ssllabs.from_cache(host, maxAge)
  return ssllabs.analyze({
    host = host,
    maxAge = maxAge,
    fromCache = 'on'
  })
end

--- Start new assessment.
-- Short for `ssllabs.analyze({host = host, startNew = true})`.
-- @tab opts options table with arguments
-- @string opts.host hostname
-- @bool[opt=false] opts.publish if set to `'on'` or `true` the result will be published on the public result boards.
-- @bool[opt=false] opts.ignoreMismatch set to `on` to proceed with assessments even when the server certificate doesn't match the assessment hostname. Please note that this parameter is ignored if a cached report is returned.
-- @treturn ?table|nil [Host table](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#host)
-- @treturn ?nil|number error status code
-- @treturn ?nil|string error status message
-- @usage local result = ssllabs.new_assessment({
--   host = 'example.com',
--   publish = true,
--   ignoreMismatch = false
-- })
function ssllabs.new_assessment(opts)
  return ssllabs.analyze({
    host = opts.host,
    startNew = 'on',
    publish = opts.publish,
    ignoreMismatch = opts.ignoreMismatch
  })
end

--- Retrieve detailed endpoint information.
-- This call is used to retrieve detailed endpoint information. Implements the [getEndpointData API call](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#retrieve-detailed-endpoint-information)
-- @tab opts options table with arguments
-- @string opts.host hostname
-- @string opts.s endpoint IP address
-- @bool[opt=true] opts.fromCache
-- @treturn ?table|nil [Endpoint table](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#endpoint)
-- @treturn ?nil|number error status code
-- @treturn ?nil|string error status message
-- @usage local ep_data = ssllabs.get_endpoint_data()
function ssllabs.get_endpoint_data(opts)
  assert(opts.host and opts.s, 'host and endpoint IP address required.')

  setmetatable(opts, { __index = DEFAULTS })

  local payload = {
    host = opts.host,
    s = opts.s,
    fromCache = opts.fromCache
  }

  return api_request('getEndpointData', payload)
end

--- Retrieve known status codes.
-- @treturn ?table|nil [StatusCode table](https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#statuscodes)
-- @treturn ?nil|number error status code
-- @treturn ?nil|string error status message
-- @usage local code = ssllabs.get_status_codes()
function ssllabs.get_status_codes()
  return api_request('getStatusCodes')
end

--- Retrieve root certificates.
-- @treturn string This call returns the root certificates used for trust validation.
-- @usage local certs = ssllabs.get_root_certs_raw()
function ssllabs.get_root_certs_raw()
  return api_request('getRootCertsRaw')
end


if _TEST then
  ssllabs._bool_to_parameter = bool_to_parameter
end

return ssllabs