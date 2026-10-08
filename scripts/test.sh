#!/usr/bin/env bash
set -euo pipefail
mkdir -p .tools/test-classes
javac -d .tools/test-classes app/src/main/java/com/ironcrowns/game/Campaign.java tests/CampaignTest.java
java -cp .tools/test-classes CampaignTest
