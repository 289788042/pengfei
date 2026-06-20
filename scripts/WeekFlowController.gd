## WeekFlowController.gd
## Owns weekday/weekend transitions and end-week confirmation flow.
extends RefCounted

var _main: Node


func init(main: Node) -> void:
	_main = main


func enter_weekday() -> void:
	_main.current_phase = _main.Phase.WEEKDAY
	_main.return_to_home_environment("weekday")
	_main.btn_next_week.visible = false
	_main._hide_all_popups()
	_main._disable_app_grid()
	GameManager.check_auto_unlock_npcs()
	_update_work_button_text()
	_main.weekday_panel.visible = false
	reset_weekday_choice_buttons()
	_main._refresh_ui()
	_main.sync_ui_state()
	_main.call_deferred("_begin_weekday_flow")


func begin_weekday_flow() -> void:
	if _main.current_phase != _main.Phase.WEEKDAY:
		return
	if maybe_trigger_weekday_story_event():
		_main.set("_weekday_panel_waiting_for_story", true)
		_main.set("_weekday_panel_clear_frames", 0)
		_main.sync_ui_state()
		return
	show_weekday_planning_panel()


func show_weekday_planning_panel() -> void:
	if _main.current_phase != _main.Phase.WEEKDAY or GameManager.game_finished or GameManager.awaiting_month_settle:
		return
	_main.set("_weekday_panel_clear_frames", 0)
	reset_weekday_choice_buttons()
	_main.weekday_panel.visible = true
	_main.sync_ui_state()


func reset_weekday_choice_buttons() -> void:
	_main.btn_food_low.disabled = false
	_main.btn_food_mid.disabled = false
	_main.btn_food_high.disabled = false
	_main.btn_work_normal.disabled = true
	_main.btn_work_slack.disabled = true
	_main.btn_work_overtime.disabled = true
	if _main.ui_state and _main.ui_state.has_method("clear_stored_disabled"):
		_main.ui_state.clear_stored_disabled(_main.weekday_panel)


func maybe_trigger_weekday_story_event() -> bool:
	if _main.current_phase != _main.Phase.WEEKDAY or GameManager.game_finished or GameManager.awaiting_month_settle:
		return false
	if GameManager.month == 1 and GameManager.week_in_month == 2:
		_main._trigger_mainline_lin_fan_first_brush()
		return true
	elif GameManager.month == 1 and GameManager.week_in_month == 3:
		_main._push_a_qiang_family_hint_01()
		return true
	elif GameManager.month == 2 and GameManager.week_in_month == 1:
		_main._trigger_mainline_lin_fan_second_brush()
		return true
	elif GameManager.month == 2 and GameManager.week_in_month == 3:
		_main._push_a_qiang_family_hint_02()
		return true
	elif GameManager.month == 2 and GameManager.week_in_month == 4:
		_main._unlock_lin_fan_story_contact()
		return true
	elif GameManager.month == 3 and GameManager.week_in_month == 1:
		_main._trigger_chen_mo_dinner_notice()
		return true
	elif GameManager.month == 3 and GameManager.week_in_month == 2:
		_main._trigger_chen_mo_first_dinner()
		return true
	elif GameManager.month == 3 and GameManager.week_in_month == 3:
		_main._unlock_a_qiang_story_contact()
		return true
	elif GameManager.month == 3 and GameManager.week_in_month == 4:
		_main._push_chen_mo_light_followup()
		return true
	return false


func enter_weekend() -> void:
	_main.current_phase = _main.Phase.WEEKEND
	_main.weekday_panel.visible = false
	_main.return_to_home_environment("weekend")
	_main.btn_next_week.visible = true
	_main._enable_app_grid()
	update_weekend_ui()
	_main._refresh_ui()
	_main.sync_ui_state()
	_main.btn_next_week.disabled = _main._is_tutorial_end_week_locked()
	_main._maybe_start_first_week_app_tutorial()
	_main.call_deferred("_maybe_show_second_week_map_hint")
	_main.call_deferred("_maybe_show_client_dinner_prep_prompt")


