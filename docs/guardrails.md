# Guardrail Catalogue

`GuardrailEvaluator` applies safety rules emitted by the blueprint and injected into generated Apex. Guardrails run before any DML to prevent unsafe actions while still allowing LLM flexibility.

## Supported Guardrail Types

| Type | Parameters | Behavior |
|------|------------|----------|
| `FLS_VIEW` / `FLS_ACCESS` | `fields: List<String>` | Verifies that the running user has `isAccessible()` permissions for each field. |
| `FLS_EDIT` / `FLS_UPDATE` / `FLS_WRITE` | `fields: List<String>` | Requires `isUpdateable()` access. Missing fields raise an error. |
| `NUMERIC_POSITIVE` | `field: String` | Ensures the provided numeric value is greater than zero. |
| `NUMERIC_RANGE` | `field: String`, `min: Decimal?`, `max: Decimal?` | Validates that the numeric field falls within the inclusive range. |
| `ENUM_ALLOWED` | `field: String`, `values: List<String>` | Ensures the value matches one of the allowed strings. |
| `PII_REDACT` | `fields: List<String>` | Requires specified fields to be cleared/redacted before execution. |
| `SHARING_REQUIRED` | *(optional)* | Confirms that the user can create/update the target SObject (basic sharing check). |

*Messages*: A custom `message` string overrides the default error. Guardrails append errors to the orchestrator result and stop execution.

## Extending Guardrails

1. Add a new `type` handler inside `GuardrailEvaluator.apply`.
2. Update the blueprint prompt to teach the LLM about the new guardrail.
3. Provide tests that cover both success and failure cases.

Example extension (pseudo-code):

```apex
if (type == 'PRIVACY_BLOCKLIST') {
    enforcePrivacyBlocklist(guardrail, normalized, errors);
    continue;
}
```

## Blueprint Guidance

When crafting prompt examples, describe inputs and guardrails clearly:

```text
- Enforce FLS edit access for: StageName, CloseDate
- Quantity must be greater than 0 (NUMERIC_POSITIVE)
```

The more explicit the instructions, the more reliably the LLM will emit valid guardrail blocks.

## Examples

```jsonc
{
  "type": "FLS_EDIT",
  "params": { "fields": ["StageName", "CloseDate"] },
  "message": "Ensure the user can edit Opportunity fields."
}
```

```jsonc
{
  "type": "PII_REDACT",
  "params": { "fields": ["Description"] },
  "message": "Strip PII before saving."
}
```

```jsonc
{
  "type": "NUMERIC_RANGE",
  "params": { "field": "Discount__c", "min": 0, "max": 0.3 },
  "message": "Discount must be between 0% and 30%."
}
```

## Configuration Tips

- **PII_REDACT** – Pair with a preprocessing hook that removes sensitive values before executing generated code.
- **SHARING_REQUIRED** – Use when actions must respect org sharing; combine with `SchemaSnapshotService` output to indicate private objects.
- **ENUM_ALLOWED** – Provide a curated list of acceptable options so LLM output remains within picklist rules.

## Testing Guardrails

Generated classes invoke `GuardrailEvaluator.apply(...)`. Unit tests should assert both success and failure paths. See `GuardrailEvaluator_Test` for examples covering numeric, enum, and PII scenarios.
