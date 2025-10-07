// Load previous recommend json from a Custom Setting, or just re-call recommend here for simplicity:
String narrative = 'For AAA insurance sales, when a deal is approved, set the opportunity to Closed Won.';
List<String> includeObjects = new List<String>{'Opportunity'};
RecommendFunctionalities.Response r = RecommendFunctionalities.run(narrative, includeObjects, 1);

PlanModels.ActionBlueprint bp = r.recommendations.isEmpty() ? null : r.recommendations[0].blueprint;
DynamicActionPipeline.Result result = DynamicActionPipeline.executeFromBlueprint(
    bp,
    null,  // schema slice (optional)
    null   // constraints (optional)
);
System.debug(JSON.serialize(result));
