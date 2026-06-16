## ActionService.gd
## One place for player-facing action costs and action logs.
extends RefCounted

var _main: Node
var action_log: Array[String] = []


func init(main: Node) -> void:
	_main = main


func can_use_weekend_action(_label: String = "") -> bool:
	return true


func spend_weekend_action(label: String = "") -> bool:
	_record("weekend_action_ignored", {"label": label})
	return true


func apply_stat_changes(changes: Dictionary) -> Dictionary:
	var applied: Dictionary = {}
	for stat_name in changes:
		var amount: int = int(changes[stat_name])
		if amount == 0:
			continue
		match str(stat_name):
			"pending_salary":
				GameManager.pending_salary += amount
			"monthly_food_cost":
				GameManager.monthly_food_cost = maxi(GameManager.monthly_food_cost + amount, 0)
			"night_school_progress":
				GameManager.night_school_progress = clampi(GameManager.night_school_progress + amount, 0, 12)
			"degree":
				GameManager.degree = clampi(GameManager.degree + amount, 0, 1)
			"job_level":
				GameManager.job_level = clampi(GameManager.job_level + amount, 0, 2)
			"max_energy":
				GameManager.max_energy = maxi(GameManager.max_energy + amount, 1)
				GameManager.energy = clampi(GameManager.energy, 0, GameManager.max_energy)
			"weekend_actions":
				continue
			"credit_debt":
				GameManager.huabei_debt = maxi(GameManager.huabei_debt + amount, 0)
				GameManager.credit_debt = GameManager.huabei_debt
			_:
				GameManager.modify_stat(str(stat_name), amount)
		applied[stat_name] = int(applied.get(stat_name, 0)) + amount
	_record("stat_changes", applied)
	if is_instance_valid(_main) and _main.has_method("_refresh_ui"):
		_main._refresh_ui()
	GameManager.stats_updated.emit()
	return applied


func add_pending_salary(amount: int, label: String) -> Dictionary:
	var changes := apply_stat_changes({"pending_salary": amount})
	_record("pending_salary", {"label": label, "amount": amount, "total": GameManager.pending_salary})
	return changes


func add_monthly_food(cost: int, label: String, sanity_delta: int = 0, energy_delta: int = 0) -> Dictionary:
	var changes := {"monthly_food_cost": cost}
	if sanity_delta != 0:
		changes["sanity"] = sanity_delta
	if energy_delta != 0:
		changes["energy"] = energy_delta
	var applied := apply_stat_changes(changes)
	_record("monthly_food", {
		"label": label,
		"cost": cost,
		"monthly_food_cost": GameManager.monthly_food_cost,
	})
	return applied


func show_action_result(story_text: String, changes: Dictionary, after: Callable = Callable(), title: String = "【结算】") -> void:
	var clean_story := story_text.strip_edges()
	if clean_story != "" and is_instance_valid(_main) and _main.has_method("show_galgame_dialog"):
		_main.show_galgame_dialog([clean_story], func() -> void:
			show_result(changes, after, title)
		)
	else:
		show_result(changes, after, title)


func show_deferred_action_result(story_text: String, changes: Dictionary, after: Callable = Callable(), title: String = "【结算】") -> void:
	var clean_story := story_text.strip_edges()
	var show_and_apply := func() -> void:
		var apply_after_result := func() -> void:
			apply_stat_changes(changes)
			if after.is_valid():
				after.call()
		show_result(changes, apply_after_result, title)
	if clean_story != "" and is_instance_valid(_main) and _main.has_method("show_galgame_dialog"):
		_main.show_galgame_dialog([clean_story], show_and_apply)
	else:
		show_and_apply.call()


func show_result(changes: Dictionary, after: Callable = Callable(), title: String = "【结算】") -> void:
	if changes.is_empty():
		if after.is_valid():
			after.call()
		return
	if is_instance_valid(_main) and _main.has_method("show_stat_result"):
		_main.show_stat_result(changes, after, title)
	elif after.is_valid():
		after.call()


func merge_changes(base: Dictionary, extra: Dictionary) -> Dictionary:
	var merged := base.duplicate()
	for key in extra:
		merged[key] = int(merged.get(key, 0)) + int(extra[key])
	return _without_zeroes(merged)


func _without_zeroes(changes: Dictionary) -> Dictionary:
	var cleaned: Dictionary = {}
	for key in changes:
		var amount := int(changes[key])
		if amount != 0:
			cleaned[key] = amount
	return cleaned


func get_food_bill_text(cost: int) -> String:
	return "本月餐饮账单 +%d" % cost


func get_monthly_pressure_summary() -> String:
	var debt := GameManager.huabei_debt + GameManager.huabei_installment_debt
	return "餐饮账单:%d | 花呗:%d | 房租:%d" % [GameManager.monthly_food_cost, debt, GameManager.base_rent]


func get_recent_log(max_count: int = 8) -> Array[String]:
	var start := maxi(action_log.size() - max_count, 0)
	return action_log.slice(start, action_log.size())


func _record(kind: String, payload: Dictionary) -> void:
	var line := "%s %s" % [kind, JSON.stringify(payload)]
	action_log.append(line)
	if action_log.size() > 80:
		action_log.pop_front()
