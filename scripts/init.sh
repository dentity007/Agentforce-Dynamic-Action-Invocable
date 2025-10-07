#!/usr/bin/env bash
set -euo pipefail

ORG_ALIAS="${1:-dynamicAction}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$PROJECT_ROOT/.tmp"
mkdir -p "$TMP_DIR"

# 0) Refresh curated blueprint library
node "$PROJECT_ROOT/scripts/build-blueprint-library.js"

# 1) Create scratch org & push source
echo "Creating scratch org $ORG_ALIAS" >&2
sf org create scratch -f "$PROJECT_ROOT/config/project-scratch-def.json" -a "$ORG_ALIAS" -s
sf project deploy start -o "$ORG_ALIAS"

# 2) Register stub/no-op LLM client (safe to ignore failures)
sf apex run -o "$ORG_ALIAS" -f "$PROJECT_ROOT/scripts/register-llm.apex" || true

# 3) Generate action artifacts (writes combined JSON)
GENERATE_JSON="$TMP_DIR/generate.json"
sf apex run -o "$ORG_ALIAS" -f "$PROJECT_ROOT/scripts/generate.apex" --json > "$GENERATE_JSON"

# 4) Convert & deploy generated artifacts
node "$PROJECT_ROOT/scripts/deploy-artifacts.js" "$GENERATE_JSON" "$ORG_ALIAS"

# 5) Run local tests
echo "Running Apex tests" >&2
sf apex run test -o "$ORG_ALIAS" -l RunLocalTests -r human

echo "Initialization complete."
