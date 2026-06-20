## DiaryAppController.gd
## Owns diary app layout, filters, monthly summary, and activity log rendering.
extends RefCounted

const HeavyAppUI = preload("res://scripts/HeavyAppUI.gd")

var _main: Node
var _app: RefCounted
var _filter: String = "全部"
var _filter_buttons: Dictionary = {}
var _summary_label: Label


func init(main: Node, app_system: RefCounted) -> void:
	_main = main
	_app = app_system


func setup_heavy_ui() -> void:
	var diary_popup := _diary_popup()
	if not is_instance_valid(diary_popup):
		return
	_app._setup_heavy_app_layer(diary_popup, 80, Vector2(960, 760))
	if bool(diary_popup.get_meta("heavy_diary_built", false)):
		return

	var vbox := diary_popup.find_child("DiaryVBox", true, false) as VBoxContainer
	var filter_hbox := diary_popup.find_child("DiaryFilterHBox", true, false) as HBoxContainer
	var scroll := diary_popup.find_child("DiaryScroll", true, false) as ScrollContainer
	var close_btn := diary_popup.find_child("BtnCloseDiary", true, false) as Button
	if not is_instance_valid(vbox) or not is_instance_valid(filter_hbox) or not is_instance_valid(scroll) or not is_instance_valid(close_btn):
		return

	_app._detach_from_parent(filter_hbox)
	_app._detach_from_parent(scroll)
	_app._detach_from_parent(close_btn)
	for child: Node in vbox.get_children():
		child.queue_free()

	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_make_heavy_header("日记本", "活动流水、数值变化和关键选择复盘", close_btn))

	_summary_label = _make_body_label("")
	vbox.add_child(_make_heavy_card("本月回顾", [_summary_label]))

	filter_hbox.add_theme_constant_override("separation", 8)
	filter_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_make_heavy_card("筛选", [filter_hbox]))
	_collect_filter_buttons()
	_style_filter_buttons()

	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_theme_stylebox_override("panel", _app._make_flat_style(Color(1, 1, 1, 0), Color(1, 1, 1, 0), 0, 0))

	var log_container := _log_container()
	log_container.add_theme_constant_override("separation", 8)
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var log_card := _make_heavy_card("最近记录（最新在上）", [scroll])
	log_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(log_card)
	diary_popup.set_meta("heavy_diary_built", true)


func open_diary() -> void:
	if not _app._can_open_phone_app():
		return
	if not _app._ensure_app_unlocked("diary"):
		return
	_app._close_all_menus()
	refresh_ui()
	_app._set_layer_visible(_diary_popup(), true)


func on_filter(category: String) -> void:
	_filter = category
	_style_filter_buttons()
	refresh_ui()


func refresh_ui() -> void:
	var log_container := _log_container()
	for child in log_container.get_children():
		log_container.remove_child(child)
		child.queue_free()

	var logs: Array = GameManager.activity_log
	var counts: Dictionary = {}
	for entry_variant in logs:
		var entry_for_count := entry_variant as Dictionary
		var count_category := str(entry_for_count.get("category", "日常"))
		counts[count_category] = int(counts.get(count_category, 0)) + 1
	_update_summary(logs.size(), counts)

	var shown_count := 0
	for i in range(logs.size() - 1, -1, -1):
		var entry: Dictionary = logs[i]
		if _filter != "全部" and entry.get("category", "") != _filter:
			continue
		_add_log_entry(entry)
		shown_count += 1
	if shown_count == 0:
		var empty_label := _make_body_label("暂无%s记录。去地图、工作、消费或聊天后，这里会留下可复盘的行动流水。" % _filter)
		empty_label.add_theme_color_override("font_color", Color(0.40, 0.50, 0.46, 1))
		log_container.add_child(empty_label)


func _make_heavy_header(title: String, subtitle: String, close_btn: Button) -> Control:
	var header := PanelContainer.new()
	header.name = "HeavyAppHeader"
	header.custom_minimum_size = Vector2(0, 72)
	header.add_theme_stylebox_override("panel", _app._make_flat_style(Color(0.11, 0.28, 0.24, 1), Color(0.25, 0.55, 0.48, 0.55), 1, 12))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	header.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	hbox.add_child(title_box)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_box.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.add_theme_font_size_override("font_size", 13)
	subtitle_label.add_theme_color_override("font_color", Color(0.82, 0.92, 0.88, 1))
	title_box.add_child(subtitle_label)

	_app._detach_from_parent(close_btn)
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(46, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_btn.tooltip_text = "关闭日记"
	_app._style_text_button(close_btn, Color(0.86, 0.92, 0.90, 1), Color(0.76, 0.86, 0.82, 1), Color(0.08, 0.20, 0.17, 1))
	hbox.add_child(close_btn)
	return header


func _make_body_label(text: String) -> Label:
	return HeavyAppUI.make_body_label(text, 14, Color(0.14, 0.22, 0.20, 1))


func _make_heavy_card(title: String, controls: Array) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _app._make_flat_style(Color(0.975, 0.985, 0.980, 1), Color(0.76, 0.86, 0.82, 1), 1, 9))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(box)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color(0.07, 0.28, 0.23, 1))
	box.add_child(title_label)

	for control_variant in controls:
		var control := control_variant as Control
		if not is_instance_valid(control):
			continue
		_app._detach_from_parent(control)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(control)
	return card


func _collect_filter_buttons() -> void:
	_filter_buttons.clear()
	var diary_popup := _diary_popup()
	for cat: String in ["全部", "日常", "提升", "社交", "消费"]:
		var btn := diary_popup.find_child("Btn_DiaryFilter_" + cat, true, false) as Button
		if is_instance_valid(btn):
			_filter_buttons[cat] = btn


