# Schema → Recommendation → Implementation

`SchemaIntentPipeline` exposes a turnkey entry point that bundles the three core steps:

1. **Schema Snapshot** – Uses `SchemaSnapshot` (fallback to `SchemaSnapshotService` options) to gather object/field metadata (limited by options).
2. **Recommendation Ranking** – Calls `BlueprintRecommendationService` to blend curated entries (`BlueprintLibraryService`) with LLM/heuristic output and score the combined list.
3. **Implementation Generation** – Reuses `DynamicActionPlanner` and `CodeGenService` to produce a runnable plan and code artifacts.

## Usage

```apex
SchemaIntentPipeline.Options options = new SchemaIntentPipeline.Options();
options.schemaOptions.maxObjects = 5;
options.schemaOptions.includeRelationships = true;

PlanModels.PipelineResult pipeline = SchemaIntentPipeline.run(
    'Recommend follow-up actions for high value opportunities',
    options
);
```

### Result Object

| Field | Description |
|-------|-------------|
| `schema` | Map containing `generatedAt`, `objectCount`, and an `objects` array summarising metadata. |
| `recommendations` | Ranked list of `PlanModels.Recommendation` items: name, score, rationale, and blueprint. |
| `plan` | `PlanModels.Plan` ready for `DynamicActionOrchestrator.run`. |
| `artifacts` | `PlanModels.CodeArtifacts` with Apex classes, tests, and metadata annotations. |

## Options

- `schemaOptions.maxObjects` – Limit the number of objects included in the snapshot.
- `schemaOptions.maxFieldsPerObject` – Limit field detail per object to keep prompts concise.
- `schemaOptions.includeRelationships` – When `true`, child relationships are surfaced for deeper graph prompts.
- `includeObjects` – Explicit list of sObjects to snapshot when a schema is not provided.
- `blueprintName` – Provide a curated blueprint key (see `BlueprintLibrary.listEntries`) to bypass LLM recommendations.
- `constraints` – Pass model hints or guardrail directives directly to `BlueprintSynthesisService`.

## Next Steps

- Persist the returned blueprints for auditing or reuse.
- Pipe `pipeline.plan` into `DynamicActionOrchestrator.run` once a user confirms the checkpoint.
- Extend `BlueprintRecommendationService` to blend heuristic scores with telemetry (conversion rates, success metrics) for smarter ranking.
