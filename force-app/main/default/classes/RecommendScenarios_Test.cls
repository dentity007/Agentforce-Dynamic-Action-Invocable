@IsTest
private class RecommendScenarios_Test {
    @IsTest static void scenario0_caseEscalation_hasRecommendations() {
        String n = 'For P1 customer issues, escalate the case to Tier 2 and set priority to High.';
        List<String> objs = new List<String>{'Case','Task','Lead','Opportunity'};
        RecommendFunctionalities.Response r = RecommendFunctionalities.run(n, objs, 3);
        System.assertNotEquals(null, r, 'Response should not be null');
        System.assertNotEquals(null, r.recommendations, 'Recommendations should not be null');
        System.assert(r.recommendations.size() > 0, 'Should return at least one recommendation');
    }

    @IsTest static void scenario1_leadQualified_hasRecommendations() {
        String n = 'When an SDR qualifies interest, move the lead to Qualified and set rating to Hot.';
        List<String> objs = new List<String>{'Case','Task','Lead','Opportunity'};
        RecommendFunctionalities.Response r = RecommendFunctionalities.run(n, objs, 3);
        System.assert(r.recommendations.size() > 0, 'Should return at least one recommendation');
    }

    @IsTest static void scenario2_opportunityClosedLost_hasRecommendations() {
        String n = 'If negotiations fail, mark the opportunity Closed Lost and capture a short loss reason.';
        List<String> objs = new List<String>{'Case','Task','Lead','Opportunity'};
        RecommendFunctionalities.Response r = RecommendFunctionalities.run(n, objs, 3);
        System.assert(r.recommendations.size() > 0, 'Should return at least one recommendation');
    }

    @IsTest static void scenario3_caseFollowupTask_hasRecommendations() {
        String n = 'After resolving the issue, create a follow-up task on the case for a satisfaction call.';
        List<String> objs = new List<String>{'Case','Task','Lead','Opportunity'};
        RecommendFunctionalities.Response r = RecommendFunctionalities.run(n, objs, 3);
        System.assert(r.recommendations.size() > 0, 'Should return at least one recommendation');
    }
}

