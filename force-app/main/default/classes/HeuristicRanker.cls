public with sharing class HeuristicRanker {
    public class Recommendation {
        public PlanModels.ActionBlueprint blueprint;
        public Decimal score;
        public String rationale;
        public String source; // "heuristic" | "llm" | "library"
    }

    public static List<Recommendation> rank(String narrative, SchemaSnapshot snap, List<PlanModels.ActionBlueprint> cands, Integer topK) {
        Map<String, Integer> termFreq = tf(tokens(narrative));
        List<Recommendation> recs = new List<Recommendation>();
        for (PlanModels.ActionBlueprint bp : cands) {
            Decimal score = 0;
            StringBuilder why = new StringBuilder();

            if (bp.targetSObject != null && snap.objects.containsKey(bp.targetSObject)) {
                score += 2; why.append('Matches object ' + bp.targetSObject + '. ');
            }
            if (bp.operation != null && narrative.toLowerCase().contains(bp.operation.toLowerCase())) {
                score += 1; why.append('Mentions operation ' + bp.operation + '. ');
            }
            if (bp.inputs != null) {
                for (String key : bp.inputs.keySet()) {
                    if (termFreq.containsKey(key.toLowerCase())) {
                        score += 0.5; why.append('Mentions field ' + key + '. ');
                    }
                }
            }

            Recommendation r = new Recommendation();
            r.blueprint = bp; r.score = score; r.rationale = why.toString(); r.source = 'heuristic';
            recs.add(r);
        }
        recs.sort(new Comparator());
        Integer k = (topK == null || topK <= 0) ? 3 : topK;
        return recs.subList(0, Math.min(k, recs.size()));
    }

    private class Comparator implements System.Comparator<Recommendation> {
        public Integer compare(Recommendation a, Recommendation b) {
            return a.score == b.score ? 0 : (a.score > b.score ? -1 : 1);
        }
    }
    private static List<String> tokens(String s) {
        if (String.isBlank(s)) return new List<String>();
        List<String> out = new List<String>();
        for (String t : s.toLowerCase().replaceAll('[^a-z0-9_ ]',' ').split('\\s+')) if (t.length() > 2) out.add(t);
        return out;
    }
    private static Map<String,Integer> tf(List<String> toks){
        Map<String,Integer> m = new Map<String,Integer>();
        for (String t: toks) m.put(t, (m.containsKey(t)? m.get(t)+1 : 1));
        return m;
    }
}