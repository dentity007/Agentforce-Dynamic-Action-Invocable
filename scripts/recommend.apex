// Quick Step-2 runner
// Set `scenario` to 0..3 to test specific narratives, or set runAll=true.
Integer scenario = 0; // 0: Case escalation, 1: Lead, 2: Opp Closed Lost, 3: Case follow-up task
Boolean runAll = false;

List<String> narratives = new List<String>{
    'For P1 customer issues, escalate the case to Tier 2 and set priority to High.',
    'When an SDR qualifies interest, move the lead to Qualified and set rating to Hot.',
    'If negotiations fail, mark the opportunity Closed Lost and capture a short loss reason.',
    'After resolving the issue, create a follow-up task on the case for a satisfaction call.'
};

List<String> includeObjects = new List<String>{'Case','Task','Lead','Opportunity'};

if (runAll) {
    for (Integer i = 0; i < narratives.size(); i++) {
        String n = narratives[i];
        System.debug('\n=== Scenario ' + i + ' ===\n' + n);
        RecommendFunctionalities.Response r = RecommendFunctionalities.run(n, includeObjects, 3);
        System.debug(JSON.serializePretty(r));
    }
} else {
    Integer idx = Math.max(0, Math.min(scenario, narratives.size() - 1));
    String narrative = narratives[idx];
    RecommendFunctionalities.Response r = RecommendFunctionalities.run(narrative, includeObjects, 3);
    System.debug(JSON.serializePretty(r));
}
