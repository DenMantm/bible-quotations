# GitHub Copilot Instructions for n8n Workflow Development

## Project Context
This repository contains n8n workflow automation projects, primarily focused on AI-powered content generation and multi-platform publishing.

## Critical n8n Workflow Editing Rules

### 1. File Encoding (CRITICAL)
**ALWAYS use Node.js for editing n8n JSON workflow files. NEVER use PowerShell or Python directly.**

**Why**: n8n workflow files contain:
- UTF-8 BOM (Byte Order Mark: `ef bb bf`)
- Unicode characters (emojis in node names: 📱, 🎨, ✅)
- Curly quotes in JSON keys ('')
- PowerShell and Python corrupt these characters

**Correct Approach**:
```javascript
const fs = require('fs');

// Read with BOM handling
let content = fs.readFileSync('workflow.json', 'utf8');
if (content.charCodeAt(0) === 0xFEFF) {
  content = content.slice(1);
}

// Parse, modify, and write back
const workflow = JSON.parse(content);
// ... make changes ...
fs.writeFileSync('workflow.json', 
  '\ufeff' + JSON.stringify(workflow, null, 2), 
  'utf8'
);
```

### 2. Node Reference Integrity
When renaming nodes, you MUST update ALL references in the `connections` object.

**Example Problem**:
```json
// Node renamed from "AI Agent" to "🎯 Select Spiritual Theme"
// But connection still references old name:
"connections": {
  "Some Node": {
    "main": [[{"node": "AI Agent", ...}]]  // ❌ BROKEN
  }
}
```

**Solution**:
Search entire connections object for old node name and replace with exact new name (including emojis).

**Validation Script Pattern**:
```javascript
// Find all missing node references
const nodeNames = new Set(workflow.nodes.map(n => n.name));
Object.values(workflow.connections).forEach(conn => {
  conn.main?.forEach(outputs => {
    outputs?.forEach(target => {
      if (!nodeNames.has(target.node)) {
        console.log(`Missing: ${target.node}`);
      }
    });
  });
});
```

### 3. n8n Expression Language
**Always wrap expressions in `={{ }}`**

Common patterns:
```javascript
// Access current node data
={{ $json.fieldName }}

// Access specific node's first item
={{ $('Node Name').first().json.fieldName }}

// Access specific node's current item (in loops)
={{ $('Node Name').item.json.fieldName }}

// Conditional with fallback
={{ $json.photo ? $json.photo[0].file_id : '' }}

// String concatenation
={{ 'Prefix ' + $json.value + ' suffix' }}

// Nested access with safety
={{ $json.message?.chat?.id || 'default' }}
```

**IMPORTANT**: Node names in expressions must match EXACTLY (including emojis):
```javascript
// ✅ Correct
={{ $('📱 User Request').first().json.chatId }}

// ❌ Wrong (missing emoji)
={{ $('User Request').first().json.chatId }}
```

### 4. Connection Structure
Connections map outputs to inputs:

```json
{
  "connections": {
    "Source Node Name": {
      "main": [           // Connection type
        [                 // Output index 0
          {
            "node": "Target Node Name",
            "type": "main",
            "index": 0    // Input index on target
          }
        ]
      ]
    }
  }
}
```

**Connection Types**:
- `main`: Standard data flow
- `ai_tool`: AI agent tools
- `ai_languageModel`: AI language models
- `ai_embedding`: Vector embeddings
- `ai_document`: Document loaders

**Multiple Outputs**:
```json
{
  "Branch Node": {
    "main": [
      [{"node": "Target1", "type": "main", "index": 0}],
      [{"node": "Target2", "type": "main", "index": 0}],
      [{"node": "Target3", "type": "main", "index": 0}]
    ]
  }
}
```

**Merge Inputs**:
```json
// Multiple sources → single merge node
{
  "Source1": {
    "main": [[{"node": "Merge", "type": "main", "index": 0}]]
  },
  "Source2": {
    "main": [[{"node": "Merge", "type": "main", "index": 1}]]
  }
}
```

