public with sharing class GuardrailEvaluator {
    public static void apply(String sobjectApiName, List<PlanModels.Guardrail> guardrails, Map<String, Object> normalized, List<String> errors) {
        if (guardrails == null || guardrails.isEmpty()) {
            return;
        }
        Schema.DescribeSObjectResult describeResult = null;
        Map<String, Schema.SObjectField> fieldMap = null;

        for (PlanModels.Guardrail guardrail : guardrails) {
            if (guardrail == null || String.isBlank(guardrail.type)) {
                continue;
            }
            String type = guardrail.type.trim().toUpperCase();
            if (type.startsWith('FLS')) {
                if (describeResult == null) {
                    describeResult = describe(sobjectApiName);
                    fieldMap = (describeResult == null) ? new Map<String, Schema.SObjectField>() : describeResult.fields.getMap();
                }
                handleFls(type, guardrail, fieldMap, errors);
                continue;
            }
            if (type == 'NUMERIC_POSITIVE') {
                enforceNumericPositive(guardrail, normalized, errors);
                continue;
            }
            if (type == 'NUMERIC_RANGE') {
                enforceNumericRange(guardrail, normalized, errors);
                continue;
            }
            if (type == 'ENUM_ALLOWED') {
                enforceEnumAllowed(guardrail, normalized, errors);
                continue;
            }
            if (type == 'PII_REDACT') {
                enforcePiiRedaction(guardrail, normalized, errors);
                continue;
            }
            if (type == 'SHARING_REQUIRED') {
                ensureSharing(describeResult == null ? describe(sobjectApiName) : describeResult, guardrail, errors);
                continue;
            }
        }
    }

    private static void handleFls(String type, PlanModels.Guardrail guardrail, Map<String, Schema.SObjectField> fieldMap, List<String> errors) {
        if (fieldMap == null) {
            errors.add('Unable to evaluate field-level security.');
            return;
        }
        List<String> fields = toStringList(guardrail.params != null ? guardrail.params.get('fields') : null);
        if (fields.isEmpty()) {
            return;
        }
        List<String> blocked = new List<String>();
        for (String fieldApi : fields) {
            if (!fieldMap.containsKey(fieldApi)) {
                blocked.add(fieldApi + ' (missing)');
                continue;
            }
            Schema.DescribeFieldResult dr = fieldMap.get(fieldApi).getDescribe();
            Boolean allowed;
            if (type == 'FLS_EDIT' || type == 'FLS_UPDATE' || type == 'FLS_WRITE') {
                allowed = dr.isUpdateable();
            } else {
                allowed = dr.isAccessible();
            }
            if (!allowed) {
                blocked.add(fieldApi);
            }
        }
        if (!blocked.isEmpty()) {
            String msg = !String.isBlank(guardrail.message)
                ? guardrail.message
                : 'Access denied for fields: ' + String.join(blocked, ', ');
            errors.add(msg);
        }
    }

    private static void enforceNumericPositive(PlanModels.Guardrail guardrail, Map<String, Object> normalized, List<String> errors) {
        String fieldName = guardrailParamAsString(guardrail, 'field');
        if (String.isBlank(fieldName) || normalized == null || !normalized.containsKey(fieldName)) {
            return;
        }
        Decimal value = toDecimal(normalized.get(fieldName));
        if (value != null && value <= 0) {
            String msg = !String.isBlank(guardrail.message)
                ? guardrail.message
                : fieldName + ' must be greater than zero.';
            errors.add(msg);
        }
    }

    private static void enforceNumericRange(PlanModels.Guardrail guardrail, Map<String, Object> normalized, List<String> errors) {
        String fieldName = guardrailParamAsString(guardrail, 'field');
        if (String.isBlank(fieldName) || normalized == null || !normalized.containsKey(fieldName)) {
            return;
        }
        Decimal value = toDecimal(normalized.get(fieldName));
        Decimal min = toDecimal(guardrail.params != null ? guardrail.params.get('min') : null);
        Decimal max = toDecimal(guardrail.params != null ? guardrail.params.get('max') : null);
        if (value == null) {
            return;
        }
        Boolean violation = false;
        if (min != null && value < min) {
            violation = true;
        }
        if (max != null && value > max) {
            violation = true;
        }
        if (violation) {
            String msg = !String.isBlank(guardrail.message)
                ? guardrail.message
                : fieldName + ' must be between ' + String.valueOf(min) + ' and ' + String.valueOf(max) + '.';
            errors.add(msg);
        }
    }

    private static void enforcePiiRedaction(PlanModels.Guardrail guardrail, Map<String, Object> normalized, List<String> errors) {
        List<String> fields = toStringList(guardrail.params != null ? guardrail.params.get('fields') : null);
        if (fields.isEmpty() || normalized == null) {
            return;
        }
        List<String> flagged = new List<String>();
        for (String fieldName : fields) {
            if (normalized.containsKey(fieldName) && normalized.get(fieldName) != null && String.valueOf(normalized.get(fieldName)).trim() != '') {
                flagged.add(fieldName);
            }
        }
        if (!flagged.isEmpty()) {
            String msg = !String.isBlank(guardrail.message)
                ? guardrail.message
                : 'Fields require redaction before execution: ' + String.join(flagged, ', ');
            errors.add(msg);
        }
    }

    private static void enforceEnumAllowed(PlanModels.Guardrail guardrail, Map<String, Object> normalized, List<String> errors) {
        String fieldName = guardrailParamAsString(guardrail, 'field');
        if (String.isBlank(fieldName) || normalized == null || !normalized.containsKey(fieldName)) {
            return;
        }
        List<String> allowed = toStringList(guardrail.params != null ? guardrail.params.get('values') : null);
        if (allowed.isEmpty()) {
            return;
        }
        String value = String.valueOf(normalized.get(fieldName));
        if (!allowed.contains(value)) {
            String msg = !String.isBlank(guardrail.message)
                ? guardrail.message
                : fieldName + ' must be one of: ' + String.join(allowed, ', ');
            errors.add(msg);
        }
    }

    private static void ensureSharing(Schema.DescribeSObjectResult describeResult, PlanModels.Guardrail guardrail, List<String> errors) {
        if (describeResult == null) {
            errors.add('Unable to verify sharing rules for object.');
            return;
        }
        if (!describeResult.isCreateable() && !describeResult.isUpdateable()) {
            String msg = !String.isBlank(guardrail.message)
                ? guardrail.message
                : 'User lacks sharing access required to mutate ' + describeResult.getName() + '.';
            errors.add(msg);
        }
    }

    private static Schema.DescribeSObjectResult describe(String apiName) {
        if (String.isBlank(apiName)) {
            return null;
        }
        Schema.DescribeSObjectResult result;
        try {
            result = Schema.getGlobalDescribe().get(apiName).getDescribe();
        } catch (Exception e) {
            result = null;
        }
        return result;
    }

    private static List<String> toStringList(Object raw) {
        List<String> values = new List<String>();
        if (raw == null) {
            return values;
        }
        if (raw instanceof List<String>) {
            values.addAll((List<String>) raw);
            return values;
        }
        if (raw instanceof Set<String>) {
            values.addAll((Set<String>) raw);
            return values;
        }
        if (raw instanceof List<Object>) {
            for (Object item : (List<Object>) raw) {
                values.add(String.valueOf(item));
            }
            return values;
        }
        values.add(String.valueOf(raw));
        return values;
    }

    private static String guardrailParamAsString(PlanModels.Guardrail guardrail, String key) {
        if (guardrail == null || guardrail.params == null || !guardrail.params.containsKey(key)) {
            return null;
        }
        return String.valueOf(guardrail.params.get(key));
    }

    private static Decimal toDecimal(Object raw) {
        if (raw == null) {
            return null;
        }
        try {
            if (raw instanceof Decimal) {
                return (Decimal) raw;
            }
            if (raw instanceof Integer) {
                return Decimal.valueOf((Integer) raw);
            }
            if (raw instanceof Long) {
                return Decimal.valueOf((Long) raw);
            }
            return Decimal.valueOf(String.valueOf(raw));
        } catch (Exception e) {
            return null;
        }
    }
}
