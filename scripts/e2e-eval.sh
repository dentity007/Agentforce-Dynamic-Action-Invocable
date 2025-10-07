#!/usr/bin/env bash
set -euo pipefail

ORG_ALIAS="${1:-dynamicAction}"

# 0) Create scratch org & deploy core
sf org create scratch -f config/project-scratch-def.json -a "$ORG_ALIAS" -s
sf project deploy start -o "$ORG_ALIAS"

# 1) Assign minimal permissions if you have a permset
sf org assign permset -o "$ORG_ALIAS" -n DynamicAction_Permissions || true

# 2) Run evaluation tests (deterministic, no live LLM required)
export SF_ORG_ALIAS="$ORG_ALIAS"
node scripts/eval.js