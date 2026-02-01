---
name: code-executor
description: 执行 Python 代码以进行数学计算、数据处理、字符串操作或算法验证。当遇到复杂的逻辑问题或需要精确计算时使用。


enabled: true---

# Code Executor

## Instructions
本技能提供了一个安全的 Python 执行环境。
你需要使用提供的 Python 脚本 `scripts/execute.py` 来运行代码。

### Steps
1. **编写代码**: 生成简洁、高效的 Python 代码。
2. **执行代码**:
   使用 Python 运行 `scripts/execute.py`，可以通过 `--code` 参数传递代码字符串。
   ```bash
   python skills/code_executor/scripts/execute.py --code "print('Hello World')"
   ```
   *注意*: 对于复杂的代码，建议将其写入临时文件然后运行，或者确保命令行转义正确。

## Examples

**User**: "计算 100 以内的斐波那契数列。"
**Assistant**:
```bash
python skills/code_executor/scripts/execute.py --code "a, b = 0, 1; result = []; 
while a < 100: result.append(a); a, b = b, a+b; 
print(result)"
```
**Output**: 
`[0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]`

**User**: "验证 'racecar' 是否是回文。"
**Assistant**:
```bash
python skills/code_executor/scripts/execute.py --code "s = 'racecar'; print(s == s[::-1])"
```
**Output**: 
`True`
