<div align="center">
  <img src="https://www.image2url.com/r2/default/images/1795519428668-08e17509-eb29-45cf-b1a2-7ddb06372b47.png" alt="ForktUI logo" width="128" />
  <h1>ForktUI</h1>
  <p><strong>A modular Luau interface toolkit for Roblox.</strong></p>
  <p>
    <a href="https://github.com/HamZyy4/ForktUI">Source</a> ·
    <a href="https://hamzyy4.github.io/ForktUI-Docs/">Documentation</a> ·
    <a href="https://github.com/HamZyy4/Icons">Icon packs</a>
  </p>
  <p>Maintained by <strong>sukitovone</strong></p>
</div>

---

## Overview

ForktUI is a component-based interface library for Roblox client experiences. It provides a window shell, sidebar navigation, tabs, sections, controls, dialogs, popups, notifications, theme management, localization, and optional configuration persistence.

The visual system is designed around graphite surfaces, restrained contrast, compact spacing, and clear interaction states. Its layout is independently maintained for ForktUI rather than relying on the visual identity of another UI library.

## Loader

The distributable is built from the source in `src/` and published at `dist/main.lua`.

**Copy this loader example:**

```lua
local ForktUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/HamZyy4/ForktUI/main/dist/main.lua"
))()
```

The URL above follows the latest successful build on `main`. For repeatable releases, pin the URL to a reviewed commit or release asset instead of tracking `main`.

> The `loadstring` loader requires a client environment that explicitly supports `loadstring` and HTTP retrieval. For a normal Roblox Studio project, use the Rojo/ModuleScript installation described below. Do not place executor-only APIs in a standard LocalScript.

## Quick start

```lua
local ForktUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/HamZyy4/ForktUI/main/dist/main.lua"
))()

local Window = ForktUI:CreateWindow({
    Title = "My Interface",
    Author = "sukitovone",
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.RightShift,
    Size = UDim2.fromOffset(640, 460),
    AutoScale = true,
    User = {
        Enabled = true,
        Anonymous = false,
    },
})

local MainTab = Window:Tab({
    Title = "General",
    Icon = "house",
})

MainTab:Toggle({
    Title = "Example setting",
    Desc = "A basic ForktUI toggle.",
    Value = false,
    Callback = function(enabled)
        print("Enabled:", enabled)
    end,
})

MainTab:Button({
    Title = "Show notification",
    Callback = function()
        ForktUI:Notify({
            Title = "ForktUI",
            Content = "The interface is ready.",
            Duration = 4,
        })
    end,
})
```

## Interface components

The current source includes these element methods:

| Category | Methods |
| --- | --- |
| Basic controls | `Button`, `Toggle`, `Input`, `Dropdown`, `Slider`, `Colorpicker`, `Keybind` |
| Content | `Paragraph`, `Code`, `Image`, `Viewport`, `ProgressBar`, `Divider`, `Space` |
| Layout | `Section`, `Group`, `HStack`, `VStack` |
| Window | `Tab`, `Section`, `Dialog`, `Tag`, `CreateTopbarButton`, `EditOpenButton` |
| Library | `Notify`, `Popup`, `SetTheme`, `AddTheme`, `Localization`, `SetLanguage` |

See the [API documentation](https://hamzyy4.github.io/ForktUI-Docs/) for configuration fields and method examples. The docs are written against the source files included in this repository.

## User profile card

Set `User.Enabled = true` to show the account card in the sidebar. Selecting it opens a profile summary for the local Roblox account, including its display name, username, user ID, account age, and profile URL. `User.Anonymous = true` masks the displayed identity.

```lua
local Window = ForktUI:CreateWindow({
    Title = "My Interface",
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function(player)
            print("Profile selected:", player.Name)
        end,
    },
})
```

If the runtime does not provide a clipboard function, the profile popup displays the profile URL so it can be copied manually.

## Configuration persistence

Configuration persistence depends on filesystem functions supplied by the runtime. It is optional and should be checked before use.

```lua
local Window = ForktUI:CreateWindow({
    Title = "My Interface",
    Folder = "MyInterface",
})

local ConfigManager = Window.ConfigManager
if type(ConfigManager) == "table" then
    local Config = ConfigManager:Config("default")
    -- Create controls with unique Flag values before saving or loading.
    local saved, err = Config:Save()
    if not saved then
        warn("Could not save config:", err)
    end
else
    warn("Config persistence is unavailable in this environment.")
end
```

Use a unique `Flag` for every saved element. The config system is a convenience for client preferences; it is not secure storage and must not be used for secrets or server-side authorization.

## Themes and notifications

```lua
ForktUI:SetTheme("Dark")

ForktUI:Notify({
    Title = "Saved",
    Content = "Your preference was saved.",
    Duration = 4,
})
```

Custom themes can be registered with `ForktUI:AddTheme()`. See [Themes](https://hamzyy4.github.io/ForktUI-Docs/docs/theme) and [Notifications](https://hamzyy4.github.io/ForktUI-Docs/docs/notification).

## Install as a Roblox project

For a standard Roblox Studio workflow, clone the repository with its icon submodule and map it with Rojo:

```bash
git clone --recurse-submodules https://github.com/HamZyy4/ForktUI.git
cd ForktUI
git submodule update --init --recursive
aftman install
rojo build default.project.json -o ForktUI.rbxm
```

Then place the resulting ModuleScript in `ReplicatedStorage` and require `ForktUI.Init` from a client-side `LocalScript`.

## Build from source

The build uses the tool versions pinned in `aftman.toml`.

```bash
npm install
aftman install
npm run build
```

The generated distributable is written to `dist/main.lua`. Review build output before publishing or using the raw loader URL.

## Repository map

- `src/` — modular Luau implementation.
- `src/elements/` — public element factories and component methods.
- `src/components/window/` — window shell, tabs, dialogs, and navigation.
- `src/config/` — optional filesystem-backed configuration manager.
- `examples/` — full interactive showcase.
- `dist/main.lua` — generated loader bundle.
- `build/` — build scripts and DarkLua configuration.

## License and attribution

ForktUI-specific maintenance and modifications are maintained by **sukitovone**. This repository also contains portions derived from upstream open-source work; the applicable notices and retained upstream attribution are documented in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md). The project is distributed under the MIT terms in [`LICENSE`](LICENSE).
