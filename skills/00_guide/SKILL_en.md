---
name: skill-guide
description: Official Skill development guide, including directory structure, metadata specifications, and build process. Only used to guide developers in creating new Skills.
locked: true
for_ai: false
---

# Official Skill Format Guide

This project follows the official Skill format standard. Each Skill is a standalone directory containing definition files and related resources.

## 1. Directory Structure

The standard Skill directory structure is as follows:

```text
skill-name/
├── SKILL.md (Required)
│   ├── YAML Frontmatter (Required)
│   │   ├── name: (Required)
│   │   └── description: (Required)
│   └── Markdown Instructions (Required)
└── Resources (Optional)
    ├── scripts/     - Executable code
    ├── references/  - Context documentation
    └── assets/      - Output files (templates, etc.)
```

## 2. SKILL.md Format Specifications

### YAML Frontmatter

The top of the `SKILL.md` file must contain YAML formatted metadata:

```yaml
---
name: your-skill-name
description: What this skill does and when to use it. Includes trigger context, file types, task types, and keywords users might mention.
---
```

**Field Requirements:**

| Field | Required | Format | Description |
| :--- | :--- | :--- | :--- |
| `name` | Yes | Lowercase, hyphens allowed, max 64 chars | Unique identifier for the skill. |
| `description` | Yes | Max 1024 chars | **Core Point**: Must include **WHAT** and **WHEN**. This is the key to triggering the skill. |

### Body Content

Below the metadata is the content in Markdown format:

```markdown
# Your Skill Name

[Instructions Section]
Clear, step-by-step instructions for Claude. Always use imperative/infinitive forms.

[Examples Section]
Concrete input/output examples.
```

> **Note**: Information about "When to use" should be in the `description`, **NOT** in the body content, because the body is only loaded *after* the skill is triggered by its description.

## 3. Operation Mechanism

Understanding the two-stage loading mechanism of a Skill is crucial:

### Phase 1: Routing
- The system reads only the `name` and `description` from the YAML Frontmatter.
- The LLM decides whether to utilize the skill based on the `description` (which includes What & When).
- **Key Point**: If the `description` is poorly written, the Skill will never be triggered.

### Phase 2: Execution
- Once a Skill is selected, the system injects the Markdown body (`Instructions` and `Examples`) into the current Context (System Prompt).
- **Key Point**: The body only needs to include **How** (Execution Instructions). Do not repeat verbose "When to use" conditions in the body to save Tokens.

## 4. Build Process

### Step 1: Understand Through Examples
Before creating a Skill, collect specific usage scenarios:
- "What functionality should this skill support?"
- "What will the user say to trigger this skill?" (e.g., "Remove red eye from this image", "Build a todo app")

### Step 2: Plan Reusable Content
Analyze examples to identify needed scripts and resources:
- **Scripts**: Code that needs to run every time (e.g., `scripts/rotate_pdf.py`).
- **Assets**: Boilerplate code or templates (e.g., `assets/hello-world/`).
- **References**: Static documentation to consult (e.g., `references/schema.md`).

### Step 3: Initialize Skill
Create the directory and initialize `SKILL.md`.

```bash
mkdir -p my-skill/{scripts,references,assets}
touch my-skill/SKILL.md
```

### Step 4: Edit Skill
Write the content of `SKILL.md`.

**Frontmatter Example:**
```yaml
---
name: docx-processor
description: Comprehensive document creation, editing, and analysis, supporting change tracking, comments, formatting preservation, and text extraction. Use when Claude needs to handle professional documents (.docx files): (1) create new docs, (2) modify or edit content, (3) handle tracked changes, (4) add comments, or any other document task.
---
```

**Body Structure Suggestions:**
```markdown
# Skill Name

## Getting Started
[Basic first steps]

## Core Workflows
[Step-by-step procedures]

## Extended Capabilities
- **Feature A**: See [FEATURE_A.md](references/feature_a.md)

## Examples
[Concrete input/output pairs]
```

### Step 5: Package Skill (Optional)
If explanation is needed, the skill folder can be packaged into a `.skill` file (zip format), verifying metadata and structure.

### Step 6: Iterate Based on Usage
- Use the skill on real tasks.
- Identify bottlenecks and inefficiencies.
- Only actual usage reveals needed improvements in SKILL.md or resources.
- Immediate feedback, immediate iteration.
