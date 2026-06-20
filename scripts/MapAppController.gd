## MapAppController.gd
## Owns Gaode map app opening, compact map UI rendering, and location-card activation.
extends RefCounted

var _main: Node
var _app: RefCounted


func init(main: Node, app_system: RefCounted) -> void:
	_main = main
	_app = app_system


func open_map() -> bool:
	if not _app._can_open_phone_app():
		return false
	if not _app._ensure_app_unlocked("map"):
		return false
	_app._clear_phone_focus_overlays()
	_app._close_all_menus()
	_app._restore_map_to_phone_layer()
	_app._reset_layer_visual_state(_location_menu())
	render_map_menu()
	return true


func close_map() -> void:
	_app._set_layer_visible(_location_menu(), false)


func render_map_menu() -> void:
	var location_menu := _location_menu()
	for child in location_menu.get_children():
		location_menu.remove_child(child)
		child.queue_free()

	var outer := MarginContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 10)
	outer.add_theme_constant_override("margin_top", 28)
	outer.add_theme_constant_override("margin_right", 10)
	outer.add_theme_constant_override("margin_bottom", 10)
	location_menu.add_child(outer)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_flat_style(Color(0.955, 0.980, 0.965, 1), Color(0.42, 0.62, 0.54, 0.45), 1, 13))
	outer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 7)
	vbox.add_child(header_row)

	var app_mark := PanelContainer.new()
	app_mark.custom_minimum_size = Vector2(34, 34)
	app_mark.add_theme_stylebox_override("panel", _make_flat_style(Color(0.08, 0.55, 0.43, 1), Color(1, 1, 1, 0.10), 1, 9))
	header_row.add_child(app_mark)

	var app_mark_label := Label.new()
	app_mark_label.text = "高"
	app_mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app_mark_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	app_mark_label.add_theme_font_size_override("font_size", 18)
	app_mark_label.add_theme_color_override("font_color", Color.WHITE)
	app_mark.add_child(app_mark_label)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 0)
	header_row.add_child(title_box)

	var title_lbl := Label.new()
	title_lbl.text = "高德地图"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.05, 0.18, 0.15, 1))
	title_box.add_child(title_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "深圳 · 周末路线"
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.add_theme_font_size_override("font_size", 13)
	status_lbl.add_theme_color_override("font_color", Color(0.34, 0.48, 0.43, 1))
	title_box.add_child(status_lbl)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(34, 34)
	_style_text_button(close_btn, Color(0.80, 0.90, 0.85, 1), Color(0.70, 0.84, 0.77, 1), Color(0.05, 0.25, 0.20, 1))
	close_btn.pressed.connect(close_map)
	header_row.add_child(close_btn)

	vbox.add_child(_make_route_summary())

	var metric_row := HBoxContainer.new()
	metric_row.add_theme_constant_override("separation", 5)
	vbox.add_child(metric_row)
	metric_row.add_child(_make_metric_chip("精力", "%d/%d" % [GameManager.energy, GameManager.max_energy], Color(0.08, 0.55, 0.35, 1)))
	metric_row.add_child(_make_metric_chip("现金", str(GameManager.money), Color(0.17, 0.39, 0.78, 1)))
	metric_row.add_child(_make_metric_chip("花呗", str(GameManager.huabei_debt + GameManager.huabei_installment_debt), Color(0.78, 0.24, 0.22, 1)))

	var section_row := HBoxContainer.new()
	section_row.add_theme_constant_override("separation", 6)
	vbox.add_child(section_row)

	var section_lbl := Label.new()
	section_lbl.text = "附近地点"
	section_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_lbl.add_theme_font_size_override("font_size", 16)
	section_lbl.add_theme_color_override("font_color", Color(0.08, 0.20, 0.17, 1))
	section_row.add_child(section_lbl)

	var count_lbl := Label.new()
	count_lbl.text = _available_count_text()
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", Color(0.35, 0.48, 0.43, 1))
	section_row.add_child(count_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var loc_list := VBoxContainer.new()
	loc_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loc_list.add_theme_constant_override("separation", 7)
	scroll.add_child(loc_list)

	for location_id: String in _location_order():
		_add_location_card(loc_list, location_id)

	_app._set_layer_visible(location_menu, true)
	_app._reset_layer_visual_state(location_menu)


func start_location(location_id: String) -> void:
	_app._start_location(location_id)


func _location_menu() -> Control:
	return _app.location_menu as Control


func _make_flat_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	return _app._make_flat_style(bg, border, border_width, radius)


func _style_text_button(button: Button, normal: Color, hover: Color, font_color: Color = Color.WHITE) -> void:
	_app._style_text_button(button, normal, hover, font_color)


func _location_config(location: String) -> Dictionary:
	return _app._location_config(location)


func _weekly_location_visits(location: String) -> int:
	if _app.has_method("_get_weekly_location_visits"):
		return int(_app._get_weekly_location_visits(location))
	return 0


func _repeat_scale(visit_index: int) -> float:
	if _app.has_method("_location_repeat_scale"):
		return float(_app._location_repeat_scale(visit_index))
	if visit_index <= 0:
		return 1.0
	if visit_index == 1:
		return 0.5
	return 0.25


func _apply_repeat_decay(changes: Dictionary, visit_index: int) -> Dictionary:
	if _app.has_method("_apply_location_repeat_decay"):
		return _app._apply_location_repeat_decay(changes, visit_index)
	return changes.duplicate()


func _park_visited_this_week() -> bool:
	if _app.has_method("_is_once_per_week_location_visited"):
		return bool(_app._is_once_per_week_location_visited())
	return false


func _location_order() -> Array[String]:
	if GameManager.month <= 1:
		match GameManager.week_in_month:
			1:
				if _is_first_week_beach_route_unlocked():
					return ["park", "overtime", "home", "market", "library", "cafe", "gym", "bar"]
				return ["overtime", "park", "home", "market", "library", "cafe", "gym", "bar"]
			2:
				return ["park", "home", "market", "overtime", "library", "cafe", "gym", "bar"]
			3:
				return ["library", "cafe", "gym", "park", "home", "market", "overtime", "bar"]
			_:
				if _projected_cash_after() < 1000:
					return ["overtime", "home", "park", "market", "library", "cafe", "gym", "bar"]
				return ["home", "park", "library", "cafe", "gym", "market", "overtime", "bar"]
	return ["library", "gym", "bar", "home", "park", "cafe", "market", "overtime"]


func _add_location_card(parent: VBoxContainer, location_id: String) -> void:
	var config := _location_config(location_id)
	if config.is_empty():
		return
	var state := _location_state(location_id, config)
	var can_go := bool(state.get("can_go", false))
	var req_text := _requirement_summary(config)
	var repeat_text := _repeat_hint(location_id)
	var meta := _location_meta(location_id)
	var guidance := _guidance_for(location_id)
	var accent_color: Color = meta.get("color", Color(0.12, 0.48, 0.40, 1))
	var tutorial_locked := not _location_unlocked(location_id)

	var card := PanelContainer.new()
	card.name = "MapCard_" + location_id
	var card_height := 76 if tutorial_locked else 136
	if not tutorial_locked and req_text != "无":
		card_height += 24
	if not tutorial_locked and repeat_text != "":
		card_height += 22
	card.custom_minimum_size = Vector2(0, card_height)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can_go else Control.CURSOR_ARROW
	card.tooltip_text = "地点行动：%s" % str(config.get("name", location_id)) if can_go else "暂未开放"
	var card_bg := Color(1, 1, 1, 0.96) if can_go else Color(0.88, 0.90, 0.89, 0.86)
	var border_color := Color(0.70, 0.82, 0.76, 0.70) if can_go else Color(0.70, 0.73, 0.72, 0.55)
	var card_style := _make_flat_style(card_bg, border_color, 1, 11)
	card.add_theme_stylebox_override("panel", card_style)
	parent.add_child(card)
	if _should_pulse_location_card(location_id, can_go):
		_start_location_card_pulse(card, card_style)
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			card.accept_event()
			if can_go:
				start_location(location_id)
	)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 10)
	card_margin.add_theme_constant_override("margin_right", 10)
	card_margin.add_theme_constant_override("margin_top", 9)
	card_margin.add_theme_constant_override("margin_bottom", 9)
	card.add_child(card_margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card_margin.add_child(row)

	var marker := ColorRect.new()
	marker.custom_minimum_size = Vector2(7, 0)
	marker.color = accent_color if can_go else Color(0.58, 0.62, 0.60, 0.72)
	row.add_child(marker)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 4)
	row.add_child(body)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 5)
	body.add_child(top_row)

	var name_lbl := Label.new()
	name_lbl.text = str(config.get("name", location_id))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 18 if can_go else 16)
	name_lbl.add_theme_color_override("font_color", Color(0.06, 0.17, 0.15, 1) if can_go else Color(0.40, 0.45, 0.43, 1))
	top_row.add_child(name_lbl)
	if can_go and not guidance.is_empty():
		top_row.add_child(_make_tag(str(guidance.get("text", "")), guidance.get("bg", Color(0.62, 0.44, 0.16, 1)), guidance.get("fg", Color.WHITE)))
	if not can_go:
		top_row.add_child(_make_tag(str(state.get("text", "锁定")), state.get("bg", Color(0.50, 0.50, 0.50, 1)), state.get("fg", Color.WHITE)))

	var note_lbl := Label.new()
	note_lbl.text = str(meta.get("note", ""))
	note_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_lbl.add_theme_font_size_override("font_size", 13)
	note_lbl.add_theme_color_override("font_color", Color(0.35, 0.45, 0.41, 1) if can_go else Color(0.54, 0.58, 0.56, 1))
	note_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body.add_child(note_lbl)

	if tutorial_locked:
		_add_card_line(body, "", _locked_hint(location_id), Color(0.50, 0.54, 0.52, 1), 13)
	else:
		_add_card_line(body, "消耗", _cost_summary(location_id, config), Color(0.55, 0.25, 0.18, 1))
		_add_card_line(body, "收益", _change_summary(_preview_changes(location_id, config), true, location_id), Color(0.08, 0.42, 0.30, 1))
		if req_text != "无":
			_add_card_line(body, "条件", req_text, Color(0.56, 0.42, 0.14, 1))
		if repeat_text != "":
			_add_card_line(body, "本周", repeat_text, Color(0.56, 0.42, 0.14, 1))


