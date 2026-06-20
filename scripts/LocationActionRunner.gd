## LocationActionRunner.gd
## Owns location action config, execution flow, event lifetime, background switching,
## and return-to-weekend cleanup.
extends RefCounted

var _main: Node
var _app: RefCounted
var _event_hold_count: int = 0
var _loc_visit_count: Dictionary = {}
var _weekly_location_turn: int = -999
var _weekly_location_visits: Dictionary = {}
var _weekly_reunion_seen: Dictionary = {}
var _park_visited_week: int = -999


func init(main: Node, app_system: RefCounted) -> void:
	_main = main
	_app = app_system


func begin_location_event() -> void:
	_event_hold_count += 1
	_sync_app_hold_count()
	var gal = _main.get("galgame")
	if gal and gal.has_method("hold_location_bg"):
		gal.hold_location_bg()


func end_location_event() -> void:
	if _event_hold_count <= 0:
		_event_hold_count = 0
		_sync_app_hold_count()
		return
	_event_hold_count -= 1
	_sync_app_hold_count()
	var gal = _main.get("galgame")
	if gal and gal.has_method("release_location_bg"):
		gal.release_location_bg()
	elif _main.has_method("return_to_home_environment"):
		_main.return_to_home_environment("location_event_end")


func hold_count() -> int:
	return _event_hold_count


func finish_after(after: Callable = Callable()) -> Callable:
	return func() -> void:
		if after.is_valid():
			after.call()
		end_location_event()
		if is_instance_valid(_main) and _main.get("current_phase") == _main.Phase.EVENT:
			_main.set("current_phase", _main.Phase.WEEKEND)
			if _main.has_method("sync_ui_state"):
				_main.sync_ui_state()
			if _main.has_method("_refresh_ui"):
				_main._refresh_ui()


func location_config(location: String) -> Dictionary:
	match location:
		"library":
			return {
				"name": "图书馆",
				"category": "提升",
				"energy_req": 20,
				"changes": {"energy": -20, "intellect": 3, "sanity": 5},
				"fallback": "在图书馆读了一下午。",
				"activity": "在图书馆读书，学识+3，情绪+5",
			}
		"gym":
			return {
				"name": "健身房",
				"category": "提升",
				"energy_req": 45,
				"payment_cost": 200,
				"payment_desc": "健身房消费",
				"changes": {"energy": -45, "charm": 2, "sanity": 5, "max_energy": 1},
				"fallback": "在健身房练到浑身发热。",
				"activity": "去健身房挥汗如雨，颜值+2，情绪+5，精力上限+1",
			}
		"bar":
			return {
				"name": "高档酒吧",
				"category": "社交",
				"energy_req": 30,
				"payment_cost": 500,
				"payment_desc": "酒吧消费",
				"req_stats": {"eq": 10},
				"changes": {"energy": -30, "eq": 2, "sanity": 25},
				"fallback": "在酒吧喝了一杯。",
				"activity": "在酒吧喝了一杯，情商+2，情绪+25",
			}
		"home":
			return {
				"name": "宅家刷手机",
				"category": "日常",
				"energy_req": 10,
				"changes": {"energy": -10, "sanity": 20},
				"fallback": "宅家刷了一整天手机。",
				"activity": "宅家刷了一整天手机，情绪+20",
			}
		"park":
			return {
				"name": "公园·深圳湾",
				"category": "日常",
				"once_per_week": true,
				"changes": {"energy": 10, "sanity": 3},
				"fallback": "在深圳湾吹了会儿海风。",
				"activity": "在公园·深圳湾散步，精力+10，情绪+3",
			}
		"cafe":
			return {
				"name": "咖啡厅",
				"category": "提升",
				"energy_req": 15,
				"payment_cost": 80,
				"payment_desc": "咖啡厅消费",
				"changes": {"energy": -15, "intellect": 2, "eq": 2},
				"fallback": "在咖啡厅坐了一下午。",
				"activity": "在咖啡厅学习，学识+2，情商+2",
			}
		"market":
			return {
				"name": "夜市·大排档",
				"category": "美食",
				"energy_req": 10,
				"payment_cost": 100,
				"payment_desc": "夜市消费",
				"changes": {"energy": -10, "sanity": 15},
				"fallback": "在夜市吃了点热乎东西。",
				"activity": "在夜市吃了夜宵，情绪+15",
			}
		"overtime":
			var overtime_pay: int = randi() % 300 + 500
			return {
				"name": "公司加班",
				"category": "工作",
				"energy_req": 40,
				"changes": {"energy": -40, "sanity": -35, "money": overtime_pay},
				"fallback": "办公室只剩你一个人。你熬到深夜，终于把这版方案交了出去。加班费到账：%d。",
				"format_value": overtime_pay,
				"activity": "公司加班，赚了%d元加班费" % overtime_pay,
			}
	return {}


