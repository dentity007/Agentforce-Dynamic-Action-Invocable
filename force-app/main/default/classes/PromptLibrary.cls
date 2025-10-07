public with sharing class PromptLibrary {
    public static String blueprintPrompt(String goal, Map<String, Object> schemaSlice, Map<String, Object> constraints) {
        StringBuilder prompt = new StringBuilder();
        prompt.append('You are a Salesforce automation architect. ');
        prompt.append('Design Apex/Flow-ready action blueprints that the platform can compile into executable code.\n');
        prompt.append('Follow the JSON contract: { "actions": [ { "name", "label", "category", "targetSObject", "operation", "summary", "keyFields", "inputs": [ { "apiName", "fieldApiName", "label", "dataType", "required", "usage" } ], "guardrails": [ { "type", "params", "message" } ], "checkpoint" } ] }.\n');
        prompt.append('Only return JSON.\n');

        prompt.append('\n# Goal\n');
        prompt.append(String.isBlank(goal) ? 'No goal provided.' : goal);

        if (schemaSlice != null && !schemaSlice.isEmpty()) {
            prompt.append('\n\n# Schema\n');
            prompt.append(JSON.serializePretty(schemaSlice));
        }
        if (constraints != null && !constraints.isEmpty()) {
            prompt.append('\n\n# Constraints\n');
            prompt.append(JSON.serializePretty(constraints));
        }

        prompt.append('\n\nReturn the most concise blueprint(s) that satisfy the goal while respecting FLS and sharing guardrails.');
        return prompt.toString();
    }
}
