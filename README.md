# AI 旅游规划助手

> 基于 Flutter + FastAPI + LangChain + MCP 协议的跨平台智能旅行应用  
> Claude Code + DeepSeek 辅助开发

## 项目展示

<div align="center">

| 登录页 | 主页 | Prompt 页 |
|:---:|:---:|:---:|
| ![login](https://images.unsplash.com/photo-1436491865332-7a61a109bb05?w=200) | ![home](https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=200) | ![prompt](https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=200) |

</div>

---

## 技术栈

| 层级 | 技术 |
|------|------|
| **前端** | Flutter 3.x · Dart · Material 3 |
| **后端** | Python · FastAPI · Uvicorn |
| **AI/Agent** | LangChain · LangGraph · DeepSeek (deepseek-chat) |
| **MCP 工具** | 高德地图 API · 博查 AI 搜索 |
| **本地存储** | SQLite (sqflite) · SharedPreferences |
| **通信** | HTTP · JSON-RPC 2.0 · RESTful API |

## 项目架构

```
┌──────────────────────────┐       HTTP/REST       ┌──────────────────────────────┐
│   Flutter 前端             │ ←─────────────────→ │   FastAPI Agent 后端 (:9000)   │
│                           │                      │                               │
│  • Material 3 主题         │   POST /generate_trip│  • LangGraph ReAct Agent       │
│  • 10 个页面               │   POST /search_places│  • DeepSeek 大模型              │
│  • 自定义路由动画           │   POST /query_weather│  • MCP 工具调用                 │
│  • Drawer + BottomNav      │   GET  /health        │  • Pydantic 请求校验            │
│  • SQLite 收藏 + SP 暂存   │                      │  • CORS 跨域支持               │
└──────────────────────────┘                      └──────────────────────────────┘
                                                              │
                                                    ┌─────────┼─────────┐
                                                    │         │         │
                                                高德地图   高德天气   博查搜索
                                                MCP Tool   MCP Tool  MCP Tool
```

## 功能概览

| 功能 | 描述 |
|------|------|
| 🎨 **沉浸式 UI** | 渐变背景、半透明卡片、SliverAppBar 视差滚动、结构化 Markdown 渲染 |
| 🤖 **AI 行程规划** | 自然语言输入 → Agent 调用高德/天气/博查 → 生成完整行程 |
| 💬 **AI 智能对话** | 对话框形式 + SharedPreferences 长记忆，支持离线建议 |
| ⭐ **收藏系统** | SQLite 持久化目的地收藏 + SharedPreferences JSON 序列化 AI 计划 |
| 🗺️ **MCP 工具配置** | 动态发现 MCP 服务端工具列表，支持开关控制 |
| 🌙 **深色模式** | 亮色/暗色主题切换，SharedPreferences 持久化 |
| ✏️ **编辑资料** | 头像选择 / 昵称 / 个性签名修改 |
| 🔐 **登录/注册** | 表单校验 + 密码可见性切换 + 登录态持久化 |
| 📱 **多平台** | Windows / Android / Chrome Web |

## 快速开始

### 环境要求

- Flutter SDK >= 3.x
- Python >= 3.10
- Dart SDK >= 3.x

### 1. 克隆项目

```bash
git clone <your-repo-url>
cd travel_planner
```

### 2. 安装 Flutter 依赖

```bash
flutter pub get
```

### 3. 安装 Python 依赖

```bash
cd agent_backend
pip install -r requirements.txt
```

### 4. 配置 API Key

编辑 `agent_backend/.env`：

```env
DEEPSEEK_API_KEY=sk-your-deepseek-key
AMAP_API_KEY=your-amap-key
BOCHA_API_KEY=sk-your-bocha-key
```

### 5. 启动 Agent 后端

```bash
cd agent_backend
python agent_backend.py
# → http://localhost:9000
# → API 文档: http://localhost:9000/docs
```

### 6. 运行 Flutter App

```bash
# Windows 桌面
flutter run -d windows

# Android 模拟器（需先配置 MCP 地址为 http://10.0.2.2:9000）
flutter run -d android

# Chrome 浏览器
flutter run -d chrome
```

## 项目结构

```
travel_planner/
├── lib/                              # Flutter 前端
│   ├── main.dart                     # 入口：主题/路由/动画
│   ├── constants/
│   │   └── app_constants.dart        # 全局常量
│   ├── models/
│   │   ├── trip_model.dart           # 行程模型（JSON + SQLite）
│   │   └── tool_model.dart           # AI 工具模型
│   ├── pages/                        # 10 个页面
│   │   ├── login_page.dart           # 登录/注册
│   │   ├── home_page.dart            # 主页（Hero + Drawer + 收藏）
│   │   ├── chat_page.dart            # AI 智能对话（长记忆）
│   │   ├── prompt_page.dart          # AI Prompt 输入
│   │   ├── result_page.dart          # 行程结果展示 + 收藏
│   │   ├── detail_page.dart          # 景点详情
│   │   ├── tools_selection_page.dart # MCP 工具配置
│   │   ├── settings_page.dart        # 应用设置
│   │   ├── profile_page.dart         # 个人中心
│   │   └── edit_profile_page.dart    # 编辑资料
│   ├── services/                     # 服务层
│   │   ├── db_service.dart           # SQLite CRUD
│   │   ├── local_storage_service.dart# SharedPreferences 封装
│   │   ├── mcp_client_service.dart   # MCP HTTP 客户端
│   │   ├── mcp_config.dart           # MCP 动态配置
│   │   └── mock_data_service.dart    # 模拟数据（降级）
│   ├── utils/
│   │   └── ui_helper.dart            # Loading/Toast 工具
│   └── widgets/                      # 可复用组件
├── agent_backend/                    # Python Agent 后端
│   ├── agent_backend.py              # FastAPI + LangGraph + MCP
│   ├── requirements.txt              # Python 依赖
│   └── .env                          # API Key 配置
└── pubspec.yaml                      # Flutter 依赖
```

## 页面路由

| 路由 | 页面 | 说明 |
|------|------|------|
| `/login` | 登录/注册 | 表单校验 + 密码显示切换 |
| `/home` | 主页 | Hero 大图 + 搜索 + 分类 + 目的地列表 |
| `/chat` | AI 聊天 | 对话框 + 长记忆 + 快捷清空 |
| `/prompt` | AI Prompt | 自然语言输入 + 模板选择 |
| `/result` | 结果页 | Markdown 解析 + 结构化卡片 |
| `/detail` | 景点详情 | SliverAppBar 视差 + AI 生成入口 |
| `/tools` | MCP 工具 | 动态服务发现 + 开关配置 |
| `/settings` | 应用设置 | 深色模式 + 默认城市 + Agent 地址 |
| `/profile` | 个人中心 | 收藏列表 + 编辑资料 |
| `/edit_profile` | 编辑资料 | 头像/昵称/签名修改 |

## Agent API

| 方法 | 路径 | 描述 |
|------|------|------|
| `GET` | `/health` | 健康检查 |
| `POST` | `/generate_trip` | AI 生成行程规划 |
| `POST` | `/search_places` | 高德 POI 搜索 |
| `POST` | `/query_weather` | 天气查询 |

## 开发方式

本项目全程使用 **Claude Code** 作为 AI 编程助手，结合 **DeepSeek** 大模型进行 Agent 推理，覆盖需求分析 → 架构设计 → 编码实现 → 调试优化的全流程 AI 辅助开发。

- 累计 10 个 Flutter 页面、6 个 Service 层、3 个 Widget 组件
- `dart analyze` 零错误零警告
- 支持 Windows / Android / Chrome 三平台编译运行

## License

MIT