func update_weekend_ui() -> void:
	_main.btn_next_week.text = "⏭ 结束本周"
	_main.btn_next_week.tooltip_text = "%s\n\n本周日程：%s" % [
		_main._build_week_confirm_text(),
		GameManager.get_weekend_schedule_text(),
	]
	_main.btn_next_week.disabled = _main._is_tutorial_end_week_locked()
	_main._sync_phone_home_apps(true)


func on_pay_rent() -> void:
	_main.set_ui_layer_visible(_main.month_end_popup, false)
	GameManager.start_new_month()
	if GameManager.awaiting_ending_choice:
		return
	if not GameManager.game_finished:
		enter_weekday()


func on_next_week_pressed() -> void:
	if _main.get("_phone_focus_button") == _main.btn_next_week:
		_main._stop_phone_focus_pulse()
	if bool(_main.get("_skip_week_confirm")):
		proceed_next_week()
		return
	show_week_confirm_popup()


func show_week_confirm_popup() -> void:
	var overlay := ColorRect.new()
	overlay.name = "WeekConfirmOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.z_index = 80
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_main.add_child(overlay)
	_main.sync_ui_state()

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.98, 0.97, 0.95, 1)
	panel_style.set_corner_radius_all(12.0)
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "确认结束本周？"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.BLACK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = _main._build_week_confirm_text()
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(desc)

	var no_remind := CheckBox.new()
	no_remind.text = "不再提醒"
	no_remind.add_theme_font_size_override("font_size", 13)
	no_remind.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	no_remind.add_theme_icon_override("checked", null)
	no_remind.add_theme_icon_override("unchecked", null)
	var hbox_remind := HBoxContainer.new()
	hbox_remind.add_theme_constant_override("separation", 4)
	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_remind.add_child(spacer_l)
	hbox_remind.add_child(no_remind)
	vbox.add_child(hbox_remind)

	var btn_confirm := Button.new()
	btn_confirm.text = "确认，结束本周"
	btn_confirm.custom_minimum_size = Vector2(0, 44)
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = Color(0.027, 0.757, 0.376, 1)
	confirm_style.set_corner_radius_all(8)
	btn_confirm.add_theme_stylebox_override("normal", confirm_style)
	btn_confirm.add_theme_color_override("font_color", Color.WHITE)
	btn_confirm.add_theme_font_size_override("font_size", 16)
	btn_confirm.pressed.connect(_on_week_confirm.bind(overlay, no_remind))
	vbox.add_child(btn_confirm)

	var btn_back := Button.new()
	btn_back.text = "返回，再逛逛"
	btn_back.custom_minimum_size = Vector2(0, 44)
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = Color(0.5, 0.5, 0.5, 1)
	back_style.set_corner_radius_all(8)
	btn_back.add_theme_stylebox_override("normal", back_style)
	btn_back.add_theme_color_override("font_color", Color.WHITE)
	btn_back.add_theme_font_size_override("font_size", 16)
	btn_back.pressed.connect(func() -> void:
		overlay.queue_free()
		_main.call_deferred("sync_ui_state")
	)
	vbox.add_child(btn_back)


func proceed_next_week() -> void:
	GameManager.advance_week()
	if GameManager.awaiting_month_settle:
		return
	if not GameManager.game_finished:
		enter_weekday()


func _on_week_confirm(overlay: ColorRect, no_remind: CheckBox) -> void:
	if no_remind.button_pressed:
		_main.set("_skip_week_confirm", true)
	overlay.queue_free()
	_main.call_deferred("sync_ui_state")
	if GameManager.sanity < 30 and randf() < 0.5:
		_main.app._enter_late_night()
		return
	proceed_next_week()


func _update_work_button_text() -> void:
	_main.btn_work_normal.text = "正常打卡 (精力-30, 情绪-15, 待发工资+%d)" % _main._get_salary("normal")
	_main.btn_work_slack.text = "摸鱼混日子 (精力-10, 情绪+5, 待发工资+%d)" % _main._get_salary("slack")
	_main.btn_work_overtime.text = "疯狂自愿加班 (精力-60, 情绪-30, 待发工资+%d)" % _main._get_salary("overtime")
