public with sharing class GenerationBenchmark {
    public class CaseResult {
        @AuraEnabled public String name;
        @AuraEnabled public Boolean blueprintMatches;
        @AuraEnabled public Boolean classAssertionsPassed;
        @AuraEnabled public Boolean testAssertionsPassed;
        @AuraEnabled public List<String> notes;

        public CaseResult() {
            notes = new List<String>();
        }
    }

    private class CaseDefinition {
        public String name;
        public String goal;
        public PlanModels.ActionBlueprint goldenBlueprint;
        public List<String> classMustContain;
        public List<String> testMustContain;
    }

    public static List<CaseResult> run() {
        List<CaseResult> results = new List<CaseResult>();
        for (CaseDefinition definition : goldenCases()) {
            CaseResult result = new CaseResult();
            result.name = definition.name;

            List<PlanModels.ActionBlueprint> blueprints = HeuristicBlueprintFactory.fromGoal(definition.goal);
            PlanModels.ActionBlueprint candidate = blueprints.isEmpty() ? null : blueprints[0];

            result.blueprintMatches = compareBlueprint(candidate, definition.goldenBlueprint, result.notes);

            CodeTemplateEngine.RenderedArtifact artifact = CodeTemplateEngine.renderAction(candidate);
            result.classAssertionsPassed = containsAll(artifact.body, definition.classMustContain, result.notes, 'class');
            result.testAssertionsPassed = containsAll(artifact.testBody, definition.testMustContain, result.notes, 'test');

            results.add(result);
        }
        return results;
    }

    public static String summarize() {
        List<CaseResult> results = run();
        List<String> lines = new List<String>();
        for (CaseResult res : results) {
            lines.add(res.name + ': blueprint=' + String.valueOf(res.blueprintMatches)
                + ', class=' + String.valueOf(res.classAssertionsPassed)
                + ', test=' + String.valueOf(res.testAssertionsPassed));
            if (!res.notes.isEmpty()) {
                lines.add('  notes: ' + String.join(res.notes, ' | '));
            }
        }
        return String.join(lines, '\n');
    }

    private static Boolean compareBlueprint(PlanModels.ActionBlueprint candidate, PlanModels.ActionBlueprint golden, List<String> notes) {
        if (candidate == null || golden == null) {
            notes.add('Blueprint missing for comparison.');
            return false;
        }
        Boolean matches = true;
        if (candidate.targetSObject != golden.targetSObject) {
            matches = false;
            notes.add('Target mismatch: expected ' + golden.targetSObject + ' but found ' + candidate.targetSObject);
        }
        if (candidate.operation != golden.operation) {
            matches = false;
            notes.add('Operation mismatch: expected ' + golden.operation + ' but found ' + candidate.operation);
        }
        if ((candidate.inputs == null ? 0 : candidate.inputs.size()) != (golden.inputs == null ? 0 : golden.inputs.size())) {
            matches = false;
            notes.add('Input count mismatch. expected ' + (golden.inputs == null ? 0 : golden.inputs.size())
                + ' but found ' + (candidate.inputs == null ? 0 : candidate.inputs.size()));
        }
        return matches;
    }

    private static Boolean containsAll(String body, List<String> fragments, List<String> notes, String artifactType) {
        if (String.isBlank(body)) {
            notes.add('Generated ' + artifactType + ' body is empty.');
            return false;
        }
        Boolean allFound = true;
        if (fragments == null) {
            return true;
        }
        for (String fragment : fragments) {
            if (String.isBlank(fragment)) {
                continue;
            }
            if (!body.contains(fragment)) {
                notes.add('Missing fragment in ' + artifactType + ': ' + fragment);
                allFound = false;
            }
        }
        return allFound;
    }

    private static List<CaseDefinition> goldenCases() {
        List<CaseDefinition> cases = new List<CaseDefinition>();
        // Opportunity Stage Update
        CaseDefinition oppStage = new CaseDefinition();
        oppStage.name = 'Opportunity Stage Update';
        oppStage.goal = 'Update opportunity stage to Closed Won';
        oppStage.goldenBlueprint = (PlanModels.ActionBlueprint) JSON.deserialize(goldenOpportunityStageBlueprint(), PlanModels.ActionBlueprint.class);
        oppStage.classMustContain = new List<String>{'Database.update', 'Opportunity', 'StageName'};
        oppStage.testMustContain = new List<String>{'missingInputsProduceErrors'};
        cases.add(oppStage);

        // Inventory Reservation Task
        CaseDefinition inventory = new CaseDefinition();
        inventory.name = 'Inventory Reservation Task';
        inventory.goal = 'Reserve stock for a product';
        inventory.goldenBlueprint = (PlanModels.ActionBlueprint) JSON.deserialize(goldenInventoryBlueprint(), PlanModels.ActionBlueprint.class);
        inventory.classMustContain = new List<String>{'Database.insert', 'Task', 'Quantity__c'};
        inventory.testMustContain = new List<String>{'missingInputsProduceErrors'};
        cases.add(inventory);

        return cases;
    }

    private static String goldenOpportunityStageBlueprint() {
        return '{' +
            '"name":"UpdateOpportunityStage",' +
            '"label":"Update Opportunity Stage",' +
            '"category":"DOMAIN",' +
            '"targetSObject":"Opportunity",' +
            '"operation":"UPDATE",' +
            '"summary":"Updated Opportunity stage based on agent directive.",' +
            '"checkpoint":"I will update the Opportunity stage. Proceed?",' +
            '"keyFields":["Id"],' +
            '"inputs":[' +
                '{"apiName":"Id","fieldApiName":"Id","label":"Opportunity Id","dataType":"Id","required":true,"usage":"FIELD"},' +
                '{"apiName":"StageName","fieldApiName":"StageName","label":"New Stage","dataType":"String","required":true,"usage":"FIELD"}' +
            '],' +
            '"guardrails":[' +
                '{"type":"FLS_EDIT","params":{"fields":["Id","StageName"]},"message":null}' +
            ']'+
        '}';
    }

    private static String goldenInventoryBlueprint() {
        return '{' +
            '"name":"CreateInventoryReservationTask",' +
            '"label":"Create Inventory Reservation Task",' +
            '"category":"DOMAIN",' +
            '"targetSObject":"Task",' +
            '"operation":"INSERT",' +
            '"summary":"Created a high priority Task to trigger inventory follow-up.",' +
            '"checkpoint":"I will log a Task to request inventory reservation. Proceed?",' +
            '"inputs":[' +
                '{"apiName":"Subject","fieldApiName":"Subject","label":"Task Subject","dataType":"String","required":true,"usage":"FIELD"},' +
                '{"apiName":"Product2Id","fieldApiName":"WhatId","label":"Product Reference","dataType":"Id","required":true,"usage":"FIELD"},' +
                '{"apiName":"Quantity__c","fieldApiName":"Quantity__c","label":"Requested Quantity","dataType":"Decimal","required":true,"usage":"FIELD"}' +
            '],' +
            '"guardrails":[' +
                '{"type":"NUMERIC_POSITIVE","params":{"field":"Quantity__c"},"message":"Quantity must be greater than zero."}' +
            ']'+
        '}';
    }
}
