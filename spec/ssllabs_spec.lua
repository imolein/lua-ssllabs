package.path = package.path .. ';./?/init.lua'

local ssll
local url

describe('ssl labs', function()
  setup(function()
    ssll = require('ssllabs')
    url = 'httpbin.org'
  end)

  it('checks info API call', function()    
    local result = ssll.info()
    local expected = { 
      criteriaVersion = 'string',
      currentAssessments = 'number',
      engineVersion = 'string',
      maxAssessments = 'number',
      messages = 'table',
      newAssessmentCoolOff = 'number'
    }
    
    for k, v in pairs(result) do
      assert.are.same(expected[k], type(v))
    end
  end)

  it('starts an assessment', function()
      pending('no idea how to test it yet')
  end)

  it('checks getStatusCodes API call', function()
    local result = ssll.get_status_codes()
    
    assert.is_table(result.statusDetails)
  end)
end)
