---
id: weather_fetcher
name: "全球天气查询 (OpenWeatherMap)"
description: "跨平台插件：通过 OpenWeatherMap HTTP 接口查询全球实时天气。"
platforms: [all]
enabled: false
tools:
  - name: get_weather
    description: "通过经纬度获取指定位置的当前天气信息。"
    type: http
    command: "https://api.openweathermap.org/data/2.5/weather?lat={{lat}}&lon={{lon}}&appid={{appid}}&units={{units}}&lang={{lang}}"
    method: GET
    input_schema:
      type: object
      properties:
        lat:
          type: number
          description: "纬度 (Latitude)"
        lon:
          type: number
          description: "经度 (Longitude)"
        appid:
          type: string
          description: "OpenWeatherMap API Key. 如果用户没提供，建议提醒用户前往官网获取。"
        units:
          type: string
          description: "度量单位，可选：standard, metric (摄氏度), imperial (华氏度)。默认为 metric。"
          default: "metric"
        lang:
          type: string
          description: "返回语言，如 zh_cn (中文), en (英文)。默认为 zh_cn。"
          default: "zh_cn"
      required: [lat, lon, appid]
    input_examples:
      - lat: 31.23
        lon: 121.47
        appid: "YOUR_API_KEY"
        units: "metric"
        lang: "zh_cn"
---

# OpenWeatherMap 使用指南

1. **获取 API Key**: 用户需要从 [OpenWeatherMap 官网](https://openweathermap.org/api) 获取免费的 AppID。
2. **多端支持**: 由于采用了 `type: http`，此插件在 Android、iOS 及 PC 端均可完美运行。
3. **坐标查询**: AI 在调用前应先尝试获取或确认用户的经纬度坐标（可以结合其他位置插件或要求用户提供）。

## 返回示例参考
当调用成功时，你会收到如下格式的 JSON：
- `main.temp`: 当前温度
- `weather[0].description`: 天气状况描述
- `name`: 城市名称