func _should_pulse_location_card(location_id: String, can_go: bool) -> bool:
	if can_go and _should_pulse_first_week_park_card() and location_id == "park":
		return true
	return can_go and GameManager.month == 1 and GameManager.week_in_month == 1 and location_id == "overtime"


func _start_location_card_pulse(card: PanelContainer, style: StyleBoxFlat) -> void:
	if not is_instance_valid(card) or not is_instance_valid(_main):
		return
	style.shadow_offset = Vector2.ZERO
	style.shadow_color = Color(1.0, 0.58, 0.12, 0.35)
	style.shadow_size = 8
	style.border_color = Color(0.95, 0.46, 0.20, 0.90)
	var tween := _main.create_tween().bind_node(card).set_loops()
	tween.tween_property(card, "modulate", Color(1.0, 0.96, 0.82, 1.0), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(style, "shadow_size", 22, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(style, "shadow_color", Color(1.0, 0.64, 0.10, 0.82), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "modulate", Color(1, 1, 1, 1), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(style, "shadow_size", 8, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(style, "shadow_color", Color(1.0, 0.58, 0.12, 0.35), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _make_route_summary() -> PanelContainer:
	var route := PanelContainer.new()
	route.custom_minimum_size = Vector2(0, 54)
	route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route.add_theme_stylebox_override("panel", _make_flat_style(Color(0.86, 0.95, 0.90, 1), Color(0.42, 0.68, 0.55, 0.55), 1, 11))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	route.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)

	var title := Label.new()
	title.text = _route_title()
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.05, 0.24, 0.18, 1))
	box.add_child(title)

	var sub := Label.new()
	sub.text = _route_hint()
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.28, 0.42, 0.36, 1))
	box.add_child(sub)
	return route


