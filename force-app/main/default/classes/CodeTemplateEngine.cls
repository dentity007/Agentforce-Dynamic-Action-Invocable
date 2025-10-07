public with sharing class CodeTemplateEngine {
    public class RenderedArtifact {
        public String className;
        public String testName;
        public String body;
        public String testBody;
    }

    public static RenderedArtifact renderAction(PlanModels.ActionBlueprint blueprint) {
        if (blueprint == null) {
            throw new AuraHandledException('Blueprint cannot be null');
        }
        RenderedArtifact artifact = new RenderedArtifact();
        String baseName = sanitizeName((blueprint.name != null) ? blueprint.name : 'GeneratedAction');
        artifact.className = 'DynamicAction_' + baseName;
        artifact.testName = artifact.className + '_Test';

        Map<String, PlanModels.ActionInput> fieldInputs = collectFieldInputs(blueprint);
        StringBuilder cls = new StringBuilder();
        appendLine(cls, 'public with sharing class ' + artifact.className + ' implements InvocableActionFactory.IAction {');
        appendLine(cls, '    public PlanModels.OrchestratorResult execute(Map<String, Object> payload) {');
        appendLine(cls, '        PlanModels.OrchestratorResult res = PlanModels.newResult();');
        appendLine(cls, '        Map<String, Object> input = (payload == null) ? new Map<String, Object>() : payload.clone();');
        appendLine(cls, '        List<String> errors = new List<String>();');
        appendLine(cls, '        Map<String, Object> normalized = new Map<String, Object>();');

        buildFieldDictionaries(cls, fieldInputs);
        buildRequiredChecks(cls);
        buildNormalizationBlock(cls);
        buildGuardrailBlock(cls, blueprint);
        buildErrorShortCircuit(cls);
        buildDmlBlock(cls, blueprint);
        appendLine(cls, '        return res;');
        appendLine(cls, '    }');
        appendLine(cls, '');
        appendLine(cls, buildGuardrailFactory(blueprint));
        appendLine(cls, '}');

        artifact.body = cls.toString();
        artifact.testBody = renderTestClass(artifact.className, artifact.testName);
        return artifact;
    }

    private static Map<String, PlanModels.ActionInput> collectFieldInputs(PlanModels.ActionBlueprint blueprint) {
        Map<String, PlanModels.ActionInput> fieldInputs = new Map<String, PlanModels.ActionInput>();
        if (blueprint.inputs == null) {
            return fieldInputs;
        }
        for (PlanModels.ActionInput input : blueprint.inputs) {
            if (input == null) {
                continue;
            }
            if (input.usage != null && input.usage != 'FIELD') {
                continue;
            }
            String fieldApi = String.isBlank(input.fieldApiName) ? input.apiName : input.fieldApiName;
            if (String.isBlank(fieldApi)) {
                continue;
            }
            fieldInputs.put(fieldApi, input);
        }
        return fieldInputs;
    }

    private static void buildFieldDictionaries(StringBuilder cls, Map<String, PlanModels.ActionInput> fieldInputs) {
        appendLine(cls, '        Map<String, String> fieldLabels = new Map<String, String>();');
        for (String fieldApi : fieldInputs.keySet()) {
            PlanModels.ActionInput ai = fieldInputs.get(fieldApi);
            String label = String.isBlank(ai.label) ? fieldApi : ai.label;
            appendLine(cls, '        fieldLabels.put(\'' + fieldApi + '\', \'' + escape(label) + '\');');
        }

        appendLine(cls, '        Map<String, String> fieldTypes = new Map<String, String>();');
        for (String fieldApi : fieldInputs.keySet()) {
            PlanModels.ActionInput ai = fieldInputs.get(fieldApi);
            String typeVal = String.isBlank(ai.dataType) ? 'String' : ai.dataType;
            appendLine(cls, '        fieldTypes.put(\'' + fieldApi + '\', \'' + typeVal + '\');');
        }

        appendLine(cls, '        Map<String, String> payloadBindings = new Map<String, String>();');
        for (String fieldApi : fieldInputs.keySet()) {
            PlanModels.ActionInput ai = fieldInputs.get(fieldApi);
            String payloadKey = String.isBlank(ai.apiName) ? fieldApi : ai.apiName;
            appendLine(cls, '        payloadBindings.put(\'' + payloadKey + '\', \'' + fieldApi + '\');');
        }

        appendLine(cls, '        Set<String> requiredInputs = new Set<String>();');
        for (String fieldApi : fieldInputs.keySet()) {
            PlanModels.ActionInput ai = fieldInputs.get(fieldApi);
            if (ai.required == true) {
                String payloadKey = String.isBlank(ai.apiName) ? fieldApi : ai.apiName;
                appendLine(cls, '        requiredInputs.add(\'' + payloadKey + '\');');
            }
        }
    }

    private static void buildRequiredChecks(StringBuilder cls) {
        appendLine(cls, '        for (String requiredKey : requiredInputs) {');
        appendLine(cls, '            String targetField = payloadBindings.get(requiredKey);');
        appendLine(cls, '            RuntimeTypeAdapters.requireField(input, requiredKey, fieldLabels.get(targetField), errors);');
        appendLine(cls, '        }');
    }

    private static void buildNormalizationBlock(StringBuilder cls) {
        appendLine(cls, '        for (String payloadKey : payloadBindings.keySet()) {');
        appendLine(cls, '            if (!input.containsKey(payloadKey)) {');
        appendLine(cls, '                continue;');
        appendLine(cls, '            }');
        appendLine(cls, '            Object raw = input.get(payloadKey);');
        appendLine(cls, '            if (raw == null) {');
        appendLine(cls, '                continue;');
        appendLine(cls, '            }');
        appendLine(cls, '            String fieldApi = payloadBindings.get(payloadKey);');
        appendLine(cls, '            Object converted = RuntimeTypeAdapters.convert(fieldTypes.get(fieldApi), raw, fieldLabels.get(fieldApi), errors);');
        appendLine(cls, '            if (converted != null) {');
        appendLine(cls, '                normalized.put(fieldApi, converted);');
        appendLine(cls, '            }');
        appendLine(cls, '        }');
    }

    private static void buildGuardrailBlock(StringBuilder cls, PlanModels.ActionBlueprint blueprint) {
        appendLine(cls, '        GuardrailEvaluator.apply(\'' + escape(blueprint.targetSObject) + '\', blueprintGuardrails(), normalized, errors);');
    }

    private static void buildErrorShortCircuit(StringBuilder cls) {
        appendLine(cls, '        if (!errors.isEmpty()) {');
        appendLine(cls, '            res.errors.addAll(errors);');
        appendLine(cls, '            return res;');
        appendLine(cls, '        }');
    }

    private static void buildDmlBlock(StringBuilder cls, PlanModels.ActionBlueprint blueprint) {
        String operation = String.isBlank(blueprint.operation) ? 'UPDATE' : blueprint.operation.toUpperCase();
        String sobjectApi = String.isBlank(blueprint.targetSObject) ? 'SObject' : blueprint.targetSObject;
        String successMessage = String.isBlank(blueprint.summary) ? 'Executed ' + blueprint.name : blueprint.summary;
        appendLine(cls, '        try {');
        appendLine(cls, '            SObject record = Schema.getGlobalDescribe().get(\'' + escape(sobjectApi) + '\').newSObject(null);');
        appendLine(cls, '            for (String fieldApi : normalized.keySet()) {');
        appendLine(cls, '                record.put(fieldApi, normalized.get(fieldApi));');
        appendLine(cls, '            }');
        if (operation == 'INSERT' || operation == 'CREATE') {
            appendLine(cls, '            Database.SaveResult sr = Database.insert(record, false);');
        } else if (operation == 'UPSERT') {
            String keyField = (blueprint.keyFields != null && !blueprint.keyFields.isEmpty()) ? blueprint.keyFields.get(0) : 'Id';
            appendLine(cls, '            Database.UpsertResult sr = Database.upsert(record, \'' + escape(keyField) + '\', false);');
        } else {
            appendLine(cls, '            Database.SaveResult sr = Database.update(record, false);');
        }
        appendLine(cls, '            res.success = true;');
        appendLine(cls, '            res.logs.add(\'' + escape(successMessage) + '\');');
        appendLine(cls, '        } catch (Exception ex) {');
        appendLine(cls, '            res.success = false;');
        appendLine(cls, '            res.errors.add(ex.getMessage());');
        appendLine(cls, '        }');
    }

    private static String buildGuardrailFactory(PlanModels.ActionBlueprint blueprint) {
        StringBuilder method = new StringBuilder();
        appendLine(method, '    private static List<PlanModels.Guardrail> blueprintGuardrails() {');
        appendLine(method, '        List<PlanModels.Guardrail> rules = new List<PlanModels.Guardrail>();');
        if (blueprint.guardrails != null) {
            for (PlanModels.Guardrail g : blueprint.guardrails) {
                if (g == null) {
                    continue;
                }
                appendLine(method, '        {');
                appendLine(method, '            PlanModels.Guardrail rule = new PlanModels.Guardrail();');
                appendLine(method, '            rule.type = \'' + escape(g.type) + '\';');
                if (g.params != null && !g.params.isEmpty()) {
                    appendLine(method, '            rule.params = new Map<String, Object>();');
                    for (String key : g.params.keySet()) {
                        Object value = g.params.get(key);
                        appendLine(method, '            rule.params.put(\'' + escape(key) + '\', ' + serializeParam(value) + ');');
                    }
                } else {
                    appendLine(method, '            rule.params = new Map<String, Object>();');
                }
                if (!String.isBlank(g.message)) {
                    appendLine(method, '            rule.message = \'' + escape(g.message) + '\';');
                }
                appendLine(method, '            rules.add(rule);');
                appendLine(method, '        }');
            }
        }
        appendLine(method, '        return rules;');
        appendLine(method, '    }');
        return method.toString();
    }

    private static String renderTestClass(String className, String testName) {
        StringBuilder test = new StringBuilder();
        appendLine(test, '@IsTest');
        appendLine(test, 'private class ' + testName + ' {');
        appendLine(test, '    @IsTest static void missingInputsProduceErrors() {');
        appendLine(test, '        InvocableActionFactory.IAction action = (InvocableActionFactory.IAction) Type.forName(\'' + className + '\').newInstance();');
        appendLine(test, '        PlanModels.OrchestratorResult result = action.execute(new Map<String, Object>());');
        appendLine(test, '        System.assertEquals(false, result.success, \'' + className + ' should fail when inputs are missing\');');
        appendLine(test, '        System.assertNotEquals(0, result.errors.size(), \'' + className + ' should surface validation errors\');');
        appendLine(test, '    }');
        appendLine(test, '}');
        return test.toString();
    }

    private static void appendLine(StringBuilder sb, String line) {
        sb.append(line);
        sb.append('\n');
    }

    private static String sanitizeName(String raw) {
        String value = String.isBlank(raw) ? 'GeneratedAction' : raw;
        String cleaned = value.replaceAll('[^A-Za-z0-9_]', '_');
        if (String.isBlank(cleaned)) {
            cleaned = 'GeneratedAction';
        }
        if (!Pattern.matches('^[A-Za-z].*', cleaned)) {
            cleaned = 'A' + cleaned;
        }
        return cleaned;
    }

    private static String escape(String raw) {
        if (raw == null) {
            return '';
        }
        return raw.replace('\\', '\\\\').replace('\'', '\\'');
    }

    private static String serializeParam(Object value) {
        if (value == null) {
            return 'null';
        }
        if (value instanceof String) {
            return '\'' + escape((String) value) + '\'';
        }
        if (value instanceof Boolean || value instanceof Integer || value instanceof Long || value instanceof Decimal) {
            return String.valueOf(value);
        }
        if (value instanceof List<String>) {
            List<String> listVal = (List<String>) value;
            List<String> rendered = new List<String>();
            for (String item : listVal) {
                rendered.add('\'' + escape(item) + '\'');
            }
            return 'new List<String>{' + String.join(rendered, ',') + '}';
        }
        if (value instanceof Set<String>) {
            Set<String> setVal = (Set<String>) value;
            List<String> rendered = new List<String>();
            for (String item : setVal) {
                rendered.add('\'' + escape(item) + '\'');
            }
            return 'new Set<String>{' + String.join(rendered, ',') + '}';
        }
        if (value instanceof List<Object>) {
            List<Object> listVal = (List<Object>) value;
            List<String> rendered = new List<String>();
            for (Object item : listVal) {
                rendered.add(serializeParam(item));
            }
            return 'new List<Object>{' + String.join(rendered, ',') + '}';
        }
        if (value instanceof Map<String, Object>) {
            Map<String, Object> mapVal = (Map<String, Object>) value;
            List<String> rendered = new List<String>();
            for (String key : mapVal.keySet()) {
                rendered.add('\'' + escape(key) + '\' => ' + serializeParam(mapVal.get(key)));
            }
            return 'new Map<String, Object>{' + String.join(rendered, ',') + '}';
        }
        return '\'' + escape(String.valueOf(value)) + '\'';
    }
}
