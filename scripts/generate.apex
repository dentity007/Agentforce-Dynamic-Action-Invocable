String CLASS_META_TEMPLATE = '<?xml version="1.0" encoding="UTF-8"?>\n'
    + '<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">\n'
    + '    <apiVersion>64.0</apiVersion>\n'
    + '    <status>Active</status>\n'
    + '</ApexClass>\n';

DynamicActionPipeline.Result pipeline = DynamicActionPipeline.execute(
    'Update an opportunity to Closed Won',
    null,
    null
);

Map<String, Object> files = new Map<String, Object>();
String basePath = 'force-app/main/default/classes/';
for (Map<String, String> artifact : pipeline.artifacts.apex) {
    String name = artifact.get('name');
    String body = artifact.get('content');
    if (String.isBlank(name) || body == null) continue;
    files.put(basePath + name + '.cls', body);
    files.put(basePath + name + '.cls-meta.xml', CLASS_META_TEMPLATE);
}
for (Map<String, String> artifact : pipeline.artifacts.tests) {
    String name = artifact.get('name');
    String body = artifact.get('content');
    if (String.isBlank(name) || body == null) continue;
    files.put(basePath + name + '.cls', body);
    files.put(basePath + name + '.cls-meta.xml', CLASS_META_TEMPLATE);
}

Map<String, Object> output = new Map<String, Object>();
output.put('result', pipeline);
output.put('artifacts', files);

System.debug(JSON.serialize(output));