func _month_end_preview() -> Dictionary:
	if is_instance_valid(_main) and _main.has_method("_get_month_end_preview"):
		var result: Variant = _main.call("_get_month_end_preview")
		if result is Dictionary:
			return result
	return {}


func _projected_cash_after() -> int:
	var preview := _month_end_preview()
	return int(preview.get("cash_after_all", GameManager.money))


func _route_title() -> String:
	if GameManager.month <= 1:
		return "第一月路线 · 活过第一张账单"
	return "从城中村出租屋出发"


func _route_hint() -> String:
	if GameManager.month <= 1:
		match GameManager.week_in_month:
			1:
				if _is_first_week_beach_route_unlocked():
					return "加班后情绪很低，先去海边吹吹风，把自己捡回来。"
				return "先去公司加班，挣一笔应急现金，再决定要不要低成本行动。"
			2:
				return "身体开始报警，恢复类地点不是浪费周末。"
			3:
				return "成长能改变下个月，缺现金时再选高压加班。"
			_:
				return "月底前最后修正：缺钱补现金，太累先补状态。"
	return "点亮起的地点卡片行动，事件结算后回家。"


func _locked_hint(location_id: String) -> String:
	if GameManager.month == 1 and GameManager.week_in_month == 1:
		if _is_first_week_beach_route_unlocked():
			if location_id == "overtime":
				return "先去海边散心"
		elif location_id == "park":
			return "加班后开放"
	match location_id:
		"home":
			return "第2周开放"
		"market":
			return "第2周开放"
		"park":
			return "第2周开放"
		"library", "cafe", "gym":
			return "第3周开放"
		"bar":
			return "第二个月开放"
	return "后续开放"


