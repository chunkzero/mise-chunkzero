local http = require("http")
local json = require("json")

local M = {}

-- MISE_CHUNKZERO_REGISTRY overrides the registry base URL, e.g. to test against a local copy.
M.BASE = os.getenv("MISE_CHUNKZERO_REGISTRY") or "https://raw.githubusercontent.com/chunkzero/mise-registry/main"

function M.load(tool)
    local response = http.get({ url = M.BASE .. "/tools/" .. tool .. ".json" })
    if response.status_code == 404 then
        error("chunkzero has no tool named " .. tool .. "; see https://github.com/chunkzero/mise-registry/tree/main/tools")
    end
    if response.status_code ~= 200 then
        error("couldn't read the chunkzero registry for " .. tool .. ": HTTP " .. response.status_code)
    end
    return json.decode(response.body)
end

function M.channel(version)
    if version:find("-nightly.", 1, true) then
        return "nightly"
    end
    return version:find("-", 1, true) and "beta" or "latest"
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
