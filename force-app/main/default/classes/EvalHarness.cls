public with sharing class EvalHarness {
    public class EvalResult {
        public String name;
        public String goal;
        public Map<String,String> artifacts; // filenames -> contents
        public String planJson;              // serialized blueprint/plan if needed
    }

    /**
     * Generate artifacts using a curated blueprint (by name) and a goal/narrative.
     * This bypasses LLM so CI stays deterministic.
     */
    public static String generateFromBlueprintName(String blueprintName, String goal) {
        // 1) Load curated blueprint by name
        PlanModels.ActionBlueprint bp = null;
        for (BlueprintLibrary.Entry e : BlueprintLibrary.loadAll()) {
            if (e.name == blueprintName) {
                bp = e.blueprint;
                break;
            }
        }
        if (bp == null) {
            return JSON.serializePretty(new Map<String,Object>{
                'error' => 'Blueprint not found: ' + blueprintName
            });
        }

        // 2) Execute pipeline with explicit blueprint
        DynamicActionPipeline.Result result = DynamicActionPipeline.execute(
            goal,
            bp,
            null // options if any
        );

        // 3) Shape eval output
        EvalResult out = new EvalResult();
        out.name = blueprintName;
        out.goal = goal;
        out.artifacts = result.artifacts;
        out.planJson = JSON.serialize(result.plan);

        return JSON.serialize(out);
    }
}