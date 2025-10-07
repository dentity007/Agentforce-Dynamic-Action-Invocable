public with sharing class SchemaSnapshot {
    public Map<String, SObjectInfo> objects = new Map<String, SObjectInfo>();

    public class SObjectInfo {
        public String apiName;
        public Map<String, FieldInfo> fields = new Map<String, FieldInfo>();
        public List<String> childRelationships = new List<String>();
    }
    public class FieldInfo {
        public String apiName;
        public String type;
        public Boolean nillable;
        public Boolean createable;
        public Boolean updateable;
        public List<String> picklistValues = new List<String>();
    }

    public static SchemaSnapshot buildSnapshot(Set<String> includeObjects) {
        SchemaSnapshot snap = new SchemaSnapshot();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for (String name : gd.keySet()) {
            if (includeObjects != null && !includeObjects.isEmpty() && !includeObjects.contains(name)) continue;
            Schema.DescribeSObjectResult d = gd.get(name).getDescribe();
            if (!d.isCreateable() && !d.isUpdateable()) continue; // focus on actionable objects
            SObjectInfo info = new SObjectInfo();
            info.apiName = name;

            Map<String, Schema.SObjectField> fd = d.fields.getMap();
            for (String fName : fd.keySet()) {
                Schema.DescribeFieldResult fr = fd.get(fName).getDescribe();
                FieldInfo fi = new FieldInfo();
                fi.apiName = fName;
                fi.type = String.valueOf(fr.getType());
                fi.nillable = fr.isNillable();
                fi.createable = fr.isCreateable();
                fi.updateable = fr.isUpdateable();
                if (fr.getType() == Schema.DisplayType.Picklist) {
                    for (Schema.PicklistEntry pe : fr.getPicklistValues()) fi.picklistValues.add(pe.getValue());
                }
                info.fields.put(fName, fi);
            }
            for (Schema.ChildRelationship cr : d.getChildRelationships()) {
                info.childRelationships.add(cr.getChildSObject() + '.' + String.valueOf(cr.getRelationshipName()));
            }
            snap.objects.put(name, info);
        }
        return snap;
    }
}
