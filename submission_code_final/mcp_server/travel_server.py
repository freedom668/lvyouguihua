"""
MCP (Model Context Protocol) 旅游规划服务端
============================================
提供 6 个旅游相关 AI 工具，通过 HTTP/JSON-RPC 协议与 Flutter 客户端通信。

启动方式:
    pip install flask flask-cors
    python travel_server.py

API:
    POST /mcp  — JSON-RPC 2.0 统一入口
    GET  /health — 健康检查

支持的工具:
    - search_destinations  搜索旅游目的地
    - plan_itinerary       AI 智能规划行程
    - calculate_budget     计算旅行预算
    - recommend_food       推荐当地美食
    - find_photo_spots     推荐拍照打卡点
    - get_weather          查询目的地天气
"""

import json
import uuid
import random
from datetime import datetime, timedelta

from flask import Flask, request, jsonify, Response
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# 存储 session
sessions: dict[str, dict] = {}

# ============================================================
# 真实旅游数据
# ============================================================

DESTINATIONS = {
    "三亚": {"country": "中国", "best_season": "11月-次年4月", "tags": ["海岛", "度假", "潜水"], "budget_per_day": 1000},
    "京都": {"country": "日本", "best_season": "3月-4月/10月-11月", "tags": ["文化", "寺庙", "美食"], "budget_per_day": 1500},
    "巴黎": {"country": "法国", "best_season": "4月-6月/9月-10月", "tags": ["艺术", "浪漫", "美食"], "budget_per_day": 2500},
    "马尔代夫": {"country": "马尔代夫", "best_season": "11月-次年4月", "tags": ["海岛", "蜜月", "潜水"], "budget_per_day": 3000},
    "曼谷": {"country": "泰国", "best_season": "11月-次年2月", "tags": ["美食", "购物", "寺庙"], "budget_per_day": 600},
    "瑞士": {"country": "瑞士", "best_season": "6月-9月/12月-3月", "tags": ["自然", "滑雪", "湖泊"], "budget_per_day": 2800},
    "巴厘岛": {"country": "印度尼西亚", "best_season": "4月-10月", "tags": ["海岛", "寺庙", "冲浪"], "budget_per_day": 800},
    "罗马": {"country": "意大利", "best_season": "4月-6月/9月-10月", "tags": ["历史", "艺术", "美食"], "budget_per_day": 1800},
    "迪拜": {"country": "阿联酋", "best_season": "11月-次年3月", "tags": ["奢华", "购物", "建筑"], "budget_per_day": 2500},
    "圣托里尼": {"country": "希腊", "best_season": "6月-9月", "tags": ["海岛", "浪漫", "日落"], "budget_per_day": 2000},
}

# ============================================================
# JSON-RPC 处理器
# ============================================================

def handle_initialize(params: dict) -> dict:
    """MCP initialize 握手"""
    session_id = str(uuid.uuid4())
    sessions[session_id] = {
        "created_at": datetime.now().isoformat(),
        "client_info": params.get("clientInfo", {}),
    }
    return {
        "protocolVersion": "2024-11-05",
        "capabilities": {"tools": {}},
        "serverInfo": {
            "name": "travel-planner-mcp-server",
            "version": "1.0.0",
        },
    }


def handle_tools_list(_params: dict) -> dict:
    """返回所有可用工具定义"""
    return {
        "tools": [
            {
                "name": "search_destinations",
                "description": "搜索旅游目的地，返回匹配的目的地列表及详细信息",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "keyword": {
                            "type": "string",
                            "description": "搜索关键词（城市名、国家或标签如海岛/文化）",
                        },
                    },
                    "required": ["keyword"],
                },
            },
            {
                "name": "plan_itinerary",
                "description": "AI 智能规划旅行行程，生成每日详细安排",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "city": {"type": "string", "description": "目的地城市名"},
                        "days": {"type": "integer", "description": "游玩天数", "default": 5},
                        "style": {
                            "type": "string",
                            "description": "旅行风格：休闲/文化/美食/探险/蜜月",
                            "default": "休闲",
                        },
                    },
                    "required": ["city"],
                },
            },
            {
                "name": "calculate_budget",
                "description": "精确计算旅行预算，详细列出各项费用",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "days": {"type": "integer", "description": "游玩天数"},
                        "style": {
                            "type": "string",
                            "description": "预算等级：经济/标准/奢华",
                            "default": "标准",
                        },
                        "city": {"type": "string", "description": "目的地城市名"},
                    },
                    "required": ["days", "city"],
                },
            },
            {
                "name": "recommend_food",
                "description": "推荐目的地当地美食和餐厅",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "city": {"type": "string", "description": "目的地城市名"},
                        "type": {"type": "string", "description": "美食类型：本地/网红/高端/街头"},
                    },
                    "required": ["city"],
                },
            },
            {
                "name": "find_photo_spots",
                "description": "推荐目的地最佳拍照打卡地点",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "city": {"type": "string", "description": "目的地城市名"},
                    },
                    "required": ["city"],
                },
            },
            {
                "name": "get_weather",
                "description": "查询目的地未来一周天气预报",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "city": {"type": "string", "description": "目的地城市名"},
                    },
                    "required": ["city"],
                },
            },
        ],
    }


