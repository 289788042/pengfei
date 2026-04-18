## DebugPanel.gd - 开发调试面板
## 按 F1 切换显示/隐藏
## 三个标签页：场景切换 / 女主属性 / 男主判定
extends Control

var _tab_idx: int = 0
var _sliders: Dictionary = {}

# UI references
var _panel_bg: PanelContainer
var _tab_bar: TabBar
var _content: ScrollContainer
var _content_vb: VBoxContainer
var _visible: bool = false

func _ready() -> void:
	## 整体容器
	_panel_bg = PanelContainer.new()
	_panel_bg.name = "DebugBG"
	_panel_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel_bg.offset_left = 10
	_panel_bg.offset_top = 10
	_panel_bg.offset_right = 430
	_panel_bg.offset_bottom = 750
	_panel_bg.modulate.a = 0.85
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.1, 0.92)
	sb.border_color = Color(0.4, 0.4, 0.5, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	_panel_bg.add_theme_stylebox_override("panel", sb)
	add_child(_panel_bg)

	var main_vb = VBoxContainer.new()
	main_vb.name = "MainVBox"
	main_vb.add_theme_constant_override("separation", 4)
	_panel_bg.add_child(main_vb)

	## 标题行
	var title_hb = HBoxContainer.new()
	var title_label = Label.new()
	title_label.text = "🔧 开发调试面板 (F1切换)"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	title_hb.add_child(title_label)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hb.add_child(spacer)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(func(): _toggle_visible())
	title_hb.add_child(close_btn)
	main_vb.add_child(title_hb)

	## 标签栏
	_tab_bar = TabBar.new()
	_tab_bar.tab_count = 3
	_tab_bar.set_tab_title(0, "场景")
	_tab_bar.set_tab_title(1, "女主属性")
	_tab_bar.set_tab_title(2, "男主判定")
	_tab_bar.tab_clicked.connect(func(idx: int): _switch_tab(idx))
	main_vb.add_child(_tab_bar)

	## 内容区（带滚动）
	_content = ScrollContainer.new()
	_content.name = "ScrollContent"
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vb.add_child(_content)

	_content_vb = VBoxContainer.new()
	_content_vb.name = "ContentVBox"
	_content_vb.add_theme_constant_override("separation", 4)
	_content_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(_content_vb)

	_switch_tab(0)
	visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_F1 and event.pressed:
		_toggle_visible()

func _toggle_visible() -> void:
	_visible = not _visible
	visible = _visible
	_panel_bg.visible = _visible

func _switch_tab(idx: int) -> void:
	_tab_idx = idx
	for child in _content_vb.get_children():
		child.queue_free()
	_sliders.clear()
	match idx:
		0: _build_scene_tab()
		1: _build_stat_tab()
		2: _build_npc_tab()

## ==================== 获取 MainGame 节点 ====================
func _get_main_game() -> Node:
	return get_parent()

## ==================== 标签1：场景切换 ====================
func _build_scene_tab() -> void:
	_add_label("快捷跳转场景：", 15, Color(0.7, 0.9, 1.0))
	_add_spacer()

	_add_scene_btn("直接进入周末（自由活动）", func():
		var mg = _get_main_game()
		if mg and mg.has_method("_enter_weekend"):
			mg._hide_all_popups()
			if mg.has_node("WeekdayPanel"):
				mg.get_node("WeekdayPanel").visible = false
			mg._enter_weekend()
			GameManager.stats_updated.emit()
			_add_status("已切换到周末模式")
	)

	_add_scene_btn("回到工作日（选饮食/工作）", func():
		var mg = _get_main_game()
		if mg and mg.has_method("_enter_weekday"):
			mg._enter_weekday()
			_add_status("已切换到工作日模式")
	)

	_add_scene_btn("跳过本周 → 下一周", func():
		var mg = _get_main_game()
		if mg and mg.has_method("_proceed_next_week"):
			mg._proceed_next_week()
			_add_status("已推进到下一周 (第%d周)" % GameManager.week_in_month)
	)

	_add_spacer()
	_add_label("调试操作：", 15, Color(0.7, 0.9, 1.0))

	_add_scene_btn("重置所有数据并重新开始", func():
		GameManager.charm = 10
		GameManager.intellect = 10
		GameManager.eq = 10
		GameManager.money = 3000
		GameManager.energy = 100
		GameManager.sanity = 100
		GameManager.max_energy = 100
		GameManager.unlocked_npcs.clear()
		GameManager.encounter_failed_ids.clear()
		GameManager.week_in_month = 1
		GameManager.turn_count = 1
		GameManager.month = 1
		GameManager.age = 23
		GameManager.game_finished = false
		GameManager.load_npc_data()
		GameManager.stats_updated.emit()
		var mg = _get_main_game()
		if mg and mg.has_method("_enter_weekday"):
			mg._enter_weekday()
		_add_status("数据已重置")
	)

	_add_scene_btn("解锁全部微信NPC", func():
		for npc_id in ["family_group", "lin_fan", "chen_yu", "gu_lin", "zhang_minghao", "wang_teacher", "xiao_ya"]:
			if GameManager.npcs.has(npc_id):
				GameManager.npcs[npc_id]["unlocked"] = true
		for npc in GameManager.npc_database:
			if not GameManager.is_npc_unlocked(npc.get("id", "")):
				GameManager.unlock_npc(npc.get("id", ""))
		GameManager.stats_updated.emit()
		_refresh_current_tab()
	)

	_add_scene_btn("给自己加满钱和属性", func():
		GameManager.money = 99999
		GameManager.charm = 99
		GameManager.intellect = 99
		GameManager.eq = 99
		GameManager.energy = 100
		GameManager.sanity = 100
		GameManager.stats_updated.emit()
		_refresh_current_tab()
	)

	_add_scene_btn("清除邂逅失败记录", func():
		GameManager.encounter_failed_ids.clear()
		_add_status("已清除 %d 条失败记录" % GameManager.encounter_failed_ids.size())
		_refresh_current_tab()
	)

## ==================== 标签2：女主属性滑块 ====================
func _build_stat_tab() -> void:
	_add_label("女主角属性调节（拖动即时生效）：", 15, Color(0.7, 0.9, 1.0))
	_add_spacer()

	_add_stat_slider("颜值 (charm)", "charm", 0, 100)
	_add_stat_slider("学识 (intellect)", "intellect", 0, 100)
	_add_stat_slider("情商 (eq)", "eq", 0, 100)
	_add_stat_slider("金钱 (money)", "money", 0, 99999)
	_add_stat_slider("精力 (energy)", "energy", 0, 200)
	_add_stat_slider("情绪 (sanity)", "sanity", -100, 100)
	_add_stat_slider("精力上限 (max_energy)", "max_energy", 50, 300)

	_add_spacer()
	_add_label("当前周: 第%d周 | 月: %d | 年龄: %d" % [GameManager.week_in_month, GameManager.month, GameManager.age], 13, Color(0.8, 0.8, 0.8))

func _add_stat_slider(label_text: String, stat_name: String, min_val: int, max_val: int) -> void:
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 150
	lbl.add_theme_font_size_override("font_size", 13)
	hb.add_child(lbl)

	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = 1
	slider.value = GameManager.get(stat_name)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 120
	hb.add_child(slider)

	var val_label = Label.new()
	val_label.text = str(int(slider.value))
	val_label.custom_minimum_size.x = 50
	val_label.add_theme_font_size_override("font_size", 13)
	val_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hb.add_child(val_label)

	slider.value_changed.connect(func(v: float):
		val_label.text = str(int(v))
		GameManager.set(stat_name, int(v))
		GameManager.stats_updated.emit()
	)

	_sliders[stat_name] = {"slider": slider, "val_label": val_label}
	_content_vb.add_child(hb)

## ==================== 标签3：男主判定面板 ====================
func _build_npc_tab() -> void:
	_add_label("男主邂逅判定一览：", 15, Color(0.7, 0.9, 1.0))
	_add_spacer()

	## 遍历 npc_database 显示判定信息
	var has_npc: bool = false
	for npc in GameManager.npc_database:
		has_npc = true
		var npc_id: String = npc.get("id", "")
		var npc_name: String = npc.get("name", "")
		var rarity: String = npc.get("rarity", "")
		var enc: Dictionary = npc.get("encounter", {})
		var req: Dictionary = enc.get("req_stats", {})
		var location: String = enc.get("location", "")
		var runtime: Dictionary = GameManager.get_npc_runtime(npc_id)
		var affection: int = runtime.get("affection", 0)
		var is_unlocked: bool = GameManager.is_npc_unlocked(npc_id)
		var failed: bool = npc_id in GameManager.encounter_failed_ids

		## NPC 标题
		var status_text: String = "未遇到"
		if is_unlocked:
			status_text = "已解锁✓"
		elif failed:
			status_text = "已失败(不会再触发)"
		_add_label("[%s] %s — %s" % [rarity, npc_name, status_text], 14, Color(1.0, 0.85, 0.3))
		_add_label("  邂逅地点: %s" % location, 12, Color(0.7, 0.7, 0.7))

		## 邂逅条件（可编辑）
		if req.size() > 0:
			_add_spacer()
			_add_label("  邂逅条件（可修改数值做平衡）：", 12, Color(0.7, 0.9, 1.0))
			for stat_name in req:
				_add_encounter_req_editor(npc, stat_name)

		## 好感度滑块
		_add_spacer()
		_add_npc_affection_slider(npc_id, npc_name, affection)

		## 里程碑一览（可编辑）
		var milestones: Array = npc.get("milestones", [])
		if milestones.size() > 0:
			_add_spacer()
			_add_label("  里程碑（可修改阈值）：", 12, Color(0.7, 0.9, 1.0))
			for i in range(milestones.size()):
				var ms: Dictionary = milestones[i]
				var ms_title: String = ms.get("title", "")
				_add_milestone_editor(npc, i, ms_title, ms)

		_add_spacer()

	if not has_npc:
		_add_label("暂无男主数据（检查npc_data.json）", 13, Color(0.8, 0.5, 0.5))

## 编辑邂逅条件的数值
func _add_encounter_req_editor(npc: Dictionary, stat_name: String) -> void:
	var enc: Dictionary = npc.get("encounter", {})
	var req: Dictionary = enc.get("req_stats", {})
	var cur_req_val: int = int(req.get(stat_name, 0))
	var cur_val: int = GameManager.get(stat_name) if stat_name != "money" else GameManager.money
	var ok: bool = cur_val >= cur_req_val

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)

	var lbl = Label.new()
	lbl.text = "    %s ≥" % stat_name
	lbl.custom_minimum_size.x = 80
	lbl.add_theme_font_size_override("font_size", 12)
	hb.add_child(lbl)

	var spinbox = SpinBox.new()
	spinbox.min_value = 0
	spinbox.max_value = 200
	spinbox.step = 1
	spinbox.value = cur_req_val
	spinbox.custom_minimum_size.x = 60
	spinbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hb.add_child(spinbox)

	var info_lbl = Label.new()
	info_lbl.text = "(当前%d) %s" % [cur_val, "✓" if ok else "✗"]
	info_lbl.add_theme_font_size_override("font_size", 12)
	info_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4) if ok else Color(1.0, 0.4, 0.4))
	hb.add_child(info_lbl)

	spinbox.value_changed.connect(func(v: float):
		req[stat_name] = int(v)
		var new_ok: bool = cur_val >= int(v)
		info_lbl.text = "(当前%d) %s" % [cur_val, "✓" if new_ok else "✗"]
		info_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4) if new_ok else Color(1.0, 0.4, 0.4))
	)

	_content_vb.add_child(hb)

