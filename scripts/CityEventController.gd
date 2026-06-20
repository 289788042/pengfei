## CityEventController.gd
## Owns city fragment loading, fragment choices, and fragment result cleanup.
extends RefCounted

var _main: Node
var _app: RefCounted
var _fragments: Dictionary = {}
var _choice_container: VBoxContainer = null
var _pending_base_changes: Dictionary = {}
var _pending_applied_changes: Dictionary = {}


func init(main: Node, app_system: RefCounted) -> void:
	_main = main
	_app = app_system
	_load_fragments()


func fragments() -> Dictionary:
	return _fragments


func has_fragments(location: String) -> bool:
	return _fragments.get(location, []).size() > 0


func trigger_fragment(location: String, base_changes: Dictionary = {}, already_applied_changes: Dictionary = {}) -> void:
	var pool: Array = _fragments.get(location, [])
	if pool.size() == 0:
		return
	var filtered: Array = []
	for fragment in pool:
		if fragment.get("min_turn", 0) <= GameManager.turn_count:
			filtered.append(fragment)
	if filtered.size() == 0:
		filtered = pool

	var fragment: Dictionary = filtered[randi() % filtered.size()]
	var text: String = fragment.get("text", "")
	text = _app._strip_embedded_result_lines(text)
	var choices: Array = fragment.get("choices", [])
	if choices.size() > 0:
		var pages: Array = [text]
		_main.galgame.show_galgame_dialog(pages, func() -> void:
			_show_fragment_choices(choices, base_changes, already_applied_changes)
		)
		return

	var effects: Dictionary = fragment.get("effect", {})
	var pending_changes: Dictionary = _app._merge_change_dicts(base_changes, effects)
	_app._show_story_then_apply_changes(text, pending_changes, already_applied_changes, _app._finish_location_event_after())


func _load_fragments() -> void:
	var frag_file := FileAccess.open("res://Data/city_fragments.json", FileAccess.READ)
	if not frag_file:
		_fragments = {}
		return
	var json := JSON.new()
	if json.parse(frag_file.get_as_text()) == OK and json.data is Dictionary:
		_fragments = json.data
	frag_file.close()


func _show_fragment_choices(choices: Array, base_changes: Dictionary = {}, already_applied_changes: Dictionary = {}) -> void:
	var gal: RefCounted = _main.galgame
	var box: Panel = gal.left_dialog_box
	box.visible = true
	box.modulate.a = 1.0
	_pending_base_changes = base_changes.duplicate()
	_pending_applied_changes = already_applied_changes.duplicate()
	gal.left_dialog_text.text = ""
	gal.left_dialog_text.visible = false
	_set_next_week_locked(true)

	if is_instance_valid(_choice_container):
		_choice_container.queue_free()
	_choice_container = VBoxContainer.new()
	_choice_container.name = "FragChoiceContainer"
	_choice_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_container.offset_left = 20
	_choice_container.offset_top = 12
	_choice_container.offset_right = -16
	_choice_container.offset_bottom = -12
	_choice_container.add_theme_constant_override("separation", 8)
	box.add_child(_choice_container)

	for choice in choices:
		var btn := Button.new()
		btn.text = choice.get("text", "...")
		btn.add_theme_font_size_override("font_size", 20)
		btn.custom_minimum_size.y = 48

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.2, 0.85)
		style.set_corner_radius_all(10.0)
		style.set_content_margin_all(12)
		style.border_color = Color(0.5, 0.5, 0.6, 0.6)
		style.set_border_width_all(1)
		btn.add_theme_stylebox_override("normal", style)

		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.25, 0.28, 0.38, 0.92)
		hover_style.set_corner_radius_all(10.0)
		hover_style.set_content_margin_all(12)
		hover_style.border_color = Color(0.7, 0.75, 0.9, 0.8)
		hover_style.set_border_width_all(1)
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.3, 0.35, 0.5, 0.95)
		pressed_style.set_corner_radius_all(10.0)
		pressed_style.set_content_margin_all(12)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		var cost: Dictionary = choice.get("cost", {})
		var cost_money: int = int(cost.get("money", 0))
		if cost_money > 0 and GameManager.money < cost_money:
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 0.7))
			var disabled_style := StyleBoxFlat.new()
			disabled_style.bg_color = Color(0.1, 0.1, 0.12, 0.5)
			disabled_style.set_corner_radius_all(10.0)
			disabled_style.set_content_margin_all(12)
			btn.add_theme_stylebox_override("disabled", disabled_style)
		else:
			btn.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95, 1))

		var captured_choice: Dictionary = choice
		btn.pressed.connect(func() -> void:
			_on_fragment_choice(captured_choice)
		)
		_choice_container.add_child(btn)


func _on_fragment_choice(choice: Dictionary) -> void:
	var result_changes: Dictionary = {}
	var cost: Dictionary = choice.get("cost", {})
	for stat_name in cost:
		var cost_value: int = int(cost[stat_name])
		if cost_value != 0:
			result_changes[stat_name] = int(result_changes.get(stat_name, 0)) - cost_value

	var effects: Dictionary = choice.get("effect", {})
	for stat_name in effects:
		var effect_value: int = int(effects[stat_name])
		if effect_value == 0:
			continue
		result_changes[stat_name] = int(result_changes.get(stat_name, 0)) + effect_value

	var pending_changes: Dictionary = _app._merge_change_dicts(_pending_base_changes, result_changes)
	var already_applied_changes: Dictionary = _pending_applied_changes.duplicate()
	if is_instance_valid(_choice_container):
		_choice_container.visible = false
		_choice_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_choice_container.queue_free()
		_choice_container = null

	var result: String = choice.get("result", "")
	_pending_base_changes.clear()
	_pending_applied_changes.clear()
	call_deferred("_show_fragment_choice_result", result, pending_changes, already_applied_changes)


func _show_fragment_choice_result(result: String, pending_changes: Dictionary, already_applied_changes: Dictionary) -> void:
	var gal: RefCounted = _main.galgame
	gal.left_dialog_text.visible = true
	var after_result := func() -> void:
		_set_next_week_locked(false)
		_app._end_location_event()
	_app._show_story_then_apply_changes(result, pending_changes, already_applied_changes, after_result)


func _set_next_week_locked(locked: bool) -> void:
	var skip_btn: Button = _main.get_node_or_null("HBoxContainer/RightMargin/RightSystemArea/Btn_NextWeek")
	if skip_btn:
		skip_btn.disabled = locked
	if not locked and _main.has_method("sync_ui_state"):
		_main.sync_ui_state()
