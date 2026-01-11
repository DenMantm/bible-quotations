# n8n Workflow Structure Documentation

## Overview
This document provides comprehensive guidance for working with n8n workflows in JSON format, based on analysis of production workflows.

## Core Workflow Structure

### Top-Level Properties
```json
{
  "id": "unique-workflow-id",
  "meta": { /* workflow metadata */ },
  "name": "Workflow Display Name",
  "tags": [],
  "nodes": [ /* array of node objects */ ],
  "active": false,
  "pinData": {},
  "settings": { "executionOrder": "v1" },
  "versionId": "version-uuid",
  "connections": { /* node connection mappings */ }
}
```

## Node Structure

### Essential Node Properties
Every node in the `nodes` array contains:

```json
{
  "id": "uuid-format-node-id",
  "name": "Display Name (can include emojis/Unicode)",
  "type": "node-type-identifier",
  "position": [x, y],  // Canvas coordinates
  "parameters": { /* node-specific configuration */ },
  "typeVersion": 1.2  // Node type version
}
```

### Optional Node Properties
- `webhookId`: For trigger/webhook nodes
- `credentials`: Reference to credential configuration
- `notesInFlow`: Internal node documentation

## Node Types Reference

### 1. Trigger Nodes
**Purpose**: Initiate workflow execution

**Examples**:
- `n8n-nodes-base.telegramTrigger`: Telegram bot messages
- `n8n-nodes-base.manualTrigger`: Manual execution button
- `n8n-nodes-base.webhook`: HTTP webhook endpoints
- `n8n-nodes-base.formTrigger`: Interactive web forms

**Common Parameters**:
```json
{
  "updates": ["message", "photo"],  // Event types to trigger on
  "additionalFields": {}
}
```

**Form Trigger Configuration**:
```json
{
  "type": "n8n-nodes-base.formTrigger",
  "parameters": {
    "formTitle": "My Form Title",
    "formDescription": "Description text",
    "formFields": {
      "values": [
        {
          "fieldLabel": "Topic",
          "fieldType": "text",
          "requiredField": true,
          "placeholder": "Enter topic here"
        },
        {
          "fieldLabel": "Upload Image",
          "fieldType": "file",
          "multipleFiles": false,
          "acceptFileTypes": ".jpg, .png"
        },
        {
          "fieldLabel": "Choose Option",
          "fieldType": "dropdown",
          "fieldOptions": {
            "values": [
              {"option": "Yes"},
              {"option": "No"}
            ]
          }
        }
      ]
    },
    "responseMode": "lastNode",
    "options": {
      "buttonLabel": "Submit"
    }
  }
}
```

**Field Types**: text, textarea, number, email, dropdown, date, time, file

### 2. Set Nodes
**Purpose**: Transform data, set variables, configure workflow constants

**Type**: `n8n-nodes-base.set`

**Parameters Structure**:
```json
{
  "assignments": {
    "assignments": [
      {
        "id": "id-1",
        "name": "variableName",
        "type": "string|number|boolean",
        "value": "={{ expression }}"  // Can use n8n expressions
      }
    ]
  },
  "includeOtherFields": true  // Pass through previous data
}
```

**Use Cases**:
- Configuration constants (API keys, settings)
- Data extraction/transformation
- Variable assignment

### 3. HTTP Request Nodes
**Purpose**: Make external API calls

**Type**: `n8n-nodes-base.httpRequest`

**Key Parameters**:
```json
{
  "url": "https://api.example.com/endpoint",
  "method": "POST|GET|PUT|DELETE",
  "sendBody": true,
  "sendHeaders": true,
  "contentType": "json|multipart-form-data|form-urlencoded",
  "headerParameters": {
    "parameters": [
      {"name": "Authorization", "value": "Bearer token"},
      {"name": "Content-Type", "value": "application/json"}
    ]
  },
  "jsonBody": "={{ JSON.stringify(data) }}",
  "bodyParameters": {  // For multipart/form data
    "parameters": [
      {
        "name": "file",
        "parameterType": "formBinaryData",
        "inputDataFieldName": "fieldName"
      }
    ]
  },
  "options": {
    "response": {
      "response": {
        "responseFormat": "json|file|string"
      }
    }
  }
}
```

### 4. AI/LLM Nodes

#### AI Agent Node
**Type**: `@n8n/n8n-nodes-langchain.agent`

**Purpose**: Create AI agents with tools, memory, and structured output

```json
{
  "type": "@n8n/n8n-nodes-langchain.agent",
  "parameters": {
    "text": "={{ $json.userInput }}",
    "promptType": "define",
    "hasOutputParser": true,
    "agent": "conversationalAgent",
    "options": {
      "systemMessage": "You are a helpful assistant..."
    }
  }
}
```

**Connections**:
- `ai_languageModel`: Connect language model node
- `ai_tool`: Connect tool nodes (SerpAPI, Calculator, etc.)
- `ai_outputParser`: Connect structured output parser

**Structured Output Parser**:
```json
{
  "type": "@n8n/n8n-nodes-langchain.outputParserStructured",
  "parameters": {
    "schemaType": "manual",
    "inputSchema": "{\"type\": \"object\", \"properties\": {\"name\": {\"type\": \"string\"}, \"description\": {\"type\": \"string\"}}}"
  }
}
```

**Output**: Agent returns JSON matching schema in `$json.output`

#### OpenAI Node
**Type**: `@n8n/n8n-nodes-langchain.openAi`

