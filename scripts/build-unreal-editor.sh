#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${UE_ROOT:?Set UE_ROOT to your legally installed Unreal Engine 5.6 directory}"
BUILD="$UE_ROOT/Engine/Build/BatchFiles/Linux/Build.sh"
if [[ ! -f "$BUILD" ]]; then
  echo "Unreal's Linux build tool was not found at $BUILD" >&2
  exit 1
fi
bash "$BUILD" IronCrownsEditor Linux Development -Project="$PWD/unreal/IronCrowns.uproject" -WaitMutex -NoHotReloadFromIDE
