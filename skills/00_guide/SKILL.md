---
id: skill_guide
name: "插件开发指南"
description: "详细解释如何构建、配置及优化你的自定义 AI 插件。"
locked: true
for_ai: false
---

# 欢迎使用 Aurora 插件系统
本指南旨在帮助你快速掌握如何通过 `SKILL.md` 扩展 AI 的能力。

## 1. 核心参数说明

| 参数 | 类型 | 用途 | 示例 |
| :--- | :--- | :--- | :--- |
| `id` | String | 插件唯一标识符，用于工具命名前缀。 | `translate_helper` |
| `name` | String | 在 UI 界面显示的标题。 | `翻译助手` |
| `description` | String | 简短的功能描述。 | `帮用户翻译各种语言。` |
| `is_locked` | Boolean | 若为 `true`，则该插件置顶且不可删除/停用。 | `true` |
| `enabled` | Boolean | 控制插件当前是否对 AI 可见。 | `true` |
| `for_ai` | Boolean | 若为 `false`，则该插件仅供人类阅读，不占用 AI 提示词空间。 | `false` |
| `platforms`| List    | 限定插件运行平台。可选：`windows`, `android`, `ios`, `desktop`, `mobile` 等。默认为 `all`。 | `[windows, android]` |

## 2. 规范与最佳实践 (Best Practices)

### 命名规范
为了获得最佳的 AI 理解效果，请遵循以下约定：
- **ID/Name**: 使用小写字母、数字和连字符（如 `my-tool-v1`）。
- **动词开头**: 工具名建议以动词开头（如 `get_weather`, `run_code`）。

### 工具示例 (Input Examples)
Anthropic 强烈建议为复杂工具提供示例。可以通过 `input_examples` 字段添加：
```yaml
tools:
  - name: calculate_sum
    input_examples:
      - numbers: [1, 2, 3]
      - numbers: [10.5, 20]
```
这些示例能显著提升 AI 在面对模糊输入时的调用准确率。

## 3. 工具定义 (Tools)
在 `tools` 列表中定义 AI 可以调用的功能。

### Shell 类型 (仅限 PC 端)
```yaml
- name: execute_cmd
  type: shell
  command: "ls -la {{path}}" # 使用 {{arg}} 作为占位符
  input_schema:
    type: object
    properties:
      path: { type: string, description: "路径" }
```

### HTTP 类型 (跨平台支持)
```yaml
- name: get_api
  type: http
  command: "https://api.example.com/data"
  method: "POST" # 可选 GET/POST
```

## 3. 指令说明 (Instructions)
在 `---` 分隔符下方编写 Markdown 内容。这些内容会被直接加入到 AI 的 `System Prompt` 中。
- **Tips**: 这里可以写具体的处理规则、输出格式或是约束条件。

## 4. 开发技巧
- **调试**: 使用 Shell 模式时，建议先在终端手动跑通命令。
- **变量**: 确保 `input_schema` 里的属性名与 `command` 里的 `{{name}}` 完全对应。
- **跨平台**: 如果你的插件要在移动端使用，请务必提供 `http` 类型的工具。