```json
{
  "modelId": {
    "__rl": true,
    "mode": "id",
    "value": "gpt-4o-mini|gpt-4o"
  },
  "messages": {
    "values": [
      {
        "content": "={{ 'Prompt with ' + $json.variable }}"
      }
    ]
  },
  "resource": "text|image",  // text for chat, image for DALL-E
  "options": {
    "temperature": 0.7
  }
}
```

**Image Generation**:
```json
{
  "resource": "image",
  "prompt": "={{ $json.imageDescription }}",
  "options": {
    "size": "1024x1024",
    "quality": "standard"
  }
}
```

#### Google Gemini Node
**Type**: `@n8n/n8n-nodes-langchain.lmChatGoogleGemini`

```json
{
  \"modelName\": \"models/gemini-2.0-flash-exp|models/gemini-pro\",
  \"options\": {
    \"temperature\": 0.4
  }
}
```

#### Perplexity Node
**Type**: `n8n-nodes-base.perplexity`

```json
{
  "model": "sonar|sonar-pro",
  "messages": {
    "message": [
      {
        "content": "Search query here"
      }
    ]
  }
}
```

### 5. Code Nodes
**Purpose**: Custom JavaScript/Python logic

**Type**: `n8n-nodes-base.code`

**Parameters**:
```json
{
  "jsCode": "return items.map(item => {\n  // Transform logic\n  return item;\n});"
}
```

**Important**: Code must return array of items with structure:
```javascript
[
  {
    json: { /* data object */ },
    binary: { /* binary data */ }
  }
]
```

### 6. Wait Node
**Purpose**: Pause execution for async operations

**Type**: `n8n-nodes-base.wait`

```json
{
  "unit": "seconds|minutes|hours",
  "amount": 10
}
```

**Use Case**: Waiting for external API processing (e.g., video generation)

### 7. Merge and Aggregate Nodes

#### Merge Node
**Purpose**: Combine data from multiple branches

**Type**: `n8n-nodes-base.merge`

```json
{
  "mode": "chooseBranch|append|combine",
  "combineBy": "combineByPosition|combineByKey",
  "numberInputs": 4,
  "options": {
    "includeUnpaired": true  // Include items without match
  }
}
```

**Modes**:
- `chooseBranch`: Pass through one branch
- `append`: Concatenate all items
- `combine`: Merge items by position or key

#### Aggregate Node
**Purpose**: Combine all execution items into single array

**Type**: `n8n-nodes-base.aggregate`

```json
{
  "aggregate": "aggregateAllItemData",
  "options": {}
}
```

**Use Case**: Collect results from parallel executions before final processing

### 8. IF Node
**Purpose**: Conditional branching based on data

**Type**: `n8n-nodes-base.if`

**Parameters**:
```json
{
  "conditions": {
    "combinator": "and|or",
    "conditions": [
      {
        "id": "condition-1",
        "leftValue": "={{ $json.data.approved }}",
        "operator": {
          "type": "boolean",
          "operation": "true"
        }
      }
    ]
  }
}
```

**Operators**:
- Boolean: `true`, `false`
- String: `equals`, `contains`, `startsWith`, `endsWith`, `regex`
- Number: `equals`, `notEquals`, `larger`, `smaller`
- Array: `contains`, `empty`, `notEmpty`

**Outputs**:
- Output 0 (top): Condition TRUE
- Output 1 (bottom): Condition FALSE

### 9. Sticky Note Nodes
**Purpose**: Visual documentation on canvas

**Type**: `n8n-nodes-base.stickyNote`

```json
{
  "color": 4,  // Color scheme number
  "width": 400,
  "height": 1038,
  "content": "# Markdown formatted documentation"
}
```

### 9. Platform-Specific Nodes

#### Telegram
**Types**:
- `n8n-nodes-base.telegramTrigger`: Receive messages
- `n8n-nodes-base.telegram`: Send messages/media

**Operations**: sendMessage, sendPhoto, sendVideo, getFile
#### Social Media Platforms
**Types**:
- `n8n-nodes-base.twitter`: Post tweets (X/Twitter)
- `n8n-nodes-base.linkedIn`: Create LinkedIn posts
- `n8n-nodes-base.facebookGraphApi`: Facebook/Instagram Graph API
- `n8n-nodes-base.gmail`: Send emails with approval workflows

**Common Parameters**:
```json
// Twitter/X Post
{
  "text": "={{ $json.content }}",
  "additionalFields": {}
}

// LinkedIn Post
{
  "text": "={{ $json.content }}",
  "postAs": "organization|person",
  "organization": "org-id",
  "shareMediaCategory": "IMAGE|NONE",
  "binaryPropertyName": "data"
}

// Facebook Graph API
{
  "edge": "photos|feed|media|media_publish",
  "node": "page-id|user-id",
  "httpRequestMethod": "POST",
  "graphApiVersion": "v20.0",
  "options": {
    "queryParameters": {
      "parameter": [
        {"name": "message", "value": "Post content"},
        {"name": "caption", "value": "Image caption"}
      ]
    }
  },
  "sendBinaryData": true,
  "binaryPropertyName": "data"
}
```

**Instagram Publishing** (via Facebook Graph API):
```
1. Create Media Container → 2. Publish Media Container
```

