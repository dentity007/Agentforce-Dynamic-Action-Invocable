# Agentforce Dynamic Action Architecture

## Vision
Agentforce Dynamic Action turns org metadata plus a natural language business goal into runnable Salesforce actions. It advances the earlier **Data Aware Agent** work by delivering an end-to-end LLM blueprint → code generation → runtime orchestration pipeline.

## Layered Architecture

| Layer | Apex Components | Responsibility |
|-------|-----------------|----------------|
| **Schema Snapshot** | `SchemaSnapshot`, `SchemaSnapshotService` | Produce a trimmed org metadata slice for the blueprinting prompt. |
| **Intent & Prompting** | `BlueprintSynthesisService`, `PromptLibrary`, `LLMClientGateway` | Build prompts, call (or stub) an LLM, parse JSON into `ActionBlueprint` objects. |
| **Blueprint Heuristics** | `HeuristicBlueprintFactory` | Provide offline/default blueprints when no LLM is available. |
| **Blueprint Ranking** | `BlueprintRecommendationService`, `BlueprintLibraryService` | Blend curated exemplars with LLM output and score the recommended actions. |
| **Synthesis** | `CodeTemplateEngine`, `RuntimeTypeAdapters`, `GuardrailEvaluator`, `CodeGenService` | Render Apex/test source code from blueprints, enforce guardrails, and normalize input types. |
| **Planning** | `DynamicActionPlanner`, `PlanModels` | Assemble a runtime plan (actions, dependencies, checkpoint messaging). |
| **Runtime** | `DynamicActionPipeline`, `DynamicActionOrchestrator`, `InvocableActionFactory` | Drive the full pipeline, deploy artifacts, and execute generated actions. |
| **Turnkey Pipeline** | `SchemaIntentPipeline` | Orchestrate schema snapshot → recommendations → plan + artifacts. |
| **Tests** | `CodeTemplateEngine_Test`, `DynamicActionPipeline_Test`, `SchemaIntentPipeline_Test`, `GenerationBenchmark_Test` | Validate template output, turnkey pipeline, and benchmark harness. |

## End-to-End Flow

1. **Schema Snapshot (external)** – Pull org metadata or provide a curated `schemaSlice` map. (Future work will port `SchemaGraphStore` services.)
2. **Intent Intake** – Accept a user goal and constraints (e.g., preferred model, guardrails) via controller or invocable.
3. **LLM Blueprinting** – `BlueprintSynthesisService` composes a prompt using `PromptLibrary` and calls `LLMClientGateway`. The stub client falls back to heuristics for offline use.
4. **Dynamic Action Synthesis** – `CodeTemplateEngine` transforms each blueprint into Apex classes and unit tests. `GuardrailEvaluator` hooks are injected to enforce FLS, sharing, numeric, and enum policies.
5. **Deployment & Registration** – `CodeGenService` returns artifacts that can be persisted to metadata. `InvocableActionFactory` resolves generated classes at runtime using a naming convention or explicit registry entries.
6. **Execution Loop** – `DynamicActionOrchestrator` executes actions sequentially, honoring checkpoints and guardrail outcomes.
7. **Feedback (future)** – Execution telemetry will later feed into the planner to improve prompt grounding and template selection.

## Data Contracts

- `PlanModels.ActionBlueprint` – Canonical description of an action (inputs, guardrails, checkpoint text, summary, target sObject, operation).
- `PlanModels.Plan` – The runtime plan containing the goal, ordered actions, dependencies, and checkpoint message.
- `PlanModels.CodeArtifacts` – Generated Apex/test sources and metadata describing the synthesis run.
- `PlanModels.OrchestratorResult` – Logs, warnings, and success/errors from executing an action.

See `docs/blueprint-contract.md` for the JSON structure consumed and produced by the blueprinting layer.

## Extensibility Hooks

- **LLM Provider** – Implement `LLMClientGateway.LLMClient` to plug in Vertex AI, OpenAI, or Einstein GPT.
- **Guardrails** – Extend `GuardrailEvaluator` with privacy filters, policy lookups, or anomaly detection.
- **Template Variants** – Augment `CodeTemplateEngine` with Flow metadata or composite SOQL emitters.
- **Deployment Automation** – Add Metadata API utilities or Git automation to persist generated assets automatically.

## Implementation Roadmap

1. Port schema discovery services into this repo (currently referenced from the previous project).
2. Introduce deployment helpers (metadata writer, scratch-org automation).
3. Expand the template library to support Flow, invocable actions, and Lightning web components.
4. Wire telemetry capture and tuning feedback loops (prompt revision, outcome scoring).
5. Harden testing with end-to-end orchestrator scenarios and mocked LLM responses.

## Turnkey Pipeline

Call `SchemaIntentPipeline.run(goal, options)` to execute the complete flow in one method. The result bundles the schema snapshot, ranked recommendations, plan, and generated code artifacts so UI or automation layers can drive confirmation and execution.
