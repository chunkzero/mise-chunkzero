local registry = require("registry")

-- `chunkzero:chunk-nightly` and `chunkzero:chunk-beta` list only that channel's releases, so mise's `latest` picks its
-- newest; as separate tools they also get separate caches and installs. `chunkzero:chunk` lists every release.
function PLUGIN:BackendListVersions(ctx)
    local tool, channel = registry.parse(ctx.tool)
    local versions = {}
    for _, entry in ipairs(registry.load(tool).versions) do
        if channel == nil or registry.channel(entry.version) == channel then
            table.insert(versions, entry.version)
        end
    end
    return { versions = versions }
end