### 5. Node Types Quick Reference

#### Trigger Nodes
- `n8n-nodes-base.manualTrigger`: Manual execution button
- `n8n-nodes-base.telegramTrigger`: Telegram bot events
- `n8n-nodes-base.webhook`: HTTP webhooks

#### Data Transformation
- `n8n-nodes-base.set`: Set variables, extract data
- `n8n-nodes-base.code`: Custom JavaScript/Python
- `n8n-nodes-base.merge`: Combine multiple branches

#### HTTP/API
- `n8n-nodes-base.httpRequest`: Generic HTTP requests
- `n8n-nodes-base.telegram`: Telegram API
- `n8n-nodes-base.googleSheets`: Google Sheets operations

#### AI/LLM
- `@n8n/n8n-nodes-langchain.openAi`: OpenAI GPT models
- `n8n-nodes-base.perplexity`: Perplexity AI search
- Vector stores: `@n8n/n8n-nodes-langchain.vectorStoreQdrant`

#### Utility
- `n8n-nodes-base.wait`: Pause execution
- `n8n-nodes-base.stickyNote`: Canvas documentation

### 6. Binary Data Handling

**Upload Files**:
```json
{
  "contentType": "multipart-form-data",
  "bodyParameters": {
    "parameters": [
      {
        "name": "file",
        "parameterType": "formBinaryData",
        "inputDataFieldName": "binaryFieldName"
      }
    ]
  }
}
```

**Transform Binary in Code Node**:
```javascript
return items.map(item => {
  const binary = item.binary?.fieldName;
  if (!binary) return item;
  
  // Clone with modifications
  item.binary.newField = {
    ...binary,
    fileName: 'newname.ext',
    mimeType: 'application/type'
  };
  
  return item;
});
```

**Receive as File**:
```json
{
  "options": {
    "response": {
      "response": {
        "responseFormat": "file",
        "outputPropertyName": "binaryFieldName"
      }
    }
  }
}
```

### 7. Common Patterns

#### Pattern: Configuration Node
Create Set node at start with all constants:
```json
{
  "name": "Workflow Configuration",
  "type": "n8n-nodes-base.set",
  "parameters": {
    "assignments": {
      "assignments": [
        {"name": "apiKey", "type": "string", "value": "KEY"},
        {"name": "maxItems", "type": "number", "value": 100}
      ]
    }
  }
}
```
Access: `{{ $('Workflow Configuration').first().json.apiKey }}`

#### Pattern: Async Job Processing
1. Submit → get job ID
2. Wait node (delay)
3. Poll status
4. Download result

#### Pattern: Multi-Platform Publishing
```
Prepare → Platform1 ↘
        → Platform2 → Merge → Update Status
        → Platform3 ↗
```

#### Pattern: AI Chain
```
Research AI → Script AI → Voice Synthesis → Video Generation
```

### 8. Debugging Workflows

**Missing Node References**:
- Symptom: "Could not find node X"
- Cause: Renamed node but connections not updated
- Fix: Search connections for old name, replace all occurrences

**Expression Errors**:
- Symptom: "Cannot read property of undefined"
- Cause: Accessing non-existent nested property
- Fix: Add optional chaining or conditionals

**Binary Data Not Found**:
- Symptom: "Binary data X not found"
- Cause: Wrong field name or not passed through
- Fix: Check binary field names, ensure previous node outputs binary

**Credential Errors**:
- Symptom: "Credentials not found"
- Cause: Credential ID doesn't exist in instance
- Fix: Re-add credentials in UI, update IDs in JSON

### 9. Development Workflow

1. **Before Editing**:
   - Check file encoding (UTF-8 with BOM)
   - List all node names
   - Identify connection dependencies

2. **During Editing**:
   - Use Node.js for all JSON manipulation
   - Preserve UTF-8 BOM
   - Update connections when renaming nodes