```json
// Step 1: Create media container
{
  "edge": "media",
  "node": "instagram-account-id",
  "options": {
    "queryParameters": {
      "parameter": [
        {"name": "image_url", "value": "https://..."},
        {"name": "caption", "value": "Post caption"}
      ]
    }
  }
}

// Step 2: Publish container
{
  "edge": "media_publish",
  "node": "instagram-account-id",
  "options": {
    "queryParameters": {
      "parameter": [
        {"name": "creation_id", "value": "={{ $json.id }}"}
      ]
    }
  }
  }
}
```

#### Google Sheets
**Type**: `n8n-nodes-base.googleSheets`

**Operations**:
- `append`: Add new rows
- `appendOrUpdate`: Add or update based on matching columns
- `update`: Update existing rows

```json
{
  "operation": "appendOrUpdate",
  "documentId": {"__rl": true, "mode": "id", "value": "sheet-id"},
  "sheetName": {"__rl": true, "mode": "id", "value": "Sheet1"},
  "columns": {
    "value": {
      "COLUMN_NAME": "={{ $json.value }}"
    },
    "matchingColumns": ["ID_COLUMN"]
  }
}
```

#### Blotato (Social Media Publishing)
**Type**: `@blotato/n8n-nodes-blotato.blotato`

**Parameters**:
```json
{
  "platform": "tiktok|instagram|linkedin|facebook|twitter|youtube|threads|bluesky|pinterest",
  "accountId": {"__rl": true, "mode": "list", "value": "account-id"},
  "postContentText": "={{ $json.caption }}",
  "postContentMediaUrls": "={{ $json.mediaUrl }}"
}
```

## Connection Structure

### Connection Object Format
The `connections` object maps node outputs to inputs:

```json
{
  "connections": {
    "Source Node Name": {
      "main": [  // Connection type
        [  // Output index (0 = first output)
          {
            "node": "Target Node Name",
            "type": "main",
            "index": 0  // Input index on target node
          }
        ]
      ]
    }
  }
}
```

### Connection Types
1. **main**: Standard data flow between nodes
2. **ai_tool**: AI agent tool connections
3. **ai_languageModel**: AI language model connections
4. **ai_embedding**: Vector embedding connections
5. **ai_document**: Document loader connections

### Multiple Outputs
Nodes can have multiple output branches:
```json
{
  "Source Node": {
    "main": [
      [{"node": "Branch1", "type": "main", "index": 0}],
      [{"node": "Branch2", "type": "main", "index": 0}],
      [{"node": "Branch3", "type": "main", "index": 0}]
    ]
  }
}
```

### Merge Inputs
Merge nodes accept multiple inputs:
```json
{
  "Branch1": {
    "main": [[{"node": "Merge1", "type": "main", "index": 0}]]
  },
  "Branch2": {
    "main": [[{"node": "Merge1", "type": "main", "index": 1}]]
  },
  "Branch3": {
    "main": [[{"node": "Merge1", "type": "main", "index": 2}]]
  }
}
```

## n8n Expression Language

### Accessing Previous Node Data
```javascript
// Current node's data
$json.fieldName

// Specific node's first item
$('Node Name').first().json.fieldName

// Specific node's current item
$('Node Name').item.json.fieldName

// All items from a node
$('Node Name').all()

// Binary data
$binary.dataName
```

### Common Expression Patterns
```javascript
// Conditional
={{ $json.value ? 'yes' : 'no' }}

// String interpolation
={{ 'Hello ' + $json.name }}

// Array access
={{ $json.array[0].property }}

// Nested node reference
={{ $('Step 1').first().json.config.apiKey }}

// Ternary with node reference
={{ $json.photo ? $json.photo[$json.photo.length - 1].file_id : '' }}

// Regex replacement (URL transformation)
={{ $json.url.replace(/^http:\/\/tmpfiles\.org\/(\d+)\/(.*)$/i, 'https://tmpfiles.org/dl/$1/$2') }}
```

### Expression Best Practices
1. Always wrap expressions in `={{ }}`
2. Reference specific nodes by exact name: `$('Node Name')`
3. Use `.first()` for single-item access, `.item` for current item in loops
4. Access nested properties with dot notation: `$json.message.chat.id`
5. Check existence before accessing: `$json.photo ? $json.photo[0] : ''`

## Credentials Management

### Credential Reference Format
```json
{
  "credentials": {
    "credentialType": {
      "id": "credential-id",
      "name": "Display Name"
    }
  }
}
```

### Common Credential Types
- `telegramApi`: Telegram bot token
- `openAiApi`: OpenAI API key
- `perplexityApi`: Perplexity API key
- `googleSheetsOAuth2Api`: Google Sheets OAuth
- `blotatoApi`: Blotato API key
- Custom HTTP: Use header parameters instead

## Workflow Patterns

### Pattern 1: Trigger → Configure → Process → Output
```
Trigger → Set (Config) → Extract Data → API Calls → Save Results
```

### Pattern 2: Parallel Processing → Merge
```
Input → Branch1 ↘
      → Branch2 → Merge → Next Step
      → Branch3 ↗
```

### Pattern 3: Sequential AI Processing
```
Input → Research AI → Generate AI → Enhance AI → Output
```

### Pattern 4: Upload → Process → Download
```
Upload File → Submit to API → Wait → Poll Status → Download Result
```

### Pattern 5: Email Approval Workflow
```
Generate Content → Format Email → Send for Approval → Wait → Check Response → Proceed/Stop
```

