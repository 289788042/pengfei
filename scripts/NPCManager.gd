## NPCManager.gd - NPC 配置与逻辑管理中心（单例）
## 负责：头像颜色、自动回复、朋友圈数据、NPC专属聊天/约会逻辑
## 新增 NPC 只需在此文件添加数据即可，无需修改 MainGame.gd
extends Node

# ==================== NPC 注册表 ====================
## 所有 NPC 的配置数据，新增 NPC 只需在此添加条目
const NPC_CONFIG: Dictionary = {
	"family_group": {
		"name": "相亲相爱一家人 (爸妈)",
		"avatar_color": Color(1.0, 0.6, 0.2, 1),
		"auto_replies": ["你妈：吃饭了没？", "你爸：注意身体。", "妈：今天降温了，多穿点！", "爸：工作顺利吗？"],
		"moments_text": "妈：今天包了饺子，等你回来吃！🏠",
		"moments_likes": 12,
	},
	"wang_teacher": {
		"name": "尚德夜校-王老师",
		"avatar_color": Color(0.12, 0.35, 0.75, 1),
		"auto_replies": ["好好学习！", "下周记得来上课", "加油！毕业指日可待"],
		"moments_text": "教育改变命运！尚德夜校春季班火热招生中！",
		"moments_likes": 42,
	},
	"shen_yi": {
		"name": "沈逸",
		"avatar_color": Color(0.2, 0.35, 0.5, 1),
		"auto_replies": ["嗯。", "在忙，晚点说。", "你今天加班到几点？", "发了个表情包"],
		"moments_text": "今天在图书馆又遇到了那本有趣的书。",
		"moments_likes": 28,
	},
}

## 默认配置（NPC_CONFIG 中未注册的 NPC 使用）
const DEFAULT_CONFIG: Dictionary = {
	"avatar_color": Color(0.3, 0.3, 0.3, 1),
	"auto_replies": ["嗯", "好的"],
	"moments_text": "...",
	"moments_likes": 0,
}


# ==================== 数据查询接口 ====================

## 获取 NPC 头像颜色
func get_avatar_color(npc_id: String) -> Color:
	var cfg: Dictionary = NPC_CONFIG.get(npc_id, {})
	return cfg.get("avatar_color", DEFAULT_CONFIG["avatar_color"])


## 获取 NPC 随机自动回复
func get_auto_reply(npc_id: String) -> String:
	var cfg: Dictionary = NPC_CONFIG.get(npc_id, {})
	var pool: Array = cfg.get("auto_replies", DEFAULT_CONFIG["auto_replies"])
	return pool[randi() % pool.size()]


## 获取 NPC 朋友圈文本
func get_moments_text(npc_id: String) -> String:
	var cfg: Dictionary = NPC_CONFIG.get(npc_id, {})
	return cfg.get("moments_text", DEFAULT_CONFIG["moments_text"])


## 获取 NPC 朋友圈点赞数
func get_moments_likes(npc_id: String) -> int:
	var cfg: Dictionary = NPC_CONFIG.get(npc_id, {})
	return cfg.get("moments_likes", DEFAULT_CONFIG["moments_likes"])


## 获取 NPC 显示名称
func get_npc_name(npc_id: String) -> String:
	var cfg: Dictionary = NPC_CONFIG.get(npc_id, {})
	return cfg.get("name", npc_id)


## 检查 NPC 是否已注册
func is_registered(npc_id: String) -> bool:
	return NPC_CONFIG.has(npc_id)


# ==================== NPC 聊天逻辑 ====================

## 获取 NPC 通用聊天的结果
## 返回: {"msg": String, "sanity": int, "affection": int}
func get_chat_result(npc_id: String) -> Dictionary:
	var result: Dictionary = {"msg": "聊天结束。", "sanity": 5, "affection": 5}

	# 未来可在此为特定 NPC 添加差异化聊天逻辑
	# 示例：
	# if npc_id == "shen_yi":
	#     result = _chat_shen_yi()

	return result


# ==================== NPC 约会逻辑 ====================

## 获取 NPC 约会的结果
## 返回: {"msg": String, "sanity": int, "affection": int, "money_cost": int}
func get_date_result(npc_id: String) -> Dictionary:
	var npc_name: String = get_npc_name(npc_id)
	var result: Dictionary = {
		"msg": "与 %s 浪漫约会，感情升温！" % npc_name,
		"sanity": 40,
		"affection": 30,
		"money_cost": 500,
	}

	# 未来可在此为特定 NPC 添加差异化约会逻辑
	# 示例：
	# if npc_id == "shen_yi":
	#     result = _date_shen_yi()

	return result
