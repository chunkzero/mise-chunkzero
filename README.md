# mise-chunkzero

A [mise](https://mise.jdx.dev) backend plugin for chunkzero tools. It installs releases listed in
[chunkzero/mise-registry](https://github.com/chunkzero/mise-registry), verifies each archive's sha256, and keeps the
runtime files bundled next to the executable.

```toml
[plugins]
chunkzero = "https://github.com/chunkzero/mise-chunkzero"

[tools]
# Newest nightly, or newest alpha/beta/rc with channel = "beta".
"chunkzero:chunk" = { version = "latest", channel = "nightly", prerelease = true, minimum_release_age = "0s" }
# An exact version from any channel.
"chunkzero:rpp" = "0.1.0-nightly.20261004062300.ge282f11816cd"
```

`channel` limits mise to that channel's releases, and `prerelease = true` lets `latest` select them. mise ignores
releases younger than `minimum_release_age` (24 hours by default), so nightlies need it lowered. With `mise.lock`, the
resolved version is pinned until `mise upgrade`.

Stable releases don't need the plugin:

```toml
[tools]
"github:chunkzero/chunk" = "latest"
```

Tools: `chunk`, `rpp`. Platforms: Linux and macOS on x64 and arm64, Windows on x64.

## Development

`test/e2e.sh` installs chunk from a local copy of the registry and checks that a wrong checksum is rejected. Set
`MISE_CHUNKZERO_REGISTRY` to point the plugin at another registry URL.