**Gmail Send and Wait**:
```json
{
  "type": "n8n-nodes-base.gmail",
  "parameters": {
    "operation": "sendAndWait",
    "sendTo": "approver@example.com",
    "subject": "Approval Required",
    "message": "={{ $json.content }}",
    "approvalOptions": {
      "values": {
        "approvalType": "double"  // Approve/Reject buttons
      }
    },
    "options": {
      "limitWaitTime": {
        "values": {
          "resumeUnit": "minutes",
          "resumeAmount": 45
        }
      }
    }
  }
}
```

**Output**: Returns `$json.data.approved` (true/false)

### Pattern 6: Multi-Platform Broadcasting
```
Prepare Content → Platform1 ↘
                → Platform2 → Merge → Log Status
                → Platform3 ↗
```

**Example**: Social Media Publishing
```
Content Factory → Instagram ↘
                → Facebook  → Aggregate Results → Email Report
                → LinkedIn  ↗
                → X/Twitter ↗
```

**Error Handling**: Use `onError: "continueRegularOutput"` and `alwaysOutputData: true` to collect results even on failure

## Binary Data Handling

### File Upload Pattern
```json
{
  "contentType": "multipart-form-data",
  "bodyParameters": {
    "parameters": [
      {
        "name": "file",
        "parameterType": "formBinaryData",
        "inputDataFieldName": "audio_mp3"  // Binary field name
      }
    ]
  }
}
```

### Binary Data Transformation (Code Node)
```javascript
return items.map(item => {
  const b = item.binary?.audio;
  if (!b) return item;
  
  // Clone binary data with new properties
  item.binary.audio_mp3 = {
    ...b,
    fileName: b.fileName.replace(/\.mpga$/i, '.mp3'),
    mimeType: 'audio/mpeg'
  };
  
  return item;
});
```

### Response as File
```json
{
  "options": {
    "response": {
      "response": {
        "responseFormat": "file",
        "outputPropertyName": "audio"  // Binary field name
      }
    }
  }
}
```

## Resource Lists (Dynamic Dropdowns)

### Resource List Format
Used for dynamic dropdown values (accounts, sheets, etc.):

```json
{
  "accountId": {
    "__rl": true,
    "mode": "list|id",
    "value": "selected-value",
    "cachedResultUrl": "https://api.example.com/resource",
    "cachedResultName": "Display Name"
  }
}
```

## File Encoding Considerations

### UTF-8 BOM Handling
- n8n workflow JSON files may have UTF-8 BOM (bytes: `ef bb bf`)
- Node.js reading: Strip BOM with `if(content.charCodeAt(0)===0xFEFF) content=content.slice(1);`
- PowerShell/Python: May corrupt Unicode characters (emojis, curly quotes)

### Unicode in Node Names
- Node names support full Unicode (emojis: 📱, 🎨, ✅)
- Use emojis for visual organization on canvas
- Reference nodes by exact name including emojis: `$('📱 User Request')`

### Safe JSON Manipulation
**Recommended approach for editing n8n JSON files:**

```javascript
const fs = require('fs');

// Read with BOM handling
let content = fs.readFileSync('workflow.json', 'utf8');
if (content.charCodeAt(0) === 0xFEFF) content = content.slice(1);

// Parse and modify
const workflow = JSON.parse(content);
// ... make changes ...

// Write back with BOM preserved
fs.writeFileSync('workflow.json', 
  '\ufeff' + JSON.stringify(workflow, null, 2), 
  'utf8'
);
```

## Common Workflow Components

### Configuration Node Pattern
Create a Set node at workflow start with all configuration:

```json
{
  "name": "Workflow Configuration",
  "type": "n8n-nodes-base.set",
  "parameters": {
    "assignments": {
      "assignments": [
        {"name": "apiKey", "type": "string", "value": "KEY"},
        {"name": "maxDuration", "type": "number", "value": 30},
        {"name": "model", "type": "string", "value": "gpt-4o"}
      ]
    }
  }
}
```

Reference later: `{{ $('Workflow Configuration').first().json.apiKey }}`

### Data Extraction Pattern
Extract specific fields from trigger data:

```json
{
  "name": "Extract Photo and Theme",
  "type": "n8n-nodes-base.set",
  "parameters": {
    "assignments": {
      "assignments": [
        {
          "name": "photoUrl",
          "value": "={{ $json.message.photo ? $json.message.photo[$json.message.photo.length - 1].file_id : '' }}"
        },
        {
          "name": "theme",
          "value": "={{ $json.message.caption || $json.message.text || 'default' }}"
        }
      ]
    },
    "includeOtherFields": true
  }
}
```

### Async API Processing Pattern
1. Submit job → get request_id
2. Wait node (delay)
3. Poll status with request_id
4. Download result

```json
// Submit
{"url": "https://api.example.com/submit", "method": "POST"}
// Wait
{"unit": "minutes", "amount": 10}
// Poll
{"url": "https://api.example.com/status/{{ $json.request_id }}"}
```

## Troubleshooting Guide

### Connection Errors
**Symptom**: "Could not find node X"
**Cause**: Node name changed but connections still reference old name
**Solution**: Search connections object for old name, replace with new exact name

### Expression Errors
**Symptom**: "Cannot read property of undefined"
**Cause**: Accessing nested property that doesn't exist
**Solution**: Add conditional checks: `{{ $json.prop?.nested || 'default' }}`

### Binary Data Not Found
**Symptom**: "Binary data X not found"
**Cause**: Wrong field name or binary not passed through
**Solution**: Check binary field name, ensure previous node outputs binary data

