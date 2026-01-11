# Bible Quotations Workflow - Architecture Diagram

## 🎯 Complete Workflow Flow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         📱 TELEGRAM USER INPUT                               │
│                    (Webhook: Receives text or voice)                         │
└───────────────────────────────────┬──────────────────────────────────────────┘
                                    │
                                    ↓
                    ┌───────────────────────────────┐
                    │  ⚙️ WORKFLOW CONFIGURATION   │
                    │  • Image model settings       │
                    │  • Dimensions (1024x1024)     │
                    │  • Memory window (10 msgs)    │
                    │  • Voice enable flag          │
                    └───────────────┬───────────────┘
                                    │
                                    ↓
                    ┌───────────────────────────────┐
                    │   🔀 ROUTE INPUT TYPE         │
                    │   (Switch Node)                │
                    └──────┬────────────────┬────────┘
                           │                │
                  ┌────────┴────────┐      │
                  │  VOICE PATH     │      │  TEXT PATH
                  │                 │      │
                  ↓                 │      ↓
    ┌─────────────────────┐        │   (Direct to Merge)
    │ 📥 Get Voice Info   │        │
    │ • Extract file_id   │        │
    └──────────┬──────────┘        │
               │                    │
               ↓                    │
    ┌─────────────────────┐        │
    │ 📥 Download Voice   │        │
    │ • Telegram API      │        │
    └──────────┬──────────┘        │
               │                    │
               ↓                    │
    ┌─────────────────────┐        │
    │ 🎙️ Whisper AI      │        │
    │ • Transcribe voice  │        │
    └──────────┬──────────┘        │
               │                    │
               └────────┬───────────┘
                        │
                        ↓
            ┌───────────────────────────┐
            │  🔗 MERGE TEXT & VOICE    │
            │  (Combine both paths)     │
            └───────────┬───────────────┘
                        │
                        ↓
            ┌───────────────────────────┐
            │  🔄 NORMALIZE INPUT       │
            │  • userInput              │
            │  • chatId                 │
            │  • username               │
            │  • inputType              │
            └───────────┬───────────────┘
                        │
                        ↓
            ┌───────────────────────────┐
            │  📅 GET IRISH DATE/TIME   │
            │  • Current timestamp       │
            │  • Europe/Dublin timezone  │
            └───────────┬───────────────┘
                        │
                        ↓
            ┌───────────────────────────┐
            │  🗓️ IRISH CALENDAR AI    │
            │  (Liturgical Context)      │
            │  • Season                  │
            │  • Feast days              │
            │  • Irish traditions        │
            └───────────┬───────────────┘
                        │
                        ↓
            ┌───────────────────────────┐
            │  🎯 THEME SELECTOR AI     │
            │  • 13 theme categories     │
            │  • Liturgically aware      │
            │  • Returns: theme name     │
            └───────────┬───────────────┘
                        │
                        ↓
    ┌───────────────────────────────────────────────┐
    │      ✍️ POST CREATOR AI (Main Agent)         │
    │  ┌─────────────────────────────────────────┐  │
    │  │  Connected Tools & Resources:           │  │
    │  │  • 📖 English Bible RAG (Qdrant)       │  │
    │  │  • 💭 Conversation Memory (10 msgs)    │  │
    │  │  • 🗓️ Calendar context (from above)    │  │
    │  │  • 🎯 Theme (from above)               │  │
    │  └─────────────────────────────────────────┘  │
    │                                                │
    │  Output: Bible post with verse + reflection   │
    └──────────┬────────────────┬───────────┬────────┘
               │                │           │
               │                │           │
   ┌───────────┴──────┐   ┌────┴────┐   ┌──┴─────────────┐
   │  OUTPUT 1        │   │OUTPUT 2 │   │  OUTPUT 3      │
   │  📤 Send Text    │   │🎨 Image │   │  🇷🇺 Russian  │
   │     Post         │   │Generator│   │   Translation  │
   └──────────────────┘   └────┬────┘   └────┬───────────┘
                               │              │
                               │              │
        ┌──────────────────────┘              │
        │                                     │
        ↓                                     ↓
