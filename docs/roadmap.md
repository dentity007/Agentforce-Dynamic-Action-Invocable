# Roadmap

Planned enhancements for Agentforce Dynamic Action.

## Near Term

- **Schema Services** – Port metadata discovery (`SchemaGraphStore`, `MetadataDiscovery`) from the legacy repo and expose them via `schema/` package.
- **Deployment Utilities** – Provide Apex util classes to persist generated artifacts automatically (Metadata API wrapper).
- **Expanded Guardrails** – Add privacy classification, rate limiting, and record-level sharing policies.
- **✅ Blueprint Library** – Seed a catalog of curated blueprints for common Sales/Service scenarios. *(Completed: 24+ blueprints covering Sales/Service/SaaS/CPQ/Marketing domains)*

## Mid Term

- **Flow & Invocable Generation** – Extend template engine to produce Flow XML and invocable metadata alongside Apex.
- **✅ LLM Evaluation Harness** – Capture prompt/response telemetry, run automated validation, and score responses for consistency. *(Completed: Deterministic golden test harness with CI integration, optional LLM mode)*
- **UI Integration** – Build Lightning components that surface plans, generated code diffs, and execution logs.

## Long Term

- **Self-Tuning Loop** – Feed execution telemetry back into prompt selection and template choices.
- **Policy Studio** – Allow admins to author guardrail policies declaratively, with enforcement handled by the code generator.
- **Multi-Org Blueprint Sharing** – Package blueprints and templates for reuse across orgs with version management.

Contributions and suggestions welcome—open an issue or PR referencing the roadmap item you aim to tackle.
