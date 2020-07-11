# HACK

This is a quick & dirty hack of [ekisu’s mpv-webm][mpv-webm] that adds an option for selecting an encoding profile. All profiles starting with `enc-` are considered encoding profiles. CRF can be changed independently and overrides any CRF setting in profile. All other options have been removed.

# mpv-clipper
Simple clip maker for [mpv][mpv], with no external dependencies.

![sample](/img/sample.png)

## Installation
Place [this][build] in your mpv `scripts` folder. By default, the script is activated by the W (shift+w) key.

## Usage
Follow the on-screen instructions.

## Building (development)
Building requires [`moonc`, the MoonScript compiler][moonscript], added to the PATH, and a GNU Make-compatible make. Run `make` on the root directory. The output files will be placed under the `build` directory.

[build]: https://raw.githubusercontent.com/Igetin/mpv-webm/master/build/webm.lua
[mpv]: https://mpv.io
[mpv-webm]: https://github.com/ekisu/mpv-webm
[moonscript]: https://moonscript.org
