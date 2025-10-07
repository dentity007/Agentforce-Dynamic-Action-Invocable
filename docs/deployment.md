# Deployment Guide

Generated artifacts come back as in-memory maps. This guide outlines options for persisting them to your Salesforce project or deploying on the fly.

## 1. Persist to Source Tracking (Recommended)

1. Call `DynamicActionPipeline.execute(goal, schemaSlice, constraints)` or, when you already have a chosen blueprint, `DynamicActionPipeline.executeFromBlueprint(blueprint, schemaSlice, constraints)`.
2. Iterate over `result.artifacts.apex` and write each entry to `force-app/main/default/classes/` as `*.cls` / `*.cls-meta.xml` pairs.
3. Do the same for `result.artifacts.tests` (usually auto-generated).
4. Commit the files to source control and deploy using your normal CI/CD pipeline (`sfdx force:source:deploy`).

Sample script (Developer Console):
```apex
for (Map<String, String> artifact : result.artifacts.apex) {
    System.debug('Class ' + artifact.get('name'));
    System.debug(artifact.get('content'));
}
```

Generating directly from a recommended blueprint:
```apex
PlanModels.ActionBlueprint bp = r.recommendations.isEmpty() ? null : r.recommendations[0].blueprint;
DynamicActionPipeline.Result result = DynamicActionPipeline.executeFromBlueprint(bp, null, null);
```

## 2. Metadata API Deployment

Convert the generated content into a `Zip` structure and deploy via `MetadataService`. Useful for runtime deployment bots.

Steps:
1. Create `MetadataService.MetadataPort` instance.
2. Populate `MetadataService.ApexClass` objects with `name` and `content`.
3. Call `create` or `deploy` depending on strategy.

## 3. Tooling API

For rapid prototyping, insert directly into the Tooling API `ApexClass` and `ApexTestClass` objects. Beware of namespace and permission considerations.

## Environment Considerations

- **Tests**: Always run generated unit tests (`force:apex:test:run`) before promoting code.
- **Namespaces**: Update naming conventions if deploying into a namespaced org.
- **Dependencies**: Ensure guardrail helpers (`GuardrailEvaluator`, `RuntimeTypeAdapters`) and factories are deployed alongside generated actions.
- **Rollback Strategy**: Store the original blueprint JSON so you can regenerate code if deployments fail.

## Automation Tips

- Build a CI job that:
  1. Pulls latest schema snapshot.
  2. Runs the pipeline for approved goals.
  3. Writes artifacts to the repo and opens a pull request.
- Use branch policies to require Apex tests before merging auto-generated code.

## Automation Script

Use `scripts/deploy_artifacts.py` to persist and deploy artifacts in one step.

```bash
# Write pipeline.artifacts to a JSON file first
echo $PIPELINE_JSON > /tmp/pipeline-artifacts.json

# Deploy and run local tests
python3 scripts/deploy_artifacts.py /tmp/pipeline-artifacts.json --run-tests --wait 30
```

The script writes Apex/test classes to a temporary workspace, runs `sfdx force:source:deploy`, and (optionally) executes `sfdx force:apex:test:run`. The command exits non-zero if deployment or tests fail, making it CI-friendly.
