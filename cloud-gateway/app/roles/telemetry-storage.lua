local checks = require('checks')
local errors = require('errors')

local function tuple_to_table(format, tuple)
    local map = {}
    for i, v in ipairs(format) do
        map[v.name] = tuple[i]
    end
    return map
end

local function init_space()
    -- box.space.telemetry:drop()
    
    box.schema.space.create(
        'telemetry',
        {
            format = {
                {'id', 'string'},
                {'device_id', 'string'},
                {'device_name', 'string'},
                {'bucket_id', 'unsigned'},
                {'telemetry_key', 'string'},
                {'telemetry_value', 'unsigned'},
                {'timestamp', 'unsigned'}
            },

            if_not_exists = true,
        }
    )
    box.space.telemetry:create_index('primary', {
        parts = {{'id', 'string'}},
        type = 'HASH',
        if_not_exists = true,
    })

    box.space.telemetry:create_index('device_id', {
        parts = {'device_id'},
        unique = false,
        if_not_exists = true,
    })

    box.space.telemetry:create_index('bucket_id', {
        parts = {'bucket_id'},
        unique = false,
        if_not_exists = true,
    })
end

local function telemetry_add(telemetry)
    checks('table')

    box.space.telemetry:insert(box.space.telemetry:frommap(telemetry))

    return {ok = true, error = nil}
end

local function get_telemetrys_by_device(device_id)
    checks('number')
    local tupels = box.space.telemetry:select{device_id = device_id}
    local telemetry = {}
    for i = 1, #tupels do
        local values = telemetry[tupels[i][5]] or {}
        table.insert(values, {tupels[i][6], tupels[i][7]*1000} ) 
        telemetry[tupels[i][5]] = values
    end

    local collection = {}
    for k, datapoints in pairs(telemetry) do 
        table.insert(collection, {target = k, datapoints = datapoints}) 
    end

    return collection
end

local function init(opts)
    if opts.is_master then
        init_space()

        box.schema.func.create('telemetry_add', {if_not_exists = true})
        box.schema.func.create('get_telemetrys_by_device', {if_not_exists = true})
    end

    rawset(_G, 'telemetry_add', telemetry_add)
    rawset(_G, 'get_telemetrys_by_device', get_telemetrys_by_device)

    return true
end

return {
    role_name = 'telemetry-storage',
    init = init,
    utils = {
        telemetry_add = telemetry_add,
        get_telemetrys_by_device = get_telemetrys_by_device,
    },
    dependencies = {
        'cartridge.roles.vshard-storage'
    }
}
