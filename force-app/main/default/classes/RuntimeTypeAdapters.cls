public with sharing class RuntimeTypeAdapters {
    public static Object convert(String dataType, Object raw, String fieldLabel, List<String> errors) {
        if (dataType == null) {
            return raw;
        }
        String dt = dataType.toLowerCase();
        if (dt == 'string' || dt == 'textarea' || dt == 'picklist') {
            return (raw == null) ? null : String.valueOf(raw);
        }
        if (dt == 'id' || dt == 'reference') {
            return toId(raw, fieldLabel, errors);
        }
        if (dt == 'decimal' || dt == 'double' || dt == 'currency') {
            return toDecimal(raw, fieldLabel, errors);
        }
        if (dt == 'integer' || dt == 'long') {
            return toInteger(raw, fieldLabel, errors);
        }
        if (dt == 'boolean') {
            return toBoolean(raw, fieldLabel, errors);
        }
        if (dt == 'date') {
            return toDate(raw, fieldLabel, errors);
        }
        if (dt == 'datetime') {
            return toDateTime(raw, fieldLabel, errors);
        }
        return raw;
    }

    public static Id toId(Object raw, String fieldLabel, List<String> errors) {
        if (raw == null) {
            return null;
        }
        String val = String.valueOf(raw);
        if (Id.isValid(val)) {
            return (Id) val;
        }
        errors.add('Invalid Id value for ' + fieldLabel + ': ' + val);
        return null;
    }

    public static Decimal toDecimal(Object raw, String fieldLabel, List<String> errors) {
        if (raw == null) {
            return null;
        }
        try {
            return Decimal.valueOf(String.valueOf(raw));
        } catch (Exception e) {
            errors.add('Invalid Decimal value for ' + fieldLabel + ': ' + String.valueOf(raw));
            return null;
        }
    }

    public static Integer toInteger(Object raw, String fieldLabel, List<String> errors) {
        if (raw == null) {
            return null;
        }
        try {
            return Integer.valueOf(String.valueOf(raw));
        } catch (Exception e) {
            errors.add('Invalid Integer value for ' + fieldLabel + ': ' + String.valueOf(raw));
            return null;
        }
    }

    public static Boolean toBoolean(Object raw, String fieldLabel, List<String> errors) {
        if (raw == null) {
            return null;
        }
        if (raw instanceof Boolean) {
            return (Boolean) raw;
        }
        String val = String.valueOf(raw).toLowerCase();
        if (val == 'true' || val == 'false') {
            return Boolean.valueOf(val);
        }
        errors.add('Invalid Boolean value for ' + fieldLabel + ': ' + String.valueOf(raw));
        return null;
    }

    public static Date toDate(Object raw, String fieldLabel, List<String> errors) {
        if (raw == null) {
            return null;
        }
        if (raw instanceof Date) {
            return (Date) raw;
        }
        try {
            return Date.valueOf(String.valueOf(raw));
        } catch (Exception e) {
            errors.add('Invalid Date value for ' + fieldLabel + ': ' + String.valueOf(raw));
            return null;
        }
    }

    public static Datetime toDateTime(Object raw, String fieldLabel, List<String> errors) {
        if (raw == null) {
            return null;
        }
        if (raw instanceof Datetime) {
            return (Datetime) raw;
        }
        try {
            return Datetime.valueOf(String.valueOf(raw));
        } catch (Exception e) {
            errors.add('Invalid Datetime value for ' + fieldLabel + ': ' + String.valueOf(raw));
            return null;
        }
    }

    public static void requireField(Map<String, Object> payload, String apiName, String label, List<String> errors) {
        if (payload == null || !payload.containsKey(apiName) || payload.get(apiName) == null || String.valueOf(payload.get(apiName)).trim() == '') {
            errors.add('Missing required field: ' + label);
        }
    }
}
