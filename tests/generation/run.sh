#!/usr/bin/env bash
# Run the generation benchmark and emit a summary suitable for CI.
set -euo pipefail

ORG_ALIAS=""
while getopts "o:" opt; do
  case "$opt" in
    o) ORG_ALIAS="$OPTARG" ;;
  esac
done

APEX_SNIPPET='System.debug(GenerationBenchmark.summarize());'

CMD=(sf apex run --apexcode "$APEX_SNIPPET")
if [[ -n "$ORG_ALIAS" ]]; then
  CMD+=(--target-org "$ORG_ALIAS")
fi

echo "Running GenerationBenchmark..." >&2
"${CMD[@]}"