func _style_filter_buttons() -> void:
	if _filter_buttons.is_empty():
		_collect_filter_buttons()
	for cat: String in _filter_buttons.keys():
		var btn := _filter_buttons[cat] as Button
		if not is_instance_valid(btn):
			continue
		btn.custom_minimum_size = Vector2(72, 36)
		if cat == _filter:
			_app._style_text_button(btn, Color(0.10, 0.52, 0.42, 1), Color(0.12, 0.62, 0.50, 1), Color.WHITE)
		else:
			_app._style_text_button(btn, Color(0.86, 0.93, 0.90, 1), Color(0.78, 0.88, 0.84, 1), Color(0.08, 0.24, 0.20, 1))


func _category_color(category: String) -> Color:
	match category:
		"提升":
			return Color(0.12, 0.35, 0.75, 1)
		"社交":
			return Color(0.85, 0.35, 0.10, 1)
		"消费":
			return Color(0.76, 0.12, 0.10, 1)
		"工作":
			return Color(0.34, 0.25, 0.70, 1)
		_:
			return Color(0.14, 0.22, 0.20, 1)


func _stat_name(stat_name: String) -> String:
	var extra_names := {
		"affection": "好感",
		"family_affection": "亲情",
		"max_energy": "精力上限",
		"pending_salary": "待发工资",
		"monthly_food_cost": "餐饮账单",
		"night_school_progress": "夜校学分",
		"degree": "学历",
		"job_level": "职位",
		"huabei_debt": "花呗欠款",
		"huabei_installment_debt": "花呗分期",
	}
	return GameManager.stat_names.get(stat_name, extra_names.get(stat_name, stat_name))


func _compact_changes(changes: Dictionary) -> Dictionary:
	var compact: Dictionary = {}
	for stat_name in changes:
		var key := str(stat_name)
		if key == "huabei_debt" and changes.has("credit_debt"):
			continue
		var amount := int(changes[stat_name])
		if amount != 0:
			compact[key] = int(compact.get(key, 0)) + amount
	return compact


func _changes_text(changes: Dictionary) -> String:
	var compact := _compact_changes(changes)
	if compact.is_empty():
		return ""
	var ordered := [
		"money", "pending_salary", "monthly_food_cost", "credit_debt",
		"energy", "max_energy", "sanity", "charm", "intellect", "eq",
		"night_school_progress", "degree", "job_level", "affection", "family_affection",
	]
	var used: Dictionary = {}
	var parts: Array = []
	for key: String in ordered:
		if compact.has(key):
			var amount := int(compact[key])
			var sign := "+" if amount > 0 else ""
			parts.append("%s %s%d" % [_stat_name(key), sign, amount])
			used[key] = true
	for key in compact:
		var key_text := str(key)
		if used.has(key_text):
			continue
		var amount := int(compact[key])
		var sign := "+" if amount > 0 else ""
		parts.append("%s %s%d" % [_stat_name(key_text), sign, amount])
	return "变化：" + " / ".join(parts)


func _changes_color(changes: Dictionary) -> Color:
	var compact := _compact_changes(changes)
	var pressure_keys := ["monthly_food_cost", "credit_debt", "huabei_debt", "huabei_installment_debt"]
	for key in compact:
		if pressure_keys.has(str(key)) and int(compact[key]) > 0:
			return Color(0.62, 0.28, 0.18, 1)
	return Color(0.10, 0.40, 0.30, 1)


func _week_str(entry: Dictionary) -> String:
	if entry.has("age") and entry.has("month") and entry.has("week_in_month"):
		return "%d岁 %d月第%d周" % [entry["age"], entry["month"], entry["week_in_month"]]
	return "第%d周" % entry.get("week", 0)


func _update_summary(total_count: int, counts: Dictionary) -> void:
	if not is_instance_valid(_summary_label):
		return
	var parts: Array = []
	for cat: String in ["日常", "工作", "提升", "社交", "消费"]:
		var count := int(counts.get(cat, 0))
		if count > 0:
			parts.append("%s %d" % [cat, count])
	var count_text := "暂无记录" if parts.is_empty() else " / ".join(parts)
	_summary_label.text = "共 %d 条记录｜当前筛选：%s\n%s\n日记只做复盘，不消耗精力。它应该帮玩家想清楚：刚才做了什么，为什么钱、情绪或关系变了。" % [total_count, _filter, count_text]


func _add_log_entry(entry: Dictionary) -> void:
	var category := str(entry.get("category", "日常"))
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", _app._make_flat_style(Color(1, 1, 1, 1), Color(0.82, 0.90, 0.86, 1), 1, 8))
	_log_container().add_child(row)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	row.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(box)

	var meta_label := Label.new()
	meta_label.text = "%s  ·  %s" % [_week_str(entry), category]
	meta_label.add_theme_font_size_override("font_size", 12)
	meta_label.add_theme_color_override("font_color", _category_color(category))
	box.add_child(meta_label)

	var desc_label := Label.new()
	desc_label.text = str(entry.get("desc", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.12, 0.18, 0.17, 1))
	box.add_child(desc_label)

	var changes_text := _changes_text(entry.get("changes", {}))
	if changes_text != "":
		var changes_label := Label.new()
		changes_label.text = changes_text
		changes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		changes_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		changes_label.add_theme_font_size_override("font_size", 12)
		changes_label.add_theme_color_override("font_color", _changes_color(entry.get("changes", {})))
		box.add_child(changes_label)


func _diary_popup() -> ColorRect:
	return _app.diary_popup as ColorRect


func _log_container() -> VBoxContainer:
	return _app.diary_log_container as VBoxContainer
