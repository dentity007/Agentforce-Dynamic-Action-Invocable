public with sharing class HeuristicBlueprintFactory {
    public static List<PlanModels.ActionBlueprint> fromGoal(String goal) {
        String normalized = (goal == null) ? '' : goal.toLowerCase();
        List<PlanModels.ActionBlueprint> results = new List<PlanModels.ActionBlueprint>();
        if (normalized.contains('inventory') || normalized.contains('stock')) {
            results.add(inventoryReservation());
            return results;
        }
        if (normalized.contains('lead')) {
            results.add(leadQualification());
            return results;
        }
        results.add(opportunityStageUpdate());
        return results;
    }

    private static PlanModels.ActionBlueprint opportunityStageUpdate() {
        PlanModels.ActionBlueprint bp = new PlanModels.ActionBlueprint();
        bp.name = 'UpdateOpportunityStage';
        bp.label = 'Update Opportunity Stage';
        bp.category = 'DOMAIN';
        bp.targetSObject = 'Opportunity';
        bp.operation = 'UPDATE';
        bp.summary = 'Updated Opportunity stage based on agent directive.';
        bp.keyFields.add('Id');
        bp.checkpoint = 'I will update the Opportunity stage. Proceed?';

        bp.inputs.add(requiredInput('Id', 'Id', 'Opportunity Id', 'Id'));
        bp.inputs.add(requiredInput('StageName', 'StageName', 'New Stage', 'String'));
        bp.inputs.add(optionalInput('CloseDate', 'CloseDate', 'Close Date', 'Date'));

        PlanModels.Guardrail guardrail = new PlanModels.Guardrail();
        guardrail.type = 'FLS_EDIT';
        guardrail.params = new Map<String, Object>{'fields' => new List<String>{'Id', 'StageName', 'CloseDate'}};
        bp.guardrails.add(guardrail);

        return bp;
    }

    private static PlanModels.ActionBlueprint inventoryReservation() {
        PlanModels.ActionBlueprint bp = new PlanModels.ActionBlueprint();
        bp.name = 'CreateInventoryReservationTask';
        bp.label = 'Create Inventory Reservation Task';
        bp.category = 'DOMAIN';
        bp.targetSObject = 'Task';
        bp.operation = 'INSERT';
        bp.summary = 'Created a high priority Task to trigger inventory follow-up.';
        bp.checkpoint = 'I will log a Task to request inventory reservation. Proceed?';

        bp.inputs.add(requiredInput('Subject', 'Subject', 'Task Subject', 'String'));
        bp.inputs.add(requiredInput('Product2Id', 'WhatId', 'Product Reference', 'Id'));
        bp.inputs.add(requiredInput('Quantity__c', 'Quantity__c', 'Requested Quantity', 'Decimal'));
        bp.inputs.add(optionalInput('Description', 'Description', 'Task Notes', 'String'));

        PlanModels.Guardrail qtyGuard = new PlanModels.Guardrail();
        qtyGuard.type = 'NUMERIC_POSITIVE';
        qtyGuard.params = new Map<String, Object>{'field' => 'Quantity__c'};
        qtyGuard.message = 'Quantity must be greater than zero.';
        bp.guardrails.add(qtyGuard);

        return bp;
    }

    private static PlanModels.ActionBlueprint leadQualification() {
        PlanModels.ActionBlueprint bp = new PlanModels.ActionBlueprint();
        bp.name = 'QualifyLead';
        bp.label = 'Qualify Lead';
        bp.category = 'DOMAIN';
        bp.targetSObject = 'Lead';
        bp.operation = 'UPDATE';
        bp.summary = 'Qualified lead and updated status fields.';
        bp.keyFields.add('Id');
        bp.checkpoint = 'I will qualify the lead and update its status. Proceed?';

        bp.inputs.add(requiredInput('Id', 'Id', 'Lead Id', 'Id'));
        bp.inputs.add(requiredInput('Status', 'Status', 'Lead Status', 'String'));
        bp.inputs.add(optionalInput('Rating', 'Rating', 'Lead Rating', 'String'));

        PlanModels.Guardrail guardrail = new PlanModels.Guardrail();
        guardrail.type = 'FLS_EDIT';
        guardrail.params = new Map<String, Object>{'fields' => new List<String>{'Id', 'Status', 'Rating'}};
        bp.guardrails.add(guardrail);

        PlanModels.Guardrail statusGuard = new PlanModels.Guardrail();
        statusGuard.type = 'ENUM_ALLOWED';
        statusGuard.params = new Map<String, Object>{
            'field' => 'Status',
            'values' => new List<String>{'New', 'Working', 'Qualified', 'Unqualified'}
        };
        bp.guardrails.add(statusGuard);

        return bp;
    }

    private static PlanModels.ActionInput requiredInput(String apiName, String fieldApiName, String label, String dataType) {
        PlanModels.ActionInput input = new PlanModels.ActionInput();
        input.apiName = apiName;
        input.fieldApiName = fieldApiName;
        input.label = label;
        input.dataType = dataType;
        input.required = true;
        input.usage = 'FIELD';
        return input;
    }

    private static PlanModels.ActionInput optionalInput(String apiName, String fieldApiName, String label, String dataType) {
        PlanModels.ActionInput input = requiredInput(apiName, fieldApiName, label, dataType);
        input.required = false;
        return input;
    }
}
