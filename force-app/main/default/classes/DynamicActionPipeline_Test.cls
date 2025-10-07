@IsTest
private class DynamicActionPipeline_Test {
    @IsTest
    static void plannerBuildsBlueprintsFromGoal() {
        PlanModels.Plan plan = DynamicActionPlanner.buildPlan('Update the opportunity stage to needs analysis', null, null);
        System.assert(plan.actions.size() > 0, 'Planner should derive at least one action.');
        System.assertEquals('Opportunity', plan.actions[0].targetSObject, 'Heuristic should route to Opportunity.');
    }

    @IsTest
    static void pipelineGeneratesArtifacts() {
        DynamicActionPipeline.Result result = DynamicActionPipeline.execute('Qualify the lead and set status to Working', null, null);
        System.assert(result.plan.actions.size() == result.artifacts.apex.size(), 'Each blueprint should produce one Apex artifact.');
        System.assert(result.artifacts.tests.size() == result.artifacts.apex.size(), 'Each blueprint should emit a matching unit test.');
        System.assertNotEquals(0, result.artifacts.metadata.size(), 'Artifacts should include metadata annotations.');
    }
}
