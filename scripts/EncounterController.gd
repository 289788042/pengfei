## EncounterController.gd
## Owns NPC encounter gates, cooldowns, and reunion presentation.
extends RefCounted

var _main: Node
var _app: RefCounted
var _cooldowns: Dictionary = {}
var _reunion_lines: Array = [
	"在{loc}又遇到了{name}，ta冲你笑了笑。你们聊了几句。",
	"{name}看到你，主动走了过来打招呼。",
	"远远看到{name}在做自己的事，你过去打了个招呼。",
	"和{name}撞了个正着，两个人都笑了。",
	"{name}递给你一瓶水，说看你气色不太好。",
	"你帮{name}捡起了掉在地上的东西，ta说了声谢谢。",
	"和{name}聊起了最近的工作，ta给了你一些建议。",
	"今天在{loc}和{name}待了会儿，感觉心情好了不少。",
	"{name}请你喝了一杯东西，你们聊得很开心。",
	"碰巧和{name}坐在了一起，度过了愉快的一段时光。",
	"{name}给你看了看ta手机上的照片，最近去了不少地方。",
	"你和{name}交换了对某个话题的看法，聊得很投机。",
	"{name}看起来心情不错，说最近发生了点好事。",
	"你们聊起了深圳的生活，{name}说已经习惯了。",
	"和{name}告别的时候，ta说下次再约。",
	"{name}夸你今天看起来气色不错，你心里美滋滋的。",
]


func init(main: Node, app_system: RefCounted, cooldowns: Dictionary) -> void:
	_main = main
	_app = app_system
	_cooldowns = cooldowns


func check_encounter(_location: String) -> Dictionary:
	# 第一阶段先关闭核心男性随机邂逅；关系入口改由主线事件确定触发。
	return {}


func check_reunion(location: String) -> Dictionary:
	var candidates: Array = []
	for npc in GameManager.npc_database:
		var enc: Dictionary = npc.get("encounter", {})
		if enc.get("location", "") != location:
			continue
		if enc.get("auto_unlock", false):
			continue
		var npc_id: String = npc.get("id", "")
		if not GameManager.is_npc_unlocked(npc_id):
			continue
		if _app._has_seen_weekly_reunion(npc_id):
			continue
		candidates.append(npc)
	if candidates.size() == 0:
		return {}
	return candidates[randi() % candidates.size()]


func handle_reunion(npc: Dictionary, location: String) -> void:
	var npc_id: String = npc.get("id", "")
	var npc_name: String = npc.get("name", "")
	var loc_cn := _location_name(location)
	var text := _reunion_text(npc_name, loc_cn)
	var changes := {"affection": 3, "sanity": 3, "eq": 1}
	GameManager.add_activity("社交", "在%s遇到了%s，聊了几句" % [loc_cn, npc_name], changes)
	_app._show_story_then_apply_npc_changes(text, {}, {}, npc_name, _app._finish_location_event_after(), "【结算】", npc_id, changes)


func show_reunion_result(npc: Dictionary, location: String, base_changes: Dictionary) -> void:
	var npc_id: String = npc.get("id", "")
	var npc_name: String = npc.get("name", "")
	_app._record_weekly_reunion(npc_id)
	var loc_cn := _location_name(location)
	var text := _reunion_text(npc_name, loc_cn)
	var bonus := {"affection": 3, "sanity": 3, "eq": 1}
	_app._show_story_then_apply_npc_changes(text, base_changes, {}, npc_name, _app._finish_location_event_after(), "【结算】", npc_id, bonus)
	GameManager.add_activity("社交", "在%s遇到了%s，聊了几句" % [loc_cn, npc_name], _app._merge_change_dicts(base_changes, bonus))


func handle_encounter(npc: Dictionary, location: String, config: Dictionary, pending_changes: Dictionary, already_applied_changes: Dictionary = {}, visit_index: int = 0) -> void:
	var enc: Dictionary = npc.get("encounter", {})
	var npc_id: String = npc.get("id", "")
	var npc_name: String = npc.get("name", "")
	_cooldowns[npc_id] = GameManager.turn_count + 99
	if meets_encounter_requirements(enc):
		var pass_changes: Dictionary = enc.get("pass_stat_changes", {})
		var display_changes := already_applied_changes.duplicate()
		var pages: Array = []
		for line in enc.get("scene_lines", []):
			pages.append(line)
		for line in enc.get("dialogue_lines", []):
			pages.append(npc_name + "：" + line)

		var wechat_req: Dictionary = enc.get("wechat_request", {})
		if wechat_req.size() > 0:
			_main.galgame._gal_encounter_data = enc
			_main.galgame._gal_npc_id = npc_id
			_main.galgame.show_galgame_dialog(pages, func() -> void:
				_app._show_story_then_apply_npc_changes("", pending_changes, display_changes, npc_name, _main.galgame.start_wechat_request_phase, "【结算】", npc_id, pass_changes)
			)
		else:
			_main.galgame.show_galgame_dialog(pages, func() -> void:
				_app._show_story_then_apply_npc_changes("", pending_changes, display_changes, npc_name, _app._finish_location_event_after(), "【结算】", npc_id, pass_changes)
			)
		var encounter_changes: Dictionary = _app._merge_change_dicts(_app._merge_change_dicts(already_applied_changes, pending_changes), pass_changes)
		GameManager.add_activity("社交", "在%s邂逅了%s" % [str(config.get("name", location)), npc_name], encounter_changes)
	else:
		var fail_pages: Array = []
		for line in enc.get("scene_lines", []):
			fail_pages.append(line)
		for line in enc.get("dialogue_lines", []):
			fail_pages.append(npc_name + "：" + line)
		var requirement_hint := format_encounter_requirement_hint(enc)
		if requirement_hint != "":
			fail_pages.append(requirement_hint)
		else:
			fail_pages.append("（你的属性不满足邂逅条件，擦肩而过...）")
		_cooldowns[npc_id] = GameManager.turn_count + 4
		_main.galgame.show_galgame_dialog(fail_pages, func() -> void:
			_app._record_location_activity(location, config, pending_changes, already_applied_changes, visit_index)
			_app._show_location_result_from_config(location, config, pending_changes, already_applied_changes)
		)


func meets_encounter_requirements(enc: Dictionary) -> bool:
	var req: Dictionary = enc.get("req_stats", {})
	for stat_name in req:
		var needed: int = int(req[stat_name])
		var current: int = GameManager.get(stat_name) if stat_name != "money" else GameManager.money
		if current < needed:
			return false
	return true


func format_encounter_requirement_hint(enc: Dictionary) -> String:
	var req: Dictionary = enc.get("req_stats", {})
	if req.is_empty():
		return ""
	var parts: Array = []
	for stat_name in req:
		var needed: int = int(req[stat_name])
		var current: int = GameManager.get(stat_name) if stat_name != "money" else GameManager.money
		if current >= needed:
			continue
		var cn: String = GameManager.stat_names.get(stat_name, stat_name)
		parts.append("%s需要%d，当前%d" % [cn, needed, current])
	if parts.is_empty():
		return ""
	return "（邂逅条件不足：%s。）" % "；".join(parts)


func _location_name(location: String) -> String:
	return {
		"gym": "健身房",
		"library": "图书馆",
		"bar": "酒吧",
		"home": "家里",
		"park": "公园",
		"cafe": "咖啡厅",
		"market": "夜市",
	}.get(location, location)


func _reunion_text(npc_name: String, loc_cn: String) -> String:
	var template: String = _reunion_lines[randi() % _reunion_lines.size()]
	return template.replace("{name}", npc_name).replace("{loc}", loc_cn)
