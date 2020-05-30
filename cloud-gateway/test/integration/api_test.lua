local t = require('luatest')
local g = t.group('integration_api')

local helper = require('test.helper.integration')
local cluster = helper.cluster
local deepcopy = require('table').deepcopy

local test_telemetry = {
    id = '123',
    device_id = 'dev01',
    device_name = 'Device_01',
    bucket_id = 1,
    telemetry_key = 'temperature',
    telemetry_value = 86
}

g.test_on_post_ok = function ()
    local test_telemetry_data = deepcopy(test_telemetry)
    helper.assert_http_json_request('post', '/api/telemetry', test_telemetry_data, {
        body = {info = "Successfully created"}, 
        status=201
    })
end
