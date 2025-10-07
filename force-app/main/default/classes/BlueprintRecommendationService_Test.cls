@IsTest
private class BlueprintRecommendationService_Test {
    @IsTest
    static void recommendBlendsCuratedAndLlm() {
        Map<String, Object> schema = new Map<String, Object>();
        schema.put('objects', new List<Object>{
            new Map<String, Object>{
                'apiName' => 'Opportunity',
                'fields' => new List<Object>{ new Map<String, Object>{'apiName' => 'StageName'} }
            }
        });
        BlueprintRecommendationService.RecommendationResponse response = BlueprintRecommendationService.recommend('Update opportunity stage', schema, null);
        System.assert(response.recommendations.size() > 0, 'Expected recommendations.');
        Boolean hasCurated = false;
        for (PlanModels.Recommendation rec : response.recommendations) {
            if (rec.source == 'CURATED') {
                hasCurated = true;
                System.assert(rec.tags.contains('sales'), 'Curated recommendation should retain tags.');
            }
        }
        System.assert(hasCurated, 'Recommendations should include curated library entries.');
    }
}
