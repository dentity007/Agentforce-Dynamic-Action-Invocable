@IsTest
private class DynamicActionInvoke_Test {

    private class StubRecommendationGateway implements DynamicActionInvoke.RecommendationGateway {
        public RecommendFunctionalities.Response recommend(String goal, List<String> includeObjects, Integer topN) {
            PlanModels.ActionBlueprint blueprint = new PlanModels.ActionBlueprint();
            blueprint.name = 'StubAction';
            blueprint.label = 'Stub Action';
            blueprint.targetSObject = 'Opportunity';
            blueprint.operation = 'UPDATE';

            HeuristicRanker.Recommendation rec = new HeuristicRanker.Recommendation();
            rec.blueprint = blueprint;
            rec.rationale = 'stub rationale';
            rec.score = Decimal.valueOf('0.9');

            RecommendFunctionalities.Response response = new RecommendFunctionalities.Response();
            response.recommendations = new List<HeuristicRanker.Recommendation>{ rec };
            return response;
        }
    }

    private class StubPipelineGateway implements DynamicActionInvoke.PipelineGateway {
        public DynamicActionPipeline.Result execute(PlanModels.ActionBlueprint blueprint, OffloadModels.Options options) {
            DynamicActionPipeline.Result result = new DynamicActionPipeline.Result();
            result.plan = new PlanModels.Plan();
            result.plan.goal = 'Stub Goal';
            result.plan.actions.add(blueprint);

            PlanModels.CodeArtifacts artifacts = new PlanModels.CodeArtifacts();
            artifacts.apex.add(new Map<String, String>{
                'name' => 'DynamicAction_StubAction',
                'content' => 'public class DynamicAction_StubAction {}'
            });
            artifacts.tests.add(new Map<String, String>{
                'name' => 'DynamicAction_StubAction_Test',
                'content' => '@IsTest private class DynamicAction_StubAction_Test {}'
            });
            result.artifacts = artifacts;
            return result;
        }
    }

    @IsTest
    static void runProducesFlowFriendlyResponse() {
        DynamicActionInvoke.RecommendationGateway originalRec = DynamicActionInvoke.recommendationGateway;
        DynamicActionInvoke.PipelineGateway originalPipeline = DynamicActionInvoke.pipelineGateway;
        try {
            DynamicActionInvoke.recommendationGateway = new StubRecommendationGateway();
            DynamicActionInvoke.pipelineGateway = new StubPipelineGateway();

            DynamicActionInvoke.Request req = new DynamicActionInvoke.Request();
            req.goal = 'Update opportunity stage';
            req.includeObjectsCsv = 'Opportunity, Lead';
            req.topN = 2;

            Test.startTest();
            List<DynamicActionInvoke.Response> responses = DynamicActionInvoke.run(new List<DynamicActionInvoke.Request>{ req });
            Test.stopTest();

            System.assertEquals(1, responses.size(), 'Expect single response');
            DynamicActionInvoke.Response resp = responses[0];
            System.assertEquals(true, resp.ok, 'Response should indicate success');
            System.assertEquals('Generated action and tests', resp.message, 'Message should reflect generation success');
            System.assertEquals('StubAction', resp.chosenBlueprint, 'Chosen blueprint name should bubble up');
            System.assertEquals('stub rationale', resp.rationale, 'Rationale should come from recommendation');
            System.assertNotEquals(null, resp.planJson, 'Plan JSON should be serialized');
            System.assert(resp.planJson.contains('Stub Goal'), 'Plan JSON should include stub goal');
            System.assertEquals(null, resp.artifactsOffload, 'Artifacts should remain inline when not offloaded');
            System.assertNotEquals(null, resp.artifactsJson, 'Artifacts JSON should be serialized');
            System.assert(resp.artifactsJson.contains('DynamicAction_StubAction'), 'Artifacts JSON should include generated class name');
        } finally {
            DynamicActionInvoke.recommendationGateway = originalRec;
            DynamicActionInvoke.pipelineGateway = originalPipeline;
            DynamicActionInvoke.resetGateways();
        }
    }
}
