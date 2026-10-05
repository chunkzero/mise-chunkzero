# mise-chunkzero

A [mise](https://mise.jdx.dev) backend plugin for chunkzero tools. It installs releases listed in
[chunkzero/mise-registry](https://github.com/chunkzero/mise-registry), verifies each archive's sha256, and keeps the
runtime files bundled next to the executable.

```toml
[plugins]
chunkzero = "https://github.com/chunkzero/mise-chunkzero"

[tools]
# The newest nightly; `chunkzero:rpp-beta` follows the newest alpha, beta or rc instead.
"chunkzero:chunk-nightly" = { version = "latest", prerelease = true }
# An exact version from any channel.
"chunkzero:rpp" = "0.1.0-nightly.20261004062300.ge282f11816cd"
```

Each channel is its own tool, so its releases are cached and installed separately from the others. `prerelease = true`
lets `latest` select nightly and beta versions. With `mise.lock`, the resolved version stays pinned; `mise upgrade`
moves to the channel's newest release. The registry has no release dates, so mise's `minimum_release_age` doesn't apply
to these tools.

Stable releases don't need the plugin:

```toml
[tools]
"github:chunkzero/chunk" = "latest"
```

Tools: `chunk`, `rpp`. Platforms: Linux and macOS on x64 and arm64, Windows on x64.

## Development

`test/e2e.sh` installs chunk from a local copy of the registry and checks that a wrong checksum is rejected. Set
`MISE_CHUNKZERO_REGISTRY` to point the plugin at another registry URL.
