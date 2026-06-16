## HeavyAppUI.gd - shared helpers for large information-heavy phone apps.
## Phone icons can stay as entry points, while dense apps open in a readable overlay.
extends RefCounted


static func setup_layer(
	layer: Control,
	host: Node,
	z: int = 80,
	panel_min_size: Vector2 = Vector2(960, 760),
	overlay_color: Color = Color(0.015, 0.020, 0.026, 0.66),
	panel_bg: Color = Color(0.950, 0.970, 0.965, 1),
	panel_border: Color = Color(0.42, 0.58, 0.54, 0.40)
) -> void:
	if not is_instance_valid(layer) or not is_instance_valid(host):
		return
	if layer.get_parent() != host:
		var old_parent := layer.get_parent()
		if old_parent:
			old_parent.remove_child(layer)
		host.add_child(layer)

	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.offset_left = 0
	layer.offset_top = 0
	layer.offset_right = 0
	layer.offset_bottom = 0
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.z_index = z
	if layer is ColorRect:
		(layer as ColorRect).color = overlay_color

	var centers := layer.find_children("", "CenterContainer", true, false)
	if centers.size() > 0 and centers[0] is CenterContainer:
		var center := centers[0] as CenterContainer
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.offset_left = 24
		center.offset_top = 24
		center.offset_right = -24
		center.offset_bottom = -24

	var panels := layer.find_children("", "PanelContainer", true, false)
	if panels.size() > 0 and panels[0] is PanelContainer:
		var panel := panels[0] as PanelContainer
		panel.custom_minimum_size = panel_min_size
		panel.add_theme_stylebox_override("panel", make_flat_style(panel_bg, panel_border, 1, 12))


static func detach_from_parent(node: Node) -> void:
	if not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent:
		parent.remove_child(node)


static func make_flat_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(float(radius))
	return style


static func style_text_button(button: Button, normal: Color, hover: Color, font_color: Color = Color.WHITE) -> void:
	if not is_instance_valid(button):
		return
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 36.0)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_stylebox_override("normal", make_flat_style(normal, Color(1, 1, 1, 0.08), 1, 8))
	button.add_theme_stylebox_override("hover", make_flat_style(hover, Color(1, 1, 1, 0.16), 1, 8))
	button.add_theme_stylebox_override("pressed", make_flat_style(normal.darkened(0.12), Color(0, 0, 0, 0.12), 1, 8))
	button.add_theme_stylebox_override("disabled", make_flat_style(normal.darkened(0.25), Color(0, 0, 0, 0.10), 1, 8))


static func make_body_label(text: String, font_size: int = 14, font_color: Color = Color(0.14, 0.22, 0.20, 1)) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	return label
