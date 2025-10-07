@IsTest
private class GuardrailEvaluator_Test {
    @IsTest
    static void numericPositiveFailsForZero() {
        PlanModels.Guardrail guardrail = new PlanModels.Guardrail();
        guardrail.type = 'NUMERIC_POSITIVE';
        guardrail.params = new Map<String, Object>{'field' => 'Quantity__c'};

        Map<String, Object> normalized = new Map<String, Object>{'Quantity__c' => 0};
        List<String> errors = new List<String>();

        GuardrailEvaluator.apply('Task', new List<PlanModels.Guardrail>{guardrail}, normalized, errors);
        System.assertEquals(1, errors.size(), 'Guardrail should block non-positive quantity.');
    }

    @IsTest
    static void piiRedactRequiresClearingFields() {
        PlanModels.Guardrail guardrail = new PlanModels.Guardrail();
        guardrail.type = 'PII_REDACT';
        guardrail.params = new Map<String, Object>{'fields' => new List<String>{'Description'}};

        Map<String, Object> normalized = new Map<String, Object>{'Description' => 'Contains SSN'};
        List<String> errors = new List<String>();

        GuardrailEvaluator.apply('Task', new List<PlanModels.Guardrail>{guardrail}, normalized, errors);
        System.assertEquals(1, errors.size(), 'PII guardrail should flag descriptions that require redaction.');
    }

    @IsTest
    static void enumAllowedRejectsInvalidValue() {
        PlanModels.Guardrail guardrail = new PlanModels.Guardrail();
        guardrail.type = 'ENUM_ALLOWED';
        guardrail.params = new Map<String, Object>{
            'field' => 'StageName',
            'values' => new List<String>{'Prospecting', 'Closed Won'}
        };

        Map<String, Object> normalized = new Map<String, Object>{'StageName' => 'Invalid'};
        List<String> errors = new List<String>();

        GuardrailEvaluator.apply('Opportunity', new List<PlanModels.Guardrail>{guardrail}, normalized, errors);
        System.assertEquals(1, errors.size(), 'Guardrail should block unexpected value.');
    }
}