### Credential Errors
**Symptom**: "Credentials not found"
**Cause**: Credential ID doesn't exist in instance
**Solution**: Re-add credentials in n8n UI, update credential IDs in JSON

### Merge Node Issues
**Symptom**: Merge waits forever
**Cause**: Not all input branches executing
**Solution**: Verify all paths lead to merge, check `numberInputs` matches actual inputs

## Best Practices

### 1. Naming Conventions
- Use descriptive names: ✅ "Generate Script with GPT-4" ❌ "AI Node 1"
- Add emojis for visual grouping: 📱 Telegram, 🎨 Image, 🤖 AI
- Keep names consistent in connections

### 2. Error Handling
- Add error workflows with error trigger nodes
- Use "Continue On Fail" setting for non-critical nodes
- Implement retry logic for API calls

### 3. Performance
- Minimize sequential node chains (use parallel when possible)
- Batch API calls instead of loops
- Use Set nodes to prepare data before heavy operations

### 4. Maintainability
- Add sticky notes to document complex sections
- Group related nodes visually on canvas
- Use consistent parameter naming across workflow

### 5. Security
- Never hardcode credentials in JSON (use credential system)
- Store sensitive data in Set nodes referenced from environment
- Sanitize user inputs before AI/API calls

### 6. Testing
- Test each branch independently
- Pin test data during development
- Validate expressions in isolation before deployment

## Version Control

### Git Best Practices
- Commit after significant changes
- Use descriptive commit messages: "Add Russian Bible support"
- Create branches for major features
- Remove credential IDs before committing (replace with placeholders)

### File Structure
```
project/
├── workflows/
│   ├── bible-quotations.json
│   ├── tiktok-creator.json
│   └── ...
├── documentation/
│   └── workflow-guide.md
└── .gitignore (exclude credentials)
```

## Canvas Organization

### Visual Layout Tips
1. **Left to right flow**: Trigger → Process → Output
2. **Top to bottom branches**: Main path top, alternates below
3. **Sticky notes**: Place above/around node groups
4. **Spacing**: Leave gaps between logical sections
5. **Alignment**: Use grid for clean appearance

### Position Coordinates
- Format: `[x, y]` in pixels
- Negative values allowed
- Typical spacing: 200-400 pixels between nodes
- Example: `[-2832, -304]` (far left, upper area)

## Advanced Patterns

### Dynamic Configuration
Load config from external source:
```
HTTP Request (Get Config) → Set (Parse Config) → Main Workflow
```

### Conditional Branching
Use IF node or Switch node to route based on conditions

### Loop Pattern
Use Loop Over Items or Split In Batches for iteration

### Subworkflow Pattern
Call other workflows with Execute Workflow node

### Webhook Response Pattern
For webhook triggers, use Respond to Webhook node to send immediate response while continuing processing

## Workflow Metadata

### Meta Object
```json
{
  "meta": {
    "instanceId": "unique-instance-id",
    "templateCredsSetupCompleted": true
  }
}
```

### Settings Object
```json
{
  "settings": {
    "executionOrder": "v1",
    "saveDataErrorExecution": "all",
    "saveDataSuccessExecution": "all",
    "saveManualExecutions": true,
    "callerPolicy": "workflowsFromSameOwner"
  }
}
```

## Summary Checklist

When creating/editing n8n workflows:

- [ ] Use Node.js for JSON manipulation (avoid PowerShell/Python encoding issues)
- [ ] Strip UTF-8 BOM when reading
- [ ] Preserve UTF-8 BOM when writing
- [ ] Update ALL connection references when renaming nodes
- [ ] Use exact node names (including emojis/Unicode)
- [ ] Test expressions with `{{ }}` syntax
- [ ] Verify credential IDs exist in target instance
- [ ] Add sticky notes for complex logic
- [ ] Follow left-to-right visual flow
- [ ] Remove sensitive data before version control
- [ ] Test all branches independently
- [ ] Validate binary data field names
- [ ] Check merge node input counts
- [ ] Use meaningful variable names in Set nodes
- [ ] Document API requirements in sticky notes

## Sample Workflows Reference

This repository includes several production-ready workflow examples in the `sample-dashboards/` folder:

### 1. Productivity Agent (Jarvis Template)
**File**: `productivity-agent.json` | **Nodes**: 52

**Purpose**: AI-powered personal assistant via Telegram for productivity management

**Key Technologies**:
- **MCP (Model Context Protocol)**: Client and server implementations
- **LangChain Agents**: Memory-enabled conversational AI
- **Integrations**: Gmail, Google Calendar, Google Tasks, Google Sheets

**Features**:
- Telegram bot interface with voice message transcription (ElevenLabs)
- Session-based memory (keyed by username)
- Switch node routing for audio vs. text messages
- **MCP Client Tools**:
  - Gmail MCP: Email management (send, reply, draft, labels)
  - Calendar MCP: Event management (create, check availability, reschedule)  
  - Tasks MCP: Google Tasks integration
  - Finance MCP: Expense tracking via Google Sheets

**MCP Server Endpoints**:
```
Gmail MCP Server: /mcp/gmail-mcp/sse
Calendar MCP Server: /mcp/calendar-mcp/sse
Tasks MCP Server: /mcp/task-YOUR_OPENAI_KEY_HERE
Finance MCP Server: /mcp/finance-mcp/sse
```

