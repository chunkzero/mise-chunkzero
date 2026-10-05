local registry = require("registry")

-- With `channel = "nightly"` or `channel = "beta"`, only that channel's releases are listed, so mise's `latest` picks
-- its newest. Without a channel every release is listed, so exact versions from any channel resolve.
function PLUGIN:BackendListVersions(ctx)
    local channel = ctx.options and ctx.options.channel
    if channel ~= nil and channel ~= "latest" and channel ~= "beta" and channel ~= "nightly" then
        error("channel must be latest, beta or nightly, not " .. tostring(channel))
    end
    local versions = {}
    for _, entry in ipairs(registry.load(ctx.tool).versions) do
        if channel == nil or registry.channel(entry.version) == channel then
            table.insert(versions, entry.version)
        end
    end
    return { versions = versions }
end
