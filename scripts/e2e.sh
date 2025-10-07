#!/usr/bin/env bash
set -euo pipefail
ORG_ALIAS="${1:-dynamicAction}"

# 0) Create scratch org & deploy core
sf org create scratch -f config/project-scratch-def.json -a "$ORG_ALIAS" -d

# Build curated blueprint library prior to deploy so static resource is current
node scripts/build-blueprint-library.js

sf project deploy start -o "$ORG_ALIAS"

# 1) Assign permissions to current user
sf org assign permset -o "$ORG_ALIAS" -n DynamicAction_Permissions || true

# 2) Recommend (capture output)
mkdir -p .tmp
sf apex run -o "$ORG_ALIAS" -f scripts/recommend.apex --json > .tmp/recommend.json

# 3) Generate from top recommendation (capture output)
sf apex run -o "$ORG_ALIAS" -f scripts/generate_from_top.apex --json > .tmp/generate.json

# 4) Convert & deploy generated artifacts
node scripts/deploy-artifacts.js .tmp/generate.json "$ORG_ALIAS"

# 5) Run tests
sf apex run test -o "$ORG_ALIAS" -l RunLocalTests -r human
