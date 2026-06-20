## PhoneAppOverlayBuilder.gd
## Builds the shared phone-list overlay used by lightweight phone apps.
extends RefCounted

var _app: RefCounted


func init(app_system: RefCounted) -> void:
	_app = app_system


func build_app_overlay(parent: ColorRect, title: String, top_color: Color, subtitle: String, items: Array) -> void:
	_app._setup_phone_layer(parent)
	parent.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.color = Color(0, 0, 0, 0.52)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_top = 8
	panel.offset_bottom = -8
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.95, 0.95, 0.95, 1)
	panel_style.set_corner_radius_all(12.0)
	panel_style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", panel_style)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	var top_bar := PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 44)
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = top_color
	top_style.set_corner_radius_all(10.0)
	top_style.set_content_margin_all(8)
	top_style.corner_detail = 8
	top_bar.add_theme_stylebox_override("panel", top_style)
	vbox.add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_bar.add_child(top_hbox)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.custom_minimum_size = Vector2(42, 30)
	close_btn.pressed.connect(func() -> void:
		_app._set_layer_visible(parent, false)
	)
	top_hbox.add_child(close_btn)

	if subtitle != "":
		var sub_bar := PanelContainer.new()
		sub_bar.custom_minimum_size = Vector2(0, 28)
		var sub_style := StyleBoxFlat.new()
		sub_style.bg_color = Color(0.9, 0.9, 0.9, 1)
		sub_style.set_content_margin_all(6)
		sub_bar.add_theme_stylebox_override("panel", sub_style)
		vbox.add_child(sub_bar)

		var sub_lbl := Label.new()
		sub_lbl.text = subtitle
		sub_lbl.add_theme_font_size_override("font_size", 12)
		sub_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sub_bar.add_child(sub_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var scroll_vbox := VBoxContainer.new()
	scroll_vbox.add_theme_constant_override("separation", 4)
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_vbox)

	for item_variant in items:
		var item: Dictionary = item_variant as Dictionary
		var is_locked: bool = item.get("locked", false)
		var is_current: bool = item.get("current", false)
		var row := _make_row(item, is_locked, is_current)
		scroll_vbox.add_child(row)

		if not is_locked and item.has("action"):
			var captured_action: Callable = item["action"]
			var close_on_action: bool = bool(item.get("close_on_action", true))
			row.mouse_filter = Control.MOUSE_FILTER_STOP
			var row_hbox := row.get_child(0) as HBoxContainer
			if is_instance_valid(row_hbox):
				for child in row_hbox.get_children():
					child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					if close_on_action:
						_app._set_layer_visible(parent, false)
					captured_action.call()
			)


func _make_row(item: Dictionary, is_locked: bool, is_current: bool) -> PanelContainer:
	var row := PanelContainer.new()
	var row_style := StyleBoxFlat.new()
	if is_locked:
		row_style.bg_color = Color(0.88, 0.88, 0.88, 1)
	elif is_current:
		row_style.bg_color = Color(0.85, 0.95, 0.85, 1)
	else:
		row_style.bg_color = Color.WHITE
	row_style.set_content_margin_all(10)
	row_style.set_corner_radius_all(8.0)
	row.add_theme_stylebox_override("panel", row_style)

	var row_hbox := HBoxContainer.new()
	row_hbox.add_theme_constant_override("separation", 8)
	row_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(row_hbox)

	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.color = item.get("icon_color", Color.GRAY)
	row_hbox.add_child(icon)

	var text_vbox := VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_hbox.add_child(text_vbox)

	var name_lbl := Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1))
	if is_locked:
		name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	text_vbox.add_child(name_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = item.get("cost", "")
	cost_lbl.add_theme_font_size_override("font_size", 11)
	cost_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
	cost_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_child(cost_lbl)

	if is_locked and item.has("lock_reason") and str(item["lock_reason"]).strip_edges() != "":
		var reason_lbl := Label.new()
		reason_lbl.text = item["lock_reason"]
		reason_lbl.add_theme_font_size_override("font_size", 10)
		reason_lbl.add_theme_color_override("font_color", Color(0.72, 0.22, 0.22, 1))
		reason_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reason_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_child(reason_lbl)

	if is_current:
		_add_side_label(row_hbox, "当前", 13, Color(0.2, 0.6, 0.2, 1))
	elif is_locked:
		_add_side_label(row_hbox, "X", 14, Color(0.8, 0.3, 0.3, 1))
	else:
		_add_side_label(row_hbox, ">", 20, Color(0.75, 0.75, 0.75, 1))

	var arrow_mr := Control.new()
	arrow_mr.custom_minimum_size = Vector2(12, 0)
	row_hbox.add_child(arrow_mr)
	return row


func _add_side_label(row_hbox: HBoxContainer, text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row_hbox.add_child(label)
