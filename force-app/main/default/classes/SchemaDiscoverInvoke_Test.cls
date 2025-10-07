@IsTest
private class SchemaDiscoverInvoke_Test {
    @IsTest
    static void runReturnsSchemaSnapshot() {
        SchemaDiscoverInvoke.Request req = new SchemaDiscoverInvoke.Request();
        req.includeObjectsCsv = 'Account, Contact';
        req.maxFieldsPerObject = 5;

        Test.startTest();
        List<SchemaDiscoverInvoke.Response> responses = SchemaDiscoverInvoke.run(new List<SchemaDiscoverInvoke.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return a response per request');
        SchemaDiscoverInvoke.Response resp = responses[0];
        System.assertEquals(true, resp.ok, 'Schema discovery should succeed');
        System.assertNotEquals(null, resp.snapshotJson, 'Snapshot JSON should be returned');
        System.assert(resp.snapshotJson.contains('Account'), 'Snapshot should include Account when requested');
        System.assert(resp.snapshotJson.contains('requestedMaxFieldsPerObject'), 'Snapshot JSON should note requested field limit');
    }

    @IsTest
    static void runHandlesNullRequest() {
        Test.startTest();
        List<SchemaDiscoverInvoke.Response> responses = SchemaDiscoverInvoke.run(new List<SchemaDiscoverInvoke.Request>{ null });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return response placeholder even for null request');
        SchemaDiscoverInvoke.Response resp = responses[0];
        System.assertEquals(false, resp.ok, 'Null request should be marked as failure');
        System.assertEquals('Request payload was null', resp.message);
    }
}
