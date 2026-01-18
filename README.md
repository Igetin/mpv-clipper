# HACK

This is a quick & dirty hack of [ekisu’s mpv-webm][mpv-webm] that adds an option for selecting an encoding profile. All profiles starting with `enc-` are considered encoding profiles. CRF can be changed independently and overrides any CRF setting in profile. All other options have been removed.

Has basic support for HLS network streams, including livestreams. Not tested extensively for livestreams, but it should mostly work at least with YouTube and Twitch.

# mpv-clipper
Simple clip maker for [mpv][mpv], with no external dependencies.

![sample](/img/sample.png)

## Installation
Place [this][build] in your mpv `scripts` folder. The `scripts` folder can be found (or created, if it does not already exist) in the following paths:
- Linux/macOS: `~/.config/mpv/scripts`, where `~` is your user's home folder;
- Windows: mpv will try to load scripts from `%APPDATA%\mpv\scripts`, followed by `<mpv binary folder>\portable_config\scripts` and `<mpv binary folder>\mpv\scripts`; where `%APPDATA%` is a Windows-specific directory (typing `%APPDATA%` on Windows + R should take you to that folder), and `<mpv binary folder>` is the folder that contains the `mpv.exe` binary.

Additional details about the folder structure can be found in the [mpv's manual][file locations].

By default, the script is activated by the W (shift+w) key.

## Usage
Follow the on-screen instructions.

## Configuration
You can configure the script's defaults by either changing the `options` at the beginning of the script, or placing a `clipper.conf` inside the `script-opts` directory. Note that you don't need to specify all options, only the ones you wish to override.

## Building (development)
Building requires [`moonc`, the MoonScript compiler][moonscript], added to the PATH, and a GNU Make-compatible make. Run `make` on the root directory. The output files will be placed under the `build` directory.

[build]: https://raw.githubusercontent.com/Igetin/mpv-webm/master/build/clipper.lua
[file locations]: https://mpv.io/manual/master/#files
[mpv]: https://mpv.io
[moonscript]: https://moonscript.org
