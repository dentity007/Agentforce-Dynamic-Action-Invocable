public with sharing class OpenAIClient implements LLMClientGateway.LLMClient {
    private String model;
    public OpenAIClient(String modelName) { this.model = modelName; }

    // Minimal "complete" — used by your Step-2 ranker and Step-3 synthesis
    public String complete(LLMClientGateway.LLMRequest request) {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        // Named Credential defined as "LLM_Provider"
        // OpenAI chat completions:
        req.setEndpoint('callout:LLM_Provider/v1/chat/completions');
        req.setHeader('Content-Type','application/json');

        // OpenAI payload (chat style). For Azure OpenAI, change "model" to your deployment name and endpoint accordingly.
        Map<String,Object> body = new Map<String,Object>{
            'model' => model,
            'messages' => new List<Object>{
                new Map<String,Object>{ 'role' => 'system', 'content' => 'You are a precise Salesforce Apex code planner and generator.' },
                new Map<String,Object>{ 'role' => 'user',   'content' => request.prompt }
            },
            'temperature' => request.temperature,
            'max_tokens' => request.maxTokens
        };
        req.setBody(JSON.serialize(body));

        Http h = new Http();
        HTTPResponse res = h.send(req);
        if (res.getStatusCode() >= 300) {
            throw new CalloutException('LLM error ' + res.getStatus() + ': ' + res.getBody());
        }
        Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> choices = (List<Object>) parsed.get('choices');
        if (choices == null || choices.isEmpty()) return '';
        Map<String,Object> first = (Map<String,Object>) choices[0];
        Map<String,Object> msg = (Map<String,Object>) first.get('message');
        return (String) msg.get('content');
    }
}