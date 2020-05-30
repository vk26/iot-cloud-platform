local t = require('luatest')
local g = t.group('unit_storage_utils')
local helper = require('test.helper.unit')

require('test.helper.unit')

local deepcopy = require('table').deepcopy
local storage = require('app.roles.telemetry-storage')
local utils = storage.utils

local telemetry1 = {
    id = '1',
    device_id = 'dev01',
    device_name = 'Device_01',
    bucket_id = 1,
    telemetry_key = 'temperature',
    telemetry_value = 86,
    timestamp = 1590631001
}
local telemetry2 = {
    id = '2',
    device_id = 'dev01',
    device_name = 'Device_01',
    bucket_id = 1,
    telemetry_key = 'temperature',
    telemetry_value = 65,
    timestamp = 1590632002
}
local telemetry3 = {
    id = '3',
    device_id = 'dev01',
    device_name = 'Device_01',
    bucket_id = 1,
    telemetry_key = 'temperature',
    telemetry_value = 90,
    timestamp = 1590633003
}
local telemetry4 = {
    id = '4',
    device_id = 'dev01',
    device_name = 'Device_01',
    bucket_id = 1,
    telemetry_key = 'pressure',
    telemetry_value = 124,
    timestamp = 1590634148
}


g.test_sample = function()
    t.assert_equals(type(box.cfg), 'table')
end

g.test_telemetry_add_ok = function()
    local to_insert = deepcopy(telemetry1)
    t.assert_equals(utils.telemetry_add(to_insert), {ok = true})
    local from_space = box.space.telemetry:get('1')
    t.assert_equals(from_space, box.space.telemetry:frommap(to_insert))
end

g.test_get_telemetry_by_device = function()
    box.space.telemetry:insert(box.space.telemetry:frommap(telemetry2))
    box.space.telemetry:insert(box.space.telemetry:frommap(telemetry1))
    box.space.telemetry:insert(box.space.telemetry:frommap(telemetry3))
    box.space.telemetry:insert(box.space.telemetry:frommap(telemetry4))
    t.assert_equals(utils.get_telemetry_by_device('dev01'), {
        {
            target = "pressure",
            datapoints =  {
                {124,1590634148000},
            }
        },
        {
            target = "temperature",
            datapoints  = {
                {86,1590631001000},
                {65,1590632002000},
                {90,1590633003000},
            }
        },
    })
end

g.before_all(function()
    storage.init({is_master = true})
end)

g.before_each(function ()
    box.space.telemetry:truncate()
end)