**Node Types Used**:
- `@n8n/n8n-nodes-langchain.mcpClientTool`: Connect to MCP servers as agent tools
- `@n8n/n8n-nodes-langchain.mcpTrigger`: Expose MCP server endpoints
- `@n8n/n8n-nodes-langchain.memoryBufferWindow`: Session memory
- `n8n-nodes-base.gmailTool`, `n8n-nodes-base.googleCalendarTool`: Native tool nodes

**Architecture Pattern**: Telegram → Switch → AI Agent + MCP Tools → Response

---

### 2. YouTube Shorts Factory (ASMR)
**File**: `youtube.json` | **Nodes**: 32 | **Tags**: AI, YouTube, Content Creation

**Purpose**: Fully automated YouTube Shorts content creation pipeline for ASMR content

**Workflow Stages**:
1. **AI Ideation** (Schedule Trigger → OpenAI Agent)
   - Generate trending ASMR ideas based on current trends
   - Enrich idea into structured content plan
   - Log to Google Sheets tracking

2. **Asset Generation** (Parallel Audio Creation)
   - Parse idea into multiple audio prompts
   - Create audio clips via ElevenLabs API (parallel execution)
   - Wait for audio generation completion
   - Retrieve generated audio URLs

3. **Video Assembly** (Seedance API)
   - List audio elements
   - Sequence clips into final video
   - Wait for video rendering
   - Download final video file

4. **Distribution** (Upload & Notify)
   - Upload to YouTube with metadata
   - Update Google Sheets with video URL
   - Send notifications (Gmail + Telegram)

**Key APIs**:
- **ElevenLabs**: Text-to-speech audio generation
- **Seedance**: Video sequencing and rendering
- **YouTube Data API**: Video upload
- **Google Sheets**: Content tracking

**Pattern Highlights**:
- Schedule-based automation (no manual trigger)
- Parallel asset generation with Wait nodes
- Multi-stage async processing (create → wait → retrieve)
- Comprehensive logging and notifications

---

### 3. Social Media Content Factory (Detailed example below)
**File**: `social-media.json` | **Nodes**: 57

**Purpose**: Multi-platform social media content generation and publishing

**Platforms**: LinkedIn, Instagram, Facebook, X/Twitter, TikTok, Threads, YouTube Shorts

**See detailed breakdown in Advanced Workflow Example section below**

---

### 4. Auto Service Content Generator
**File**: `social-media-2.json` | **Nodes**: 50

**Purpose**: AI content generation for automotive service businesses

**Features**:
- Industry-specific content (automotive services, repairs, maintenance)
- Similar architecture to Social Media Content Factory
- Platform-optimized posting for service businesses
- Form-based input for service topics

**Use Case**: Automotive shops, tire centers, car dealerships, repair services

---

### 5. RAG WhatsApp Knowledge Base
**File**: `rag-whatsup.json` | **Nodes**: ~40 | **Lines**: 1503

**Purpose**: RAG-powered chatbot for WhatsApp customer support

**Key Components**:
- Knowledge Base Agent with vector store retrieval
- WhatsApp Business API integration
- Context-aware responses using RAG pattern
- Production-ready customer service automation

**Pattern**:
```
WhatsApp Message → Knowledge Base Retrieval → AI Agent → Contextual Response → WhatsApp
```

**Technologies**:
- Vector database for knowledge storage
- LangChain agent with retrieval tools
- WhatsApp Business API
- RAG (Retrieval-Augmented Generation) pattern

---

## Advanced Workflow Example: Social Media Content Factory

This is a complete example of a production workflow that demonstrates multiple advanced patterns.

### Workflow Overview
**Purpose**: Automated multi-platform social media content generation and publishing

**Flow Stages**:
1. Form input → 2. AI content generation → 3. Email approval → 4. Image creation → 5. Multi-platform publish → 6. Results reporting

### Key Components

#### 1. Form Trigger (User Input)
```json
{
  "type": "n8n-nodes-base.formTrigger",
  "name": "Submit Social Post Details",
  "parameters": {
    "formTitle": "workflows.diy",
    "formDescription": "AI-Powered Social Media Assistant",
    "formFields": {
      "values": [
        {
          "fieldLabel": "Topic",
          "requiredField": true,
          "placeholder": "Provide a concise title..."
        },
        {
          "fieldLabel": "Keywords or Hashtags (optional)",
          "requiredField": false
        },
        {
          "fieldLabel": "Link (optional)",
          "placeholder": "URL to include in post"
        }
      ]
    },
    "responseMode": "lastNode",
    "options": {
      "buttonLabel": "Automatically Generate Social Media Content"
    }
  }
}
```

**Access form data**: `$json.Topic`, `$json['Keywords or Hashtags (optional)']`, `$json['Link (optional)']`

#### 2. AI Content Factory (LangChain Agent)
```json
{
  "type": "@n8n/n8n-nodes-langchain.agent",
  "name": "Social Media Content Factory",
  "parameters": {
    "text": "You are a content creation AI for workflows.diy...",
    "promptType": "define",
    "hasOutputParser": true,
    "agent": "conversationalAgent",
    "options": {
      "systemMessage": "Use the provided tools to research the topic..."
    }
  }
}
```

**Connections**:
- Language Model: Connect `gpt-4o LLM` node
- Tools: Connect `SerpAPI` tool for trend research
- Output Parser: Connect `Social Media Content` structured output parser

