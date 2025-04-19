# FnMacTweak

A lightweight iOS Theos tweak for Fortnite iOS on Mac. Implements several QoL features to improve the keyboard & mouse experience.

## Features
Currently implements the following:
- Implements pointer lock toggling using the `Left Option` key (unlocked by default)
- Unlocks the 120 FPS setting (requires a 120Hz display, blame VSync)
- Enables graphics preset selection (Low, Medium, High, Epic; 120 FPS limits to Medium)
- Adds a custom options menu (keybind `P`) for adjusting mouse sensitivity
- Fixes mouse interactions with the mobile UI

## Releases
The latest builds can be found in the [Releases](https://github.com/rt-someone/FnMacTweak/releases/) section, as well as in the [FnMacAssistant Discord](https://discord.gg/nfEBGJBfHD).

## Building
You can build the tweak yourself by running `make package FINALPACKAGE=1`, make sure you have Theos installed.

## Credits
Made by: @rt2746 (me)

- Uses Facebook's [Fishhook library](https://github.com/facebook/fishhook) as an alternative to %hookf hooking in a jailed environment
- Some code taken from PlayCover's [PlayTools repository](https://github.com/PlayCover/PlayTools) for device model spoofing
