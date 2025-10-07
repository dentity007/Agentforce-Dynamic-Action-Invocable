public with sharing class DynamicActionInvoke {

    public interface RecommendationGateway {
        RecommendFunctionalities.Response recommend(String goal, List<String> includeObjects, Integer topN);
    }

    public interface PipelineGateway {
        DynamicActionPipeline.Result execute(PlanModels.ActionBlueprint blueprint, OffloadModels.Options options);
    }

    private class DefaultRecommendationGateway implements RecommendationGateway {
        public RecommendFunctionalities.Response recommend(String goal, List<String> includeObjects, Integer topN) {
            return RecommendFunctionalities.run(goal, includeObjects, topN);
        }
    }

    private class DefaultPipelineGateway implements PipelineGateway {
        public DynamicActionPipeline.Result execute(PlanModels.ActionBlueprint blueprint, OffloadModels.Options options) {
            return DynamicActionPipeline.executeFromBlueprintWithOptions(blueprint, null, null, options);
        }
    }

    @TestVisible private static RecommendationGateway recommendationGateway = new DefaultRecommendationGateway();
    @TestVisible private static PipelineGateway pipelineGateway = new DefaultPipelineGateway();

    @TestVisible private static void resetGateways() {
        recommendationGateway = new DefaultRecommendationGateway();
        pipelineGateway = new DefaultPipelineGateway();
    }

    public class Request {
        @InvocableVariable(required=true)
        public String goal;

        @InvocableVariable
        public String blueprintName;

        @InvocableVariable
        public String includeObjectsCsv;

        @InvocableVariable
        public Integer topN = 1;

        @InvocableVariable
        public Boolean offloadArtifacts = false;
    }

    public class Response {
        @InvocableVariable public Boolean ok;
        @InvocableVariable public String message;
        @InvocableVariable public String chosenBlueprint;
        @InvocableVariable public String rationale;
        @InvocableVariable public String artifactsJson;
        @InvocableVariable public String artifactsOffload;
        @InvocableVariable public String planJson;
    }

    @InvocableMethod(
        label='Dynamic Action: Recommend+Generate',
        description='Recommend an ActionBlueprint from schema + goal, then synthesize Apex + tests'
    )
    public static List<Response> run(List<Request> batch) {
        List<Response> outputs = new List<Response>();
        if (batch == null) {
            return outputs;
        }

        for (Request req : batch) {
            Response resp = new Response();
            if (req == null) {
                resp.ok = false;
                resp.message = 'Request payload was null.';
                outputs.add(resp);
                continue;
            }

            try {
                Set<String> include = new Set<String>();
                if (!String.isBlank(req.includeObjectsCsv)) {
                    for (String token : req.includeObjectsCsv.split('\s*,\s*')) {
                        if (!String.isBlank(token)) {
                            include.add(token.trim());
                        }
                    }
                }

                Integer desired = (req.topN == null || req.topN <= 0) ? 1 : req.topN;

                OffloadModels.Options offloadOptions = new OffloadModels.Options();
                offloadOptions.offloadArtifacts = (req.offloadArtifacts == true);

                PlanModels.ActionBlueprint chosen;
                String rationale;

                if (!String.isBlank(req.blueprintName)) {
                    PlanModels.ActionBlueprint forced = BlueprintLibraryService.getBlueprint(req.blueprintName);
                    if (forced == null) {
                        throw new AuraHandledException('Blueprint not found: ' + req.blueprintName);
                    }
                    chosen = forced;
                    rationale = 'Forced by caller';
                } else {
                    RecommendFunctionalities.Response rec = recommendationGateway.recommend(
                        req.goal,
                        include.isEmpty() ? null : new List<String>(include),
                        desired
                    );
                    if (rec == null || rec.recommendations == null || rec.recommendations.isEmpty()) {
                        throw new AuraHandledException('No recommendations returned');
                    }
                    HeuristicRanker.Recommendation top = rec.recommendations[0];
                    if (top == null || top.blueprint == null) {
                        throw new AuraHandledException('Top recommendation missing blueprint');
                    }
                    chosen = top.blueprint;
                    rationale = top.rationale;
                }

                DynamicActionPipeline.Result result = pipelineGateway.execute(chosen, offloadOptions);

                resp.ok = true;
                resp.message = 'Generated action and tests';
                resp.chosenBlueprint = chosen != null ? chosen.name : null;
                resp.rationale = rationale;
                resp.planJson = result != null ? JSON.serialize(result.plan) : null;

                if (result != null) {
                    if (result.artifactsRef != null) {
                        Map<String, Object> offloadEnvelope = new Map<String, Object>{
                            '$offload' => '1',
                            'ref' => result.artifactsRef
                        };
                        resp.artifactsOffload = JSON.serialize(offloadEnvelope);
                    } else if (result.artifacts != null) {
                        resp.artifactsJson = JSON.serialize(result.artifacts);
                    }
                }

            } catch (Exception ex) {
                resp.ok = false;
                resp.message = ex.getMessage();
            }

            outputs.add(resp);
        }

        return outputs;
    }
}
