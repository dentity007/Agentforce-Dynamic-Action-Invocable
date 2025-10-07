# LLM Integration Guide

Agentforce Dynamic Action ships with a stubbed LLM client (`LLMClientGateway.StubLLMClient`) so you can run locally without network calls. To connect a real provider, implement the `LLMClientGateway.LLMClient` interface.

## Quick Start with OpenAI

The repository includes a production-ready OpenAI client:

1. **Deploy the Named Credential**:
   - `force-app/main/default/namedCredentials/LLM_Provider.namedCredential-meta.xml` is configured for OpenAI
   - In Salesforce Setup → Named Credentials → LLM_Provider, add:
     - **Header Name**: `Authorization`
     - **Header Value**: `Bearer YOUR_OPENAI_API_KEY`

2. **Register the client**:
   ```bash
   sf apex run -o dynamicAction -f scripts/register-llm.apex
   ```
   This registers `OpenAIClient('gpt-4o-mini')` which uses the Chat Completions API.

3. **Test the integration**:
   ```bash
   sf apex run -o dynamicAction -f scripts/recommend.apex
   ```
   Should now return LLM-ranked recommendations instead of heuristic-only results.

## OpenAI Client Implementation

The included `OpenAIClient.cls` implements the interface using OpenAI's Chat Completions API:

```apex
public with sharing class OpenAIClient implements LLMClientGateway.LLMClient {
    private String model;
    
    public OpenAIClient(String modelName) { 
        this.model = modelName; 
    }

    public String complete(LLMClientGateway.LLMRequest request) {
        // Uses callout:LLM_Provider Named Credential
        // Formats request as Chat Completions API
        // Returns parsed response content
    }
}
```

**Supported Models**: `gpt-4o-mini` (default, cost-effective), `gpt-4.1` (higher quality), or any OpenAI model.

**Azure OpenAI**: Update the Named Credential endpoint to your Azure resource and adjust the API path accordingly.

## Interface

```apex
public interface LLMClient {
    String complete(LLMClientGateway.LLMRequest request);
}
```

Each request contains:
- `prompt` – Fully rendered prompt string produced by `PromptLibrary`.
- `model` – Default `gpt-4o-mini`; override via `constraints.put('model', 'your-model-id')`.
- `temperature` / `maxTokens` – Tunable generation parameters.
- `metadata` – Map containing the original goal and optional schema slice for logging/telemetry.

## Implementation Steps

1. **Create a service class** implementing `LLMClient`. Example skeleton:
   ```apex
   public with sharing class VertexLLMClient implements LLMClientGateway.LLMClient {
       public String complete(LLMClientGateway.LLMRequest request) {
           // Callout to external LLM endpoint
           HttpRequest http = new HttpRequest();
           http.setMethod('POST');
           http.setEndpoint('callout:VertexAI');
           http.setBody(JSON.serialize(new Map<String, Object>{
               'model' => request.model,
               'prompt' => request.prompt,
               'temperature' => request.temperature,
               'maxOutputTokens' => request.maxTokens
           }));
           HttpResponse res = new Http().send(http);
           return res.getBody();
       }
   }
   ```

2. **Register the client** during org setup (e.g., custom metadata, setup script, or initialization block):
   ```apex
   LLMClientGateway.register(new VertexLLMClient());
   ```

3. **Normalize response JSON** to match the blueprint contract. If the provider returns text, ensure the string contains strictly JSON as described in `docs/blueprint-contract.md`. Consider adding:
   - JSON sanitization (strip markdown, code fences)
   - Retry logic for malformed responses
   - Telemetry logging of prompts/responses

## Prompt Customization

`PromptLibrary.blueprintPrompt` is the single source of truth for the blueprint request. Customize it to include:
- Schema annotations (field descriptions, picklist values)
- Compliance policies (fields requiring encryption)
- Example blueprints showing desired output shape

Version prompts in metadata or custom settings so experimentation doesn’t require code changes.

## Telemetry & Monitoring

Track prompt/response pairs to a custom object for observability:
- Goal, schema slice digest, model ID
- LLM latency, token counts, cost (if available)
- Post-generation validation results (parse success, guardrail failures)

Telemetry helps build feedback loops to improve prompt engineering and identify hallucinations early.

## Named Credential Quick Start

1. Deploy `namedCredentials/LLM_Provider.namedCredential-meta.xml`.
2. Update the endpoint/credential on the Named Credential in Setup.
3. Implement an `LLMClientGateway.LLMClient` that issues callouts via the Named Credential:
   ```apex
   HttpRequest req = new HttpRequest();
   req.setEndpoint('callout:LLM_Provider');
   req.setMethod('POST');
   // add body / headers
   ```
