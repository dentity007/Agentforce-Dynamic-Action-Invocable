# Code Synthesis Reference

`CodeTemplateEngine` transforms `ActionBlueprint` objects into Apex classes and unit tests. This document explains the major pieces so you can extend or swap templates.

## Rendering Pipeline

1. Collect blueprint field inputs (`collectFieldInputs`).
2. Emit dictionaries for labels, data types, payload bindings, and required fields.
3. Inject guardrail calls (`GuardrailEvaluator.apply`).
4. Build DML block based on `operation` (`INSERT`, `UPDATE`, `UPSERT`).
5. Emit paired unit test skeletons to ensure validation paths execute.

All generated classes implement `InvocableActionFactory.IAction` so the runtime can execute them without custom wiring.

## Customizing Templates

- **Additional DML Operations**: Update `buildDmlBlock` to support `DELETE`, bulk operations, or Flow invocation.
- **Telemetry Hooks**: Add logging statements or event publishing post-success (`res.logs.add(...)`).
- **Flow Generation**: Introduce new renderers returning Flow metadata XML and push those into `CodeGenService`.
- **Test Coverage**: Expand the default test templates to cover positive DML paths or guardrail failure cases.

## Handling Complex Inputs

Use `RuntimeTypeAdapters` to coerce payload values:
- Out-of-the-box converters: `Id`, `Decimal`, `Integer`, `Boolean`, `Date`, `Datetime`.
- Add new conversion helpers for complex types (e.g., `List<Id>`) and call them inside `RuntimeTypeAdapters.convert`.

## Example: Extending with Flow Artifact

```apex
public class FlowTemplateEngine {
    public static Map<String, String> render(PlanModels.ActionBlueprint bp) {
        // Build Flow XML using bp.inputs / guardrails
        return new Map<String, String>{
            'name' => 'Flow_' + bp.name,
            'content' => '<Flow ...>'
        };
    }
}

// Update CodeGenService
FlowTemplateEngine.render(blueprint);
artifacts.metadata.put('flowsGenerated', true);
```

## Guardrail Injection

Every generated class includes:
```apex
GuardrailEvaluator.apply('Opportunity', blueprintGuardrails(), normalized, errors);
```
Customize `buildGuardrailFactory` if you need richer metadata, such as severity levels or dynamic guardrail lookups.

## Naming Conventions

- Class names: `DynamicAction_<Sanitized Blueprint Name>`
- Test names: `<ClassName>_Test`
- Registry resolution: `InvocableActionFactory` maps blueprint names to class names automatically.

Keep naming deterministic to make metadata deployment predictable across environments.
