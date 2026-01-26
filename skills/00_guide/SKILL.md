---
name: skill-guide
description: 官方 Skill 开发指南，包含目录结构、元数据规范及构建流程。仅用于指导开发者创建新 Skill。
locked: true
for_ai: false
---

# 官方 Skill 开发格式指南

本项目遵循官方 Skill 格式标准。每个 Skill 都是一个独立的目录，包含定义文件和相关资源。

## 1. 目录结构

标准的 Skill 目录结构如下：

```text
skill-name/
├── SKILL.md (必需)
│   ├── YAML 前置元数据 (必需)
│   │   ├── name: (必需)
│   │   └── description: (必需)
│   └── Markdown 指令 (必需)
└── 打包资源 (可选)
    ├── scripts/     - 可执行代码
    ├── references/  - 上下文文档
    └── assets/      - 输出文件（模板等）
```

## 2. SKILL.md 格式规范

### YAML 前置元数据 (Frontmatter)

`SKILL.md` 文件的顶部必须包含 YAML 格式的元数据：

```yaml
---
name: your-skill-name
description: 这个技能做什么以及何时使用。包括触发上下文、文件类型、任务类型和用户可能提及的关键词。
---
```

**字段要求：**

| 字段 | 必需 | 格式 | 说明 |
| :--- | :--- | :--- | :--- |
| `name` | 是 | 小写，允许连字符，最多 64 字符 | 技能的唯一标识名。 |
| `description` | 是 | 最多 1024 字符 | **核心要点**：必须包含 **WHAT** (做什么) 和 **WHEN** (何时使用)。这是触发技能的关键。 |

### 主体内容

元数据下方是 Markdown 格式的指令内容：

```markdown
# Your Skill Name

[指令部分]
Claude 的清晰、分步指导。始终使用祈使/不定式形式。

[示例部分]
具体的输入/输出示例。
```

> **注意**：「何时使用」的信息应放在 `description` 中，**不要** 放在主体内容里，因为主体内容只有在其 description 触发技能后才会被加载。

## 3. 运行机制 (Mechanism)

理解 Skill 的两阶段加载机制至关重要：

### 阶段 1：路由 (Routing)
- 系统仅读取 YAML Frontmatter 中的 `name` 和 `description`。
- LLM 根据 `description` (包含了 What & When) 来决定是否需要调用该技能。
- **关键点**：如果 `description` 写得不好，Skill 永远不会被触发。

### 阶段 2：执行 (Execution)
- 一旦 Skill 被选中，系统会将 Markdown 主体部分 (`Instructions` 和 `Examples`) 注入到当前的 Context (System Prompt) 中。
- **关键点**：主体内容只需包含 **How** (如何操作)。不要在主体中重复冗长的“何时使用”条件，以节省 Token 开销。

## 4. 构建流程 (Build Process)

### 步骤 1：通过具体示例理解
在创建 Skill 之前，先收集具体使用场景：
- 「这个技能应该支持什么功能？」
- 「用户会说什么来触发这个技能？」（例如："从这张图像中去除红眼", "构建一个待办应用"）

### 步骤 2：规划可复用内容
分析示例，识别需要的脚本和资源：
- **Scripts**: 每次执行都需要运行的代码 (如 `scripts/rotate_pdf.py`)。
- **Assets**: 样板代码或模板 (如 `assets/hello-world/`)。
- **References**: 需要查阅的静态文档 (如 `references/schema.md`)。

### 步骤 3：初始化 Skill
创建目录并初始化 `SKILL.md`。

```bash
mkdir -p my-skill/{scripts,references,assets}
touch my-skill/SKILL.md
```

### 步骤 4：编辑 Skill
编写 `SKILL.md` 的内容。

**Frontmatter 示例：**
```yaml
---
name: docx-processor
description: 综合文档创建、编辑和分析，支持跟踪更改、评论、格式保留和文本提取。当 Claude 需要处理专业文档（.docx 文件）时使用：(1) 创建新文档，(2) 修改或编辑内容，(3) 处理跟踪更改，(4) 添加评论，或任何其他文档任务。
---
```

**主体结构建议：**
```markdown
# Skill Name

## Getting Started
[基本的第一步]

## Core Workflows
[分步程序]

## Extended Capabilities
- **Feature A**: See [FEATURE_A.md](references/feature_a.md)

## Examples
[具体的输入/输出对]
```

### 步骤 5：打包 Skill (可选)
如果需要分发，可以将技能文件夹打包成 `.skill` 文件（zip 格式），并验证元数据和结构。

### 步骤 6：基于使用迭代
- 在真实任务上使用技能。
- 识别瓶颈与低效环节。
- 只有在实际使用中才能发现 SKILL.md 或资源需要的改进。
- 即时反馈，即刻迭代。
