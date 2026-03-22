<div align="center">
  <img src="assets/icon/app_icon.png" width="128" />
  <h1>Aurora</h1>
  <p>Cross-platform AI client built with Flutter</p>
  <a href="README_zh.md">中文</a>
</div>

## Preview

<p align="center">
  <img src="docs/images/1.jpeg" height="340" />
  <span>&nbsp;&nbsp;&nbsp;&nbsp;</span>
  <img src="docs/images/3.png" height="340" />
</p>
<p align="center">
  <img src="docs/images/2.jpg" height="340" />
  <span>&nbsp;&nbsp;&nbsp;&nbsp;</span>
  <img src="docs/images/4.png" height="340" />
</p>

## About

Local-first cross-platform AI client. Chat, MCP, Skills, knowledge base, translation, and sync in one app.

- Multi-provider, multi-protocol routing with flexible model composition.
- Core data stored locally by default.

## Platform Support

| Platform | Status | Notes |
| --- | --- | --- |
| Windows | ✅ | Primary desktop platform. Fluent style, window management, tray, desktop Skills. |
| macOS | ✅ | Full desktop features with native layout. |
| Linux | ✅ | Full desktop features. |
| Android | ✅ | Mobile-adapted with attachments and Bottom Sheet interaction. |
| iOS | ✅ | Mobile-adapted with attachments and Bottom Sheet interaction. |

## Features

### 1. Chat & Session Management

- Locally persisted chat history, session tree, topics, token stats, and attachment references.
- Tree-style history with search, rename, delete, drag-to-reorder, and session branching.
- Streaming output, thinking/reasoning display, message retry, edit, and delete.
- `@` to switch models, `/` to switch presets in the input area.
- Markdown, code blocks, tables, images, footnotes, and LaTeX rendering.
- Message bubbles show TTFT, TPS, token usage, timestamps, and tool output.

### 2. Multi-Provider & Model Routing

- Built-in OpenAI and custom providers, compatible with OpenAI API, Gemini Native, and Anthropic Messages.
- Model list fetching, capability-based routing, provider/model toggle and sorting.
- Multi API key rotation, request timeout, global/model-level parameter configuration.
- Assign models per capability: chat, embeddings, image, speech, transcription, translation.

### 3. Assistant System

- Multiple assistants, each with its own avatar, name, description, and system prompt.
- Each assistant can bind independent Skills, MCP servers, and knowledge bases.
- Assistant-level long-term memory with configurable Provider/Model for memory distillation, or follow the current chat model.
- Memory auto-distills user preferences (language, length, format, tone, code style, etc.).

### 4. MCP & Tool Calling

- Transport: `stdio`, `streamable HTTP`.
- Connection testing, status view, reconnect, latency display, tool caching, error output.
- Three-level binding: global, session, assistant.
- Expose MCP tools directly to models during chat.

> `stdio` is desktop-only; mobile exposes HTTP-type MCP servers only.

### 5. Skills Plugins

- Reads `SKILL.md` / `SKILL_<lang>.md` from `skills/` to declare local skills as callable tools.
- Tool types: shell, HTTP, API.
- Models can auto-select and execute based on skill manuals.
- Suitable for packaging fixed workflows into reusable plugins.

> Shell-type Skills are desktop-only.

### 6. Knowledge Base (RAG)

- Create local knowledge bases, import files for chunked retrieval.
- Lexical search + optional embeddings search.
- Retrieval results injected into context; models can rewrite the search query.
- Assistants can bind independent knowledge bases.

### 7. Web Search & Translation

- Built-in web search; results injected into conversation before generating answers.
- Search configurable by engine, region, safe search, result count, timeout.
- Standalone translation page with auto language detection, side-by-side view, one-click copy.

### 8. Multimodal

- Image, audio, video, and file attachment input.
- With compatible models: image understanding, audio transcription, translation, image generation, etc.

> Actual capabilities depend on provider, model, and routing configuration.

### 9. UI, Settings & Operations

- Bilingual (EN/ZH), light/dark/custom themes, accent color, background image, blur and brightness control.
- Desktop tray, window close behavior configuration, recent session restore.
- Prompt presets with `{time}`, `{user_name}`, `{system}`, `{device}`, `{language}`, `{clipboard}` variables.
- Built-in log viewer, error records, usage statistics, model capability lab.

### 10. Sync & Backup

- WebDAV remote backup, restore, and management.
- Local export/import.
- Selective backup scope: chat history, presets, provider config, app settings, assistants, knowledge bases, usage stats.

## Project Structure

```text
lib/
  core/        Infrastructure, bootstrap, and common utilities
  features/    Chat, assistant, MCP, knowledge base, sync, etc.
  l10n/        Internationalization resources
  shared/      Shared services, themes, components, and tools
packages/
  aurora_search/  Search capability wrapper
skills/
  Skill examples and extension entry point
```

## Limitations

- Shell Skills and `stdio` MCP are desktop-only; mobile uses HTTP MCP.
- Multimodal capabilities (image, speech, transcription, translation) depend on actual model support.

## License

MIT License