func _guidance_for(location_id: String) -> Dictionary:
	var cash_after := _projected_cash_after()
	var energy_low := GameManager.energy <= 35
	if GameManager.month <= 1 and location_id == "bar":
		return {"text": "谨慎消费", "bg": Color(0.72, 0.32, 0.22, 1), "fg": Color.WHITE}
	if cash_after < 0 and location_id == "overtime":
		return {"text": "应急现金", "bg": Color(0.76, 0.22, 0.18, 1), "fg": Color.WHITE}
	if energy_low and location_id in ["home", "park"]:
		return {"text": "推荐恢复", "bg": Color(0.12, 0.50, 0.36, 1), "fg": Color.WHITE}
	if GameManager.month <= 1:
		match GameManager.week_in_month:
			1:
				if _is_first_week_beach_route_unlocked():
					if location_id == "park":
						return {"text": "去海边", "bg": Color(0.10, 0.52, 0.74, 1), "fg": Color.WHITE}
					return {}
				if location_id == "overtime":
					return {"text": "先去加班", "bg": Color(0.76, 0.22, 0.18, 1), "fg": Color.WHITE}
			2:
				if location_id in ["home", "park", "market"]:
					return {"text": "推荐恢复", "bg": Color(0.12, 0.50, 0.36, 1), "fg": Color.WHITE}
				if location_id == "overtime":
					return {"text": "谨慎耗损", "bg": Color(0.62, 0.44, 0.16, 1), "fg": Color.WHITE}
			3:
				if location_id in ["library", "cafe", "gym"]:
					return {"text": "推荐成长", "bg": Color(0.18, 0.48, 0.74, 1), "fg": Color.WHITE}
				if location_id == "overtime":
					return {"text": "缺钱再去", "bg": Color(0.62, 0.44, 0.16, 1), "fg": Color.WHITE}
			_:
				if cash_after < 1000 and location_id == "overtime":
					return {"text": "补现金", "bg": Color(0.76, 0.22, 0.18, 1), "fg": Color.WHITE}
				if location_id in ["home", "park"]:
					return {"text": "补状态", "bg": Color(0.12, 0.50, 0.36, 1), "fg": Color.WHITE}
				if cash_after >= 1000 and location_id in ["library", "cafe"]:
					return {"text": "可选成长", "bg": Color(0.18, 0.48, 0.74, 1), "fg": Color.WHITE}
	return {}


