# Energy Source

Work in progress, game jam entry for Go Godot 2.

This is a rhythm game that works in vr using OpenXR, and supports WebXR.
It has a cool mechanic where you can slow down the music inside a level.


# Known issues

## Linux
For linux builds you need to copy to the game folder libopenxr_loader.so.1 which comes with your distirbution. 

## Developer setup
Import the godot project and install the following addons:
* godot-openxr

## Developer settings
In order to run in non-vr mode for debugging set ``ENABLE_VR`` to ``false`` in ``scripts/GameVariables.gd``


## Credits
Developers:
* Rainer Weston
* Guy Sheffer

Current example Music taken from, by jennissary (joey): https://beatsaver.com/maps/19614
