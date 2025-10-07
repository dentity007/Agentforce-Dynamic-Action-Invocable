# Evaluation Harness

Use the evaluation harness to sanity check dynamic action generation across golden scenarios. The harness compares current heuristic/LLM output against frozen blueprints and expected code snippets.

## Running the Benchmark

1. Deploy the project to a scratch org or sandbox.
2. Execute the following anonymous Apex:
   ```apex
   System.debug(GenerationBenchmark.summarize());
   ```
   The summary lists each scenario with pass/fail flags for blueprint parity, generated class checks, and generated test checks.

3. (Optional) Inspect `GenerationBenchmark.run()` for structured results and build automated reporting.

## Golden Artifacts

Reference blueprints and expected fragments are stored under `tests/generation/golden/` for easy review and updates.

| File | Description |
|------|-------------|
| `opportunity_stage_blueprint.json` | Golden blueprint for the primary sales use case. |
| `opportunity_stage_expected.cls` | Representative generated Apex snippet for the opportunity scenario. |
| `opportunity_stage_expected_test.cls` | Paired unit test expectations. |
| `inventory_reservation_blueprint.json` | Golden blueprint for inventory reservation. |
| `inventory_reservation_expected.cls` | Representative generated Apex snippet for inventory scenario. |
| `inventory_reservation_expected_test.cls` | Paired unit test expectations. |

## Automating Regressions

- Add a CI step that calls `GenerationBenchmark.summarize()` and fails the build when any case reports `false`.
- Extend the harness with additional cases by updating `GenerationBenchmark.cls` and adding matching documents in `tests/generation/golden/`.
- Capture LLM vs. heuristic comparisons by overriding `LLMClientGateway` during the benchmark run.

### CLI Helper

Execute `tests/generation/run.sh` to run the benchmark via the Salesforce CLI and print the summary output.