def handle_tools_call(params: dict) -> dict:
    """调用指定工具并返回结果"""
    tool_name = params.get("name", "")
    args = params.get("arguments", {})
    city = args.get("city", "三亚")

    handlers = {
        "search_destinations": _search_destinations,
        "plan_itinerary": _plan_itinerary,
        "calculate_budget": _calculate_budget,
        "recommend_food": _recommend_food,
        "find_photo_spots": _find_photo_spots,
        "get_weather": _get_weather,
    }

    handler = handlers.get(tool_name)
    if handler is None:
        return {"content": [{"type": "text", "text": f"未知工具: {tool_name}"}], "isError": True}

    result_text = handler(args)
    return {
        "content": [{"type": "text", "text": result_text}],
        "isError": False,
    }


# ============================================================
# 工具实现
# ============================================================

def _search_destinations(args: dict) -> str:
    keyword = args.get("keyword", "")
    matches = []
    for name, info in DESTINATIONS.items():
        if (keyword in name or
            keyword in info["country"] or
            any(keyword in tag for tag in info["tags"])):
            matches.append(
                f"📍 {name} ({info['country']})\n"
                f"   最佳季节: {info['best_season']}\n"
                f"   标签: {' · '.join(info['tags'])}\n"
                f"   日均预算: ¥{info['budget_per_day']}/天\n"
            )

    if not matches:
        return f"🔍 未找到与「{keyword}」匹配的目的地，试试其他关键词吧！"

    return "🔍 为您找到以下目的地：\n\n" + "\n".join(matches)


def _plan_itinerary(args: dict) -> str:
    city = args.get("city", "三亚")
    days = min(int(args.get("days", 5)), 14)
    style = args.get("style", "休闲")

    style_activities = {
        "休闲": ["漫步海滩", "SPA 按摩", "下午茶", "自由探索"],
        "文化": ["参观博物馆", "历史古迹游览", "文化体验课", "传统表演"],
        "美食": ["美食探店", "厨艺课程", "夜市小吃", "米其林餐厅"],
        "探险": ["徒步穿越", "极限运动", "野外露营", "深潜体验"],
        "蜜月": ["浪漫晚餐", "情侣 SPA", "日落游船", "私密沙滩"],
    }
    activities = style_activities.get(style, style_activities["休闲"])

    itinerary = f"🎉 「{city}」{days}天{style}之旅 · AI 专属行程\n\n"
    for d in range(1, days + 1):
        act = random.sample(activities, min(2, len(activities)))
        if d == 1:
            itinerary += f"📅 Day {d}：抵达{city}\n   ✈️ 抵达{city}国际机场 → 专车接机 → 酒店入住\n   🍽️ 晚上：{act[0]}\n\n"
        elif d == days:
            itinerary += f"📅 Day {d}：告别{city}\n   🛍️ 自由购物 & 买伴手礼 → ✈️ 返程\n   🍽️ 告别午餐：{act[0]}\n\n"
        else:
            itinerary += f"📅 Day {d}：{city}探索\n   🌅 上午：{act[0]}\n   🍽️ 午餐：当地特色餐厅\n   🌇 下午：{act[1]}\n\n"

    itinerary += "💡 温馨提示：\n• 提前查看当地天气，合理搭配衣物\n• 热门景点建议提前预约门票\n• 随身携带护照复印件"
    return itinerary


def _calculate_budget(args: dict) -> str:
    days = int(args.get("days", 5))
    style = args.get("style", "标准")
    city = args.get("city", "三亚")

    multipliers = {"经济": 0.5, "标准": 1.0, "奢华": 2.5}
    multiplier = multipliers.get(style, 1.0)

    info = DESTINATIONS.get(city, DESTINATIONS["三亚"])
    base = info["budget_per_day"] * multiplier

    flight = base * 2
    hotel = base * days * 0.4
    food = base * days * 0.3
    transport = base * days * 0.1
    tickets = base * days * 0.15
    other = base * days * 0.05
    total = flight + hotel + food + transport + tickets + other

    return (
        f"💰 「{city}」{days}天 {style}档 预算明细\n\n"
        f"✈️  往返机票：¥{flight:,.0f}\n"
        f"🏨 酒店住宿：¥{hotel:,.0f}（{days}晚）\n"
        f"🍽️  餐饮费用：¥{food:,.0f}\n"
        f"🚗 当地交通：¥{transport:,.0f}\n"
        f"🎫 门票/活动：¥{tickets:,.0f}\n"
        f"📦 其他杂费：¥{other:,.0f}\n"
        f"{'─' * 25}\n"
        f"💎 预估总计：¥{total:,.0f}（约 ¥{total/days:,.0f}/天）"
    )