func _make_metric_chip(title: String, value: String, accent: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 50)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_theme_stylebox_override("panel", _make_flat_style(Color(1, 1, 1, 0.92), accent.lightened(0.32), 1, 9))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	chip.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	margin.add_child(box)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", Color(0.38, 0.48, 0.44, 1))
	box.add_child(title_lbl)

	var value_lbl := Label.new()
	value_lbl.text = value
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	value_lbl.add_theme_font_size_override("font_size", 15)
	value_lbl.add_theme_color_override("font_color", accent.darkened(0.05))
	box.add_child(value_lbl)
	return chip


func _available_count_text() -> String:
	var total := 0
	var unlocked := 0
	for location_id: String in _location_order():
		var config := _location_config(location_id)
		if config.is_empty():
			continue
		total += 1
		if _location_unlocked(location_id):
			unlocked += 1
	return "已开放 %d/%d" % [unlocked, total]


func _location_meta(location_id: String) -> Dictionary:
	for item: Dictionary in _location_defs():
		if str(item.get("id", "")) == location_id:
			return item.duplicate()
	return {
		"id": location_id,
		"color": Color(0.12, 0.48, 0.40, 1),
		"role": "地点",
		"note": "周末行动",
	}


func _make_tag(text: String, bg: Color, fg: Color) -> PanelContainer:
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", _make_flat_style(bg, Color(1, 1, 1, 0.16), 1, 999))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	tag.add_child(margin)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", fg)
	margin.add_child(label)
	return tag


func _add_card_line(parent: VBoxContainer, label_text: String, value_text: String, color: Color, font_size: int = 14) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	if label_text != "":
		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size = Vector2(42, 0)
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", color)
		row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	value.add_theme_font_size_override("font_size", font_size)
	value.add_theme_color_override("font_color", color)
	row.add_child(value)


func _location_defs() -> Array:
	return [
		{"id": "library", "color": Color(0.18, 0.42, 0.78, 1), "role": "成长", "note": "低成本提升学识"},
		{"id": "gym", "color": Color(0.15, 0.62, 0.33, 1), "role": "成长", "note": "颜值与精力上限"},
		{"id": "bar", "color": Color(0.48, 0.30, 0.70, 1), "role": "社交", "note": "高消费换情绪与情商"},
		{"id": "home", "color": Color(0.42, 0.47, 0.50, 1), "role": "恢复", "note": "便宜回血但消耗精力"},
		{"id": "park", "color": Color(0.08, 0.58, 0.40, 1), "role": "恢复", "note": "每周一次的免费散心"},
		{"id": "cafe", "color": Color(0.54, 0.34, 0.18, 1), "role": "成长", "note": "学识与情商的均衡点"},
		{"id": "market", "color": Color(0.82, 0.46, 0.10, 1), "role": "恢复", "note": "便宜情绪补给"},
		{"id": "overtime", "color": Color(0.26, 0.32, 0.66, 1), "role": "收入", "note": "高压换现金"},
	]


func _stat_name(stat_name: String) -> String:
	var extra_names := {
		"max_energy": "精力上限",
		"huabei_debt": "花呗欠款",
		"huabei_installment_debt": "花呗分期",
	}
	return GameManager.stat_names.get(stat_name, extra_names.get(stat_name, stat_name))


func _change_summary(changes: Dictionary, positive: bool, location: String = "") -> String:
	var parts: Array = []
	if positive and location == "overtime":
		parts.append("金钱 +500~800")
	for stat_name in changes:
		var key := str(stat_name)
		var amount := int(changes[stat_name])
		if amount == 0:
			continue
		if location == "overtime" and positive and key == "money":
			continue
		if positive and amount <= 0:
			continue
		if not positive and amount >= 0:
			continue
		var sign := "+" if amount > 0 else ""
		parts.append("%s %s%d" % [_stat_name(key), sign, amount])
	if parts.is_empty():
		return "无直接收益" if positive else "无直接消耗"
	return " / ".join(parts)


