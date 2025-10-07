# Blueprint Contract

Generated actions follow a consistent `PlanModels.ActionBlueprint` contract. The JSON schema is designed so an LLM can emit blueprints that deserialize directly into Apex.

```jsonc
{
  "name": "UpdateOpportunityStage",
  "label": "Update Opportunity Stage",
  "category": "DOMAIN",
  "targetSObject": "Opportunity",
  "operation": "UPDATE",
  "summary": "Updated Opportunity stage based on agent directive.",
  "checkpoint": "I will update the Opportunity stage. Proceed?",
  "keyFields": ["Id"],
  "inputs": [
    {
      "apiName": "Id",
      "fieldApiName": "Id",
      "label": "Opportunity Id",
      "dataType": "Id",
      "required": true,
      "usage": "FIELD"
    },
    {
      "apiName": "StageName",
      "fieldApiName": "StageName",
      "label": "Stage",
      "dataType": "String",
      "required": true,
      "usage": "FIELD"
    }
  ],
  "guardrails": [
    {
      "type": "FLS_EDIT",
      "params": {
        "fields": ["Id", "StageName"]
      },
      "message": "User must have edit access to Opportunity fields."
    }
  ]
}
```

## Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | ✅ | Action identifier. Used to resolve generated Apex class names (`DynamicAction_<Name>`). |
| `label` | ✅ | Human-readable description shown in UI/logs. |
| `category` | ✅ | Free-form grouping (e.g., `DOMAIN`, `CRUD`, `NOTIFICATION`). |
| `targetSObject` | ✅ | API name of the SObject mutated by the action. |
| `operation` | ✅ | One of `INSERT`, `CREATE`, `UPDATE`, `UPSERT`, or `CALL`. Controls the DML block emitted. |
| `summary` | ➖ | Success log text emitted after execution. |
| `checkpoint` | ➖ | Optional confirmation string surfaced before execution. |
| `keyFields` | ➖ | Fields used for `UPSERT` key resolution (defaults to `Id`). |
| `inputs` | ✅ | Array of field bindings. See below. |
| `guardrails` | ➖ | Array of guardrail descriptors consumed by `GuardrailEvaluator`. |

### Inputs

| Field | Required | Description |
|-------|----------|-------------|
| `apiName` | ✅ | Key expected in the payload map provided to the generated action. |
| `fieldApiName` | ✅ | Field to set on the target SObject. Can differ from `apiName` when renaming inputs. |
| `label` | ✅ | Display label for error messages. |
| `dataType` | ✅ | String data type hint (`String`, `Decimal`, `Id`, `Date`, `Boolean`, etc.). |
| `required` | ✅ | Whether the payload must provide a value. |
| `usage` | ➖ | One of `FIELD`, `PARAMETER`, or `CONTEXT`. Current templates only process `FIELD` entries. |
| `description` | ➖ | Extended help text; surfaced in documentation or UI integrations. |

### Guardrails

Guardrails contain a `type`, optional `params`, and optional `message`. For the current engine, supported types are documented in `docs/guardrails.md`.

Guardrails are evaluated inside generated Apex at runtime. If a guardrail fails, the action short-circuits and returns validation errors before DML occurs.

## Sample Response Envelope

LLM responses can either be an array of blueprint objects or an object with an `actions` array. Both shapes are accepted:

```jsonc
{
  "actions": [
    { "name": "UpdateOpportunityStage", ... },
    { "name": "SendNotification", ... }
  ]
}
```

When no JSON is returned (or parsing fails), the system uses the heuristic factory as a fallback.

## Schema Snapshot Shape

`SchemaSnapshot.buildSnapshot` returns the following structure (or equivalent JSON if provided externally):

```jsonc
{
  "objects": {
    "Opportunity": {
      "apiName": "Opportunity",
      "fields": {
        "StageName": {
          "apiName": "StageName",
          "type": "Picklist",
          "nillable": false,
          "createable": true,
          "updateable": true,
          "picklistValues": ["Prospecting", "Closed Won"]
        }
      },
      "childRelationships": ["Task.WhatId", "Event.WhatId"]
    }
  }
}
```

Pipeline helpers will also accept a JSON snapshot in this shape when a caller provides external metadata instead of calling `SchemaSnapshot.buildSnapshot`.