#### 3. Structured Output Schema
```json
{
  "type": "@n8n/n8n-nodes-langchain.outputParserStructured",
  "name": "Social Media Content",
  "parameters": {
    "schemaType": "manual",
    "inputSchema": "{
      \"type\": \"object\",
      \"properties\": {
        \"name\": {\"type\": \"string\"},
        \"description\": {\"type\": \"string\"},
        \"platform_posts\": {
          \"type\": \"object\",
          \"properties\": {
            \"LinkedIn\": {
              \"type\": \"object\",
              \"properties\": {
                \"image_suggestion\": {\"type\": \"string\"},
                \"post\": {\"type\": \"string\"},
                \"hashtags\": {\"type\": \"array\"},
                \"call_to_action\": {\"type\": \"string\"}
              }
            },
            \"Instagram\": {...},
            \"Facebook\": {...},
            \"X-Twitter\": {...}
          }
        }
      }
    }"
  }
}
```

**Output Access**: `$json.output.platform_posts.LinkedIn.post`

#### 4. HTML Email Formatting (AI Agent)
```json
{
  "type": "@n8n/n8n-nodes-langchain.agent",
  "name": "Prepare Content Review Email",
  "parameters": {
    "text": "Generate clean, modern HTML email content from the provided JSON data...",
    "promptType": "define"
  }
}
```

**Purpose**: Convert structured JSON to formatted HTML email for approval

#### 5. Gmail Approval Workflow
```json
{
  "type": "n8n-nodes-base.gmail",
  "name": "Gmail User for Approval",
  "parameters": {
    "operation": "sendAndWait",
    "sendTo": "={{ $env.EMAIL_ADDRESS_JOE }}",
    "subject": "🔥FOR APPROVAL🔥 {{ $json.output.name }}",
    "message": "={{ $json.output }}",
    "approvalOptions": {
      "values": {
        "approvalType": "double"  // Approve/Reject buttons
      }
    },
    "options": {
      "limitWaitTime": {
        "values": {
          "resumeUnit": "minutes",
          "resumeAmount": 45
        }
      }
    }
  }
}
```

**Output**: `$json.data.approved` (boolean)

#### 6. Conditional Branching
```json
{
  "type": "n8n-nodes-base.if",
  "name": "Is Content Approved?",
  "parameters": {
    "conditions": {
      "combinator": "and",
      "conditions": [
        {
          "leftValue": "={{ $json.data.approved }}",
          "operator": {"type": "boolean", "operation": "true"}
        }
      ]
    }
  }
}
```

#### 7. Image Generation
```json
{
  "type": "@n8n/n8n-nodes-langchain.openAi",
  "name": "OpenAI",
  "parameters": {
    "resource": "image",
    "prompt": "={{ $json.output.platform_posts.Instagram.caption }}",
    "options": {}
  }
}
```

**Upload to public URL** (imgbb.com):
```json
{
  "type": "n8n-nodes-base.httpRequest",
  "name": "Save Image to imgbb.com3",
  "parameters": {
    "url": "https://api.imgbb.com/1/upload",
    "method": "POST",
    "contentType": "multipart-form-data",
    "bodyParameters": {
      "parameters": [
        {
          "name": "image",
          "parameterType": "formBinaryData",
          "inputDataFieldName": "data"
        }
      ]
    },
    "queryParameters": {
      "parameters": [
        {"name": "key", "value": "={{ $env.IMGBB_API_KEY }}"}
      ]
    }
  }
}
```

#### 8. Multi-Platform Publishing (Parallel)

**Instagram** (2-step process):
```json
// Step 1: Create media container
{
  "type": "n8n-nodes-base.httpRequest",
  "name": "Instagram Image",
  "parameters": {
    "url": "https://graph.facebook.com/v20.0/[instagram-id]/media",
    "method": "POST",
    "queryParameters": {
      "parameters": [
        {"name": "image_url", "value": "={{ $json.data.medium.url }}"},
        {"name": "caption", "value": "={{ $('Social Media Content Factory').item.json.output.platform_posts.Instagram.caption }}"}
      ]
    }
  }
}

// Step 2: Publish media
{
  "type": "n8n-nodes-base.facebookGraphApi",
  "name": "Instragram Post",
  "onError": "continueRegularOutput",
  "alwaysOutputData": true,
  "parameters": {
    "edge": "media_publish",
    "node": "[instagram-id]",
    "options": {
      "queryParameters": {
        "parameter": [
          {"name": "creation_id", "value": "={{ $json.id }}"}
        ]
      }
    }
  }
}
```

**X/Twitter**:
```json
{
  "type": "n8n-nodes-base.twitter",
  "name": "X Post",
  "onError": "continueRegularOutput",
  "alwaysOutputData": true,
  "parameters": {
    "text": "={{ $('Social Media Content Factory').item.json.output.platform_posts['X-Twitter'].post }}"
  }
}
```

**LinkedIn**:
```json
{
  "type": "n8n-nodes-base.linkedIn",
  "name": "LinkedIn Post",
  "onError": "continueRegularOutput",
  "alwaysOutputData": true,
  "parameters": {
    "text": "={{ $json.output.platform_posts.LinkedIn.post }}",
    "postAs": "organization",
    "organization": "org-id",
    "shareMediaCategory": "IMAGE",
    "binaryPropertyName": "data"
  }
}
```

