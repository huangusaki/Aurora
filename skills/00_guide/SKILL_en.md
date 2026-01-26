---
id: skill_guide
name: "Plugin Development Guide"
description: "Detailed explanation of how to build, configure, and optimize your custom AI plugins."
locked: true
for_ai: false
---

# Welcome to Aurora Plugin System
This guide aims to help you quickly master how to extend AI capabilities via `SKILL.md`.

## 1. Core Parameters Explanation

| Parameter | Type | Purpose | Example |
| :--- | :--- | :--- | :--- |
| `id` | String | Unique identifier for the plugin, used as tool name prefix. | `translate_helper` |
| `name` | String | Title displayed in the UI. | `Translation Assistant` |
| `description` | String | Brief description of functionality. | `Helpers users translate various languages.` |
| `is_locked` | Boolean | If `true`, the plugin is pinned and cannot be deleted/disabled. | `true` |
| `enabled` | Boolean | Controls whether the plugin is currently visible to the AI. | `true` |
| `for_ai` | Boolean | If `false`, the plugin is for human reading only and does not consume AI prompt space. | `false` |
| `platforms`| List    | Limits the platform where the plugin runs. Options: `windows`, `android`, `ios`, `desktop`, `mobile`, etc. Default is `all`. | `[windows, android]` |

## 2. Standards & Best Practices

### Naming Conventions
For optimal AI understanding, please follow these conventions:
- **ID/Name**: Use lowercase letters, numbers, and hyphens (e.g., `my-tool-v1`).
- **Verb Start**: Tool names should start with a verb (e.g., `get_weather`, `run_code`).

### Tool Examples (Input Examples)
Anthropic strongly recommends providing examples for complex tools. You can add them via the `input_examples` field:
```yaml
tools:
  - name: calculate_sum
    input_examples:
      - numbers: [1, 2, 3]
      - numbers: [10.5, 20]
```
These examples significantly improve AI invocation accuracy when facing ambiguous inputs.

## 3. Tool Definitions (Tools)
Define functions that AI can call in the `tools` list.

### Shell Type (PC Only)
```yaml
- name: execute_cmd
  type: shell
  command: "ls -la {{path}}" # Use {{arg}} as placeholder
  input_schema:
    type: object
    properties:
      path: { type: string, description: "Path" }
```

### HTTP Type (Cross-Platform Support)
```yaml
- name: get_api
  type: http
  command: "https://api.example.com/data"
  method: "POST" # Optional GET/POST
```

## 3. Instructions
Write Markdown content below the `---` separator. This content will be directly added to the AI's `System Prompt`.
- **Tips**: You can write specific processing rules, output formats, or constraints here.

## 4. Development Tips
- **Debugging**: When using Shell mode, it is recommended to test the command manually in the terminal first.
- **Variables**: Ensure property names in `input_schema` match `{{name}}` in `command` exactly.
- **Cross-Platform**: If your plugin is intended for mobile use, make sure to provide `http` type tools.
