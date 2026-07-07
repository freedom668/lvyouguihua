"""
======================================================================
AI 旅游规划 Agent 后端
======================================================================

技术栈:
  - FastAPI: HTTP API 服务
  - LangChain: Agent 框架
  - DeepSeek (deepseek-chat): 大语言模型
  - 高德地图 MCP: 地点搜索 / 天气查询
  - 博查 AI 搜索 MCP: 网络搜索增强

启动方式:
  1. 安装依赖: pip install -r requirements.txt
  2. 配置环境: cp .env.example .env (填写 API Key)
  3. 启动服务: python agent_backend.py
  4. API 文档: http://localhost:9000/docs

API:
  POST /generate_trip  — AI 生成旅游行程
  POST /search_places  — 搜索目的地周边
  POST /query_weather  — 查询目的地天气
  GET  /health         — 健康检查
======================================================================
"""

import os
import json
from typing import Optional

import httpx
import requests
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# LangChain + LangGraph
from langchain_core.tools import tool
from langchain_core.messages import HumanMessage
from langchain_openai import ChatOpenAI
from langchain.agents import create_agent

# ============================================================
# 环境配置
# ============================================================
load_dotenv()

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "")
AMAP_API_KEY = os.getenv("AMAP_API_KEY", "")
BOCHA_API_KEY = os.getenv("BOCHA_API_KEY", "")

# ============================================================
# DeepSeek 大模型 (通过 LangChain ChatOpenAI 兼容接口)
# ============================================================
llm = ChatOpenAI(
    model="deepseek-chat",
    openai_api_key=DEEPSEEK_API_KEY,
    openai_api_base="https://api.deepseek.com",
    temperature=0.7,
    max_tokens=4096,
)

# ============================================================
# MCP 工具 1: 高德地图 POI 搜索
# ============================================================
@tool
def amap_search_tool(query: str) -> str:
    """
    高德地图 POI 地点搜索工具。

    用途: 搜索目的地的景点、酒店、餐厅、商场等 POI 信息。
    参数: query — 搜索关键词，格式为 "城市 类型"，如 "广州长隆"、"三亚酒店"、"杭州西湖"。
    返回: 真实的地点名称、地址、类型、评分等。
    """
    url = "https://restapi.amap.com/v3/place/text"
    params = {
        "keywords": query,
        "key": AMAP_API_KEY,
        "offset": 10,
        "extensions": "all",
    }

    try:
        resp = requests.get(url, params=params, timeout=10)
        data = resp.json()

        if data.get("status") != "1":
            return f"高德地图搜索失败: {data.get('info', '未知错误')}"

        pois = data.get("pois", [])
        if not pois:
            return f"未找到与「{query}」相关的地点。"

        results = [f"📍 高德地图搜索「{query}」结果 (共{data.get('count', 0)}条):"]
        for i, poi in enumerate(pois[:8], 1):
            name = poi.get("name", "未知")
            address = poi.get("address", "未知地址")
            poi_type = poi.get("type", "")
            rating = poi.get("biz_ext", {}).get("rating", "")
            rating_str = f" ⭐{rating}" if rating else ""
            results.append(f"\n{i}. {name}{rating_str}")
            results.append(f"   📍 {address}")
            results.append(f"   🏷️ {poi_type}")

        return "\n".join(results)

    except Exception as e:
        return f"高德地图查询异常: {str(e)}"


# ============================================================
# MCP 工具 2: 高德天气查询
# ============================================================
@tool
def weather_tool(city: str) -> str:
    """
    天气查询工具。

    用途: 查询指定城市未来几天的天气预报。
    参数: city — 城市名称，如 "三亚"、"北京"、"杭州"。
    返回: 未来几天天气情况，包括温度、湿度、风力、天气现象。
    """
    # 1. 先通过高德获取城市编码
    geo_url = "https://restapi.amap.com/v3/config/district"
    geo_params = {"keywords": city, "key": AMAP_API_KEY, "subdistrict": 0}

    try:
        geo_resp = requests.get(geo_url, params=geo_params, timeout=10)
        geo_data = geo_resp.json()

        if geo_data.get("status") != "1" or not geo_data.get("districts"):
            return f"未找到城市「{city}」，请检查城市名称。"

        adcode = geo_data["districts"][0].get("adcode")

        # 2. 查询天气
        weather_url = "https://restapi.amap.com/v3/weather/weatherInfo"
        weather_params = {"city": adcode, "key": AMAP_API_KEY, "extensions": "all"}

        weather_resp = requests.get(weather_url, params=weather_params, timeout=10)
        weather_data = weather_resp.json()

        if weather_data.get("status") != "1":
            return f"天气查询失败: {weather_data.get('info', '未知错误')}"

        forecasts = weather_data.get("forecasts", [])
        if not forecasts:
            return f"暂无「{city}」的天气预报数据。"

        forecast = forecasts[0]
        result = [f"🌤 {forecast.get('province', '')} {forecast.get('city', city)} 天气预报"]
        result.append(f"📅 发布时间: {forecast.get('reporttime', '')}\n")

        for day in forecast.get("casts", [])[:5]:
            date = day.get("date", "")
            week = day.get("week", "")
            day_weather = day.get("dayweather", "未知")
            night_weather = day.get("nightweather", "未知")
            day_temp = day.get("daytemp", "?")
            night_temp = day.get("nighttemp", "?")
            day_wind = day.get("daywind", "")
            day_power = day.get("daypower", "")

            weather_emoji = _weather_emoji(day_weather)
            result.append(
                f"{date} {week} {weather_emoji} {day_weather}转{night_weather}"
            )
            result.append(f"   🌡️ {night_temp}°C ~ {day_temp}°C | 💨 {day_wind} {day_power}级")

        return "\n".join(result)

    except Exception as e:
        return f"天气查询异常: {str(e)}"


