---
id: code_executor
name: "Python 解释器"
description: "允许 AI 执行 Python 代码并获取结果。"
enabled: false
platforms: [desktop]
tools:
  - name: execute_python
    description: "在本地环境中执行 Python 代码并返回 stdout/stderr。"
    type: shell
    command: "python -c \"{{code}}\""
    input_schema:
      type: object
      properties:
        code:
          type: string
          description: "要执行的完整 Python 代码字符串。"
      required: [code]
---

# 使用指南
1. 当用户要求进行数学计算、数据处理或验证想法时，你可以使用此工具。
2. 始终直接输出代码运行的结果，不要臆造。
3. 如果代码运行报错（stderr），你可以根据错误提示尝试修复代码。
