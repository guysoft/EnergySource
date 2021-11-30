# Energy Source

Work in progress, game jam entry for Go Godot 2.

This is a rhythm game that works in vr using OpenXR, and supports WebXR.
It has a cool mechanic where you can slow down the music inside a level.


# Known issues

## Linux
For linux builds you need to copy to the game folder libopenxr_loader.so.1 which comes with your distirbution. 

## Developer setup
1. Import the godot project and install the following addons:
    * [godot-openxr](https://godotengine.org/asset-library/asset/986)
    * [Godot XR Tools](https://godotengine.org/asset-library/asset/214)
2. Download a test song
```
wget https://as.cdn.beatsaver.com/9d9092a6d2a70bb0a2b3f1b71fb97c6d6db046ab.zip
unzip 9d9092a6d2a70bb0a2b3f1b71fb97c6d6db046ab.zip -d src/Levels/test
cp src/Levels/test/Expert.dat src/Levels/test/ExpertPlusStandard.dat
mv src/Levels/test/Info.dat src/Levels/test/info.dat
mv src/Levels/test/song.egg src/Levels/test/song.ogg
````
## Developer settings in editor
In order to run in non-vr mode for debugging set ``ENABLE_VR`` to ``false`` in ``scripts/GameVariables.gd``


## Credits
Developers:
* Rainer Weston
* Guy Sheffer

Current example Music taken from, by jennissary (joey): https://beatsaver.com/maps/19614
