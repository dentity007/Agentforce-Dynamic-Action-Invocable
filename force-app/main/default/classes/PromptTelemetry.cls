public with sharing class PromptTelemetry {
    public static void capture(String goal, LLMClientGateway.LLMRequest request, String response) {
        if (!isEnabled()) {
            return;
        }
        try {
            PromptLog__c log = new PromptLog__c();
            log.Model__c = (request == null) ? null : request.model;
            log.Prompt__c = (request == null) ? null : request.prompt;
            log.Response__c = response;
            log.Goal__c = goal;
            insert log;
        } catch (Exception e) {
            // Swallow exceptions so telemetry never blocks runtime execution.
        }
    }

    private static Boolean isEnabled() {
        DynamicActionConfig__c setting = DynamicActionConfig__c.getInstance();
        return setting != null && setting.EnableTelemetry__c;
    }
}
