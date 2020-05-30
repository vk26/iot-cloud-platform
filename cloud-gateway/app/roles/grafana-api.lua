local cartridge = require('cartridge')
local errors = require('errors')
local log = require('log')

local err_vshard_router = errors.new_class("Vshard routing error")
local err_httpd = errors.new_class("httpd error")

local function json_response(req, json, status)
    local resp = req:render({json = json})
    resp.status = status
    return resp
end

local function internal_error_response(req, error)
    local resp = json_response(req, {
        info = "Internal error",
        error = error
    }, 500)
    return resp
end

local function get_grafana_metrics_keys(req)
    local data = {"upper_25","upper_50","upper_75","upper_90","upper_95"}

    return json_response(req, data, 200)
end

local function get_grafana_metrics_data(req)
    local json=require('json')

    local device_id = 'dev01' -- TODO: 
    local router = cartridge.service_get('vshard-router').get()
    local bucket_id = router:bucket_id(device_id)

    local data, error = err_vshard_router:pcall(
        router.call,
        router,
        bucket_id,
        'read',
        'get_telemetry_by_device',
        {device_id}
    )
    log.warn(error)
    log.warn(data)
    return json_response(req, data, 200)
end

local function init(opts) -- luacheck: no unused args
   if opts.is_master then
        box.schema.user.grant('guest',
            'read,write',
            'universe',
            nil, { if_not_exists = true }
        )
    end

    local httpd = cartridge.service_get('httpd')

    if not httpd then
        return nil, err_httpd:new("not found")
    end

    httpd:route({method = 'GET', path = '/grafana'}, function()
        return {body = 'OK'}
    end)

    httpd:route(
        { path = '/grafana/search', method = 'POST', public = true },
        get_grafana_metrics_keys
    )

    httpd:route(
        { path = '/grafana/query', method = 'POST', public = true },
        get_grafana_metrics_data
    )

    return true
end

return {
    role_name = 'grafana-api',
    init = init,
    -- stop = stop,
    -- validate_config = validate_config,
    -- apply_config = apply_config,
    -- dependencies = {'cartridge.roles.vshard-router'},
}