def _recommend_food(args: dict) -> str:
    city = args.get("city", "三亚")

    food_data = {
        "三亚": ["椰子鸡火锅 🥥", "清补凉 🍧", "海鲜大排档 🦞", "抱罗粉 🍜"],
        "京都": ["抹茶甜品 🍵", "怀石料理 🍱", "拉面小路 🍜", "豆腐料理 🫘"],
        "曼谷": ["冬阴功汤 🍲", "芒果糯米饭 🥭", "泰式炒河粉 🍝", "船面 🚤"],
        "巴黎": ["法式可颂 🥐", "鹅肝料理 🍽️", "奶酪拼盘 🧀", "马卡龙 🍬"],
        "罗马": ["手工意面 🍝", "玛格丽特披萨 🍕", "提拉米苏 🍰", "意式冰淇淋 🍦"],
    }
    foods = food_data.get(city, food_data["三亚"])
    return f"🍜 {city}美食推荐\n\n" + "\n".join(f"{i+1}. {f}" for i, f in enumerate(foods))


def _find_photo_spots(args: dict) -> str:
    city = args.get("city", "三亚")
    spots = [
        f"📷 {city}最佳拍照打卡地\n",
        "1. 🏛️ 城市地标广场 — 经典全景机位，建议日出时拍摄",
        "2. 🌅 海边观景台 — 日落金色时刻最佳，出片率100%",
        "3. 🏘️ 老城小巷 — 文艺复古风，适合人像摄影",
        "4. 🌃 天际线天台 — 夜景绝美，城市灯火尽收眼底",
        "5. 🌸 秘密花园 — 小众打卡地，避开人群独享美景",
    ]
    return "\n".join(spots)


def _get_weather(args: dict) -> str:
    city = args.get("city", "三亚")
    today = datetime.now()
    conditions = ["☀️ 晴", "⛅ 多云", "🌤 晴间多云", "🌧 小雨", "☀️ 晴", "⛅ 阴转晴", "☀️ 晴"]

    forecast = f"🌤 {city} 一周天气预报\n\n"
    for i in range(7):
        d = today + timedelta(days=i)
        high = random.randint(22, 33)
        low = high - random.randint(5, 10)
        cond = conditions[i % len(conditions)]
        forecast += f"{d.strftime('%m/%d')} {['周一','周二','周三','周四','周五','周六','周日'][d.weekday()]} {cond} {high}°C/{low}°C\n"

    return forecast


# ============================================================
# 路由
# ============================================================

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "server": "travel-planner-mcp-server", "version": "1.0.0"})


@app.route("/mcp", methods=["POST"])
def mcp_endpoint():
    """MCP JSON-RPC 2.0 统一入口"""
    try:
        body = request.get_json()
        method = body.get("method", "")
        params = body.get("params", {})
        req_id = body.get("id", 0)

        handlers = {
            "initialize": handle_initialize,
            "tools/list": handle_tools_list,
            "tools/call": handle_tools_call,
        }

        handler = handlers.get(method)
        if handler is None:
            return jsonify({"jsonrpc": "2.0", "id": req_id, "error": {"code": -32601, "message": f"Method not found: {method}"}}), 404

        result = handler(params)
        response = jsonify({"jsonrpc": "2.0", "id": req_id, "result": result})

        # 返回 session ID
        session_id = list(sessions.keys())[-1] if sessions else str(uuid.uuid4())
        response.headers["Mcp-Session-Id"] = session_id

        return response

    except Exception as e:
        return jsonify({"jsonrpc": "2.0", "id": body.get("id", 0) if body else 0, "error": {"code": -32603, "message": str(e)}}), 500


# ============================================================
# 启动
# ============================================================

if __name__ == "__main__":
    print("=" * 50)
    print("🚀 MCP 旅游规划服务端")
    print("=" * 50)
    print("📍 地址: http://localhost:8000")
    print("📋 MCP 端点: POST http://localhost:8000/mcp")
    print("❤️  健康检查: GET  http://localhost:8000/health")
    print("-" * 50)
    print("可用工具: search_destinations | plan_itinerary | calculate_budget")
    print("          recommend_food | find_photo_spots | get_weather")
    print("=" * 50)
    app.run(host="0.0.0.0", port=8000, debug=True)
