public with sharing class BlueprintSynthesisService {
    public static List<PlanModels.ActionBlueprint> buildBlueprints(String goal, Map<String, Object> schemaSlice, Map<String, Object> constraints) {
        String prompt = PromptLibrary.blueprintPrompt(goal, schemaSlice, constraints);
        LLMClientGateway.LLMRequest request = new LLMClientGateway.LLMRequest();
        request.prompt = prompt;
        request.model = (constraints != null && constraints.containsKey('model'))
            ? String.valueOf(constraints.get('model'))
            : 'gpt-4o-mini';
        request.metadata.put('goal', goal);
        if (schemaSlice != null) {
            request.metadata.put('schema', schemaSlice);
        }

        List<PlanModels.ActionBlueprint> blueprints = new List<PlanModels.ActionBlueprint>();
        try {
            String response = LLMClientGateway.resolve().complete(request);
            blueprints = parseResponse(response);
        } catch (Exception e) {
            // swallow and fall back to heuristics
        }

        if (blueprints.isEmpty()) {
            blueprints = HeuristicBlueprintFactory.fromGoal(goal);
        }
        return blueprints;
    }

    private static List<PlanModels.ActionBlueprint> parseResponse(String response) {
        List<PlanModels.ActionBlueprint> results = new List<PlanModels.ActionBlueprint>();
        if (String.isBlank(response)) {
            return results;
        }
        String trimmed = response.trim();
        String jsonPayload = extractJsonPayload(trimmed);
        if (String.isBlank(jsonPayload)) {
            return results;
        }
        try {
            Object parsed = JSON.deserializeUntyped(jsonPayload);
            if (parsed instanceof List<Object>) {
                for (Object entry : (List<Object>) parsed) {
                    results.add(toBlueprint(entry));
                }
                return results;
            }
            if (parsed instanceof Map<String, Object>) {
                Map<String, Object> mapPayload = (Map<String, Object>) parsed;
                if (mapPayload.containsKey('actions')) {
                    Object actionObj = mapPayload.get('actions');
                    if (actionObj instanceof List<Object>) {
                        for (Object entry : (List<Object>) actionObj) {
                            results.add(toBlueprint(entry));
                        }
                    }
                } else {
                    results.add(toBlueprint(mapPayload));
                }
            }
        } catch (Exception e) {
            // ignore and fall back
        }
        return results;
    }

    private static String extractJsonPayload(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        Integer objStart = raw.indexOf('{');
        Integer objEnd = raw.lastIndexOf('}');
        Integer arrStart = raw.indexOf('[');
        Integer arrEnd = raw.lastIndexOf(']');
        if (arrStart != -1 && arrEnd > arrStart) {
            return raw.substring(arrStart, arrEnd + 1);
        }
        if (objStart != -1 && objEnd > objStart) {
            return raw.substring(objStart, objEnd + 1);
        }
        return null;
    }

    private static PlanModels.ActionBlueprint toBlueprint(Object entry) {
        if (entry == null) {
            return null;
        }
        String json = JSON.serialize(entry);
        return (PlanModels.ActionBlueprint) JSON.deserialize(json, PlanModels.ActionBlueprint.class);
    }
}
