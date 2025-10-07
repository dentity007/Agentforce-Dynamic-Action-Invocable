@IsTest
private class CodeTemplateEngine_Test {
    @IsTest
    static void rendersUpdateAction() {
        PlanModels.ActionBlueprint bp = HeuristicBlueprintFactory.fromGoal('Update the opportunity stage to Closed Won').get(0);
        CodeTemplateEngine.RenderedArtifact rendered = CodeTemplateEngine.renderAction(bp);
        System.assert(rendered.body.contains('Database.update'), 'Should generate an update DML block');
        System.assert(rendered.body.contains('GuardrailEvaluator.apply'), 'Should include guardrail evaluation');
        System.assert(rendered.testBody.contains(rendered.className), 'Test class should reference generated class');
    }

    @IsTest
    static void sanitizesClassNames() {
        PlanModels.ActionBlueprint bp = new PlanModels.ActionBlueprint();
        bp.name = '123 Custom Action';
        bp.label = '123 Custom Action';
        bp.targetSObject = 'Task';
        bp.operation = 'INSERT';
        bp.inputs.add(HeuristicBlueprintFactory.fromGoal('inventory').get(0).inputs[0]);
        CodeTemplateEngine.RenderedArtifact rendered = CodeTemplateEngine.renderAction(bp);
        System.assertEquals('DynamicAction_A123_Custom_Action', rendered.className, 'Class name should be letter-prefixed and sanitized');
    }
}
