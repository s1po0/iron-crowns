#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .tools/unreal-tests
${CXX:-g++} -std=c++17 -Wall -Wextra -Wpedantic -Werror -O1 -g \
  -fsanitize=address,undefined -fno-omit-frame-pointer \
  -I unreal/Source/IronCrowns/Public unreal/Tests/rules_test.cpp -o .tools/unreal-tests/rules-test
.tools/unreal-tests/rules-test
