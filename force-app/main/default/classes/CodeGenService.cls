public with sharing class CodeGenService {
    public static PlanModels.CodeArtifacts generate(List<PlanModels.ActionBlueprint> blueprints) {
        PlanModels.CodeArtifacts artifacts = new PlanModels.CodeArtifacts();
        if (blueprints == null) {
            return artifacts;
        }
        List<Map<String, String>> apexClasses = new List<Map<String, String>>();
        List<Map<String, String>> testClasses = new List<Map<String, String>>();

        for (PlanModels.ActionBlueprint blueprint : blueprints) {
            if (blueprint == null) {
                continue;
            }
            CodeTemplateEngine.RenderedArtifact rendered = CodeTemplateEngine.renderAction(blueprint);
            apexClasses.add(new Map<String, String>{
                'name' => rendered.className,
                'content' => rendered.body
            });
            testClasses.add(new Map<String, String>{
                'name' => rendered.testName,
                'content' => rendered.testBody
            });
        }

        artifacts.apex = apexClasses;
        artifacts.tests = testClasses;
        artifacts.metadata.put('generatedAt', Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        artifacts.metadata.put('blueprintCount', blueprints.size());
        return artifacts;
    }
}