**Facebook**:
```json
{
  "type": "n8n-nodes-base.facebookGraphApi",
  "name": "Facebook Post",
  "onError": "continueRegularOutput",
  "alwaysOutputData": true,
  "parameters": {
    "edge": "photos",
    "node": "[page-id]",
    "sendBinaryData": true,
    "binaryPropertyName": "data",
    "options": {
      "queryParameters": {
        "parameter": [
          {"name": "message", "value": "={{ $json.output.platform_posts.Facebook.post }}"}
        ]
      }
    }
  }
}
```

#### 9. Error Handling Pattern
**Critical Settings**:
- `onError: "continueRegularOutput"` - Continue workflow even if node fails
- `alwaysOutputData: true` - Always output data for downstream processing

This allows collecting both successful and failed results for reporting.

#### 10. Results Aggregation
```json
// Set nodes to capture individual results
{
  "type": "n8n-nodes-base.set",
  "name": "Instagram Result",
  "parameters": {
    "assignments": {
      "assignments": [
        {
          "name": "Instagram Post Result",
          "type": "string",
          "value": "={{ $json }}"
        }
      ]
    }
  }
}

// Merge all results
{
  "type": "n8n-nodes-base.merge",
  "name": "Merge Results",
  "parameters": {
    "numberInputs": 4  // Instagram, X, Facebook, LinkedIn
  }
}

// Aggregate into single array
{
  "type": "n8n-nodes-base.aggregate",
  "name": "Aggregate",
  "parameters": {
    "aggregate": "aggregateAllItemData"
  }
}
```

#### 11. Results Reporting (AI-Generated)
```json
// Generate HTML table
{
  "type": "@n8n/n8n-nodes-langchain.agent",
  "name": "Prepare Results Email",
  "parameters": {
    "text": "Parse the social media post results and generate a modern HTML table showing platform statuses..."
  }
}

// Send summary email
{
  "type": "n8n-nodes-base.gmail",
  "name": "Gmail Results",
  "parameters": {
    "sendTo": "={{ $env.EMAIL_ADDRESS_JOE }}",
    "subject": "🔥RESULTS🔥 Social Media Factory",
    "message": "={{ $json.output }}"
  }
}
```

### Workflow Connection Structure
```json
{
  "connections": {
    "Submit Social Post Details": {
      "main": [[{"node": "Social Media Content Factory"}]]
    },
    "Social Media Content Factory": {
      "main": [[{"node": "Prepare Content Review Email"}]]
    },
    "Prepare Content Review Email": {
      "main": [[{"node": "Gmail User for Approval"}]]
    },
    "Gmail User for Approval": {
      "main": [[{"node": "Is Content Approved?"}]]
    },
    "Is Content Approved?": {
      "main": [
        [
          {"node": "OpenAI"},
          {"node": "Merge1"},
          {"node": "Merge2"}
        ],
        []  // Rejected path (empty)
      ]
    },
    "OpenAI": {
      "main": [[
        {"node": "Save Image to imgbb.com3"},
        {"node": "Merge"},
        {"node": "Merge2"}
      ]]
    },
    "Is Approved?": {
      "main": [
        [
          {"node": "X Post"},
          {"node": "Merge1"},
          {"node": "Merge2"}
        ]
      ]
    },
    "Merge1": {
      "main": [[{"node": "Instagram Image"}]]
    },
    "Instagram Image": {
      "main": [[{"node": "Instragram Post"}]]
    },
    "Instragram Post": {
      "main": [[{"node": "Instagram Result"}]]
    },
    "X Post": {
      "main": [[{"node": "X Result"}]]
    },
    "Merge2": {
      "main": [[
        {"node": "Facebook Post"},
        {"node": "LinkedIn Post"}
      ]]
    },
    "Instagram Result": {
      "main": [[{"node": "Merge Results", "index": 0}]]
    },
    "X Result": {
      "main": [[{"node": "Merge Results", "index": 1}]]
    },
    "Facebook Result": {
      "main": [[{"node": "Merge Results", "index": 2}]]
    },
    "LinkedIn Result": {
      "main": [[{"node": "Merge Results", "index": 3}]]
    },
    "Merge Results": {
      "main": [[{"node": "Aggregate"}]]
    },
    "Aggregate": {
      "main": [[
        {"node": "Prepare Results Email"},
        {"node": "Prepare Results Message"}
      ]]
    }
  }
}
```

### Environment Variables Required
```
IMGBB_API_KEY=your_api_key
EMAIL_ADDRESS_JOE=approver@example.com
TELEGRAM_CHAT_ID=your_chat_id (optional)
```

### Credentials Required
- OpenAI API (GPT-4, DALL-E)
- SerpAPI (trend research)
- Gmail OAuth2
- Facebook Graph API (Instagram, Facebook)
- Twitter OAuth2
- LinkedIn OAuth2
- imgbb API key

### Key Learnings from This Workflow

1. **Form Triggers**: Excellent for user-facing workflows without coding
2. **AI Agents with Structured Output**: Enforce consistent JSON schemas
3. **Approval Workflows**: Gmail send-and-wait pattern for human-in-loop
4. **Error Resilience**: `onError` + `alwaysOutputData` for robust parallel execution
5. **AI for Formatting**: Use AI agents to generate HTML emails from JSON
6. **Merge Strategies**: Multiple merge nodes for complex branching
7. **Results Aggregation**: Collect parallel execution results into single summary
8. **Environment Variables**: Use `$env.VAR_NAME` for configuration
9. **Node References**: `$('Node Name').item.json.path` for complex workflows
10. **Instagram Two-Step**: Create media container → publish container

## Summary Checklist
