local http = require("http")
local json = require("json")

local M = {}

-- MISE_CHUNKZERO_REGISTRY overrides the registry base URL, e.g. to test against a local copy.
M.BASE = os.getenv("MISE_CHUNKZERO_REGISTRY") or "https://raw.githubusercontent.com/chunkzero/mise-registry/main"

local CHANNELS = { nightly = true, beta = true }

--- Splits `chunk-nightly` into ("chunk", "nightly"); a bare `chunk` lists every channel.
function M.parse(name)
    if not name:match("^%l[%l%d%-]*$") then
        error("invalid chunkzero tool name " .. name)
    end
    local tool, channel = name:match("^(.-)%-(%l+)$")
    if tool and CHANNELS[channel] then
        return tool, channel
    end
    return name, nil
end

function M.channel(version)
    if version:find("-nightly.", 1, true) then
        return "nightly"
    end
    return version:find("-", 1, true) and "beta" or "latest"
end

local VERSIONS = {
    "^%d+%.%d+%.%d+$",
    "^%d+%.%d+%.%d+%-alpha%.%d+$",
    "^%d+%.%d+%.%d+%-beta%.%d+$",
    "^%d+%.%d+%.%d+%-rc%.%d+$",
    "^%d+%.%d+%.%d+%-nightly%.%d+%.g%x+$",
}

function M.valid_version(version)
    for _, pattern in ipairs(VERSIONS) do
        if version:match(pattern) then
            return true
        end
    end
    return false
end

function M.load(tool)
    local response = http.get({ url = M.BASE .. "/tools/" .. tool .. ".json" })
    if response.status_code == 404 then
        error("chunkzero has no tool named " .. tool .. "; see https://github.com/chunkzero/mise-registry/tree/main/tools")
    end
    if response.status_code ~= 200 then
        error("couldn't read the chunkzero registry for " .. tool .. ": HTTP " .. response.status_code)
    end
    local registry = json.decode(response.body)
    for _, entry in ipairs(registry.versions) do
        if not M.valid_version(entry.version) then
            error("the chunkzero registry lists an invalid " .. tool .. " version: " .. entry.version)
        end
    end
    return registry
end

function M.platform()
    local os_names = { linux = "linux", darwin = "darwin", windows = "windows" }
    local arch_names = { amd64 = "x64", arm64 = "arm64" }
    local os_name, arch = os_names[RUNTIME.osType], arch_names[RUNTIME.archType]
    if not os_name or not arch then
        error("chunkzero tools don't support " .. RUNTIME.osType .. "-" .. RUNTIME.archType)
    end
    return os_name .. "-" .. arch
end

return M