## 编辑里程碑的好感阈值和属性要求值
func _add_milestone_editor(npc: Dictionary, ms_index: int, ms_title: String, ms: Dictionary) -> void:
	var aff_val: int = int(ms.get("trigger_affection", 0))
	var req_stat: String = ms.get("req_stat", "")
	var req_val: int = int(ms.get("req_val", 0))

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 3)

	var title_lbl = Label.new()
	title_lbl.text = "    ·%s" % ms_title
	title_lbl.custom_minimum_size.x = 120
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hb.add_child(title_lbl)

	# 好感阈值编辑
	var aff_lbl = Label.new()
	aff_lbl.text = "好感≥"
	aff_lbl.add_theme_font_size_override("font_size", 11)
	hb.add_child(aff_lbl)

	var aff_spin = SpinBox.new()
	aff_spin.min_value = 0
	aff_spin.max_value = 100
	aff_spin.step = 1
	aff_spin.value = aff_val
	aff_spin.custom_minimum_size.x = 50
	hb.add_child(aff_spin)

	aff_spin.value_changed.connect(func(v: float):
		ms["trigger_affection"] = int(v)
	)

	# 属性要求值编辑
	var req_lbl = Label.new()
	req_lbl.text = " %s≥" % req_stat
	req_lbl.add_theme_font_size_override("font_size", 11)
	hb.add_child(req_lbl)

	var req_spin = SpinBox.new()
	req_spin.min_value = 0
	req_spin.max_value = 200
	req_spin.step = 1
	req_spin.value = req_val
	req_spin.custom_minimum_size.x = 50
	hb.add_child(req_spin)

	req_spin.value_changed.connect(func(v: float):
		ms["req_val"] = int(v)
	)

	_content_vb.add_child(hb)