┌─────────────────────┐         ┌────────────────────────────┐
│  🎨 IMAGE BRANCH    │         │  🇷🇺 RUSSIAN BRANCH        │
│                     │         │                            │
│  1. Parse JSON      │         │  AI Agent with:            │
│  2. Build API Req   │         │  • 📖 Russian Bible RAG    │
│  3. Set Filename    │         │  • Orthodox terminology    │
│  4. Generate Image  │         │  • Cultural adaptation     │
│  5. 📤 Send Image   │         │  • 📤 Send Russian Post    │
└─────────────────────┘         └────────────────────────────┘
```

## 🧩 Component Details

### Input Processing Layer
```
┌────────────────────────────────────────────┐
│  INPUT TYPES SUPPORTED                     │
├────────────────────────────────────────────┤
│  📝 Text Messages    → Direct processing   │
│  🎙️ Voice Messages  → Whisper → Text     │
└────────────────────────────────────────────┘
```

### AI Agent Pipeline
```
Agent 1: 🗓️ Calendar Context
    ↓ (liturgical info)
Agent 2: 🎯 Theme Selector
    ↓ (spiritual theme)
Agent 3: ✍️ Post Creator [+ Memory + RAG]
    ↓ (English post)
    ├─→ Agent 4: 🎨 Image Generator
    └─→ Agent 5: 🇷🇺 Russian Translator [+ RAG]
```

### Vector Store Architecture
```
┌─────────────────────────────────────────────────┐
│  ENGLISH BIBLE RAG                              │
│  Collection: "my-collection"                    │
│  Version: CSB (Christian Standard Bible)       │
│  Embeddings: Google Gemini                      │
│  Mode: retrieve-as-tool                         │
│  Connected to: ✍️ Post Creator                 │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  RUSSIAN BIBLE RAG                              │
│  Collection: "russian-bible-collection"         │
│  Version: Synodal (Синодальный перевод)         │
│  Embeddings: Google Gemini                      │
│  Mode: retrieve-as-tool                         │
│  Connected to: 🇷🇺 Russian Post Creator        │
└─────────────────────────────────────────────────┘
```

### Memory System
```
┌─────────────────────────────────────────────────┐
│  💭 SESSION-BASED MEMORY                        │
│                                                 │
│  Type: Buffer Window                            │
│  Window Size: 10 messages                       │
│  Session Key: username or chatId                │
│  Persistence: Across executions                 │
│  Connected to: ✍️ Post Creator                 │
│                                                 │
│  Example Sessions:                              │
│  • user123 → [msg1, msg2, ..., msg10]         │
│  • user456 → [msg1, msg2, ..., msg10]         │
│  • user789 → [msg1, msg2, ..., msg10]         │
└─────────────────────────────────────────────────┘
```

## 📊 Data Flow Diagram

```
┌─────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Telegram│────→│  Config  │────→│  Switch  │────→│  Merge   │
└─────────┘     └──────────┘     └──────────┘     └──────────┘
                                      │                  │
                                      │                  │
                              ┌───────┴──────┐          │
                              │              │          │
                          ┌───▼───┐      ┌───▼───┐     │
                          │ Voice │      │ Text  │     │
                          │ Path  │      │ Path  │     │
                          └───┬───┘      └───┬───┘     │
                              │              │          │
                              └──────┬───────┘          │
                                     │                  │
                                     └──────────────────┘
                                            │
                                            ↓
                                     ┌──────────┐
                                     │Normalize │
                                     └─────┬────┘
                                           │
                      ┌────────────────────┼────────────────────┐
                      │                    │                    │
                      ↓                    ↓                    ↓
              ┌──────────┐         ┌──────────┐        ┌──────────┐
              │  Date    │────────→│ Calendar │───────→│  Theme   │
              │  Time    │         │ Context  │        │ Selector │
              └──────────┘         └──────────┘        └─────┬────┘
                                                              │
                                                              ↓
                                                       ┌──────────┐
                                                       │   Post   │
                                                       │ Creator  │◄──Memory
                                                       │          │◄──Bible RAG
                                                       └─────┬────┘
                                                             │
                          ┌──────────────────────────────────┼──────────────┐
                          │                                  │              │
                          ↓                                  ↓              ↓
                   ┌─────────────┐                   ┌──────────┐   ┌─────────────┐
                   │    Image    │                   │   Text   │   │   Russian   │
                   │  Generator  │                   │  Output  │   │  Translator │◄─Russian RAG
                   └──────┬──────┘                   └─────┬────┘   └──────┬──────┘
                          │                                │               │
                          ↓                                ↓               ↓
                   ┌─────────────┐                   ┌──────────┐   ┌─────────────┐
                   │Send Image to│                   │Send Text │   │Send Russian │
                   │  Telegram   │                   │to Telegram│   │to Telegram  │
                   └─────────────┘                   └──────────┘   └─────────────┘
