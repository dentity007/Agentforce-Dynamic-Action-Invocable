# Runtime Orchestration

`DynamicActionOrchestrator` executes generated actions while enforcing guardrails and checkpoint confirmations. Understanding its flow is key when embedding the engine into a larger automation stack.

## Execution Stages

1. **Checkpoint Verification** – Caller must set `confirmed = true`. Otherwise the orchestrator returns with a warning and skips execution.
2. **Action Loop** – For each `PlanModels.ActionBlueprint`:
   - Look up payload inputs keyed by the blueprint name.
   - Resolve the generated Apex class (`InvocableActionFactory.resolve`).
   - Execute the action and aggregate logs/warnings/errors.
3. **Short-Circuit** – If any action fails (validation or DML), the orchestrator exits immediately so downstream actions do not run.
4. **Result Envelope** – Returns `PlanModels.OrchestratorResult` with `success`, `logs`, `warnings`, and `errors` populated.

## Payload Shape

```jsonc
{
  "UpdateOpportunityStage": {
    "Id": "006...",
    "StageName": "Closed Won"
  }
}
```

Each action’s key matches the blueprint `name`. It contains a map of payload fields as defined in the blueprint `inputs` collection.

## Registering Custom Implementations

`InvocableActionFactory.register(
    'CustomAction',
    'namespace.CustomActionImpl'
);`

Use this when you want to override LLM-generated code with a curated implementation.

Call `InvocableActionFactory.clear()` during tests to reset overrides.

## Telemetry Hooks

Wrap calls to `DynamicActionOrchestrator.run` with logging to capture:
- User/session context
- Goal and blueprint identifiers
- Guardrail violations encountered
- Execution time per action

This aids in debugging hallucinations or prompt regressions.

## Embedding in Flows or Bots

- Expose `DynamicActionPipeline.execute` and `DynamicActionOrchestrator.run` via invocable methods or Apex REST services.
- Use the plan checkpoint text to prompt end users for confirmation before executing write actions.
- Surface guardrail failures (e.g., FLS errors) as user-friendly messages in the UI.