func can_start_location(location: String, config: Dictionary) -> bool:
	if not is_instance_valid(_main):
		return false
	if _main.current_phase != _main.Phase.WEEKEND:
		_main.show_message("现在不是周末，不能安排地点行动。")
		return false
	if _main.get("action_service") and _main.action_service.has_method("can_use_weekend_action"):
		if not _main.action_service.can_use_weekend_action(config.get("name", location)):
			_main.show_message("本周周末日程已经排满了。先结束本周，再安排新的地点行动。")
			return false
	if bool(config.get("once_per_week", false)) and is_once_per_week_location_visited():
		_main.show_message("这周已经去过深圳湾了，来回太远，下周再去吧。")
		return false
	var energy_req := int(config.get("energy_req", 0))
	if energy_req > 0 and GameManager.energy < energy_req:
		_main.show_message("精力不足（需%d），无法前往%s。" % [energy_req, config.get("name", location)])
		return false
	var req_stats: Dictionary = config.get("req_stats", {})
	for stat_name in req_stats:
		var needed := int(req_stats[stat_name])
		var current := int(GameManager.get(stat_name))
		if current < needed:
			var cn: String = GameManager.stat_names.get(stat_name, stat_name)
			_main.show_message("%s不足（需%d，当前%d），无法前往%s。" % [cn, needed, current, config.get("name", location)])
			return false
	return true


func start_location(location: String) -> void:
	var config := location_config(location)
	if config.is_empty():
		_main.show_message("地点尚未配置：" + location)
		return
	if not can_start_location(location, config):
		return
	_app._set_layer_visible(_app.location_menu, false)
	var payment_cost := int(config.get("payment_cost", 0))
	if payment_cost > 0:
		_main.alipay.request_payment(
			payment_cost,
			config.get("payment_desc", config.get("name", "地点消费")),
			config.get("category", "消费"),
			func() -> void:
				var payment_changes: Dictionary = _main.alipay.get_last_payment_changes()
				run_location_after_payment(location, config, payment_changes)
		)
	else:
		run_location_after_payment(location, config, {})


func run_location_after_payment(location: String, config: Dictionary, payment_changes: Dictionary) -> void:
	if not _app._use_weekend_action(config.get("name", location)):
		return
	if bool(config.get("once_per_week", false)):
		_park_visited_week = GameManager.turn_count
	begin_location_event()
	show_location_background(location)
	var visit_index := get_weekly_location_visits(location)
	var tuned_changes := apply_location_repeat_decay(config.get("changes", {}), visit_index)
	record_weekly_location_visit(location)

	var encounter_npc: Dictionary = _app._check_encounter(location)
	if encounter_npc.size() > 0:
		_app._handle_encounter(encounter_npc, location, config, tuned_changes, payment_changes, visit_index)
		return

	if _should_route_first_week_overtime_tutorial(location):
		show_location_result_from_config(location, config, tuned_changes, payment_changes, _first_week_location_finished_callback(location))
		record_location_activity(location, config, tuned_changes, payment_changes, visit_index)
		return

	if _should_route_first_week_beach_tutorial(location):
		show_location_result_from_config(location, config, tuned_changes, payment_changes, _first_week_location_finished_callback(location))
		record_location_activity(location, config, tuned_changes, payment_changes, visit_index)
		return

	var roll := randf()
	if location == "overtime" and roll < 0.50:
		var event := GameManager.roll_random_event("overtime")
		if event.size() > 0:
			_main._show_event(event, func() -> void:
				show_location_result_from_config(location, config, tuned_changes, payment_changes)
			)
			record_location_activity(location, config, tuned_changes, payment_changes, visit_index)
			return

	if roll < 0.50 and _has_city_fragments(location):
		_app._trigger_city_fragment(location, tuned_changes, payment_changes)
	else:
		show_location_result_from_config(location, config, tuned_changes, payment_changes)
	record_location_activity(location, config, tuned_changes, payment_changes, visit_index)


func show_location_result_from_config(location: String, config: Dictionary, pending_changes: Dictionary, already_applied_changes: Dictionary = {}, after: Callable = Callable()) -> void:
	_app._show_story_then_apply_changes(location_story(location, config), pending_changes, already_applied_changes, finish_after(after))


func location_story(location: String, config: Dictionary) -> String:
	var story := GameManager.get_location_narrative(location, config.get("fallback", ""))
	if config.has("format_value"):
		story = story % int(config["format_value"])
	return story


func record_location_activity(location: String, config: Dictionary, changes: Dictionary, payment_changes: Dictionary, visit_index: int) -> void:
	var logged_changes: Dictionary = _app._merge_change_dicts(payment_changes, changes)
	var desc := str(config.get("activity", config.get("name", location)))
	if visit_index > 0:
		desc += "（本周第%d次，正向收益约%d%%）" % [
			visit_index + 1,
			int(round(location_repeat_scale(visit_index) * 100.0)),
		]
	GameManager.add_activity(str(config.get("category", "日常")), desc, logged_changes)


