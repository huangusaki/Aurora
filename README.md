# Aurora

基于 Flutter 开发的跨平台 LLM 聊天客户端，支持 Windows 和 Android，简洁流畅为主要开发目的。

## 简介

Aurora 旨在提供简洁、原生的多平台使用体验。
*   **Windows**: 遵循 Fluent Design 设计规范，支持 Mica 效果。
*   **Android**: 适配移动端交互体验。

## 界面预览

<p align="center">
  <img src="docs/images/defc395b-3baa-4ed9-8095-f7e1e485e644.png" width="45%" />
  <img src="docs/images/fd02b90e-4a3f-41c0-8300-9d99d8ca0435.png" width="45%" />
</p>
<p align="center">
  <img src="docs/images/85d78b54cd085042a5e38051d1efa379_720.jpg" width="45%" />
  <img src="docs/images/85f5e391d226c60a7cf575c3e21fb41e_720.jpg" width="45%" />
</p>

## 功能

*   **界面**：
    *   Windows 端采用 Fluent UI，支持深色/浅色主题及 Mica 效果。
    *   移动端适配触摸操作和布局。
*   **多模型支持**：支持 OpenAI 格式的 API 调用（包括 OpenAI, DeepSeek, 自定义端点等）。
*   **基础对话**：支持多会话管理，本地存储聊天记录。
*   **内容渲染**：支持 Markdown 渲染，包括代码块高亮。
*   **交互**：Desktop 端支持快捷键和拖放；Mobile 端支持基础手势。

## 开发与构建

本项目使用 Flutter 开发。

### 环境要求

*   Flutter SDK (3.0.0+)
*   **Windows**: Visual Studio (带 C++ 桌面开发工作负载)
*   **Android**: Android Studio / Android SDK
*   Windows 10/11 (用于构建 Windows 版本)

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

    *   **Windows**:
        ```bash
        flutter run -d windows
        ```
    *   **Android**:
        确保已连接设备或启动模拟器：
        ```bash
        flutter run -d android
        ```

## 配置说明

首次运行时，请在设置页面配置 API 提供商。

*   **API Key**：填入对应服务的 API Key。
*   **Base URL**：
    *   兼容 OpenAI 接口的服务均可使用。

## License

MIT License
