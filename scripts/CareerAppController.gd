## CareerAppController.gd
## Owns BOSS弯聘 rendering, career gates, and job transition actions.
extends RefCounted

var _main: Node
var _app: RefCounted


func init(main: Node, app_system: RefCounted) -> void:
	_main = main
	_app = app_system


func get_job_name(level: int = GameManager.job_level) -> String:
	var names := ["初级行政", "新媒体运营", "大客户经理"]
	return names[clampi(level, 0, names.size() - 1)]


func get_degree_name(level: int = GameManager.degree) -> String:
	var names := ["大专", "成人本科"]
	return names[clampi(level, 0, names.size() - 1)]


func is_weekend_phase() -> bool:
	if not is_instance_valid(_main):
		return false
	return _main.current_phase == _main.Phase.WEEKEND


func career_action_lock_reason(energy_cost: int) -> String:
	if not is_weekend_phase():
		return "工作日只能查看，周末再安排"
	var service = _action_service()
	if service and service.has_method("can_use_weekend_action"):
		if not service.can_use_weekend_action("职业行动"):
			return "本周周末日程已排满"
	if GameManager.energy < energy_cost:
		return "精力不足：需要%d，当前%d" % [energy_cost, GameManager.energy]
	return ""


func spend_career_action(label: String, energy_cost: int, _sanity_cost: int) -> bool:
	var reason := career_action_lock_reason(energy_cost)
	if reason != "":
		_main.show_message(reason)
		return false
	var service = _action_service()
	if service and service.has_method("spend_weekend_action"):
		return service.spend_weekend_action(label)
	return true


func media_lock_reason() -> String:
	if not is_weekend_phase():
		return "工作日只能查看，周末才能面试"
	var service = _action_service()
	if service and service.has_method("can_use_weekend_action"):
		if not service.can_use_weekend_action("新媒体运营面试"):
			return "本周周末日程已排满"
	if GameManager.energy < 15:
		return "精力需15（当前%d）" % GameManager.energy
	if GameManager.degree < 1:
		return "需成人本科：微信找尚德夜校王老师上课（%d/12）" % GameManager.night_school_progress
	return ""


func client_lock_reason() -> String:
	var missing: Array = []
	if not is_weekend_phase():
		missing.append("周末面试")
	else:
		var service = _action_service()
		if service and service.has_method("can_use_weekend_action"):
			if not service.can_use_weekend_action("大客户经理面试"):
				missing.append("本周日程已满")
	if GameManager.energy < 20:
		missing.append("精力20(当前%d)" % GameManager.energy)
	if GameManager.job_level < 1:
		missing.append("新媒体运营履历")
	if GameManager.degree < 1:
		missing.append("成人本科")
	if GameManager.age >= 30:
		missing.append("年龄30岁以下")
	if missing.is_empty():
		return ""
	return "缺：" + "、".join(missing)


func open_job_app() -> void:
	if not _app._can_open_phone_app():
		return
	if not _app._ensure_app_unlocked("job"):
		return
	_app._close_all_menus()
	var menu := _job_menu()
	for child in menu.get_children():
		child.queue_free()

	var phase_text := "周末可安排面试" if is_weekend_phase() else "工作日仅查看"
	var status := "职位：%s | 学历：%s | 夜校：%d/12 | 年龄：%d | %s" % [
		get_job_name(),
		get_degree_name(),
		GameManager.night_school_progress,
		GameManager.age,
		phase_text,
	]
	var items: Array = []

	var admin_item := {
		"name": "初级行政",
		"icon_color": Color(0.3, 0.65, 0.35),
		"cost": "底薪 800/1500/2500。低门槛、低天花板、低风险。",
		"current": GameManager.job_level == 0,
	}
	if GameManager.job_level != 0:
		if is_weekend_phase():
			admin_item["action"] = on_job_admin
		else:
			admin_item["locked"] = true
			admin_item["lock_reason"] = "周末再处理离职/降岗"
	items.append(admin_item)

	var media_reason := media_lock_reason()
	var media_item := {
		"name": "投递：新媒体运营",
		"icon_color": Color(0.2, 0.55, 0.9),
		"cost": "精力-15 情绪-10 | 底薪 2000/4000/6000。要求：成人本科。",
		"current": GameManager.job_level == 1,
		"locked": media_reason != "" and GameManager.job_level != 1,
		"lock_reason": media_reason,
	}
	if GameManager.job_level != 1 and media_reason == "":
		media_item["action"] = on_job_media
	items.append(media_item)

	var client_reason := client_lock_reason()
	var client_item := {
		"name": "投递：大客户经理",
		"icon_color": Color(0.9, 0.7, 0.15),
		"cost": "精力-20 情绪-15 | 底薪 4000/8000/12000。要求：新媒体履历、成人本科、30岁以下。",
		"current": GameManager.job_level == 2,
		"locked": client_reason != "" and GameManager.job_level != 2,
		"lock_reason": client_reason,
	}
	if GameManager.job_level != 2 and client_reason == "":
		client_item["action"] = on_job_client
	items.append(client_item)

	_app._build_app_overlay(menu, "BOSS弯聘", Color(0.2, 0.55, 0.9, 1), status, items)
	_app._set_layer_visible(menu, true)


func on_job_admin() -> void:
	if GameManager.job_level == 0:
		_main.show_message("你已经在初级行政岗位上。")
		open_job_app()
		return
	GameManager.add_activity("工作", "调整回初级行政岗位，收入下降但压力也更低。")
	_app._show_action_result("已转回初级行政，底薪 800/1500/2500。", {"job_level": -GameManager.job_level}, func() -> void:
		_app._refresh_main_ui()
		open_job_app()
	)


func on_job_media() -> void:
	if GameManager.job_level == 1:
		_main.show_message("你已经是新媒体运营。")
		open_job_app()
		return
	var reason := media_lock_reason()
	if reason != "":
		_main.show_message(reason)
		return
	if not spend_career_action("新媒体运营面试", 15, 10):
		return
	GameManager.add_activity("工作", "通过新媒体运营面试，职位提升。")
	_app._show_action_result("跳槽成功。下周开始，新媒体运营底薪 2000/4000/6000。", {"energy": -15, "sanity": -10, "job_level": 1 - GameManager.job_level}, func() -> void:
		_app._refresh_main_ui()
		open_job_app()
	)


func on_job_client() -> void:
	if GameManager.job_level == 2:
		_main.show_message("你已经是大客户经理。")
		open_job_app()
		return
	var reason := client_lock_reason()
	if reason != "":
		_main.show_message(reason)
		return
	if not spend_career_action("大客户经理面试", 20, 15):
		return
	GameManager.add_activity("工作", "拿下大客户经理岗位，正式进入高薪高压轨道。")
	_app._show_action_result("面试通过。大客户经理底薪 4000/8000/12000，但从下周开始，职场风险也会更重。", {"energy": -20, "sanity": -15, "job_level": 2 - GameManager.job_level}, func() -> void:
		_app._refresh_main_ui()
		open_job_app()
	)


func _job_menu() -> ColorRect:
	return _app.job_menu as ColorRect


func _action_service():
	if is_instance_valid(_main):
		return _main.get("action_service")
	return null