func show_location_background(location: String) -> void:
	var bg_path := _get_background_path(location)
	if bg_path != "":
		_main.galgame.show_location_bg(bg_path)
		return
	var env = _main.get("environment")
	if env and env.has_method("show_location_color"):
		env.show_location_color(location)
	elif _main.has_method("return_to_home_environment"):
		_main.return_to_home_environment("location_without_bg")
	var gal = _main.get("galgame")
	if gal and gal.has_method("play_ambient_for_location"):
		gal.play_ambient_for_location(location)


func get_weekly_location_visits(location: String) -> int:
	_ensure_weekly_location_state()
	return int(_weekly_location_visits.get(location, 0))


func record_weekly_location_visit(location: String) -> void:
	_ensure_weekly_location_state()
	_weekly_location_visits[location] = int(_weekly_location_visits.get(location, 0)) + 1


func has_seen_weekly_reunion(npc_id: String) -> bool:
	_ensure_weekly_location_state()
	return _weekly_reunion_seen.has(npc_id)


func record_weekly_reunion(npc_id: String) -> void:
	if npc_id == "":
		return
	_ensure_weekly_location_state()
	_weekly_reunion_seen[npc_id] = true


func location_repeat_scale(visit_index: int) -> float:
	if visit_index <= 0:
		return 1.0
	if visit_index == 1:
		return 0.5
	return 0.25


func apply_location_repeat_decay(changes: Dictionary, visit_index: int) -> Dictionary:
	if visit_index <= 0:
		return changes.duplicate()
	var scale := location_repeat_scale(visit_index)
	var tuned: Dictionary = {}
	var growth_stats := ["intellect", "eq", "charm", "max_energy"]
	for stat_name in changes:
		var amount := int(changes[stat_name])
		if amount == 0:
			continue
		var tuned_amount := amount
		var key := str(stat_name)
		if amount > 0 and growth_stats.has(key):
			tuned_amount = int(floor(float(amount) * scale))
		elif amount > 0 and (key == "sanity" or key == "energy"):
			tuned_amount = maxi(1, int(round(float(amount) * scale)))
		if tuned_amount != 0:
			tuned[stat_name] = tuned_amount
	return tuned


func is_once_per_week_location_visited() -> bool:
	return _park_visited_week == GameManager.turn_count


func _sync_app_hold_count() -> void:
	if is_instance_valid(_app):
		_app.set("_location_event_hold_count", _event_hold_count)


func _ensure_weekly_location_state() -> void:
	if _weekly_location_turn == GameManager.turn_count:
		return
	_weekly_location_turn = GameManager.turn_count
	_weekly_location_visits.clear()
	_weekly_reunion_seen.clear()


func _has_city_fragments(location: String) -> bool:
	if not is_instance_valid(_app):
		return false
	var raw: Variant = _app.get("_city_fragments")
	if not (raw is Dictionary):
		return false
	var fragments: Dictionary = raw
	return fragments.get(location, []).size() > 0


func _should_route_first_week_overtime_tutorial(location: String) -> bool:
	if location != "overtime":
		return false
	if not is_instance_valid(_main) or not _main.has_method("on_first_week_location_finished"):
		return false
	if GameManager.month != 1 or GameManager.week_in_month != 1 or GameManager.turn_count != 1:
		return false
	return not _first_week_beach_route_unlocked()


func _should_route_first_week_beach_tutorial(location: String) -> bool:
	if location != "park":
		return false
	if not is_instance_valid(_main) or not _main.has_method("on_first_week_location_finished"):
		return false
	if GameManager.month != 1 or GameManager.week_in_month != 1 or GameManager.turn_count != 1:
		return false
	return _first_week_beach_route_unlocked()


func _first_week_beach_route_unlocked() -> bool:
	if not is_instance_valid(_main) or not _main.has_method("is_first_week_beach_route_unlocked"):
		return false
	return bool(_main.call("is_first_week_beach_route_unlocked"))


func _first_week_location_finished_callback(location: String) -> Callable:
	if not is_instance_valid(_main) or not _main.has_method("on_first_week_location_finished"):
		return Callable()
	return Callable(_main, "on_first_week_location_finished").bind(location)


func _get_background_path(location: String) -> String:
	if location == "gym":
		_loc_visit_count["gym"] = int(_loc_visit_count.get("gym", 0)) + 1
		if int(_loc_visit_count["gym"]) == 1:
			return "res://Assets/Backgrounds/gym/Gym_bg_rain_morning.jpg"
		var gym_bgs: Array[String] = [
			"res://Assets/Backgrounds/gym/Gym_bg_rain_morning.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_rain_night.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_sunny_morning.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_sunny_noon.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_sunny_evening.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_hazy_afternoon.jpg",
		]
		return gym_bgs[randi() % gym_bgs.size()]
	var bg_map: Dictionary = {
		"library": "res://Assets/Backgrounds/library/Bookshop_bg_day1.png",
		"park": "res://Assets/Backgrounds/park/beach.jpg",
	}
	return bg_map.get(location, "")
