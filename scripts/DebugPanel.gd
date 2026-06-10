## DebugPanel.gd - 开发调试面板
## F1 切换显示。定位：只改运行时状态，不修改设计数据文件。
extends Control

const PANEL_WIDTH := 520.0
const PANEL_HEIGHT := 740.0

var _tab_idx: int = 0
var _panel_bg: PanelContainer
var _tab_bar: TabBar
var _content: ScrollContainer
var _content_vb: VBoxContainer
var _visible: bool = false
var _state_snapshot: Dictionary = {}
var _debug_log: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	z_index = 500
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_panel_bg = PanelContainer.new()
	_panel_bg.name = "DebugBG"
	_panel_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel_bg.offset_left = 10
	_panel_bg.offset_top = 10
	_panel_bg.offset_right = 10 + PANEL_WIDTH
	_panel_bg.offset_bottom = 10 + PANEL_HEIGHT
	_panel_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_bg.modulate.a = 0.94
	_panel_bg.z_index = 500
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.045, 0.065, 0.96)
	sb.border_color = Color(0.34, 0.42, 0.55, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	_panel_bg.add_theme_stylebox_override("panel", sb)
	add_child(_panel_bg)

	var main_vb := VBoxContainer.new()
	main_vb.name = "MainVBox"
	main_vb.add_theme_constant_override("separation", 6)
	_panel_bg.add_child(main_vb)

	var title_hb := HBoxContainer.new()
	title_hb.add_theme_constant_override("separation", 6)
	main_vb.add_child(title_hb)

	var title_label := Label.new()
	title_label.text = "开发调试面板"
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.add_theme_color_override("font_color", Color(0.68, 0.84, 1.0))
	title_hb.add_child(title_label)

	var hotkey := Label.new()
	hotkey.text = "F1显示/隐藏 | Ctrl跳过对话 | F2标题页快进"
	hotkey.add_theme_font_size_override("font_size", 11)
	hotkey.add_theme_color_override("font_color", Color(0.62, 0.66, 0.72))
	hotkey.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hb.add_child(hotkey)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(30, 28)
	close_btn.pressed.connect(_toggle_visible)
	title_hb.add_child(close_btn)

	_tab_bar = TabBar.new()
	_tab_bar.tab_count = 4
	_tab_bar.set_tab_title(0, "流程")
	_tab_bar.set_tab_title(1, "数值")
	_tab_bar.set_tab_title(2, "NPC")
	_tab_bar.set_tab_title(3, "体检")
	_tab_bar.tab_clicked.connect(_switch_tab)
	main_vb.add_child(_tab_bar)

	_content = ScrollContainer.new()
	_content.name = "ScrollContent"
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vb.add_child(_content)

	_content_vb = VBoxContainer.new()
	_content_vb.name = "ContentVBox"
	_content_vb.add_theme_constant_override("separation", 6)
	_content_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(_content_vb)

	_switch_tab(0)
	_set_panel_visible(false)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_toggle_visible()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and _visible:
			_set_panel_visible(false)
			get_viewport().set_input_as_handled()


func _toggle_visible() -> void:
	_set_panel_visible(not _visible)


func _set_panel_visible(value: bool) -> void:
	_visible = value
	visible = true
	if _panel_bg:
		_panel_bg.visible = value
	if value:
		_refresh_current_tab()


func _switch_tab(idx: int) -> void:
	_tab_idx = idx
	if _tab_bar:
		_tab_bar.current_tab = idx
	if not _content_vb:
		return
	for child in _content_vb.get_children():
		_content_vb.remove_child(child)
		child.queue_free()
	match idx:
		0:
			_build_flow_tab()
		1:
			_build_stats_tab()
		2:
			_build_npc_tab()
		3:
			_build_audit_tab()


func _get_main_game() -> Node:
	return get_parent()


func _build_flow_tab() -> void:
	_add_snapshot()
	_add_section("Debug Session")
	_add_button_grid([
		{"text": "Save snapshot", "cb": _debug_save_snapshot},
		{"text": "Restore snapshot", "cb": _debug_restore_snapshot},
	])
	_add_section("流程控制")
	_add_button_grid([
		{"text": "关闭弹窗/清屏", "cb": _debug_close_overlays},
		{"text": "跳过当前对话", "cb": _debug_skip_dialog},
		{"text": "进入周末", "cb": _debug_enter_weekend},
		{"text": "进入工作日", "cb": _debug_enter_weekday},
		{"text": "推进下一周", "cb": _debug_next_week},
		{"text": "触发月末结算", "cb": _debug_month_end},
	])

	_add_section("重置/预设")
	_add_button_grid([
		{"text": "重置并进工作日", "cb": _debug_reset_weekday},
		{"text": "回标题重开", "cb": _debug_back_to_title},
		{"text": "满钱满属性", "cb": _debug_rich_full_stats},
		{"text": "清空债务", "cb": _debug_clear_debt},
		{"text": "解锁全部APP", "cb": _debug_unlock_all_apps},
		{"text": "刷新UI", "cb": _debug_refresh_ui},
	])

	_add_section("春节/结局测试")
	_add_button_grid([
		{"text": "跳到12月第4周", "cb": _debug_jump_december},
		{"text": "春节24岁", "cb": func() -> void: _debug_spring_festival(24)},
		{"text": "春节28岁", "cb": func() -> void: _debug_spring_festival(28)},
		{"text": "春节32岁", "cb": func() -> void: _debug_spring_festival(32)},
		{"text": "触发33岁结局", "cb": _debug_force_ending},
	])


func _build_stats_tab() -> void:
	_add_snapshot()
	_add_section("核心数值")
	_add_number_editor("金钱", "money", -50000, 999999, 100)
	_add_number_editor("待发工资", "pending_salary", 0, 999999, 100)
	_add_number_editor("精力", "energy", 0, 300, 1)
	_add_number_editor("精力上限", "max_energy", 1, 300, 1)
	_add_number_editor("情绪", "sanity", 0, 300, 1)
	_add_number_editor("情绪上限", "max_sanity", 1, 300, 1)
	_add_number_editor("颜值", "charm", 0, 200, 1)
	_add_number_editor("学识", "intellect", 0, 200, 1)
	_add_number_editor("情商", "eq", 0, 200, 1)

	_add_section("债务/资产")
	_add_number_editor("餐饮账单", "monthly_food_cost", 0, 50000, 100)
	_add_number_editor("花呗欠款", "huabei_debt", 0, 300000, 100)
	_add_number_editor("分期本金", "huabei_installment_debt", 0, 300000, 100)
	_add_number_editor("分期剩余月", "huabei_installment_months_left", 0, 60, 1)
	_add_number_editor("分期月供", "huabei_installment_monthly_pay", 0, 50000, 100)
	_add_number_editor("稳健理财", "invest_safe", 0, 999999, 100)
	_add_number_editor("高风险基金", "invest_risk", 0, 999999, 100)

	_add_section("时间/成长")
	_add_number_editor("年龄", "age", 23, 40, 1)
	_add_number_editor("月份", "month", 1, 12, 1)
	_add_number_editor("月内周", "week_in_month", 1, 4, 1)
	_add_number_editor("总周数", "turn_count", 1, 999, 1)
	_add_number_editor("周末行动", "weekend_actions", 0, 10, 1)
	_add_number_editor("最大周末行动", "max_weekend_actions", 1, 10, 1)
	_add_number_editor("职位等级", "job_level", 0, 2, 1)
	_add_number_editor("学历", "degree", 0, 1, 1)
	_add_number_editor("夜校学分", "night_school_progress", 0, 12, 1)
	_add_number_editor("住房等级", "housing_level", 0, 2, 1)

	_add_section("死亡/压力测试")
	_add_button_grid([
		{"text": "低情绪压力态", "cb": _debug_low_sanity_case},
		{"text": "破产压力态", "cb": _debug_bankrupt_case},
		{"text": "恢复健康态", "cb": _debug_recover_case},
	])


func _build_npc_tab() -> void:
	_add_snapshot()
	_add_section("NPC运行时控制")
	_add_button_grid([
		{"text": "解锁全部NPC", "cb": _debug_unlock_all_npcs},
		{"text": "清空邂逅冷却", "cb": _debug_clear_encounter_cooldowns},
		{"text": "重建微信列表", "cb": _debug_rebuild_wechat},
	])

	if GameManager.npc_database.is_empty():
		_add_label("没有加载到 npc_database。", 13, Color(1.0, 0.45, 0.45))
		return

	for npc in GameManager.npc_database:
		var npc_id: String = npc.get("id", "")
		if npc_id == "":
			continue
		var runtime: Dictionary = GameManager.unlocked_npcs.get(npc_id, {})
		var npc_name: String = npc.get("name", npc_id)
		var enc: Dictionary = npc.get("encounter", {})
		var location: String = enc.get("location", "无")
		var req: Dictionary = enc.get("req_stats", {})
		var is_unlocked: bool = GameManager.is_npc_unlocked(npc_id)
		var in_contacts: bool = GameManager.npcs.has(npc_id) and bool(GameManager.npcs[npc_id].get("unlocked", false))
		var cooldown_until: int = _get_encounter_cooldown(npc_id)
		var can_meet: bool = _req_passed(req) and cooldown_until <= GameManager.turn_count and not is_unlocked

		var status_color := Color(0.65, 0.7, 0.78)
		var status := "未遇到"
		if is_unlocked:
			status = "已解锁%s" % (" / 微信联系人" if in_contacts else " / 无联系人")
			status_color = Color(0.45, 1.0, 0.55)
		elif cooldown_until > GameManager.turn_count:
			status = "冷却到第%d周" % cooldown_until
			status_color = Color(1.0, 0.72, 0.3)
		elif can_meet:
			status = "可邂逅"
			status_color = Color(0.45, 0.86, 1.0)

		_add_label("%s  [%s]" % [npc_name, npc_id], 14, Color(1.0, 0.86, 0.35))
		_add_label("地点: %s | 状态: %s | 好感: %d" % [location, status, int(runtime.get("affection", 0))], 12, status_color)
		if req.size() > 0:
			_add_label("条件: %s" % _format_req(req), 11, Color(0.7, 0.74, 0.82))
		_add_button_grid([
			{"text": "解锁", "cb": func() -> void: _debug_unlock_npc(npc_id)},
			{"text": "移除/锁定", "cb": func() -> void: _debug_lock_npc(npc_id)},
			{"text": "好感+10", "cb": func() -> void: _debug_add_affection(npc_id, 10)},
			{"text": "好感-10", "cb": func() -> void: _debug_add_affection(npc_id, -10)},
			{"text": "清冷却", "cb": func() -> void: _debug_clear_npc_cooldown(npc_id)},
		], 5)
		_add_spacer()


func _build_audit_tab() -> void:
	_add_snapshot()
	_add_section("运行状态体检")
	var issues := _collect_runtime_issues()
	if issues.is_empty():
		_add_label("未发现明显运行时异常。", 14, Color(0.45, 1.0, 0.55))
	else:
		for issue in issues:
			_add_label("! " + issue, 13, Color(1.0, 0.55, 0.42))

	_add_section("当前弹窗")
	var mg := _get_main_game()
	var visible_popups := _visible_popups(mg)
	if visible_popups.is_empty():
		_add_label("无可见弹窗。", 12, Color(0.65, 0.72, 0.78))
	else:
		_add_label(", ".join(visible_popups), 12, Color(1.0, 0.82, 0.35))

	_add_section("最近调试日志")
	if _debug_log.is_empty():
		_add_label("暂无调试操作。", 12, Color(0.65, 0.72, 0.78))
	else:
		var start := maxi(_debug_log.size() - 8, 0)
		for i in range(start, _debug_log.size()):
			_add_label(_debug_log[i], 11, Color(0.74, 0.8, 0.88))

	_add_section("资源/数据提示")
	_add_label("F1只改运行时状态，不保存到 JSON/tscn。数值平衡请改 Data/*.json 或系统脚本。", 12, Color(0.68, 0.72, 0.8))
	_add_label("NPC页不会再调用 get_npc_runtime() 读取状态，避免打开调试面板导致NPC被隐式解锁。", 12, Color(0.68, 0.9, 1.0))

	_add_button_grid([
		{"text": "刷新体检", "cb": _refresh_current_tab},
		{"text": "关闭弹窗/清屏", "cb": _debug_close_overlays},
		{"text": "修正越界数值", "cb": _debug_normalize_state},
	])


func _add_snapshot() -> void:
	var mg := _get_main_game()
	var phase_text := _phase_name(mg)
	var total_debt: int = GameManager.huabei_debt + GameManager.huabei_installment_debt
	_add_label(
		"阶段:%s | %d岁 %d月 第%d周 | 总周:%d | 行动:%d/%d" % [
			phase_text,
			GameManager.age,
			GameManager.month,
			GameManager.week_in_month,
			GameManager.turn_count,
			GameManager.weekend_actions,
			GameManager.max_weekend_actions,
		],
		12,
		Color(0.78, 0.84, 0.92)
	)
	_add_label(
		"钱:%d | 待发:%d | 债:%d | 精力:%d/%d | 情绪:%d/%d | 颜/学/情:%d/%d/%d" % [
			GameManager.money,
			GameManager.pending_salary,
			total_debt,
			GameManager.energy,
			GameManager.max_energy,
			GameManager.sanity,
			GameManager.max_sanity,
			GameManager.charm,
			GameManager.intellect,
			GameManager.eq,
		],
		12,
		Color(0.66, 0.75, 0.84)
	)


func _add_number_editor(label_text: String, stat_name: String, min_val: int, max_val: int, step: int) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	_content_vb.add_child(hb)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 118
	lbl.add_theme_font_size_override("font_size", 12)
	hb.add_child(lbl)

	var spin := SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = step
	spin.value = int(GameManager.get(stat_name))
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(spin)

	var raw_name := Label.new()
	raw_name.text = stat_name
	raw_name.custom_minimum_size.x = 150
	raw_name.add_theme_font_size_override("font_size", 11)
	raw_name.add_theme_color_override("font_color", Color(0.48, 0.56, 0.66))
	hb.add_child(raw_name)

	spin.value_changed.connect(func(v: float) -> void:
		_set_game_value(stat_name, int(v))
		_after_state_change(false)
	)


func _add_section(text: String) -> void:
	_add_spacer()
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	_content_vb.add_child(lbl)


func _add_label(text: String, font_size: int, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vb.add_child(lbl)


func _add_spacer() -> void:
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", StyleBoxEmpty.new())
	sep.custom_minimum_size.y = 4
	_content_vb.add_child(sep)


func _add_button_grid(items: Array, columns: int = 2) -> void:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vb.add_child(grid)
	for item in items:
		var btn := Button.new()
		btn.text = item.get("text", "")
		btn.custom_minimum_size = Vector2(0, 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 12)
		var cb: Callable = item.get("cb", Callable())
		if cb.is_valid():
			btn.pressed.connect(func() -> void:
				cb.call()
			)
		grid.add_child(btn)


func _set_game_value(stat_name: String, value: int) -> void:
	match stat_name:
		"max_energy":
			GameManager.max_energy = maxi(value, 1)
			GameManager.energy = clampi(GameManager.energy, 0, GameManager.max_energy)
		"max_sanity":
			GameManager.max_sanity = maxi(value, 1)
			GameManager.sanity = clampi(GameManager.sanity, 0, GameManager.max_sanity)
		"energy":
			GameManager.energy = clampi(value, 0, GameManager.max_energy)
		"sanity":
			GameManager.sanity = clampi(value, 0, GameManager.max_sanity)
		"month":
			GameManager.month = clampi(value, 1, 12)
		"week_in_month":
			GameManager.week_in_month = clampi(value, 1, 4)
		"weekend_actions":
			GameManager.weekend_actions = clampi(value, 0, GameManager.max_weekend_actions)
		"max_weekend_actions":
			GameManager.max_weekend_actions = maxi(value, 1)
			GameManager.weekend_actions = clampi(GameManager.weekend_actions, 0, GameManager.max_weekend_actions)
		"huabei_debt", "huabei_installment_debt", "huabei_installment_months_left", "huabei_installment_monthly_pay", "pending_salary", "invest_safe", "invest_risk", "night_school_progress", "monthly_food_cost":
			GameManager.set(stat_name, maxi(value, 0))
		"job_level":
			GameManager.job_level = clampi(value, 0, 2)
		"degree":
			GameManager.degree = clampi(value, 0, 1)
		"housing_level":
			GameManager.housing_level = clampi(value, 0, 2)
		_:
			GameManager.set(stat_name, value)
	GameManager.credit_debt = GameManager.huabei_debt


func _after_state_change(refresh_panel: bool = true) -> void:
	var mg := _get_main_game()
	if mg and mg.has_method("_refresh_ui"):
		mg._refresh_ui()
	if mg and mg.has_method("_update_weekend_ui"):
		mg._update_weekend_ui()
	if mg and mg.has_method("sync_ui_state"):
		mg.sync_ui_state()
	GameManager.stats_updated.emit()
	if refresh_panel:
		_refresh_current_tab()


func _debug_save_snapshot() -> void:
	_state_snapshot = _capture_snapshot()
	_log_debug("snapshot saved")
	_refresh_current_tab()


func _debug_restore_snapshot() -> void:
	if _state_snapshot.is_empty():
		_log_debug("restore skipped: no snapshot")
		_refresh_current_tab()
		return
	_apply_snapshot(_state_snapshot)
	_log_debug("snapshot restored")
	_after_state_change()


func _capture_snapshot() -> Dictionary:
	var fields := [
		"money", "pending_salary", "energy", "max_energy", "sanity", "max_sanity",
		"charm", "intellect", "eq", "huabei_debt", "credit_debt",
		"huabei_installment_debt", "huabei_installment_months_left",
		"huabei_installment_monthly_pay", "invest_safe", "invest_risk",
		"age", "month", "week_in_month", "turn_count", "weekend_actions",
		"max_weekend_actions", "job_level", "degree", "night_school_progress",
		"housing_level", "monthly_food_cost", "consecutive_poor_food",
		"consecutive_overtime",
	]
	var snap := {}
	for field in fields:
		snap[field] = GameManager.get(field)
	var mg := _get_main_game()
	if mg:
		snap["_phase"] = int(mg.current_phase)
	return snap


func _apply_snapshot(snapshot: Dictionary) -> void:
	for key in snapshot:
		if String(key).begins_with("_"):
			continue
		GameManager.set(str(key), snapshot[key])
	var mg := _get_main_game()
	if mg and snapshot.has("_phase"):
		mg.current_phase = int(snapshot["_phase"])


func _log_debug(text: String) -> void:
	var stamp := "%d/%d-%d" % [GameManager.month, GameManager.week_in_month, GameManager.turn_count]
	_debug_log.append("[%s] %s" % [stamp, text])
	if _debug_log.size() > 30:
		_debug_log.pop_front()


func _debug_close_overlays() -> void:
	var mg := _get_main_game()
	if not mg:
		return
	if mg.has_method("_hide_all_popups"):
		mg._hide_all_popups()
	if mg.has_method("_disable_all") and GameManager.game_finished:
		pass
	if mg.galgame:
		mg.galgame.dismiss_dialog()
		mg.galgame.clear_location_bg()
	if mg.transition_screen:
		mg.transition_screen.visible = false
	if mg.weekday_panel and mg.current_phase != mg.Phase.WEEKDAY:
		mg.weekday_panel.visible = false
	_after_state_change()


func _debug_skip_dialog() -> void:
	var mg := _get_main_game()
	if mg and mg.galgame:
		if mg.galgame.is_visible():
			mg.galgame.skip_all()
		else:
			mg.galgame.dismiss_dialog()
	_after_state_change()


func _debug_enter_weekend() -> void:
	var mg := _get_main_game()
	if mg and mg.has_method("_enter_weekend"):
		_ensure_debug_identity()
		_debug_close_overlays()
		mg._enter_weekend()
	_after_state_change()


func _debug_enter_weekday() -> void:
	var mg := _get_main_game()
	if mg and mg.has_method("_enter_weekday"):
		_ensure_debug_identity()
		_debug_close_overlays()
		mg._enter_weekday()
	_after_state_change()


func _debug_next_week() -> void:
	var mg := _get_main_game()
	if mg and mg.has_method("_proceed_next_week"):
		_debug_close_overlays()
		mg._proceed_next_week()
	_after_state_change()


func _debug_month_end() -> void:
	var mg := _get_main_game()
	_debug_close_overlays()
	GameManager.week_in_month = 4
	GameManager.advance_week()
	if mg and mg.has_method("_refresh_ui"):
		mg._refresh_ui()
	_after_state_change()


func _debug_reset_weekday() -> void:
	GameManager.reset_game()
	_ensure_debug_identity()
	var mg := _get_main_game()
	if mg and mg.has_method("_enter_weekday"):
		mg._enter_weekday()
	_after_state_change()


func _debug_back_to_title() -> void:
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")


func _debug_rich_full_stats() -> void:
	GameManager.money = 99999
	GameManager.max_energy = 150
	GameManager.energy = 150
	GameManager.max_sanity = 150
	GameManager.sanity = 150
	GameManager.charm = 99
	GameManager.intellect = 99
	GameManager.eq = 99
	GameManager.job_level = 2
	GameManager.degree = 1
	GameManager.night_school_progress = 12
	_after_state_change()


func _debug_clear_debt() -> void:
	GameManager.huabei_debt = 0
	GameManager.credit_debt = 0
	GameManager.huabei_installment_debt = 0
	GameManager.huabei_installment_months_left = 0
	GameManager.huabei_installment_monthly_pay = 0
	_after_state_change()


func _debug_unlock_all_apps() -> void:
	GameManager.turn_count = 999
	for app_id in GameManager._app_unlock_turn:
		GameManager._announced_unlocks[app_id] = true
	_after_state_change()


func _debug_refresh_ui() -> void:
	_after_state_change()


func _debug_jump_december() -> void:
	GameManager.month = 12
	GameManager.week_in_month = 4
	_after_state_change()


func _debug_spring_festival(age: int) -> void:
	var mg := _get_main_game()
	_debug_close_overlays()
	GameManager.age = age
	GameManager.month = 1
	GameManager.week_in_month = 1
	GameManager.spring_festival_boss.emit(age)
	if mg:
		mg.current_phase = mg.Phase.EVENT
	_after_state_change()


func _debug_force_ending() -> void:
	GameManager.age = 33
	GameManager.game_finished = true
	var ending := GameManager.evaluate_ending()
	GameManager.last_ending = ending
	GameManager.game_ended.emit(ending.get("type", "ordinary"))
	_after_state_change()


func _debug_low_sanity_case() -> void:
	GameManager.sanity = 15
	GameManager.energy = mini(GameManager.energy, 40)
	GameManager.money = mini(GameManager.money, 1500)
	_after_state_change()


func _debug_bankrupt_case() -> void:
	GameManager.money = -3000
	GameManager.huabei_debt = 60000
	GameManager.credit_debt = GameManager.huabei_debt
	GameManager.sanity = 25
	_after_state_change()


func _debug_recover_case() -> void:
	GameManager.energy = GameManager.max_energy
	GameManager.sanity = GameManager.max_sanity
	GameManager.consecutive_overtime = 0
	GameManager.consecutive_poor_food = 0
	_after_state_change()


func _debug_unlock_all_npcs() -> void:
	for npc in GameManager.npc_database:
		var npc_id: String = npc.get("id", "")
		if npc_id != "":
			GameManager.unlock_npc(npc_id)
	_after_state_change()


func _debug_clear_encounter_cooldowns() -> void:
	var mg := _get_main_game()
	if mg and mg.app:
		mg.app._encounter_cooldowns.clear()
	GameManager.encounter_failed_ids.clear()
	_after_state_change()


func _debug_rebuild_wechat() -> void:
	var mg := _get_main_game()
	if mg and mg.wechat:
		mg.wechat._build_chat_items()
	_after_state_change()


func _debug_unlock_npc(npc_id: String) -> void:
	GameManager.unlock_npc(npc_id)
	_after_state_change()


func _debug_lock_npc(npc_id: String) -> void:
	if GameManager.unlocked_npcs.has(npc_id):
		GameManager.unlocked_npcs.erase(npc_id)
	if GameManager.npcs.has(npc_id):
		if ["family_group", "wang_teacher", "xiao_ya"].has(npc_id):
			GameManager.npcs[npc_id]["unlocked"] = false
		else:
			GameManager.npcs.erase(npc_id)
	_debug_rebuild_wechat()
	_after_state_change()


func _debug_add_affection(npc_id: String, delta: int) -> void:
	if not GameManager.unlocked_npcs.has(npc_id):
		GameManager.unlock_npc(npc_id)
	var runtime: Dictionary = GameManager.get_npc_runtime(npc_id)
	runtime["affection"] = clampi(int(runtime.get("affection", 0)) + delta, 0, 999)
	if GameManager.npcs.has(npc_id):
		GameManager.npcs[npc_id]["affection"] = clampi(int(GameManager.npcs[npc_id].get("affection", 0)) + delta, 0, 999)
	_after_state_change()


func _debug_clear_npc_cooldown(npc_id: String) -> void:
	var mg := _get_main_game()
	if mg and mg.app and mg.app._encounter_cooldowns.has(npc_id):
		mg.app._encounter_cooldowns.erase(npc_id)
	_after_state_change()


func _debug_normalize_state() -> void:
	GameManager.month = clampi(GameManager.month, 1, 12)
	GameManager.week_in_month = clampi(GameManager.week_in_month, 1, 4)
	GameManager.max_energy = maxi(GameManager.max_energy, 1)
	GameManager.max_sanity = maxi(GameManager.max_sanity, 1)
	GameManager.energy = clampi(GameManager.energy, 0, GameManager.max_energy)
	GameManager.sanity = clampi(GameManager.sanity, 0, GameManager.max_sanity)
	GameManager.weekend_actions = clampi(GameManager.weekend_actions, 0, GameManager.max_weekend_actions)
	GameManager.huabei_debt = maxi(GameManager.huabei_debt, 0)
	GameManager.huabei_installment_debt = maxi(GameManager.huabei_installment_debt, 0)
	GameManager.huabei_installment_months_left = maxi(GameManager.huabei_installment_months_left, 0)
	GameManager.huabei_installment_monthly_pay = maxi(GameManager.huabei_installment_monthly_pay, 0)
	GameManager.credit_debt = GameManager.huabei_debt
	_after_state_change()


func _ensure_debug_identity() -> void:
	if GameManager.player_name.strip_edges() == "":
		GameManager.player_name = "测试"
	if GameManager.player_zodiac.strip_edges() == "":
		GameManager.player_zodiac = "测试"


func _collect_runtime_issues() -> Array:
	var issues: Array = []
	if GameManager.player_name.strip_edges() == "":
		issues.append("player_name 为空。直接运行 MainGame 时会出现角色信息空白。")
	if GameManager.month < 1 or GameManager.month > 12:
		issues.append("month 越界：%d。" % GameManager.month)
	if GameManager.week_in_month < 1 or GameManager.week_in_month > 4:
		issues.append("week_in_month 越界：%d。" % GameManager.week_in_month)
	if GameManager.energy > GameManager.max_energy:
		issues.append("energy 高于 max_energy：%d/%d。" % [GameManager.energy, GameManager.max_energy])
	if GameManager.sanity > GameManager.max_sanity:
		issues.append("sanity 高于 max_sanity：%d/%d。" % [GameManager.sanity, GameManager.max_sanity])
	if GameManager.weekend_actions < 0:
		issues.append("weekend_actions 小于0。")
	if GameManager.huabei_debt < 0 or GameManager.huabei_installment_debt < 0:
		issues.append("花呗债务出现负数。")
	if GameManager.game_finished and GameManager.awaiting_month_settle:
		issues.append("game_finished 与 awaiting_month_settle 同时为 true。")
	var mg := _get_main_game()
	if mg and mg.payment_popup and mg.payment_popup.visible and GameManager.weekend_actions <= 0:
		issues.append("支付弹窗打开时周末行动已为0，检查是否存在先扣行动再支付的分支。")
	return issues


func _visible_popups(mg: Node) -> Array:
	var result: Array = []
	if not mg:
		return result
	var names := [
		"location_menu", "wechat_menu", "alipay_popup", "payment_popup",
		"diary_popup", "job_menu", "baotao_menu", "tuanmei_menu",
		"house_menu", "dating_popup", "zodiac_popup", "month_end_popup",
		"weekday_panel", "transition_screen", "late_night_popup",
	]
	for prop in names:
		var node = mg.get(prop) if prop in mg else null
		if node and node is CanvasItem and node.visible:
			result.append(prop)
	return result


func _req_passed(req: Dictionary) -> bool:
	for stat_name in req:
		var needed := int(req[stat_name])
		var current := int(GameManager.get(stat_name)) if stat_name != "money" else GameManager.money
		if current < needed:
			return false
	return true


func _format_req(req: Dictionary) -> String:
	var parts: Array = []
	for stat_name in req:
		var needed := int(req[stat_name])
		var current := int(GameManager.get(stat_name)) if stat_name != "money" else GameManager.money
		var mark := "OK" if current >= needed else "NO"
		parts.append("%s %d/%d %s" % [stat_name, current, needed, mark])
	return " | ".join(parts)


func _phase_name(mg: Node) -> String:
	if not mg or not ("current_phase" in mg):
		return "未知"
	var idx := int(mg.current_phase)
	var names := ["工作日", "周末", "事件", "月末", "过渡", "结局", "GameOver"]
	if idx >= 0 and idx < names.size():
		return names[idx]
	return str(idx)


func _get_encounter_cooldown(npc_id: String) -> int:
	var mg := _get_main_game()
	if mg and mg.app:
		return int(mg.app._encounter_cooldowns.get(npc_id, 0))
	return 0


func _refresh_current_tab() -> void:
	_switch_tab(_tab_idx)
