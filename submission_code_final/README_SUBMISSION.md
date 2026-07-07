# AI 旅游规划助手 - 作业代码文件

本文件夹只保留作业运行需要的核心代码文件，可覆盖到新建 Flutter 项目中运行。

## 目录说明

- `lib/`：Flutter 前端页面、模型、服务和组件代码。
- `agent_backend/`：AI 后端服务代码，包含 LangChain Agent、工具调用、短期会话记忆和行程存储接口。
- `mcp_server/`：MCP 工具服务代码。
- `android/app/src/main/AndroidManifest.xml`：Android 网络访问配置。
- `pubspec.yaml`、`analysis_options.yaml`：Flutter 项目依赖与分析配置。

## 运行方式

1. 新建 Flutter 项目后，将本文件夹内容复制覆盖到项目根目录。
2. 在项目根目录执行：

```powershell
flutter pub get
flutter run
```

3. 启动 AI 后端：

```powershell
cd agent_backend
pip install -r requirements.txt
copy .env.example .env
```

将 `.env` 中的占位内容替换为自己的 API Key 后执行：

```powershell
python agent_backend.py
```

4. 如需启动 MCP 服务：

```powershell
cd mcp_server
pip install -r requirements.txt
python travel_server.py
```

## 注意事项

提交包内未包含真实 API Key。运行前请在本地 `.env` 中配置自己的密钥。
