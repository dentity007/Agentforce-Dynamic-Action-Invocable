public with sharing class BlueprintLibraryService {
    public class MatchResult {
        public BlueprintLibrary.Entry entry;
        public Decimal score;
    }

    private static List<BlueprintLibrary.Entry> cachedEntries;

    public static List<BlueprintLibrary.Entry> allEntries() {
        if (cachedEntries == null) {
            cachedEntries = BlueprintLibrary.loadAll();
        }
        return cloneEntries(cachedEntries);
    }

    public static BlueprintLibrary.Entry getEntry(String name) {
        if (String.isBlank(name)) {
            return null;
        }
        for (BlueprintLibrary.Entry entry : cached()) {
            if (entry != null && name.equalsIgnoreCase(entry.name)) {
                return cloneEntry(entry);
            }
        }
        return null;
    }

    public static PlanModels.ActionBlueprint getBlueprint(String name) {
        BlueprintLibrary.Entry entry = getEntry(name);
        if (entry == null) {
            return null;
        }
        return (entry.blueprint == null) ? null : (PlanModels.ActionBlueprint) JSON.deserialize(JSON.serialize(entry.blueprint), PlanModels.ActionBlueprint.class);
    }

    public static List<MatchResult> findMatches(String goal, Map<String, Object> schemaSlice, Integer limit) {
        List<MatchResult> matches = new List<MatchResult>();
        String normalizedGoal = (goal == null) ? '' : goal.toLowerCase();
        Set<String> schemaTokens = extractSchemaTokens(schemaSlice);

        for (BlueprintLibrary.Entry entry : cached()) {
            Decimal score = scoreEntry(entry, normalizedGoal, schemaTokens);
            if (score > 0) {
                MatchResult result = new MatchResult();
                result.entry = cloneEntry(entry);
                result.score = score.setScale(2);
                matches.add(result);
            }
        }
        matches.sort(new MatchComparator());
        if (limit != null && limit > 0 && matches.size() > limit) {
            return matches.subList(0, limit);
        }
        return matches;
    }

    private static List<BlueprintLibrary.Entry> cached() {
        if (cachedEntries == null) {
            cachedEntries = BlueprintLibrary.loadAll();
        }
        return cachedEntries;
    }

    private static List<BlueprintLibrary.Entry> cloneEntries(List<BlueprintLibrary.Entry> entries) {
        List<BlueprintLibrary.Entry> clones = new List<BlueprintLibrary.Entry>();
        for (BlueprintLibrary.Entry entry : entries) {
            clones.add(cloneEntry(entry));
        }
        return clones;
    }

    private static BlueprintLibrary.Entry cloneEntry(BlueprintLibrary.Entry entry) {
        if (entry == null) {
            return null;
        }
        BlueprintLibrary.Entry clone = new BlueprintLibrary.Entry();
        clone.name = entry.name;
        clone.tags = (entry.tags == null) ? new List<String>() : new List<String>(entry.tags);
        clone.blueprint = (entry.blueprint == null)
            ? null
            : (PlanModels.ActionBlueprint) JSON.deserialize(JSON.serialize(entry.blueprint), PlanModels.ActionBlueprint.class);
        return clone;
    }

    private static Decimal scoreEntry(BlueprintLibrary.Entry entry, String goal, Set<String> schemaTokens) {
        Decimal score = Decimal.valueOf('0');
        if (entry.tags != null) {
            for (String tag : entry.tags) {
                if (String.isBlank(tag)) continue;
                String lower = tag.toLowerCase();
                if (goal.contains(lower)) {
                    score += Decimal.valueOf('0.4');
                }
                if (schemaTokens.contains(lower)) {
                    score += Decimal.valueOf('0.3');
                }
            }
        }
        PlanModels.ActionBlueprint bp = entry.blueprint;
        if (score == Decimal.valueOf('0') && bp != null && !String.isBlank(bp.targetSObject) && goal.contains(bp.targetSObject.toLowerCase())) {
            score += Decimal.valueOf('0.2');
        }
        return score;
    }

    private static Set<String> extractSchemaTokens(Map<String, Object> schemaSlice) {
        Set<String> tokens = new Set<String>();
        if (schemaSlice == null || !schemaSlice.containsKey('objects')) {
            return tokens;
        }
        for (Object obj : (List<Object>) schemaSlice.get('objects')) {
            if (!(obj instanceof Map<String, Object>)) continue;
            Map<String, Object> objectMap = (Map<String, Object>) obj;
            String apiName = (String) objectMap.get('apiName');
            if (!String.isBlank(apiName)) {
                tokens.add(apiName.toLowerCase());
            }
            List<Object> fields = (List<Object>) objectMap.get('fields');
            if (fields == null) continue;
            for (Object fieldObj : fields) {
                if (!(fieldObj instanceof Map<String, Object>)) continue;
                Map<String, Object> fieldMap = (Map<String, Object>) fieldObj;
                String fieldApi = (String) fieldMap.get('apiName');
                if (!String.isBlank(fieldApi)) {
                    tokens.add(fieldApi.toLowerCase());
                }
            }
        }
        return tokens;
    }

    private class MatchComparator implements System.Comparator<MatchResult> {
        public Integer compare(MatchResult a, MatchResult b) {
            if (a == null && b == null) return 0;
            if (a == null) return 1;
            if (b == null) return -1;
            Integer scoreCompare = -1 * a.score.compareTo(b.score);
            if (scoreCompare != 0) {
                return scoreCompare;
            }
            return a.entry.name.compareToIgnoreCase(b.entry.name);
        }
    }
}