func _add_npc_affection_slider(npc_id: String, npc_name: String, affection: int) -> void:
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)

	var lbl = Label.new()
	lbl.text = "  %s好感度:" % npc_name
	lbl.custom_minimum_size.x = 110
	lbl.add_theme_font_size_override("font_size", 13)
	hb.add_child(lbl)

	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = affection
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 100
	hb.add_child(slider)

	var val_label = Label.new()
	val_label.text = str(int(slider.value))
	val_label.custom_minimum_size.x = 40
	val_label.add_theme_font_size_override("font_size", 13)
	val_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.8))
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hb.add_child(val_label)

	slider.value_changed.connect(func(v: float):
		val_label.text = str(int(v))
		GameManager.get_npc_runtime(npc_id)["affection"] = int(v)
	)

	_content_vb.add_child(hb)

## ==================== 通用工具 ====================
func _add_label(text: String, font_size: int, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_vb.add_child(lbl)

func _add_spacer() -> void:
	var sep = HSeparator.new()
	sep.add_theme_stylebox_override("separator", StyleBoxEmpty.new())
	sep.custom_minimum_size.y = 4
	_content_vb.add_child(sep)

func _add_scene_btn(text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 13)
	btn.custom_minimum_size.y = 30
	btn.pressed.connect(callback)
	_content_vb.add_child(btn)

func _add_status(msg: String) -> void:
	_add_label("  → %s" % msg, 12, Color(0.4, 1.0, 0.6))

func _refresh_current_tab() -> void:
	_switch_tab(_tab_idx)
