public with sharing class LLMClientGateway {
    public interface LLMClient {
        String complete(LLMRequest request);
    }

    public class LLMRequest {
        public String prompt;
        public String model;
        public Decimal temperature;
        public Integer maxTokens;
        public Map<String, Object> metadata;

        public LLMRequest() {
            metadata = new Map<String, Object>();
            temperature = 0.15;
            maxTokens = 1024;
        }
    }

    private static LLMClient registeredClient;

    public static void register(LLMClient client) {
        registeredClient = client;
    }

    public static Boolean isRegistered() {
        return registeredClient != null;
    }

    public static LLMClient resolve() {
        if (registeredClient != null) {
            return registeredClient;
        }
        return new StubLLMClient();
    }

    private class StubLLMClient implements LLMClient {
        public String complete(LLMRequest request) {
            String goal = (request != null && request.metadata != null && request.metadata.containsKey('goal'))
                ? String.valueOf(request.metadata.get('goal'))
                : '';
            List<PlanModels.ActionBlueprint> defaults = HeuristicBlueprintFactory.fromGoal(goal);
            Map<String, Object> payload = new Map<String, Object>();
            List<Object> actions = new List<Object>();
            for (PlanModels.ActionBlueprint bp : defaults) {
                actions.add(JSON.deserializeUntyped(JSON.serialize(bp)));
            }
            payload.put('actions', actions);
            return JSON.serialize(payload);
        }
    }
}