3. **After Editing**:
   - Validate JSON syntax
   - Check all node references exist
   - Test expressions
   - Verify binary field names
   - Test workflow in n8n UI

4. **Version Control**:
   - Remove credential IDs (replace with placeholders)
   - Commit with descriptive messages
   - Use branches for major features

### 10. Code Node Best Practices

**Return Format**:
```javascript
// MUST return array of items
return items.map(item => {
  // Modify item.json for data
  item.json.newField = 'value';
  
  // Modify item.binary for files
  item.binary.newFile = { /* binary data */ };
  
  return item;
});
```

**Access Previous Data**:
```javascript
// Current node's input
const data = $input.all();

// Specific node's data
const config = $('Workflow Configuration').first().json;
```

**Error Handling**:
```javascript
return items.map(item => {
  try {
    // Process item
    return item;
  } catch (error) {
    item.json.error = error.message;
    return item;
  }
});
```

### 11. Credentials Management

**Never hardcode in JSON**:
```json
// ❌ Bad
{"apiKey": "sk-1234567890"}

// ✅ Good - reference credential
{
  "credentials": {
    "openAiApi": {
      "id": "credential-id",
      "name": "OpenAI Production"
    }
  }
}

// ✅ Good - reference config node
{"apiKey": "={{ $('Workflow Configuration').first().json.apiKey }}"}
```

### 12. Visual Organization

**Node Naming**:
- Use descriptive names: "Generate Script with GPT-4" not "AI1"
- Add emojis for grouping: 📱 Triggers, 🤖 AI, 🎨 Media, 📤 Output
- Keep names under 50 characters

**Canvas Layout**:
- Flow left-to-right: Trigger → Process → Output
- Branches top-to-bottom
- Use sticky notes for sections
- Align nodes on grid
- Space 200-400 pixels apart

**Sticky Notes**:
```json
{
  "type": "n8n-nodes-base.stickyNote",
  "parameters": {
    "color": 4,
    "width": 400,
    "height": 300,
    "content": "# Markdown Documentation\n\nExplain complex logic here"
  }
}
```

### 13. MCP (Model Context Protocol) Integration

**MCP Client Tool** (`@n8n/n8n-nodes-langchain.mcpClientTool`):
Connect AI agents to MCP servers as tools.

```json
{
  "type": "@n8n/n8n-nodes-langchain.mcpClientTool",
  "name": "Gmail MCP",
  "parameters": {
    "endpointUrl": "https://n8n.example.com/mcp/gmail-mcp/sse"
  }
}
```

**Connection**: Link to AI agent via `ai_tool` connection type.

**MCP Server Trigger** (`@n8n/n8n-nodes-langchain.mcpTrigger`):
Expose n8n workflow as MCP server endpoint.

```json
{
  "type": "@n8n/n8n-nodes-langchain.mcpTrigger",
  "name": "Gmail MCP Server",
  "webhookId": "unique-webhook-id",
  "parameters": {
    "path": "unique-webhook-id"
  }
}
```

**MCP Use Cases**:
- **Productivity Agents**: Connect to Gmail, Calendar, Tasks, Sheets
- **Custom Tools**: Expose any n8n workflow as AI tool
- **Server Pattern**: Trigger → Tool Nodes → Response
- **Client Pattern**: AI Agent + MCP Client Tools

**Example MCP Endpoints**:
```
/mcp/gmail-mcp/sse        → Email management
/mcp/calendar-mcp/sse     → Calendar operations
/mcp/task-mcp/sse         → Task management
/mcp/finance-mcp/sse      → Finance tracking
```

**Memory Integration**:
Combine MCP with memory nodes for stateful conversations:

```json
{
  "type": "@n8n/n8n-nodes-langchain.memoryBufferWindow",
  "parameters": {
    "sessionKey": "={{ $json.message.chat.username }}",
    "sessionIdType": "customKey"
  }
}
```

## Project-Specific Knowledge

