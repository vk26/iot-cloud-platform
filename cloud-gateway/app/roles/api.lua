local cartridge = require('cartridge')
local errors = require('errors')
local log = require('log')
local uuid = require('uuid')
local os = require('os')

local fiber = require('fiber')
local tnt_kafka = require('kafka')
local json = require('json')

local err_vshard_router = errors.new_class("Vshard routing error")
local err_httpd = errors.new_class("httpd error")

local error_callback = function(err)
    log.error("got error: %s", err)
end
local log_callback = function(fac, str, level)
    log.info("got log: %d - %s - %s", level, fac, str)
end

local producer, err = tnt_kafka.Producer.create({
    brokers = "localhost:9092", -- TODO: use ENV
    options = {}, -- options for librdkafka
    error_callback = error_callback, -- optional callback for errors
    log_callback = log_callback, -- optional callback for logs and debug messages
    -- default_topic_options = {
    --     ["partitioner"] = "murmur2_random",
    -- }, 
})

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

local function device_unauthorized(req)
    local resp = json_response(req, {
        info = "Unauthorized"
    }, 401)
    return resp
end

local function save_telemetry_to_storage(telemetry)
    local router = cartridge.service_get('vshard-router').get()
    local bucket_id = router:bucket_id(telemetry.device_id)
    telemetry.id = uuid.str()
    telemetry.bucket_id = bucket_id
    if not telemetry.timestamp then
        telemetry.timestamp = os.time(os.date("!*t"))
    end

    local resp, error = err_vshard_router:pcall(
        router.call,
        router,
        bucket_id,
        'write',
        'telemetry_add',
        {telemetry}
    )

    return error
end

local function produce_telemetry_to_kafka(telemetry)
    local message = json.encode(telemetry)
    local err = producer:produce_async({
        topic = "telemetry_stream",
        value = message
    })
    if err ~= nil then
        lor.error(err)
    end
end

local function http_telemetry_process(req)
    local telemetry = req:json()

    local resp, error = save_telemetry_to_storage(telemetry)

    if error then
        return internal_error_response(req, error)
    end
    -- if resp.error then
    --     return storage_error_response(req, resp.error)
    -- end

    produce_telemetry_to_kafka({
        client_id = 1,
        device_id = telemetry.device_id,
        device_type = "sensor_01",
        telemetry_key = telemetry.telemetry_key,
        telemetry_value_int = telemetry.telemetry_value,
        treshold_exceeded = false,
        region = "Central",
        city = "Saint-Petersburg",
        department = "Department_01",
        timestamp = telemetry.timestamp
    })

    return json_response(req, {info = "Successfully created"}, 201)
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

    httpd:route(
        { path = '/api/telemetry', method = 'POST', public = true },
        http_telemetry_process
    )

    return true
end

local function stop()
    producer:close() 
end

local function validate_config(conf_new, conf_old) -- luacheck: no unused args
    return true
end

local function apply_config(conf, opts) -- luacheck: no unused args
    -- if opts.is_master then
    -- end

    return true
end

return {
    role_name = 'api',
    init = init,
    stop = stop,
    validate_config = validate_config,
    apply_config = apply_config,
    -- dependencies = {'cartridge.roles.vshard-router'},
}
