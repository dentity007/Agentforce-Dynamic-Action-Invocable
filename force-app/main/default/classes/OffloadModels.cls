public with sharing class OffloadModels {
    public class Options {
        @AuraEnabled public Boolean offloadSchema;
        @AuraEnabled public Boolean offloadTelemetry;
        @AuraEnabled public Boolean offloadArtifacts;
        @AuraEnabled public Integer sizeThresholdKB;
        @AuraEnabled public String artifactsStore; // 'PlatformCache' | 'ContentVersion'
        @AuraEnabled public String schemaStore;
        @AuraEnabled public String telemetryStore;

        public Options() {
            offloadSchema = false;
            offloadTelemetry = false;
            offloadArtifacts = false;
            sizeThresholdKB = 64;
            artifactsStore = 'ContentVersion';
            schemaStore = 'PlatformCache';
            telemetryStore = 'ContentVersion';
        }
    }

    public class Ref {
        @AuraEnabled public String store; // 'PlatformCache' | 'ContentVersion'
        @AuraEnabled public String key;   // provider-specific key (e.g., cache key or ContentVersion Id)
        @AuraEnabled public Integer sizeBytes;
    }
}

