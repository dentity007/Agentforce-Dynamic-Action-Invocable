public with sharing class PlanModels {
    public class ActionInput {
        @AuraEnabled public String apiName;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String label;
        @AuraEnabled public String dataType;
        @AuraEnabled public Boolean required;
        @AuraEnabled public String usage; // FIELD, PARAMETER, CONTEXT
        @AuraEnabled public String description;

        public Boolean isFieldBinding() {
            return usage == null || usage == 'FIELD';
        }
    }

    public class Guardrail {
        @AuraEnabled public String type;
        @AuraEnabled public Map<String, Object> params;
        @AuraEnabled public String message;
    }

    public class ActionBlueprint {
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String category;
        @AuraEnabled public String targetSObject;
        @AuraEnabled public String operation; // CREATE, UPDATE, UPSERT, CALL
        @AuraEnabled public List<ActionInput> inputs;
        @AuraEnabled public List<Guardrail> guardrails;
        @AuraEnabled public List<String> keyFields;
        @AuraEnabled public String checkpoint;
        @AuraEnabled public String summary;

        public ActionBlueprint() {
            inputs = new List<ActionInput>();
            guardrails = new List<Guardrail>();
            keyFields = new List<String>();
        }
    }

    public class Plan {
        @AuraEnabled public String goal;
        @AuraEnabled public List<ActionBlueprint> actions;
        @AuraEnabled public List<String> guardrails;
        @AuraEnabled public List<String> dependencies;
        @AuraEnabled public String checkpoint;

        public Plan() {
            actions = new List<ActionBlueprint>();
            guardrails = new List<String>();
            dependencies = new List<String>();
        }
    }

    public class Recommendation {
        @AuraEnabled public String name;
        @AuraEnabled public Decimal score;
        @AuraEnabled public String rationale;
        @AuraEnabled public String source;
        @AuraEnabled public List<String> tags;
        @AuraEnabled public ActionBlueprint blueprint;

        public Recommendation() {
            tags = new List<String>();
        }
    }

    public class PipelineResult {
        @AuraEnabled public Map<String, Object> schema;
        @AuraEnabled public List<Recommendation> recommendations;
        @AuraEnabled public Plan plan;
        @AuraEnabled public CodeArtifacts artifacts;
        @AuraEnabled public OffloadModels.Ref schemaRef;
        @AuraEnabled public OffloadModels.Ref artifactsRef;

        public PipelineResult() {
            schema = new Map<String, Object>();
            recommendations = new List<Recommendation>();
        }
    }

    public class CodeArtifacts {
        @AuraEnabled public List<Map<String, String>> apex;
        @AuraEnabled public List<String> soql;
        @AuraEnabled public List<Map<String, String>> tests;
        @AuraEnabled public Map<String, Object> metadata;

        public CodeArtifacts() {
            apex = new List<Map<String, String>>();
            soql = new List<String>();
            tests = new List<Map<String, String>>();
            metadata = new Map<String, Object>();
        }
    }

    public class OrchestratorResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public List<String> logs;
        @AuraEnabled public List<String> warnings;
        @AuraEnabled public List<String> errors;
    }

    public static OrchestratorResult newResult() {
        OrchestratorResult res = new OrchestratorResult();
        res.success = false;
        res.logs = new List<String>();
        res.warnings = new List<String>();
        res.errors = new List<String>();
        return res;
    }
}