def _weather_emoji(weather: str) -> str:
    """天气文字 → emoji 映射"""
    mapping = {
        "晴": "☀️", "多云": "⛅", "阴": "☁️", "小雨": "🌧",
        "中雨": "🌧", "大雨": "⛈", "暴雨": "⛈", "雪": "❄️",
        "雨夹雪": "🌨", "雾": "🌫", "霾": "🌫", "阵雨": "🌦",
        "雷阵雨": "⛈",
    }
    for key, emoji in mapping.items():
        if key in weather:
            return emoji
    return "🌤"


# ============================================================
# MCP 工具 3: 博查 AI 搜索（旅游攻略增强）
# ============================================================
@tool
def bocha_search_tool(query: str) -> str:
    """
    博查 AI 联网搜索工具。

    用途: 搜索互联网上的旅游攻略、景点介绍、游记、实时资讯。
    参数: query — 搜索关键词，如 "三亚旅游攻略"、"杭州三天两夜行程"。
    返回: 网络搜索结果摘要，包含标题和链接。
    """
    url = "https://api.bochaai.com/v1/web-search"
    headers = {
        "Authorization": f"Bearer {BOCHA_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {"query": query, "count": 5}

    try:
        resp = requests.post(url, json=payload, headers=headers, timeout=15)
        data = resp.json()

        if data.get("code") != 200:
            return f"博查搜索失败: {data.get('msg', '未知错误')}"

        webpages = data.get("data", {}).get("webPages", {}).get("value", [])
        if not webpages:
            return f"未找到与「{query}」相关的搜索结果。"

        results = [f"🔍 博查搜索「{query}」结果:"]
        for i, page in enumerate(webpages[:5], 1):
            name = page.get("name", "无标题")
            snippet = page.get("snippet", "")[:120]
            url_link = page.get("url", "")
            results.append(f"\n{i}. **{name}**")
            if snippet:
                results.append(f"   {snippet}")
            if url_link:
                results.append(f"   🔗 {url_link}")

        return "\n".join(results)

    except Exception as e:
        return f"博查搜索异常: {str(e)}"


# ============================================================
# 初始化 LangGraph ReAct Agent
# ============================================================
tools = [amap_search_tool, weather_tool, bocha_search_tool]

agent = create_agent(
    model=llm,
    tools=tools,
)

# ============================================================
# FastAPI 服务
# ============================================================
app = FastAPI(
    title="AI 旅游规划 Agent",
    description="基于 LangChain + DeepSeek + MCP 的智能旅游规划后端",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------- 请求/响应模型 ----------
class TripRequest(BaseModel):
    prompt: str = Field(
        default="推荐一个三亚5天4晚的行程",
        description="用户的旅游需求，可以是自然语言描述",
    )
    city: Optional[str] = Field(default=None, description="目的地城市（可选，从 prompt 中提取）")
    days: Optional[int] = Field(default=5, description="游玩天数")
    style: Optional[str] = Field(default="休闲", description="旅行风格：休闲/文化/美食/探险/蜜月")


class TripResponse(BaseModel):
    success: bool
    itinerary: str
    city: Optional[str] = None
    days: Optional[int] = None
    tools_used: list = []


class ChatRequest(BaseModel):
    query: str = Field(description="用户聊天消息")


class ChatResponse(BaseModel):
    success: bool
    reply: str


class SearchRequest(BaseModel):
    query: str = Field(description="搜索关键词")


class WeatherRequest(BaseModel):
    city: str = Field(description="城市名称")


# ---------- 接口 ----------
@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "travel-agent-backend", "version": "1.0.0"}


@app.post("/generate_trip", response_model=TripResponse)
async def generate_trip(request: TripRequest):
    """
    AI 生成旅游行程。

    接收用户自然语言需求，Agent 会自主调用高德地图搜索、
    天气查询、博查 AI 搜索等 MCP 工具，生成完整的行程规划。
    """
    try:
        # 构建详细的 Agent 提示词
        agent_prompt = _build_prompt(
            prompt=request.prompt,
            city=request.city,
            days=request.days,
            style=request.style,
        )

        print(f"\n{'='*60}")
        print(f"[REQUEST] {request.prompt[:80]}...")
        print(f"{'='*60}\n")

        # Agent 执行
        result = agent.invoke({"messages": [HumanMessage(content=agent_prompt)]})
        # 提取最后一条消息（Agent 的最终回复）
        itinerary = result["messages"][-1].content

        print(f"\n{'='*60}")
        print(f"[OK] Agent finished")
        print(f"{'='*60}\n")

        return TripResponse(
            success=True,
            itinerary=itinerary,
            city=request.city,
            days=request.days,
            tools_used=[t.name for t in tools],
        )

    except Exception as e:
        print(f"[ERROR] Agent failed: {e}")
        raise HTTPException(status_code=500, detail=f"AI 生成失败: {str(e)}")


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """AI 聊天助手 —— 简短回答旅游相关问题（天气/人流量/门票/美食等）。"""
    try:
        prompt = f"""你是一个专业的 AI 旅游助手，请简洁地回答用户的旅游相关问题。

用户问题: {request.query}

要求：
- 如果问题涉及具体城市/景点的天气，请使用 weather_tool 查询真实天气数据
- 如果问题涉及景点搜索/推荐/门票价格/人流量，请使用 amap_search_tool 搜索真实数据
- 如果问题涉及旅游攻略/注意事项，请使用 bocha_search_tool 搜索
- 回答要简洁直接，不超过 300 字
- 如果有人流量相关问题，结合景点评分和评论数给出建议
- 以友好的语气回复"""

        result = agent.invoke({"messages": [HumanMessage(content=prompt)]})
        reply = str(result["messages"][-1].content)
        return ChatResponse(success=True, reply=reply)
    except Exception as e:
        print(f"[ERROR] Chat failed: {e}")
        # 降级到离线回复
        return ChatResponse(success=False, reply=_offline_reply(request.query))


def _offline_reply(query: str) -> str:
    """离线降级回复"""
    tips = [
        "建议提前查看目的地天气，合理搭配衣物。",
        "热门景点建议提前网上购票，避免排队。",
        "出行前确认护照和签证有效期。",
        "建议购买旅游保险，以防意外。",
    ]
    import random
    random.shuffle(tips)
    return f"当前 AI 后端离线。关于「{query}」的建议：\n\n" + "\n".join(tips[:3])


@app.post("/search_places")
async def search_places(request: SearchRequest):
    """搜索目的地周边地点（直接调用高德 MCP）"""
    result = amap_search_tool.invoke({"query": request.query})
    return {"success": True, "data": result}


@app.post("/query_weather")
async def query_weather(request: WeatherRequest):
    """查询目的地天气（直接调用天气 MCP）"""
    result = weather_tool.invoke({"city": request.city})
    return {"success": True, "data": result}


# ---------- Prompt 构建 ----------
def _build_prompt(prompt: str, city: Optional[str], days: int, style: str) -> str:
    return f"""
你是一个专业的 AI 旅游规划助手。请根据以下用户需求，生成一份详细的旅行行程规划。

用户需求: {prompt}
{f"目的地城市: {city}" if city else ""}
游玩天数: {days} 天
旅行风格: {style}

在规划行程之前，请务必执行以下步骤：
1. 使用高德地图搜索工具 (amap_search_tool) 搜索目的地的热门景点、酒店和美食。
2. 使用天气查询工具 (weather_tool) 查询目的地未来几天的天气情况。
3. 使用博查 AI 搜索工具 (bocha_search_tool) 搜索相关的旅游攻略和游记。

最终输出的行程规划请包含以下内容：
📋 行程概览（目的地、天数、预算预估、天气提醒）
🗺️ Day 1 ~ Day {days} 每天详细安排（含景点、美食、交通建议）
💰 费用预估（交通、住宿、餐饮、门票）
💡 旅行贴士（注意事项、推荐装备、当地特色）
🎯 推荐景点 TOP 5（基于高德地图真实搜索结果的排名）

请确保信息来自你调用工具获取的真实数据，不要凭空编造。
"""


# ============================================================
# 启动入口
# ============================================================
if __name__ == "__main__":
    import uvicorn

    print("=" * 60)
    print("[AI Travel Planner Agent Backend]")
    print("=" * 60)
    print(f"DeepSeek: {'configured' if DEEPSEEK_API_KEY else 'MISSING'}")
    print(f"Amap: {'configured' if AMAP_API_KEY else 'MISSING'}")
    print(f"Bocha: {'configured' if BOCHA_API_KEY else 'MISSING'}")
    print(f"Agent tools: {[t.name for t in tools]}")
    print("-" * 60)
    print("API docs: http://localhost:9000/docs")
    print("Health:   http://localhost:9000/health")
    print("=" * 60)

    uvicorn.run(app, host="0.0.0.0", port=9000)
