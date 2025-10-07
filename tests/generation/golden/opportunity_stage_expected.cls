public with sharing class DynamicAction_UpdateOpportunityStage implements InvocableActionFactory.IAction {
    public PlanModels.OrchestratorResult execute(Map<String, Object> payload) {
        // ... generated content omitted ...
        Database.update(record, false);
        res.logs.add('Updated Opportunity stage based on agent directive.');
        return res;
    }
}