```

## 🔧 Configuration Node Structure

```
⚙️ Workflow Configuration
├── imageModel: "fal-ai/flux/schnell"
├── imageWidth: 1024
├── imageHeight: 1024
├── maxMemoryMessages: 10
└── enableVoiceInput: true

Referenced by:
• ⚙️ Set Image Parameters → uses imageModel, imageWidth, imageHeight
• 💭 Conversation Memory → uses maxMemoryMessages
• 🔀 Route Input Type → checks enableVoiceInput (future)
```

## 🎨 AI Agent System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    AI AGENT ECOSYSTEM                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Agent 1: 🗓️ Irish Calendar Context                        │
│  ├─ Model: Google Gemini                                    │
│  ├─ Input: Current date/time (Europe/Dublin)                │
│  ├─ Output: Liturgical season, feast days, themes           │
│  └─ Format: Structured 4-field response                     │
│                                                              │
│  Agent 2: 🎯 Spiritual Theme Selector                       │
│  ├─ Model: Google Gemini                                    │
│  ├─ Input: Calendar context + user request                  │
│  ├─ Output: ONE theme from 13 categories                    │
│  └─ Examples: "Hope in Trials", "Trust in God"              │
│                                                              │
│  Agent 3: ✍️ Bible Quotation Post Creator                  │
│  ├─ Model: Google Gemini                                    │
│  ├─ Tools: English Bible RAG (Qdrant)                       │
│  ├─ Memory: Session-based (10 messages)                     │
│  ├─ Input: Theme + calendar + conversation history          │
│  ├─ Output: 150-250 word post with verse + reflection       │
│  └─ Style: Warm, compassionate, engaging                    │
│                                                              │
│  Agent 4: 🎨 Biblical Image Prompt Generator                │
│  ├─ Model: Google Gemini                                    │
│  ├─ Input: Post content from Agent 3                        │
│  ├─ Output: JSON with prompt/style/mood/colors              │
│  ├─ Style: Cinematic photography, natural lighting          │
│  └─ Symbolism: Hope→Sunrise, Peace→Still water, etc.        │
│                                                              │
│  Agent 5: 🇷🇺 Russian Post Translator                      │
│  ├─ Model: Google Gemini                                    │
│  ├─ Tools: Russian Bible RAG (Qdrant - Synodal)             │
│  ├─ Input: English post from Agent 3                        │
│  ├─ Output: Russian post with authentic Bible quote         │
│  └─ Culture: Orthodox terminology, Russian spirituality     │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## 🎯 Output Channels

```
┌────────────────────────────────────────────────────────────┐
│                    TRIPLE OUTPUT SYSTEM                    │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Channel 1: 📤 English Text Post                          │
│  ├─ Platform: Telegram                                    │
│  ├─ Format: Text message                                  │
│  ├─ Content: Reflection + Bible verse + question          │
│  ├─ Length: 150-250 words                                 │
│  └─ Features: Emojis, formatted text                      │
│                                                            │
│  Channel 2: 🖼️ Biblical Image                            │
│  ├─ Platform: Telegram                                    │
│  ├─ Format: Photo message                                 │
│  ├─ Generation: FAL.ai API                                │
│  ├─ Style: Cinematic, warm, natural                       │
│  ├─ Dimensions: 1024x1024 (configurable)                  │
│  └─ Features: Symbolic, atmospheric, peaceful             │
│                                                            │
│  Channel 3: 📤 Russian Text Post                          │
│  ├─ Platform: Telegram                                    │
│  ├─ Format: Text message                                  │
│  ├─ Content: Russian reflection + Synodal verse           │
│  ├─ Translation: Cultural adaptation, not literal         │
│  └─ Features: Orthodox terminology, Cyrillic text         │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## 📈 Workflow Metrics

