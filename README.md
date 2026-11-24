<div align="center">

# ForktUI

**A graphite-first interface library for Roblox experiences.**

[Library](https://github.com/HamZyy4/ForktUI) · [Documentation](https://hamzyy4.github.io/ForktUI-Docs) · [Icons](https://github.com/HamZyy4/Icons)

Maintainer: **sukitovone**

</div>

## Overview

ForktUI provides a modular Luau interface toolkit with a compact window shell, sidebar navigation, controls, dialogs, notifications, configurable themes, and icon packs. The default visual system uses graphite surfaces, muted contrast, restrained borders, and a narrow active-tab rail.

## Load the library

```lua
local ForktUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/HamZyy4/ForktUI/main/dist/main.lua"
))()

local Window = ForktUI:CreateWindow({
    Title = "My Hub",
    Author = "sukitovone",
    Theme = "Dark",
})
```

## Example

The repository contains one maintained end-to-end example: [`examples/full-example.client.lua`](examples/full-example.client.lua). It demonstrates window creation, tabs, sections, common controls, theme changes, notifications, dialogs, keybinds, and configuration.

## Development

```bash
npm install
aftman install
npm run build
```

The build requires the tools pinned in `aftman.toml`. GitHub Actions rebuilds `dist/main.lua` after pushes to `main`. Review the build workflow result before using the raw distribution URL.

## Key system

Key validation supports a static key, a custom `KeyValidator` callback, or configured service adapters. Saved keys use guarded filesystem calls and are revalidated when the library starts. Client-side keys are not secret; use a server-backed validation service for sensitive access control.

## Companion repositories

- [ForktUI documentation](https://github.com/HamZyy4/ForktUI-Docs)
- [ForktUI icon packs](https://github.com/HamZyy4/Icons)

## License and notices

ForktUI is distributed under the terms in [`LICENSE`](LICENSE). See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for retained upstream and icon-pack attribution.
