public with sharing class SchemaSnapshotService {
    public class Options {
        @AuraEnabled public Integer maxObjects;
        @AuraEnabled public Integer maxFieldsPerObject;
        @AuraEnabled public Boolean includeFieldLevelSecurity;
        @AuraEnabled public Boolean includeRelationships;

        public Options() {
            maxObjects = 20;
            maxFieldsPerObject = 25;
            includeFieldLevelSecurity = true;
            includeRelationships = false;
        }
    }

    public static Map<String, Object> summarize() {
        return summarize(new Options());
    }

    public static Map<String, Object> summarize(Options options) {
        Options resolved = (options == null) ? new Options() : options;
        Map<String, Object> payload = new Map<String, Object>();
        List<Map<String, Object>> objectSummaries = new List<Map<String, Object>>();

        Map<String, Schema.SObjectType> describeMap = Schema.getGlobalDescribe();
        List<String> objectNames = new List<String>(describeMap.keySet());
        objectNames.sort();

        Integer maxObjects = (resolved.maxObjects == null || resolved.maxObjects <= 0)
            ? objectNames.size()
            : Math.min(objectNames.size(), resolved.maxObjects);

        for (Integer i = 0; i < maxObjects; i++) {
            String apiName = objectNames[i];
            try {
                Schema.DescribeSObjectResult objDescribe = describeMap.get(apiName).getDescribe();
                if (!objDescribe.isQueryable()) {
                    continue;
                }
                Map<String, Object> objectSummary = new Map<String, Object>();
                objectSummary.put('apiName', apiName);
                objectSummary.put('label', objDescribe.getLabel());
                objectSummary.put('labelPlural', objDescribe.getLabelPlural());
                objectSummary.put('custom', objDescribe.isCustom());
                objectSummary.put('keyPrefix', objDescribe.getKeyPrefix());
                objectSummary.put('recordTypes', collectRecordTypes(objDescribe));

                objectSummary.put('fields', collectFields(objDescribe, resolved));

                if (resolved.includeRelationships == true) {
                    objectSummary.put('childRelationships', collectChildRelationships(objDescribe));
                }

                objectSummaries.add(objectSummary);
            } catch (Exception e) {
                // Skip objects the running user cannot describe.
            }
        }

        payload.put('generatedAt', Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        payload.put('objectCount', objectSummaries.size());
        payload.put('objects', objectSummaries);
        return payload;
    }

    private static List<Map<String, Object>> collectFields(Schema.DescribeSObjectResult objDescribe, Options options) {
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        List<String> fieldNames = new List<String>(fieldMap.keySet());
        fieldNames.sort();

        Integer maxFields = (options.maxFieldsPerObject == null || options.maxFieldsPerObject <= 0)
            ? fieldNames.size()
            : Math.min(fieldNames.size(), options.maxFieldsPerObject);

        List<Map<String, Object>> fields = new List<Map<String, Object>>();
        for (Integer i = 0; i < maxFields; i++) {
            String fieldApiName = fieldNames[i];
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldApiName).getDescribe();
            Map<String, Object> info = new Map<String, Object>();
            info.put('apiName', fieldApiName);
            info.put('label', fieldDescribe.getLabel());
            info.put('type', String.valueOf(fieldDescribe.getType()));
            info.put('custom', fieldDescribe.isCustom());
            info.put('updateable', fieldDescribe.isUpdateable());
            info.put('accessible', fieldDescribe.isAccessible());
            info.put('nillable', fieldDescribe.isNillable());
            if (fieldDescribe.getReferenceTo() != null && !fieldDescribe.getReferenceTo().isEmpty()) {
                List<String> references = new List<String>();
                for (Schema.SObjectType refType : fieldDescribe.getReferenceTo()) {
                    references.add(refType.getDescribe().getName());
                }
                info.put('references', references);
            }
            if (options.includeFieldLevelSecurity == true) {
                info.put('requiresFLS', !(fieldDescribe.isAccessible() && fieldDescribe.isUpdateable()));
            }
            fields.add(info);
        }
        return fields;
    }

    private static List<Map<String, Object>> collectChildRelationships(Schema.DescribeSObjectResult objDescribe) {
        List<Map<String, Object>> relationships = new List<Map<String, Object>>();
        for (Schema.ChildRelationship rel : objDescribe.getChildRelationships()) {
            if (rel == null) {
                continue;
            }
            Map<String, Object> info = new Map<String, Object>();
            info.put('childObject', rel.getChildSObject());
            info.put('field', rel.getField());
            info.put('cascadeDelete', rel.isCascadeDelete());
            info.put('restrictedDelete', rel.isRestrictedDelete());
            relationships.add(info);
        }
        return relationships;
    }

    private static List<Map<String, Object>> collectRecordTypes(Schema.DescribeSObjectResult objDescribe) {
        List<Map<String, Object>> recordTypes = new List<Map<String, Object>>();
        for (Schema.RecordTypeInfo rti : objDescribe.getRecordTypeInfos()) {
            Map<String, Object> info = new Map<String, Object>();
            info.put('developerName', rti.getDeveloperName());
            info.put('name', rti.getName());
            info.put('available', rti.isAvailable());
            info.put('default', rti.isDefaultRecordTypeMapping());
            recordTypes.add(info);
        }
        return recordTypes;
    }
}
