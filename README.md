# Aurora

基于 Flutter 开发的 Windows 端 LLM 聊天客户端。目前项目处于早期开发阶段。

![Screenshot](https://via.placeholder.com/800x400?text=Aurora+Screenshot)

## 简介

Aurora 尝试在 Windows 平台上提供一个符合 Fluent Design 设计规范的 AI 聊天界面。主要目标是提供简洁、原生的使用体验。

## 功能

*   **界面**：使用 Fluent UI 组件库，支持深色/浅色主题及 Mica 效果。
*   **多模型支持**：支持 OpenAI 格式的 API 调用（包括 OpenAI, DeepSeek, 自定义端点等）。
*   **基础对话**：支持多会话管理，本地存储聊天记录。
*   **内容渲染**：支持 Markdown 渲染，包括代码块高亮。
*   **交互**：支持基础的快捷键操作和剪贴板与图片拖放功能。

## 开发与构建

本项目使用 Flutter 开发。

### 环境要求

*   Flutter SDK (3.0.0+)
*   Visual Studio (带 C++ 桌面开发工作负载)
*   Windows 10/11

### 构建步骤

1.  克隆仓库：
    ```bash
    git clone https://github.com/huangusaki/Aurora.git
    cd Aurora
    ```

2.  安装依赖：
    ```bash
    flutter pub get
    ```

3.  生成代码（必须步骤）：
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4.  运行调试：
    ```bash
    flutter run -d windows
    ```

## 配置说明

首次运行时，请在设置页面配置 API 提供商。

*   **API Key**：填入对应服务的 API Key。
*   **Base URL**：
    *   OpenAI: `https://api.openai.com/v1`
    *   本地 Ollama: `http://localhost:11434/v1`
    *   其他兼容 OpenAI 接口的服务均可使用。

## License

MIT License
