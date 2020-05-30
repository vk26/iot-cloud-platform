local t = require('luatest')
local g = t.group('integration_grafana_api')

local helper = require('test.helper.integration')
local cluster = helper.cluster
local deepcopy = require('table').deepcopy

local telemetry1 = {
    id = '1',
    device_id = 'dev01',
    device_name = 'Device_01',
    bucket_id = 1,
    telemetry_key = 'temperature',
    telemetry_value = 86,
    timestamp = 1590634148
}
local telemetry2 = {
    id = '2',
    device_id = 'dev01',
    device_name = 'Device_01',
    bucket_id = 1,
    telemetry_key = 'temperature',
    telemetry_value = 65,
    timestamp = 1590634148
}
local telemetry3 = {
    id = '3',
    device_id = 'dev01',
    device_name = 'Device_01',
    bucket_id = 1,
    telemetry_key = 'pressure',
    telemetry_value = 124,
    timestamp = 1590634148
}
local data = {
    {
        target = "pressure",
        datapoints =  {
            {124,1590634148000},
        }
    },
    {
        target = "temperature",
        datapoints  = {
            {86,1590634148000},
            {65,1590634148000},
        }
    },
}

g.test_on_get_grafana_telemetry_data_ok = function ()
    local request_data = {targets = {{target= '1'}}}
    -- box.space.telemetry:insert(box.space.telemetry:frommap(telemetry1))
    -- box.space.telemetry:insert(box.space.telemetry:frommap(telemetry2))
    -- box.space.telemetry:insert(box.space.telemetry:frommap(telemetry3))
    helper.assert_http_json_request('post', '/api/telemetry', telemetry1, {
        body = {info = "Successfully created"}, 
        status=201
    })
    helper.assert_http_json_request('post', '/api/telemetry', telemetry2, {
        body = {info = "Successfully created"}, 
        status=201
    })
    helper.assert_http_json_request('post', '/api/telemetry', telemetry3, {
        body = {info = "Successfully created"}, 
        status=201
    })

    helper.assert_http_json_request('post', '/grafana/query', request_data, {
        body = data, 
        status = 200
    })
end
