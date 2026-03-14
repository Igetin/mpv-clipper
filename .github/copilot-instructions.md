# Project Guidelines

## Code Style
- Primary source files are MoonScript under `src/`, with a small Lua bootstrap layer (`src/requires.lua`, `src/options.lua`, `src/base64.lua`).
- Follow existing naming and style in nearby files instead of introducing a new style profile.
- Keep changes focused and minimal; prefer editing existing flows over adding new abstractions.
- Preserve historical event/message names used by tests (for example `webm-*` and `mpv-webm-*`) unless intentionally migrating the whole interface.

## Architecture
- Build output is a single script (`build/clipper.lua`) created by concatenating ordered source files, then compiling MoonScript output and prepending Lua bootstrap files.
- The order of `SOURCES` in `Makefile` is part of the dependency model; symbols are shared through concatenation order rather than per-file `require` usage.
- UI is page-based:
  - `src/Page.moon` is the base lifecycle for keybinds, observers, and OSD text.
  - `src/MainPage.moon`, `src/CropPage.moon`, `src/PreviewPage.moon`, and `src/EncodeOptionsPage.moon` are concrete flows.
- Encoding logic is centered in `src/encode.moon` and currently profile-driven (`enc-*` mpv profiles).
- Tests are integration-style and drive mpv through IPC (`tests/mpv_ipc.py`, `tests/testcases/base_test_case.py`).

## Build
- Build for development: `make`
- Clean and rebuild: `make clean && make`
- Install built script to local mpv config: `make install`

# Test
- All the test setup is inherited from the original mpv-webm project and has not (yet) been adapted to make it work with this project.
  - For example, tests reference `build/webm.lua` while the build currently emits `build/clipper.lua`.

## Conventions
- Do not add `require` between MoonScript files in `src/`; these files are intentionally bundled into one source unit.
- Keep a trailing blank line at the end of each `src/*.moon` file to avoid bundle concatenation issues.
- Prefer extending existing page flows and utility helpers rather than creating parallel mechanisms.
- Treat `src/formats/*.moon` as legacy/reference unless you also re-enable the related wiring in `Makefile` and `src/encode.moon`.
- When changing encode behavior, verify interactions with network/HLS handling in `src/encode.moon`.

## Pitfalls
- Reordering `SOURCES` in `Makefile` can break runtime behavior.
- The Makefile references `$(CONFFILE)` but does not define it; avoid unrelated edits to build config generation unless part of an intentional fix.

## Key Files
- Build pipeline and source order: `Makefile`
- Bundling model notes: `src/README.md`
- Main entry point: `src/main.moon`
- Encode pipeline: `src/encode.moon`
- Shared helpers: `src/util.moon`
- Base page lifecycle: `src/Page.moon`
