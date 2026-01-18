# HACK

This is a quick & dirty hack of [ekisu’s mpv-webm][mpv-webm] that adds an option for selecting an encoding profile. All profiles starting with `enc-` are considered encoding profiles. CRF can be changed independently and overrides any CRF setting in profile. All other options have been removed.

Has basic support for HLS network streams, including livestreams. Not tested extensively for livestreams, but it should mostly work at least with YouTube and Twitch.

# mpv-clipper
Simple clip maker for [mpv][mpv], with no external dependencies.

![sample](/img/sample.png)

## Installation

Prerequisites:
- moonc
- make

Run this in the project root:

```bash
make clean && make
```

Place the built file (`build/clipper.lua`) in your mpv `scripts` folder.

Additional details about the folder structure can be found in the [mpv's manual][file locations].

By default, the script is activated by the W (shift+w) key.

## Usage
Follow the on-screen instructions.

## Configuration
You can configure the script's defaults by either changing the `options` at the beginning of the script, or placing a `clipper.conf` inside the `script-opts` directory. Note that you don't need to specify all options, only the ones you wish to override.

## Building (development)
Building requires [`moonc`, the MoonScript compiler][moonscript], added to the PATH, and a GNU Make-compatible make. Run `make` on the root directory. The output files will be placed under the `build` directory.

[build]: https://raw.githubusercontent.com/Igetin/mpv-clipper/master/build/clipper.lua
[file locations]: https://mpv.io/manual/master/#files
[mpv]: https://mpv.io
[moonscript]: https://moonscript.org
