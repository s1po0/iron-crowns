#!/usr/bin/env bash
set -euo pipefail
VERSION=4.4.1
mkdir -p /tmp/godot-tools "$HOME/.local/share/godot/export_templates/$VERSION.stable"
curl -fsSL --retry 3 -o /tmp/godot-tools/editor.zip "https://github.com/godotengine/godot-builds/releases/download/$VERSION-stable/Godot_v$VERSION-stable_linux.x86_64.zip"
unzip -q -o /tmp/godot-tools/editor.zip -d /tmp/godot-tools
sudo install "/tmp/godot-tools/Godot_v$VERSION-stable_linux.x86_64" /usr/local/bin/godot
curl -fsSL --retry 3 -o /tmp/godot-tools/templates.tpz "https://github.com/godotengine/godot-builds/releases/download/$VERSION-stable/Godot_v$VERSION-stable_export_templates.tpz"
unzip -q -o /tmp/godot-tools/templates.tpz 'templates/android_debug.apk' 'templates/version.txt' -d /tmp/godot-tools
cp /tmp/godot-tools/templates/android_debug.apk "$HOME/.local/share/godot/export_templates/$VERSION.stable/"
mkdir -p "$HOME/.config/godot" "$HOME/.android"
if [ ! -f "$HOME/.android/debug.keystore" ]; then
  keytool -genkeypair -keystore "$HOME/.android/debug.keystore" -storepass android -alias androiddebugkey -keypass android -dname "CN=Android Debug,O=Android,C=US" -keyalg RSA -keysize 2048 -validity 10000
fi
cat > "$HOME/.config/godot/editor_settings-4.tres" <<SETTINGS
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "$ANDROID_HOME"
export/android/java_sdk_path = "$JAVA_HOME"
export/android/debug_keystore = "$HOME/.android/debug.keystore"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
SETTINGS
sudo apt-get update -qq
sudo apt-get install -y -qq xvfb libgl1-mesa-dri mesa-utils
