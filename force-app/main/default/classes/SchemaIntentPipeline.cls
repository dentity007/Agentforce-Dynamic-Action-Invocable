public with sharing class SchemaIntentPipeline {
    public class Options {
        @AuraEnabled public SchemaSnapshotService.Options schemaOptions;
        @AuraEnabled public Map<String, Object> constraints;
        @AuraEnabled public String blueprintName;
        @AuraEnabled public List<String> includeObjects;
        @AuraEnabled public OffloadModels.Options offloadOptions;

        public Options() {
            schemaOptions = new SchemaSnapshotService.Options();
            constraints = new Map<String, Object>();
            includeObjects = new List<String>();
            offloadOptions = new OffloadModels.Options();
        }
    }

    public static PlanModels.PipelineResult run(String goal) {
        return run(goal, null, new Options());
    }

    public static PlanModels.PipelineResult run(String goal, Options options) {
        return run(goal, null, options);
    }

    public static PlanModels.PipelineResult run(String goal, Map<String, Object> schemaSlice, Options options) {
        Options resolved = (options == null) ? new Options() : options;
        PlanModels.PipelineResult result = new PlanModels.PipelineResult();

        Map<String, Object> resolvedSchema = resolveSchema(schemaSlice, resolved.includeObjects);
        result.schema = resolvedSchema;

        BlueprintLibrary.Entry curatedEntry = BlueprintLibraryService.getEntry(resolved.blueprintName);
        PlanModels.ActionBlueprint curatedBlueprint = (curatedEntry == null) ? null : curatedEntry.blueprint;

        String effectiveGoal = goal;
        if (String.isBlank(effectiveGoal) && curatedEntry != null) {
            effectiveGoal = String.isBlank(curatedEntry.description) ? curatedEntry.name : curatedEntry.description;
        }

        List<PlanModels.ActionBlueprint> actionBlueprints = new List<PlanModels.ActionBlueprint>();
        result.recommendations = new List<PlanModels.Recommendation>();

        if (curatedBlueprint != null) {
            actionBlueprints.add(curatedBlueprint);

            PlanModels.Recommendation recommendation = new PlanModels.Recommendation();
            recommendation.name = String.isBlank(curatedBlueprint.label) ? curatedBlueprint.name : curatedBlueprint.label;
            recommendation.blueprint = curatedBlueprint;
            recommendation.source = 'CURATED';
            if (curatedEntry.tags != null) {
                recommendation.tags.addAll(curatedEntry.tags);
            }
            recommendation.score = Decimal.valueOf('1');
            String description = curatedEntry.description;
            recommendation.rationale = String.isBlank(description) ? 'Curated library blueprint' : description;
            result.recommendations.add(recommendation);
        } else {
            BlueprintRecommendationService.RecommendationResponse recommendationResponse =
                BlueprintRecommendationService.recommend(effectiveGoal, resolvedSchema, resolved.constraints);
            actionBlueprints.addAll(recommendationResponse.blueprints);
            result.recommendations.addAll(recommendationResponse.recommendations);
        }

        PlanModels.Plan plan = DynamicActionPlanner.buildPlan(effectiveGoal, resolvedSchema, resolved.constraints, actionBlueprints);
        result.plan = plan;
        result.artifacts = CodeGenService.generate(plan.actions);

        // Optional offloading
        maybeOffloadSchema(result, resolved.offloadOptions);
        maybeOffloadArtifacts(result, resolved.offloadOptions);
        return result;
    }

    private static Map<String, Object> resolveSchema(Map<String, Object> providedSlice, List<String> includeObjects) {
        if (providedSlice != null && !providedSlice.isEmpty()) {
            return providedSlice;
        }
        Set<String> objectSet = null;
        if (includeObjects != null && !includeObjects.isEmpty()) {
            objectSet = new Set<String>();
            for (String name : includeObjects) {
                if (!String.isBlank(name)) {
                    objectSet.add(name);
                }
            }
            if (objectSet.isEmpty()) {
                objectSet = null;
            }
        }
        SchemaSnapshot snapshot = SchemaSnapshot.buildSnapshot(objectSet);
        return (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(snapshot));
    }
    private static void maybeOffloadSchema(PlanModels.PipelineResult result, OffloadModels.Options opts) {
        if (result == null || result.schema == null || opts == null || opts.offloadSchema != true) return;
        String json = JSON.serialize(result.schema);
        Integer sizeBytes = Blob.valueOf(json).size();
        Integer threshold = (opts.sizeThresholdKB == null || opts.sizeThresholdKB <= 0) ? 64 : opts.sizeThresholdKB;
        if (sizeBytes < threshold * 1024) return;
        OffloadModels.Ref r = MemoryOffloadService.tryOffload(opts.schemaStore, json);
        if (r != null) {
            result.schemaRef = r;
            result.schema = new Map<String, Object>();
        }
    }

    private static void maybeOffloadArtifacts(PlanModels.PipelineResult result, OffloadModels.Options opts) {
        if (result == null || result.artifacts == null || opts == null || opts.offloadArtifacts != true) return;
        String json = JSON.serialize(result.artifacts);
        Integer sizeBytes = Blob.valueOf(json).size();
        Integer threshold = (opts.sizeThresholdKB == null || opts.sizeThresholdKB <= 0) ? 64 : opts.sizeThresholdKB;
        if (sizeBytes < threshold * 1024) return;
        OffloadModels.Ref r = MemoryOffloadService.tryOffload(opts.artifactsStore, json);
        if (r != null) {
            result.artifactsRef = r;
            // keep minimal metadata to signal offloaded
            result.artifacts = new PlanModels.CodeArtifacts();
            result.artifacts.metadata.put('offloaded', true);
            result.artifacts.metadata.put('refStore', r.store);
            result.artifacts.metadata.put('refKey', r.key);
        }
    }
}