### Bible Quotations Workflow
- **File**: `bible-agent/Bible Quotations.json`
- **Purpose**: Generate multilingual biblical social media posts
- **Key Features**:
  - English CSB Bible (Qdrant: "my-collection")
  - Russian Synodal Bible (Qdrant: "russian-bible-collection")
  - Image generation with natural text integration
  - Irish liturgical calendar integration
  - Telegram bot interface

### TikTok Creator Workflow
- **Purpose**: Automated viral TikTok video creation
- **Flow**: Photo + Theme → Trends → Script → Voice → Video → Multi-platform publish
- **APIs**: Telegram, Perplexity, OpenAI, ElevenLabs, FAL.ai (VEED), Blotato
- **Output**: 9 social platforms simultaneously

### Sample Workflow Architectures

**Productivity Agent (Jarvis Template)**:
- **Architecture**: MCP client/server with 4 external tools
- **Trigger**: Telegram bot with voice transcription (Whisper)
- **Memory**: Session-based window memory per user
- **Tools**: Gmail (read/send), Calendar (CRUD), Tasks (management), Finance (Google Sheets)
- **Pattern**: Conversational AI agent with tool execution

**YouTube Shorts Factory**:
- **Architecture**: 4-stage pipeline (Ideation → Audio → Assembly → Distribution)
- **Trigger**: Schedule trigger (automated, recurring)
- **Audio**: ElevenLabs TTS with configurable voices
- **Video**: Seedance video assembly API
- **Distribution**: YouTube Data API upload
- **Pattern**: Fully autonomous content creation pipeline

**Social Media Content Factory**:
- **Architecture**: Multi-stage AI chain with parallel publishing
- **Stages**: Research → Script → Voice → Video → Publish
- **Publishing**: 9 platforms simultaneously (TikTok, Instagram, Facebook, Twitter, LinkedIn, Pinterest, YouTube, Threads, Telegram)
- **Pattern**: Fan-out publishing with platform-specific formatting

**RAG WhatsApp Chatbot**:
- **Architecture**: Knowledge Base Agent with vector retrieval
- **Trigger**: WhatsApp message webhook
- **Memory**: Persistent conversation context
- **Knowledge**: Vector store integration for domain-specific responses
- **Pattern**: RAG (Retrieval-Augmented Generation) for support

**Auto Service Social Media**:
- **Architecture**: Industry-specific variant of content factory
- **Customization**: Auto repair/service industry prompts and branding
- **Pattern**: Template-based workflow specialization

## Common Tasks

### Add New Node
1. Generate unique UUID for `id`
2. Set `name`, `type`, `position`
3. Configure `parameters`
4. Add credentials if needed
5. Update `connections` for inputs/outputs

### Rename Node
1. Update `name` in nodes array
2. Find all references in `connections` object
3. Replace old name with exact new name (including emojis)
4. Validate no missing references

### Add AI Agent
1. Create AI agent node
2. Configure system message
3. Add tool connections (ai_tool)
4. Add model connection (ai_languageModel)
5. Connect to workflow (main)

### Add Vector Store
1. Create vector store node (Qdrant, Pinecone, etc.)
2. Add embedding model connection (ai_embedding)
3. Add document loader connections (ai_document)
4. Connect to AI agent as tool

## Testing Guidelines

1. **Expression Testing**: Test in n8n expression editor before adding to JSON
2. **Node Testing**: Test individual nodes with pinned data
3. **Branch Testing**: Test each branch independently
4. **Integration Testing**: Test full workflow end-to-end
5. **Error Testing**: Test failure scenarios and error handling

## Performance Tips

1. **Parallelize**: Use multiple output branches for independent operations
2. **Batch**: Process multiple items together instead of loops
3. **Cache**: Store frequently accessed data in Set nodes
4. **Limit**: Set reasonable limits on API calls and iterations
5. **Wait Wisely**: Use Wait nodes only when necessary

## Security Checklist

- [ ] No hardcoded API keys in JSON
- [ ] Credentials use credential system or config nodes
- [ ] Sensitive data removed before git commits
- [ ] User inputs sanitized before AI/API calls
- [ ] Webhook endpoints have authentication
- [ ] Error messages don't leak sensitive data

