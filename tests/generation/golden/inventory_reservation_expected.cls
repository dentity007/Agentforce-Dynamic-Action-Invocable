public with sharing class DynamicAction_CreateInventoryReservationTask implements InvocableActionFactory.IAction {
    public PlanModels.OrchestratorResult execute(Map<String, Object> payload) {
        // ... generated content omitted ...
        Database.insert(record, false);
        res.logs.add('Created a high priority Task to trigger inventory follow-up.');
        return res;
    }
}
