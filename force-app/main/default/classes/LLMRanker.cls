public with sharing class LLMRanker {
    public static List<HeuristicRanker.Recommendation> tryRank(String narrative, SchemaSnapshot snap, List<PlanModels.ActionBlueprint> cands, Integer topK) {
        if (!LLMClientGateway.isRegistered()) return new List<HeuristicRanker.Recommendation>();
        String prompt = buildPrompt(narrative, snap, cands);
        LLMClientGateway.LLMRequest req = new LLMClientGateway.LLMRequest();
        req.prompt = prompt;
        req.model = 'gpt-4o-mini'; // or whatever default
        req.temperature = 0;
        req.maxTokens = 1024;
        String raw = LLMClientGateway.resolve().complete(req);
        List<Object> arr = (List<Object>) JSON.deserializeUntyped(raw); // [{name,score,rationale}]
        Map<String, HeuristicRanker.Recommendation> byName = new Map<String, HeuristicRanker.Recommendation>();
        for (Object o : arr) {
            Map<String,Object> m = (Map<String,Object>) o;
            String name = (String) m.get('name');
            Decimal score = (m.get('score')==null) ? 0 : Decimal.valueOf(String.valueOf(m.get('score')));
            String rationale = (String) m.get('rationale');
            HeuristicRanker.Recommendation r = new HeuristicRanker.Recommendation();
            r.score = score; r.rationale = rationale; r.source = 'llm';
            byName.put(name, r);
        }
        for (PlanModels.ActionBlueprint bp : cands) if (byName.containsKey(bp.name)) byName.get(bp.name).blueprint = bp;
        List<HeuristicRanker.Recommendation> recs = new List<HeuristicRanker.Recommendation>();
        recs.addAll(byName.values());
        recs.sort(new HeuristicRanker.Comparator());
        Integer k = (topK == null || topK <= 0) ? 3 : topK;
        return recs.subList(0, Math.min(k, recs.size()));
    }

    private static String buildPrompt(String narrative, SchemaSnapshot snap, List<PlanModels.ActionBlueprint> cands) {
        Map<String,Object> p = new Map<String,Object>{
            'narrative' => narrative,
            'schemaSummary' => new List<String>(snap.objects.keySet()),
            'candidates' => cands
        };
        return 'Rank the candidate action blueprints for this business goal. Return JSON array of {name,score(0..1),rationale}. ' + JSON.serialize(p);
    }
}