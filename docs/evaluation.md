# Evaluation Harness

The evaluation harness validates the "recommend → synthesize → artifacts" pipeline using golden tests. It supports both deterministic (blueprint-by-name) and LLM-powered modes, with fuzzy and strict validation.

## Components

- **`EvalHarness.cls`** – Apex entry point for generating artifacts from named blueprints
- **`goldens/tests.json`** – Test definitions with blueprint names, goals, and validation checks
- **`scripts/eval.js`** – Node.js runner that executes tests in scratch orgs and validates outputs
- **`scripts/e2e-eval.sh`** – End-to-end script for local testing
- **`.github/workflows/eval.yml`** – CI workflow for deterministic tests
- **`.github/workflows/eval-llm.yml`** – Optional CI workflow for LLM-powered tests

## Deterministic Mode (CI Default)

Tests use curated blueprints by name, ensuring deterministic results without LLM calls.

### Running Locally

```bash
./scripts/e2e-eval.sh
```

This creates a scratch org, deploys code, registers blueprints, and runs all golden tests.

### Test Definitions

Edit `goldens/tests.json` to add more test cases:

```json
{
  "name": "blueprint_name",
  "goal": "Natural language goal description",
  "checks": {
    "force-app/main/default/classes": {
      "mustExist": ["DynamicAction_", "Test.cls"],
      "mustContain": {
        "*.cls": ["required", "substrings"],
        "*Test.cls": ["@IsTest", "assertions"]
      }
    }
  }
}
```

- **`mustExist`**: Array of substrings that must appear in filenames
- **`mustContain`**: Object mapping globs to required substrings per file

### Strict Snapshots

For exact diffs (useful when templates stabilize):

1. Run a test to generate artifacts: `./scripts/e2e-eval.sh`
2. Copy generated files to `goldens/<test_name>/expected/`
3. Re-run: The harness auto-detects expected files and switches to strict mode

Example:
```
goldens/opportunity_closed_won/expected/force-app/main/default/classes/DynamicAction_UpdateOpportunityStage.cls
```

## LLM Mode (Optional)

Exercises live LLM ranking/synthesis for smoke testing.

### Setup

1. **Add GitHub Secret**: `OPENAI_API_KEY` with your OpenAI API key
2. **Named Credential**: Configure `LLM_Provider` in the org with "Authorization: Bearer YOUR_KEY" header
3. **Run Workflow**: Trigger `eval-llm` manually or on schedule

### Differences from Deterministic

- Registers live LLM client via `scripts/register-llm.apex`
- Uses fuzzy checks only (LLM outputs vary)
- Scheduled weekly by default

## CI Integration

### Deterministic (Always On)

- **Trigger**: Every PR and push to main/master
- **Workflow**: `.github/workflows/eval.yml`
- **Secret**: `SFDX_AUTH_URL` for Dev Hub auth
- **Behavior**: Fails builds on any test failure

### LLM (Optional)

- **Trigger**: Manual or weekly schedule
- **Workflow**: `.github/workflows/eval-llm.yml`
- **Secrets**: `SFDX_AUTH_URL` and `OPENAI_API_KEY`
- **Behavior**: Fuzzy validation, doesn't block merges

## Troubleshooting

- **Blueprint Not Found**: Ensure the blueprint name in `tests.json` matches entries in `BlueprintLibrary`
- **FLS Errors**: Assign `DynamicAction_Permissions` permset
- **LLM Callouts Blocked**: Verify Named Credential configuration
- **Strict Diffs Failing**: Update expected files after intentional template changes
- **Scripts Not Executable**: Run `chmod +x scripts/*.sh`

## Legacy Benchmark

The original `GenerationBenchmark.cls` remains for comparing against golden blueprints. Run `GenerationBenchmark.summarize()` for detailed comparisons.
