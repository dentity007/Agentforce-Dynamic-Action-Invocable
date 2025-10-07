public with sharing class BlueprintLibrary {
    public class Entry {
        public String name;
        public List<String> tags;
        public PlanModels.ActionBlueprint blueprint;
    }

    public static List<Entry> loadAll() {
        List<Entry> out = new List<Entry>();
        List<StaticResource> srs = [SELECT Body FROM StaticResource WHERE Name = 'BlueprintLibrary' LIMIT 1];
        if (srs.isEmpty()) return out;
        String payload = srs[0].Body.toString();
        List<Object> arr = (List<Object>) JSON.deserializeUntyped(payload);
        for (Object o : arr) {
            Map<String,Object> m = (Map<String,Object>) o;
            Entry e = new Entry();
            e.name = (String) m.get('name');
            e.tags = (List<String>) m.get('tags');
            m.remove('name'); m.remove('tags');
            e.blueprint = (PlanModels.ActionBlueprint) JSON.deserialize(JSON.serialize(m), PlanModels.ActionBlueprint.class);
            out.add(e);
        }
        return out;
    }

    public static List<PlanModels.ActionBlueprint> candidates() {
        List<PlanModels.ActionBlueprint> list = new List<PlanModels.ActionBlueprint>();
        for (Entry e : loadAll()) list.add(e.blueprint);
        return list;
    }
}
