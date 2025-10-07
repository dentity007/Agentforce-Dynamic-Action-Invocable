# Memory Offloading (Optional, Off by Default)

Large schema snapshots, LLM telemetry, or generated artifacts can exceed comfortable heap sizes. This optional layer lets you offload large JSON payloads to a backing store and return lightweight references.

## Options

Use `OffloadModels.Options` to control behavior per run:

```apex
OffloadModels.Options opts = new OffloadModels.Options();
opts.offloadArtifacts = true;      // default false
opts.sizeThresholdKB = 64;         // offload if JSON > 64KB
opts.artifactsStore = 'ContentVersion'; // 'PlatformCache' or 'ContentVersion'
```

Integration points:
- `SchemaIntentPipeline.Options.offloadOptions` – Offload `schema` and/or `artifacts` in the combined result.
- `DynamicActionPipeline.executeWithOptions(...)` / `executeFromBlueprintWithOptions(...)` – Offload artifacts in generation-only runs.

When offloading occurs, the result includes a `Ref`:

```jsonc
{
  "artifacts": { "metadata": { "offloaded": true, "refStore": "ContentVersion", "refKey": "068..." } },
  "artifactsRef": { "store": "ContentVersion", "key": "068...", "sizeBytes": 123456 }
}
```

If the store is not available or an error occurs, results fall back to inline JSON.

## Stores

- `PlatformCache` – Ephemeral, fast. Good for short‑lived data. Requires a partition (defaults to `Agentforce`).
- `ContentVersion` – Durable (Files). Good for large artifacts and telemetry. Consider purge policies.

## Purge Strategy

Add a scheduled/batch job to delete old `ContentVersion` rows that match the offload prefix (see `ContentVersionOffloadProvider` for the `MOff-` prefix).

## Security

- Treat prompts/responses as potentially sensitive. Redact PII before offloading if needed.
- Files inherit org security. Platform Cache is ephemeral and stays within the org.

