@IsTest
private class GenerationBenchmark_Test {
    @IsTest
    static void runBenchmarkProducesResults() {
        List<GenerationBenchmark.CaseResult> results = GenerationBenchmark.run();
        System.assert(results.size() >= 2, 'Expected at least two evaluation cases.');
        for (GenerationBenchmark.CaseResult res : results) {
            System.assertNotEquals(null, res.name, 'Case name should be populated.');
            System.assertNotEquals(null, res.blueprintMatches, 'Blueprint comparison should run.');
            System.assertNotEquals(null, res.classAssertionsPassed, 'Code assertions should run.');
            System.assertNotEquals(null, res.testAssertionsPassed, 'Test assertions should run.');
        }
    }

    @IsTest
    static void summarizeReturnsHumanReadableReport() {
        String report = GenerationBenchmark.summarize();
        System.assert(report.contains('Opportunity Stage Update'), 'Report should include case names.');
    }
}
