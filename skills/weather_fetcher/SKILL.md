---
name: weather-fetcher
description: 获取全球任何位置的实时天气信息。当用户询问“我想知道xx的天气”或“现在的温度是多少”时使用。
enabled: true
---

# Weather Fetcher

## Instructions
请运行 Python 脚本来获取数据，以避免 Windows 下 `curl` 命令兼容性问题。

### Script Path
`skills/weather_fetcher/scripts/weather.py`

### Parameters
1. `city`: 城市名称 (e.g. Beijing)
2. `api_key`: API Key (用户需提供或使用默认 key)
3. `--units`: (可选) 单位, 默认为 metric
4. `--lang`: (可选) 语言, 默认为 zh_cn

### Execution
```bash
python skills/weather_fetcher/scripts/weather.py <city> <api_key> [--units metric] [--lang zh_cn]
```

## Examples

**User**: "北京天气怎么样？" (Key: 12345)

**Assistant**:
```bash
python skills/weather_fetcher/scripts/weather.py Beijing 12345
```

**Output**:
```json
{
  "cod": "200",
  "list": [
    {
      "dt": 1661871600,
      "main": { "temp": 25.5 },
      "weather": [ { "description": "多云" } ]
    }
  ]
}
```