## Resources

- **n8n Documentation**: https://docs.n8n.io/
- **Expression Reference**: https://docs.n8n.io/code-examples/expressions/
- **Node Documentation**: https://docs.n8n.io/integrations/builtin/
- **Community Nodes**: https://www.npmjs.com/search?q=n8n-nodes

## Quick Commands

### Validate Node References
```javascript
node -e "const w=JSON.parse(require('fs').readFileSync('workflow.json','utf8').replace(/^\ufeff/,'')); const n=new Set(w.nodes.map(x=>x.name)); Object.entries(w.connections).forEach(([k,v])=>v.main?.forEach(o=>o?.forEach(t=>{if(!n.has(t.node))console.log('Missing:',t.node)})))"
```

### List All Node Names
```javascript
node -e "console.log(JSON.parse(require('fs').readFileSync('workflow.json','utf8').replace(/^\ufeff/,'')).nodes.map(n=>n.name).join('\n'))"
```

### Count Nodes
```javascript
node -e "console.log(JSON.parse(require('fs').readFileSync('workflow.json','utf8').replace(/^\ufeff/,'')).nodes.length)"
```

## Workflow Design Best Practices

### Multi-Stage AI Processing Chain
Follow a sequential AI agent pattern for complex content generation:

```
User Input → Theme Selection → Content Creation → Image Prompt Generation → Visual Creation → Delivery
```

**Implementation Pattern**:
- **AI Agent 1 (Content Planner)**: Selects theme from user input
- **AI Agent 2 (Social Media Manager)**: Creates text content based on theme + retrieved Bible verses
- **AI Agent 3 (Image Prompt Generator)**: Generates detailed image prompts from content

**Benefits**:
- Each AI agent has a single, well-defined responsibility
- Clear system messages guide each agent's behavior
- Output from one agent feeds into the next
- Easier to debug and optimize individual stages

### Vector Store Integration for RAG (Retrieval-Augmented Generation)

**Data Preparation Branch**:
```
Manual Trigger → HTTP Request (PDF) → Extract from File → Vector Store (Insert Mode)
```

**Retrieval Branch**:
```
AI Agent → Vector Store (Retrieve-as-Tool Mode) → Context-Enhanced Generation
```

**Best Practices**:
- Use embeddings consistent across insertion and retrieval (e.g., Google Gemini Embeddings)
- Set meaningful collection names (e.g., `my-collection` for Bible verses)
- Use "retrieve-as-tool" mode to let AI agents query the vector store autonomously
- Provide descriptive `toolDescription` for vector store retrievals

### Effective System Messages & Prompts

Write comprehensive system messages that include:

**Role Definition**:
```
**Role**: Social Media Manager
```

**Clear Guidelines** (numbered for clarity):
```
1. Select the most appropriate verse from the provided list
2. Write a short, encouraging reflection (2-3 sentences)
3. Quote the selected verse clearly
4. Include the book, chapter, and verse reference
```

**Tone Instructions**:
```
- Use a warm, inviting tone
- Do not preach or be overly dogmatic; aim to inspire and comfort
```

**Output Specifications**:
```
- Use appropriate emojis to make the post visually appealing
- End with a short engaging question to encourage comments
```

### Multi-Channel Output Strategy

Implement parallel output delivery:
- Send text content to one channel (e.g., Telegram text message)
- Send visual content to another channel (e.g., Telegram photo)
- Use the same trigger for synchronized delivery

**Connection Pattern**:
```
AI Agent → [Branch 1] → Telegram Response (Text)
         → [Branch 2] → Image Generation → Telegram Response (Photo)
```

### Workflow Testing & Validation

- **Test with edge cases**: Empty responses, API failures, malformed JSON
- **Validate AI outputs**: Ensure agents follow system message instructions
- **Monitor token usage**: Track costs for large-scale deployments
- **Version control**: Save workflow versions before major changes
- **Documentation**: Use node notes to explain complex logic

