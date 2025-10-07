@IsTest
private class PromptTelemetry_Test {
    @IsTest
    static void captureRespectsToggle() {
        // Disabled by default
        PromptTelemetry.capture('Goal', null, 'response');
        System.assertEquals(0, [SELECT COUNT() FROM PromptLog__c], 'Telemetry should be disabled by default.');

        DynamicActionConfig__c setting = DynamicActionConfig__c.getInstance();
        if (setting == null) {
            setting = new DynamicActionConfig__c();
        }
        setting.SetupOwnerId = UserInfo.getOrganizationId();
        setting.EnableTelemetry__c = true;
        upsert setting;

        LLMClientGateway.LLMRequest request = new LLMClientGateway.LLMRequest();
        request.model = 'test-model';
        request.prompt = 'prompt';

        PromptTelemetry.capture('Goal', request, 'response');
        System.assertEquals(1, [SELECT COUNT() FROM PromptLog__c], 'Telemetry should insert when enabled.');
    }
}
