local t = require('luatest')

local cartridge_helpers = require('cartridge.test-helpers')
local shared = require('test.helper')

local helper = {shared = shared}

helper.cluster = cartridge_helpers.Cluster:new({
    server_command = shared.server_command,
    datadir = shared.datadir,
    use_vshard = true,
    replicasets = {
        {
            alias = 'api',
            uuid = cartridge_helpers.uuid('a'),
            roles = {'vshard-storage', 'vshard-router', 'telemetry-storage', 'api', 'grafana-api'},
            servers = {{ instance_uuid = cartridge_helpers.uuid('a', 1) }},
        }
    },
})

helper.assert_http_json_request = function (method, path, body, expected)
    checks('string', 'string', '?table', 'table')
    local response = helper.cluster.main_server:http_request(method, path, {
        json = body,
        headers = {["content-type"]="application/json; charset=utf-8"},
        raise = false
    })

    print(response.status)
    print(response.body)

    t.assert_equals(response.json, expected.body)
    t.assert_equals(response.status, expected.status)

    return response
end

t.before_suite(function() helper.cluster:start() end)
t.after_suite(function() helper.cluster:stop() end)

return helper