## Advanced Workflow Design Patterns

### Scheduled Automation Pattern
For fully autonomous, recurring workflows:

```
Schedule Trigger → Generate Ideas → Create Content → Publish → Log Results
```

**Implementation**:
- Use `n8n-nodes-base.scheduleTrigger` with cron expressions
- Add error handling with Try/Catch nodes
- Store state in Google Sheets or database
- Send status reports to Slack/Telegram

### MCP Multi-Tool Agent Pattern
For conversational AI with multiple external tools:

```
Telegram Trigger → Voice Transcription → AI Agent → [Tool1, Tool2, Tool3, ...] → Response
```

**Implementation**:
- MCP Server Triggers expose workflows as tools
- MCP Client Tools connect AI agents to servers
- Use session-based memory for context
- Each tool is a separate workflow with specific parameters

### Parallel Asset Generation Pattern
For content requiring multiple simultaneous API calls:

```
Trigger → Generate Prompts → [Audio Gen, Image Gen, Video Gen] → Wait → Merge → Assemble
```

**Implementation**:
- Use multiple output branches from single node
- Add Wait nodes to ensure all branches complete
- Merge results with aggregate/merge nodes
- Handle partial failures gracefully

### Switch-Based Routing Pattern
For workflows handling multiple input types:

```
Trigger → Switch (Input Type) → [Branch A, Branch B, Branch C] → Merge → Response
```

**Implementation**:
- Use `n8n-nodes-base.switch` node for routing
- Define rules based on input properties
- Handle "no match" case with default branch
- Common for multi-command bots

### RAG Knowledge Pattern
For context-aware AI responses:

```
User Query → Embedding → Vector Search → Context Injection → AI Agent → Response
```

**Implementation**:
- Vector store in "retrieve-as-tool" mode
- AI agent autonomously decides when to query knowledge base
- Use meaningful collection names
- Consistent embedding models for insert/retrieve

### Fan-Out Publishing Pattern
For multi-platform content distribution:

```
Content Creation → Format Adapters → [Platform1, Platform2, ...] → Status Aggregation
```

**Implementation**:
- Create platform-specific formatting nodes
- Parallel HTTP requests for simultaneous posting
- Collect results with merge node
- Log successes/failures to central location

### Voice-Enabled Bot Pattern
For Telegram bots with voice input:

```
Telegram Trigger → Switch (Message Type) → [Text Path, Voice Path] → Whisper Transcription → AI Agent
```

**Implementation**:
- Check `message.voice` vs `message.text`
- Use OpenAI Whisper for transcription
- Merge text and transcribed voice back together
- Single AI agent handles both input types

### Session Memory Pattern
For stateful conversations:

```json
{
  "type": "@n8n/n8n-nodes-langchain.memoryBufferWindow",
  "parameters": {
    "contextWindowLength": 10,
    "sessionKey": "={{ $json.message.chat.username }}",
    "sessionIdType": "customKey"
  }
}
```

**Key Points**:
- Session key typically uses user ID or username
- Window length limits token usage (5-10 messages typical)
- Connect to AI agent via `ai_memory` connection type
- Persists across workflow executions

## Remember

1. **Always use Node.js** for editing n8n JSON files
2. **Preserve UTF-8 BOM** when writing files
3. **Update all connections** when renaming nodes
4. **Test expressions** before adding to workflow
5. **Document complex logic** with sticky notes
6. **Remove credentials** before version control
7. **Validate node references** after major changes
8. **Follow naming conventions** for maintainability
9. **Separation of concerns**: Split complex workflows into specialized AI agents
10. **RAG Pattern**: Combine vector stores with AI agents for context-aware generation11. **MCP Architecture**: Use MCP servers/clients for modular tool integration
12. **Session Memory**: Enable stateful conversations with session-based memory nodes
13. **Parallel Processing**: Use multiple branches for simultaneous API calls
14. **Error Handling**: Always add fallback logic for API failures