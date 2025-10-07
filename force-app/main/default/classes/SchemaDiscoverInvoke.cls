public with sharing class SchemaDiscoverInvoke {
    public class Request {
        @InvocableVariable public String includeObjectsCsv;
        @InvocableVariable public Integer maxFieldsPerObject;
    }

    public class Response {
        @InvocableVariable public Boolean ok;
        @InvocableVariable public String snapshotJson;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Data-Aware: Discover Schema')
    public static List<Response> run(List<Request> batch) {
        List<Response> results = new List<Response>();
        if (batch == null) {
            return results;
        }

        for (Request req : batch) {
            Response resp = new Response();
            if (req == null) {
                resp.ok = false;
                resp.message = 'Request payload was null';
                results.add(resp);
                continue;
            }
            try {
                Set<String> includeObjects = new Set<String>();
                if (!String.isBlank(req.includeObjectsCsv)) {
                    for (String token : req.includeObjectsCsv.split('\s*,\s*')) {
                        if (!String.isBlank(token)) {
                            includeObjects.add(token.trim());
                        }
                    }
                }

                SchemaSnapshotService.Options options = new SchemaSnapshotService.Options();
                if (req.maxFieldsPerObject != null && req.maxFieldsPerObject > 0) {
                    options.maxFieldsPerObject = req.maxFieldsPerObject;
                }

                SchemaSnapshot snapshot = SchemaSnapshot.buildSnapshot(includeObjects.isEmpty() ? null : includeObjects);
                Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(snapshot));
                if (req.maxFieldsPerObject != null && req.maxFieldsPerObject > 0) {
                    payload.put('requestedMaxFieldsPerObject', req.maxFieldsPerObject);
                }

                resp.ok = true;
                resp.snapshotJson = JSON.serialize(payload);
                resp.message = 'Schema discovered';
            } catch (Exception ex) {
                resp.ok = false;
                resp.message = ex.getMessage();
            }
            results.add(resp);
        }
        return results;
    }
}
