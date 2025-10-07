public with sharing class BlueprintRecommendationService {
    public class RecommendationResponse {
        public List<PlanModels.ActionBlueprint> blueprints;
        public List<PlanModels.Recommendation> recommendations;

        public RecommendationResponse() {
            blueprints = new List<PlanModels.ActionBlueprint>();
            recommendations = new List<PlanModels.Recommendation>();
        }
    }

    private class RecommendationContext {
        public String source;
        public List<String> tags;
        public Decimal baseScore;

        public RecommendationContext() {
            tags = new List<String>();
        }
    }

    public static RecommendationResponse recommend(String goal, Map<String, Object> schemaSlice, Map<String, Object> constraints) {
        Map<String, RecommendationContext> contexts = new Map<String, RecommendationContext>();
        List<PlanModels.ActionBlueprint> combined = new List<PlanModels.ActionBlueprint>();
        Set<String> seenNames = new Set<String>();

        List<BlueprintLibraryService.MatchResult> curatedMatches = BlueprintLibraryService.findMatches(goal, schemaSlice, 5);
        for (BlueprintLibraryService.MatchResult match : curatedMatches) {
            if (match == null || match.entry == null || match.entry.blueprint == null) {
                continue;
            }
            PlanModels.ActionBlueprint bp = match.entry.blueprint;
            combined.add(bp);
            seenNames.add(bp.name);
            RecommendationContext ctx = new RecommendationContext();
            ctx.source = 'CURATED';
            if (match.entry.tags != null) {
                ctx.tags.addAll(match.entry.tags);
            }
            ctx.baseScore = match.score + Decimal.valueOf('0.6');
            contexts.put(bp.name, ctx);
        }

        List<PlanModels.ActionBlueprint> llmBlueprints = BlueprintSynthesisService.buildBlueprints(goal, schemaSlice, constraints);
        Integer llmIndex = 0;
        for (PlanModels.ActionBlueprint bp : llmBlueprints) {
            if (bp == null || seenNames.contains(bp.name)) {
                llmIndex++;
                continue;
            }
            combined.add(bp);
            seenNames.add(bp.name);
            RecommendationContext ctx = new RecommendationContext();
            ctx.source = 'LLM/Heuristic';
            Decimal llmBase = Decimal.valueOf('1') - (Decimal.valueOf(llmIndex) * Decimal.valueOf('0.1'));
            if (llmBase < Decimal.valueOf('0.5')) {
                llmBase = Decimal.valueOf('0.5');
            }
            ctx.baseScore = llmBase;
            contexts.put(bp.name, ctx);
            llmIndex++;
        }

        return fromBlueprints(goal, combined, contexts);
    }

    public static RecommendationResponse fromBlueprints(String goal, List<PlanModels.ActionBlueprint> blueprints) {
        return fromBlueprints(goal, blueprints, new Map<String, RecommendationContext>());
    }

    public static RecommendationResponse fromBlueprints(String goal, List<PlanModels.ActionBlueprint> blueprints, Map<String, RecommendationContext> contexts) {
        RecommendationResponse response = new RecommendationResponse();
        if (blueprints == null) {
            return response;
        }
        response.blueprints.addAll(blueprints);

        Integer index = 0;
        for (PlanModels.ActionBlueprint bp : blueprints) {
            if (bp == null) {
                continue;
            }
            RecommendationContext ctx = (contexts != null && contexts.containsKey(bp.name)) ? contexts.get(bp.name) : null;
            PlanModels.Recommendation recommendation = new PlanModels.Recommendation();
            recommendation.name = String.isBlank(bp.label) ? bp.name : bp.label;
            recommendation.blueprint = bp;
            recommendation.source = (ctx != null && !String.isBlank(ctx.source)) ? ctx.source : 'LLM/Heuristic';
            if (ctx != null && ctx.tags != null) {
                recommendation.tags.addAll(ctx.tags);
            }
            recommendation.score = calculateScore(bp, index, ctx);
            recommendation.rationale = buildRationale(bp, goal);
            response.recommendations.add(recommendation);
            index++;
        }
        response.recommendations.sort(new RecommendationSorter());
        return response;
    }

    private static Decimal calculateScore(PlanModels.ActionBlueprint bp, Integer index, RecommendationContext ctx) {
        Decimal base;
        if (ctx != null && ctx.baseScore != null) {
            base = ctx.baseScore;
        } else {
            base = Decimal.valueOf('1') - (Decimal.valueOf(index) * Decimal.valueOf('0.15'));
            if (base < Decimal.valueOf('0')) {
                base = Decimal.valueOf('0');
            }
        }
        Decimal guardrailScore = (bp.guardrails != null && !bp.guardrails.isEmpty()) ? Decimal.valueOf('0.1') : Decimal.valueOf('0');
        Decimal inputScore = Decimal.valueOf('0');
        if (bp.inputs != null) {
            inputScore = Decimal.valueOf(bp.inputs.size()) * Decimal.valueOf('0.02');
            if (inputScore > Decimal.valueOf('0.2')) {
                inputScore = Decimal.valueOf('0.2');
            }
        }
        Decimal summaryScore = !String.isBlank(bp.summary) ? Decimal.valueOf('0.05') : Decimal.valueOf('0');
        return (base + guardrailScore + inputScore + summaryScore).setScale(2);
    }

    private static String buildRationale(PlanModels.ActionBlueprint bp, String goal) {
        List<String> parts = new List<String>();
        if (!String.isBlank(bp.targetSObject)) {
            parts.add('Targets ' + bp.targetSObject);
        }
        if (bp.inputs != null && !bp.inputs.isEmpty()) {
            parts.add(bp.inputs.size() + ' required data points');
        }
        if (bp.guardrails != null && !bp.guardrails.isEmpty()) {
            parts.add('Includes ' + bp.guardrails.size() + ' guardrails');
        }
        if (String.isBlank(goal) == false) {
            parts.add('Relevant to goal: ' + goal.left(Math.min(goal.length(), 60)));
        }
        return String.join(parts, ' · ');
    }

    private class RecommendationSorter implements System.Comparator<PlanModels.Recommendation> {
        public Integer compare(PlanModels.Recommendation a, PlanModels.Recommendation b) {
            if (a == null && b == null) return 0;
            if (a == null) return 1;
            if (b == null) return -1;
            if (a.score == null && b.score == null) return 0;
            if (a.score == null) return 1;
            if (b.score == null) return -1;
            Integer scoreCompare = -1 * a.score.compareTo(b.score);
            if (scoreCompare != 0) {
                return scoreCompare;
            }
            String nameA = String.isBlank(a.name) ? '' : a.name;
            String nameB = String.isBlank(b.name) ? '' : b.name;
            return nameA.compareToIgnoreCase(nameB);
        }
    }
}
