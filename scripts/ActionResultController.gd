## ActionResultController.gd
## Owns narrative/result presentation and stat application for app actions.
extends RefCounted

var _main: Node


func init(main: Node) -> void:
	_main = main


func refresh_main_ui() -> void:
	GameManager.stats_updated.emit()
	if is_instance_valid(_main) and _main.has_method("_refresh_ui"):
		_main._refresh_ui()


func remove_colored_result_segments(line: String) -> String:
	var cleaned := line
	var start := cleaned.find("[color=")
	while start >= 0:
		var end := cleaned.find("[/color]", start)
		if end < 0:
			break
		cleaned = (cleaned.substr(0, start) + cleaned.substr(end + 8)).strip_edges()
		start = cleaned.find("[color=")
	return cleaned


func strip_embedded_result_lines(text: String) -> String:
	var kept: Array = []
	for line in text.split("\n"):
		if line.find("[color=90EE90]") >= 0 or line.find("[color=E88080]") >= 0 or line.find("[color=red]") >= 0:
			var cleaned_line := remove_colored_result_segments(line)
			if cleaned_line != "":
				kept.append(cleaned_line)
			continue
		kept.append(line)
	return "\n".join(kept).strip_edges()


func format_result(changes: Dictionary, title: String = "【结算】") -> String:
	if is_instance_valid(_main) and _main.has_method("format_stat_result"):
		return _main.format_stat_result(changes, title)
	var parts: Array = []
	for stat_name in changes:
		var val: int = int(changes[stat_name])
		if val == 0:
			continue
		var cn: String = GameManager.stat_names.get(stat_name, stat_name)
		if val > 0:
			parts.append("%s +%d" % [cn, val])
		else:
			parts.append("%s %d" % [cn, val])
	return "" if parts.is_empty() else title + "\n" + "  ".join(parts)


func format_npc_result(changes: Dictionary, npc_name: String, title: String = "【结算】") -> String:
	var text := format_result(changes, title)
	if npc_name.strip_edges() == "" or not changes.has("affection"):
		return text
	return text.replace("好感 ", "%s好感 " % npc_name)


func show_result(result_text: String, after: Callable = Callable()) -> void:
	var clean_text := result_text.strip_edges()
	if clean_text != "" and not clean_text.begins_with("【"):
		clean_text = "【结算】\n" + clean_text
	if is_instance_valid(_main) and _main.has_method("show_result_text"):
		_main.show_result_text(clean_text, after)
		return
	if clean_text != "":
		_main.galgame.show_galgame_dialog([clean_text], after)
	elif after.is_valid():
		after.call()


func show_story_then_result(story_text: String, result_text: String, after: Callable = Callable()) -> void:
	var clean_story := strip_embedded_result_lines(story_text)
	if clean_story != "":
		_main.galgame.show_galgame_dialog([clean_story], func() -> void:
			show_result(result_text, after)
		)
	else:
		show_result(result_text, after)


func show_story_then_changes(story_text: String, changes: Dictionary, after: Callable = Callable(), title: String = "【结算】") -> void:
	show_story_then_result(story_text, format_result(changes, title), after)


func show_story_then_apply_changes(story_text: String, pending_changes: Dictionary, already_applied_changes: Dictionary = {}, after: Callable = Callable(), title: String = "【结算】") -> void:
	var clean_story := strip_embedded_result_lines(story_text)
	var safe_pending_changes := drop_unbound_affection(pending_changes)
	var show_and_apply := func() -> void:
		var display_changes := merge_change_dicts(already_applied_changes, safe_pending_changes)
		show_result(format_result(display_changes, title), func() -> void:
			apply_location_changes(safe_pending_changes)
			if after.is_valid():
				after.call()
		)
	if clean_story != "":
		_main.galgame.show_galgame_dialog([clean_story], show_and_apply)
	else:
		show_and_apply.call()


func show_story_then_apply_npc_changes(story_text: String, pending_changes: Dictionary, already_applied_changes: Dictionary, npc_name: String, after: Callable = Callable(), title: String = "【结算】", npc_id: String = "", npc_pending_changes: Dictionary = {}) -> void:
	var clean_story := strip_embedded_result_lines(story_text)
	var safe_pending_changes := drop_unbound_affection(pending_changes)
	var safe_npc_changes := drop_unbound_affection(npc_pending_changes, npc_id)
	var show_and_apply := func() -> void:
		var pending_display := merge_change_dicts(safe_npc_changes, safe_pending_changes)
		var display_changes := merge_change_dicts(already_applied_changes, pending_display)
		show_result(format_npc_result(display_changes, npc_name, title), func() -> void:
			if safe_npc_changes.size() > 0:
				apply_npc_bonus_changes(npc_id, safe_npc_changes)
			apply_location_changes(safe_pending_changes)
			if after.is_valid():
				after.call()
		)
	if clean_story != "":
		_main.galgame.show_galgame_dialog([clean_story], show_and_apply)
	else:
		show_and_apply.call()


func show_location_result(location: String, fallback_text: String, changes: Dictionary, after: Callable = Callable()) -> void:
	var story := GameManager.get_location_narrative(location, fallback_text)
	show_story_then_result(story, format_result(changes), after)


func show_action_result(story_text: String, changes: Dictionary, after: Callable = Callable()) -> void:
	var service = action_service()
	if service and service.has_method("show_deferred_action_result"):
		service.show_deferred_action_result(story_text, changes, after)
	else:
		show_story_then_apply_changes(story_text, changes, {}, after)


func merge_change_dicts(base: Dictionary, extra: Dictionary) -> Dictionary:
	var merged := base.duplicate()
	for key in extra:
		var amount := int(extra[key])
		if amount == 0:
			continue
		merged[key] = int(merged.get(key, 0)) + amount
	for key in merged.keys():
		if int(merged[key]) == 0:
			merged.erase(key)
	return merged


func drop_unbound_affection(changes: Dictionary, npc_id: String = "") -> Dictionary:
	var cleaned := changes.duplicate()
	if npc_id == "" and cleaned.has("affection"):
		cleaned.erase("affection")
	return cleaned


func apply_location_changes(changes: Dictionary) -> Dictionary:
	var safe_changes := drop_unbound_affection(changes)
	var service = action_service()
	if service and service.has_method("apply_stat_changes"):
		return service.apply_stat_changes(safe_changes)
	var applied: Dictionary = {}
	for stat_name in safe_changes:
		var amount := int(safe_changes[stat_name])
		if amount == 0:
			continue
		match str(stat_name):
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
	refresh_main_ui()
	return applied


func apply_npc_bonus_changes(npc_id: String, changes: Dictionary) -> Dictionary:
	var safe_changes := drop_unbound_affection(changes, npc_id)
	var applied: Dictionary = {}
	for stat_name in safe_changes:
		var amount := int(safe_changes[stat_name])
		if amount == 0:
			continue
		if stat_name == "affection" and npc_id != "":
			if GameManager.is_npc_unlocked(npc_id):
				GameManager.add_npc_affection(npc_id, amount)
			else:
				GameManager.get_npc_runtime(npc_id)["affection"] += amount
		else:
			apply_location_changes({stat_name: amount})
		applied[stat_name] = int(applied.get(stat_name, 0)) + amount
	refresh_main_ui()
	return applied


func action_service():
	if is_instance_valid(_main):
		return _main.get("action_service")
	return null