```
┌──────────────────────────────────────────┐
│  PERFORMANCE CHARACTERISTICS             │
├──────────────────────────────────────────┤
│  Input Methods: 2 (text, voice)          │
│  Processing Paths: 2 (merge at normalize)│
│  AI Agents: 5                            │
│  Vector Stores: 2                        │
│  Output Channels: 3                      │
│  Languages: 2 (English, Russian)         │
│  Total Nodes: 48                         │
│  Total Connections: 41                   │
│  Memory: Session-based (10 msg window)   │
│  Transcription: OpenAI Whisper           │
│  Image Generation: FAL.ai Flux Schnell   │
└──────────────────────────────────────────┘
```

## 🔍 Detailed Node Breakdown

### Trigger Nodes (1)
- 📱 Telegram User Input (webhook)

### Configuration (1)
- ⚙️ Workflow Configuration

### Routing & Logic (4)
- 🔀 Route Input Type (switch)
- 🔗 Merge Text & Voice Inputs
- 🔄 Normalize Input
- Parse Image Prompt JSON

### Voice Processing (3)
- 📥 Get Voice File Info
- 📥 Download Voice from Telegram
- 🎙️ Transcribe Voice (Whisper)

### Time & Context (2)
- 📅 Get Irish Date/Time
- ⚙️ Set Image Parameters

### AI Agents (5)
- 🗓️ Irish Calendar Context
- 🎯 Select Spiritual Theme
- ✍️ Create Bible Quotation Post
- 🎨 Generate Image Prompt
- 🇷🇺 Russian Post Creator

### AI Models (5)
- Gemini Model (Calendar)
- Gemini Model (Theme Selector)
- Gemini Model (Post Creator)
- Gemini Model (Image Prompt)
- Gemini Model (Russian)

### Memory (1)
- 💭 Conversation Memory

### Vector Stores (2)
- 📖 Search Bible Verses (English CSB)
- 📖 Russian Bible Search (Synodal)

### Embeddings (4)
- Embeddings (Retrieval - English)
- Embeddings Google Gemini2 (Storage - English)
- Russian Embeddings Retrieval
- Russian Embeddings Storage

### Data Loaders (2)
- Default Data Loader1 (English)
- Russian Data Loader

### Image Generation (4)
- Build Image API Request
- Set Image Filename
- 🖼️ Generate Biblical Image (FAL.ai)

### Output Nodes (3)
- 📤 Send Text Post to User
- 📤 Send Image to User
- 📤 Send Russian Post

### Data Processing (7)
- Extract Bible Text from PDF
- Russian Bible OT Extract
- Russian Bible NT Extract
- HTTP Request - Download Bible PDF
- Russian Bible OT Download
- Russian Bible NT Download
- 💾 Store Bible in Vector DB
- Russian Bible Store

### Documentation (2)
- Sticky Note - Architecture
- Sticky Note - Error Handling

## 🔐 Credentials Required

```
┌────────────────────────────────────────┐
│  REQUIRED CREDENTIALS                  │
├────────────────────────────────────────┤
│  1. Telegram API                       │
│     • Bot token                        │
│     • Used by: Trigger, Send messages  │
│                                        │
│  2. Google Gemini API                  │
│     • API key                          │
│     • Used by: 5 AI agents, 4 embeddings│
│                                        │
│  3. Qdrant API                         │
│     • URL + API key                    │
│     • Used by: 2 vector stores         │
│                                        │
│  4. OpenAI API ⚠️ (NEW - REQUIRED)    │
│     • API key                          │
│     • Used by: Whisper transcription   │
│     • Status: NEEDS CONFIGURATION      │
│                                        │
│  5. FAL.ai API                         │
│     • API key (in Build API Request)   │
│     • Used by: Image generation        │
└────────────────────────────────────────┘
```

---

*This diagram represents the enhanced Bible Quotations workflow v2.0*  
*Generated: January 11, 2026*  
*Total Complexity: 48 nodes, 41 connections, 5 AI agents, 2 RAG systems*