func _cost_summary(location: String, config: Dictionary) -> String:
	var parts: Array = []
	var payment_cost := int(config.get("payment_cost", 0))
	if payment_cost > 0:
		parts.append("现金 -%d（可花呗）" % payment_cost)
	var change_text := _change_summary(config.get("changes", {}), false, location)
	if change_text != "无直接消耗":
		parts.append(change_text)
	if parts.is_empty():
		return "无直接消耗"
	return " / ".join(parts)


func _preview_changes(location: String, config: Dictionary) -> Dictionary:
	return _apply_repeat_decay(config.get("changes", {}), _weekly_location_visits(location))


func _repeat_hint(location: String) -> String:
	var visits := _weekly_location_visits(location)
	if visits <= 0:
		return ""
	var percent := int(round(_repeat_scale(visits) * 100.0))
	return "第%d次，正向收益约%d%%" % [visits + 1, percent]


func _requirement_summary(config: Dictionary) -> String:
	var parts: Array = []
	var req_stats: Dictionary = config.get("req_stats", {})
	for stat_name in req_stats:
		var key := str(stat_name)
		var needed := int(req_stats[stat_name])
		var current := int(GameManager.get(key))
		parts.append("%s≥%d（当前%d）" % [_stat_name(key), needed, current])
	if bool(config.get("once_per_week", false)):
		parts.append("每周一次")
	return "无" if parts.is_empty() else " / ".join(parts)


func _location_state(location: String, config: Dictionary) -> Dictionary:
	if not is_instance_valid(_main):
		return {"can_go": false, "text": "未就绪", "bg": Color(0.50, 0.50, 0.50, 1), "fg": Color.WHITE}
	if _main.current_phase != _main.Phase.WEEKEND:
		return {"can_go": false, "text": "仅周末", "bg": Color(0.58, 0.48, 0.36, 1), "fg": Color.WHITE}
	if not _location_unlocked(location):
		return {"can_go": false, "text": "未开放", "bg": Color(0.46, 0.50, 0.48, 1), "fg": Color.WHITE}
	if bool(config.get("once_per_week", false)) and _park_visited_this_week():
		return {"can_go": false, "text": "本周已去", "bg": Color(0.58, 0.48, 0.36, 1), "fg": Color.WHITE}
	var energy_req := int(config.get("energy_req", 0))
	if energy_req > 0 and GameManager.energy < energy_req:
		return {"can_go": false, "text": "精力不足", "bg": Color(0.70, 0.22, 0.20, 1), "fg": Color.WHITE}
	var req_stats: Dictionary = config.get("req_stats", {})
	for stat_name in req_stats:
		var key := str(stat_name)
		var needed := int(req_stats[stat_name])
		var current := int(GameManager.get(key))
		if current < needed:
			return {"can_go": false, "text": "%s不足" % _stat_name(key), "bg": Color(0.70, 0.22, 0.20, 1), "fg": Color.WHITE}
	return {"can_go": true, "text": "", "bg": Color(0.08, 0.53, 0.37, 1), "fg": Color.WHITE}


func _location_unlocked(location_id: String) -> bool:
	if GameManager.month > 1:
		return true
	match GameManager.week_in_month:
		1:
			if _is_first_week_beach_route_unlocked():
				return location_id == "park"
			return location_id == "overtime"
		2:
			return location_id in ["park", "home", "market", "overtime"]
		3:
			return location_id in ["library", "park", "home", "market", "cafe", "gym", "overtime"]
		_:
			return location_id != "bar"
	return true


func _is_first_week_beach_route_unlocked() -> bool:
	if not is_instance_valid(_main) or not _main.has_method("is_first_week_beach_route_unlocked"):
		return false
	return bool(_main.call("is_first_week_beach_route_unlocked"))


func _should_pulse_first_week_park_card() -> bool:
	if not is_instance_valid(_main) or not _main.has_method("should_pulse_first_week_park_card"):
		return false
	return bool(_main.call("should_pulse_first_week_park_card"))
