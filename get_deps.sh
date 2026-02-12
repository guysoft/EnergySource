#!/bin/bash
set -e

# Create addons directory
mkdir -p src/addons

echo "Downloading Godot XR Tools..."
curl -L -o godot-xr-tools.zip https://github.com/GodotVR/godot-xr-tools/archive/refs/heads/master.zip
unzip -q -o godot-xr-tools.zip
# Remove existing directory if it exists to avoid conflicts
rm -rf src/addons/godot-xr-tools
# Move only the addon folder to the correct location
mv godot-xr-tools-master/addons/godot-xr-tools src/addons/
rm -rf godot-xr-tools-master godot-xr-tools.zip
echo "Installed Godot XR Tools."

echo "Downloading Godot OpenXR Vendors..."
curl -L -o godot_openxr_vendors.zip https://github.com/GodotVR/godot_openxr_vendors/releases/download/3.0.0/godot_openxr_vendors_v3.0.0.zip
unzip -q -o godot_openxr_vendors.zip -d temp_vendors
rm -rf src/addons/godotopenxrvendors
mv temp_vendors/addons/godotopenxrvendors src/addons/
rm -rf temp_vendors godot_openxr_vendors.zip
echo "Installed Godot OpenXR Vendors."

echo "Dependencies installed successfully!"

