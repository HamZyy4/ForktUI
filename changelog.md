# ForktUI Changelog

## 1.6.66-forktui.2

### Visual system
- Reworked the default Dark palette into a graphite/charcoal system with muted neutral accents.
- Tightened window geometry, changed panel radii and spacing, and introduced a narrow active-tab rail for clearer sidebar navigation.
- Replaced the KeySystem composition with a dedicated access panel, optional thumbnail, clearer input hierarchy, provider actions, and explicit Continue / Exit actions.

### Reliability
- Added strict KeySystem configuration checks and fail-closed custom validator handling.
- Guarded clipboard, service-provider, and filesystem operations against unsupported runtime APIs.
- Fixed key persistence path consistency and sanitized the per-user key filename.
- Made exiting the KeySystem cancel window creation instead of leaving the creation flow waiting indefinitely.
- Retained defensive window/theme and gradient handling from the prior package revision.

### Icons and repository structure
- Switched icon integration to the companion `Icons` submodule at `src/Icons/Main-v2`; no server-side icon bridge or RemoteFunction is needed.
- Kept icon asset families and their existing third-party attribution in the separate `HamZyy4/Icons` repository.
- Consolidated the library's runnable showcase to `examples/full-example.client.lua`. Internal regression scripts remain under `tests/`.
- Updated repository URLs, build metadata, documentation branding, and maintainer metadata to `sukitovone`.

### Compatibility notes
- The public window, tab, control, theme, notification, localization, and configuration APIs are retained where possible.
- The upstream API baseline remains 1.6.66; this package revision identifies the ForktUI-maintained changes.
- The bundled `dist/main.lua` must be rebuilt from source before release. The repository's GitHub Actions workflow performs that build after a push to `main`.
