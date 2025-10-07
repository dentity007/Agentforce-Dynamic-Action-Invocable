public with sharing class RecommendFunctionalities {
    public class Response { public List<HeuristicRanker.Recommendation> recommendations; }

    public static Response run(String businessNarrative, List<String> includeObjects, Integer topK) {
        SchemaSnapshot snap = SchemaSnapshot.buildSnapshot(includeObjects == null ? new Set<String>() : new Set<String>(includeObjects));
        List<PlanModels.ActionBlueprint> candidates = BlueprintLibrary.candidates();

        List<HeuristicRanker.Recommendation> h = HeuristicRanker.rank(businessNarrative, snap, candidates, topK);
        List<HeuristicRanker.Recommendation> blended = h;
        List<HeuristicRanker.Recommendation> l = LLMRanker.tryRank(businessNarrative, snap, candidates, topK);
        if (!l.isEmpty()) {
            Set<String> seen = new Set<String>();
            List<HeuristicRanker.Recommendation> merged = new List<HeuristicRanker.Recommendation>();
            for (HeuristicRanker.Recommendation r : l) { merged.add(r); seen.add(r.blueprint.name); }
            for (HeuristicRanker.Recommendation r : h) if (!seen.contains(r.blueprint.name)) merged.add(r);
            blended = merged.subList(0, Math.min((topK==null?3:topK), merged.size()));
        }

        Response resp = new Response(); resp.recommendations = blended; return resp;
    }
}
