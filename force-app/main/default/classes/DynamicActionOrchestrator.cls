public with sharing class DynamicActionOrchestrator {
    @AuraEnabled
    public static PlanModels.OrchestratorResult run(PlanModels.Plan plan, Map<String, Object> userInputs, Boolean confirmed) {
        PlanModels.OrchestratorResult result = PlanModels.newResult();
        if (plan == null || plan.actions == null || plan.actions.isEmpty()) {
            result.errors.add('No actions available to execute.');
            return result;
        }
        if (confirmed == false) {
            result.warnings.add('Execution halted: user confirmation required.');
            return result;
        }

        for (PlanModels.ActionBlueprint blueprint : plan.actions) {
            if (blueprint == null) {
                continue;
            }
            Map<String, Object> actionInput = (userInputs != null && userInputs.containsKey(blueprint.name))
                ? (Map<String, Object>) userInputs.get(blueprint.name)
                : new Map<String, Object>();

            InvocableActionFactory.IAction action = InvocableActionFactory.resolve(blueprint.name);
            PlanModels.OrchestratorResult step = action.execute(actionInput);
            if (step == null || step.success == false) {
                if (step != null) {
                    if (step.errors != null) result.errors.addAll(step.errors);
                    if (step.warnings != null) result.warnings.addAll(step.warnings);
                    if (step.logs != null) result.logs.addAll(step.logs);
                } else {
                    result.errors.add('Action returned null result: ' + blueprint.name);
                }
                result.success = false;
                return result;
            }
            if (step.logs != null) result.logs.addAll(step.logs);
            if (step.warnings != null) result.warnings.addAll(step.warnings);
        }

        result.success = true;
        return result;
    }
}
