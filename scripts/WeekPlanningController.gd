## WeekPlanningController.gd
## Owns weekday planning choices: food budget, work attitude, salary, and workday completion.
extends RefCounted

var _main: Node


func init(main: Node) -> void:
	_main = main


func reset_choice_buttons() -> void:
	_main.btn_food_low.disabled = false
	_main.btn_food_mid.disabled = false
	_main.btn_food_high.disabled = false
	_main.btn_work_normal.disabled = true
	_main.btn_work_slack.disabled = true
	_main.btn_work_overtime.disabled = true
	if _main.ui_state and _main.ui_state.has_method("clear_stored_disabled"):
		_main.ui_state.clear_stored_disabled(_main.weekday_panel)


func update_work_button_text() -> void:
	_main.btn_work_normal.text = "正常打卡 (精力-30, 情绪-15, 待发工资+%d)" % get_salary("normal")
	_main.btn_work_slack.text = "摸鱼混日子 (精力-10, 情绪+5, 待发工资+%d)" % get_salary("slack")
	_main.btn_work_overtime.text = "疯狂自愿加班 (精力-60, 情绪-30, 待发工资+%d)" % get_salary("overtime")


func on_food_low() -> void:
	_choose_food(
		300,
		"low_food",
		-5,
		0,
		"吃了挂逼生存套餐（沙县/拉面），花费300元",
		true
	)


func on_food_mid() -> void:
	_choose_food(
		800,
		"mid_food",
		0,
		10,
		"吃了打工人标配（肯德基/火锅），花费800元",
		false
	)


func on_food_high() -> void:
	_choose_food(
		2000,
		"high_food",
		20,
		15,
		"吃了小资高档（日料/西餐），花费2000元",
		false
	)


func unlock_work_buttons() -> void:
	_lock_food_buttons()
	_main.btn_work_normal.disabled = false
	_main.btn_work_slack.disabled = false
	_main.btn_work_overtime.disabled = false
	_main._refresh_ui()
	_main.sync_ui_state()


func on_work_slack() -> void:
	GameManager.consecutive_overtime = 0
	var amount: int = get_salary("slack")
	complete_work_action("摸鱼混日子", {"energy": -10, "sanity": 5, "pending_salary": amount}, "摸鱼混日子，待发工资 +%d" % amount)


func on_work_normal() -> void:
	GameManager.consecutive_overtime = 0
	var amount: int = get_salary("normal")
	complete_work_action("正常打卡", {"energy": -30, "sanity": -15, "pending_salary": amount}, "正常打卡，待发工资 +%d" % amount)


func on_work_overtime() -> void:
	GameManager.consecutive_overtime += 1
	var amount: int = get_salary("overtime")
	var changes := {"energy": -60, "sanity": -30, "pending_salary": amount}
	GameManager.add_activity("日常", "疯狂加班，待发工资 +%d" % amount, changes)
	show_action_result("你选择继续加班，把这周的时间全压进了工位里。", changes, Callable(self, "finish_workday"))


func complete_work_action(label: String, changes: Dictionary, activity_desc: String) -> void:
	GameManager.add_activity("日常", activity_desc, changes)
	show_action_result("这周你选择了%s。" % label, changes, Callable(self, "finish_workday"))


func apply_action_changes(changes: Dictionary) -> Dictionary:
	if _main.action_service and _main.action_service.has_method("apply_stat_changes"):
		return _main.action_service.apply_stat_changes(changes)
	var applied: Dictionary = {}
	for stat_name in changes:
		var amount := int(changes[stat_name])
		if amount == 0:
			continue
		match str(stat_name):
			"pending_salary":
				GameManager.pending_salary += amount
			"monthly_food_cost":
				GameManager.monthly_food_cost = maxi(GameManager.monthly_food_cost + amount, 0)
			_:
				GameManager.modify_stat(str(stat_name), amount)
		applied[stat_name] = amount
	return applied


func show_action_result(story_text: String, changes: Dictionary, after: Callable = Callable()) -> void:
	_main.weekday_panel.visible = false
	if _main.action_service and _main.action_service.has_method("show_deferred_action_result"):
		_main.action_service.show_deferred_action_result(story_text, changes, func() -> void:
			var death: Dictionary = GameManager.check_behavior_death()
			if death.size() > 0:
				GameManager.game_over.emit(death["title"], death["desc"])
				return
			if after.is_valid():
				after.call()
		)
	elif _main.action_service and _main.action_service.has_method("show_action_result"):
		var applied := apply_action_changes(changes)
		_main.action_service.show_action_result(story_text, applied, after)
	else:
		var applied := apply_action_changes(changes)
		_main.show_stat_result(applied, after)


func get_salary(work_type: String) -> int:
	match GameManager.job_level:
		0:
			match work_type:
				"slack": return 800
				"normal": return 1500
				"overtime": return 2500
		1:
			match work_type:
				"slack": return 2000
				"normal": return 4000
				"overtime": return 6000
		2:
			match work_type:
				"slack": return 4000
				"normal": return 8000
				"overtime": return 12000
	return 1000


func finish_workday() -> void:
	_main._refresh_ui()
	_main.weekday_panel.visible = false
	if GameManager.pending_aging_msg != "":
		var aging_text := GameManager.pending_aging_msg
		GameManager.pending_aging_msg = ""
		_main.galgame.show_message(aging_text, true)
		_main._play_transition_after_aging()
	else:
		_main._play_transition("5天的牛马生活结束了，终于熬到了周末...")


func _choose_food(cost: int, label: String, sanity_delta: int, energy_delta: int, activity_desc: String, poor_food: bool) -> void:
	_lock_food_buttons()
	var changes: Dictionary = {}
	if _main.action_service and _main.action_service.has_method("add_monthly_food"):
		changes = _main.action_service.add_monthly_food(cost, label, sanity_delta, energy_delta)
	else:
		GameManager.monthly_food_cost += cost
		if sanity_delta != 0:
			GameManager.modify_stat("sanity", sanity_delta)
			changes["sanity"] = sanity_delta
		if energy_delta != 0:
			GameManager.modify_stat("energy", energy_delta)
			changes["energy"] = energy_delta
		changes["monthly_food_cost"] = cost
	GameManager.add_activity("日常", activity_desc, changes)
	if poor_food:
		GameManager.consecutive_poor_food += 1
	else:
		GameManager.consecutive_poor_food = 0
	GameManager.consecutive_overtime = 0
	var death: Dictionary = GameManager.check_behavior_death()
	if death.size() > 0:
		GameManager.game_over.emit(death["title"], death["desc"])
		return
	unlock_work_buttons()


func _lock_food_buttons() -> void:
	_main.btn_food_low.disabled = true
	_main.btn_food_mid.disabled = true
	_main.btn_food_high.disabled = true
