## SpringFestivalSystem.gd - 春节BOSS战系统
## 负责：加载春节数据、编排回合制审问、统计结果
## 使用 GalgameSystem 的对话框和选择按钮机制
extends RefCounted

var _main: Node
var _galgame: RefCounted
var _data: Dictionary = {}
var _current_age: int = 0
var _total_sanity_cost: int = 0
var _money_cost: int = 0
var _round_idx: int = 0
var _total_rounds: int = 0
var _used_questions: Array = []
var _on_complete: Callable = Callable()


func init(main: Node) -> void:
	_main = main
	_galgame = main.galgame
	_load_data()


func _load_data() -> void:
	var f := FileAccess.open("res://Data/spring_festival_data.json", FileAccess.READ)
	if not f:
		push_warning("SpringFestivalSystem: 无法加载数据")
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		push_warning("SpringFestivalSystem: JSON解析失败")
		f.close()
		return
	_data = json.data
	f.close()


## 开始春节BOSS战
func start_boss_fight(age: int, on_complete: Callable) -> void:
	_current_age = age
	_total_sanity_cost = 0
	_round_idx = 0
	_used_questions.clear()
	_on_complete = on_complete

	# 28岁特殊年：妈来深圳
	if age == 28:
		_start_special_year_28()
		return

	var year_config: Dictionary = _data.get("yearly", {}).get(str(age), {})
	if year_config.is_empty():
		_money_cost = 5000
		_on_complete.call(_total_sanity_cost, _money_cost)
		return

	_total_rounds = int(year_config.get("rounds", 3))
	_money_cost = int(year_config.get("cost", 5000))

	# 显示开场白
	var intro: Array = year_config.get("intro", [])
	if intro.size() > 0:
		_galgame.show_galgame_dialog(intro, _start_next_round)
	else:
		_start_next_round()


## 28岁特殊年
func _start_special_year_28() -> void:
	var special: Dictionary = _data.get("special_28", {})
	_money_cost = int(special.get("cost", 2000))
	_total_rounds = int(special.get("rounds", 2))
	var intro: Array = special.get("intro", [
		"今年春节，你妈说来深圳看你。",
		"你慌了。城中村的六平米隔断间，怎么让妈住？",
		"妈到了。她站在门口看了很久，什么也没说。"
	])
	_galgame.show_galgame_dialog(intro, _start_next_round)


## 开始下一个回合
func _start_next_round() -> void:
	if _round_idx >= _total_rounds:
		_show_summary()
		return

	# 选择题目池
	var pool_key: String = "questions_mom_28" if _current_age == 28 else "questions"
	var questions: Array = _data.get(pool_key, [])
	var available: Array = []
	for q in questions:
		if not _used_questions.has(q.get("id", "")):
			available.append(q)

	if available.is_empty():
		_used_questions.clear()
		available = questions

	if available.is_empty():
		_round_idx += 1
		_start_next_round()
		return

	var question: Dictionary = available[randi() % available.size()]
	_used_questions.append(question.get("id", ""))

	var pages: Array = question.get("pages", [])
	if pages.size() > 0:
		_galgame.show_galgame_dialog(pages, func() -> void: _show_round_choices(question))
	else:
		_show_round_choices(question)


## 显示回合选择按钮
func _show_round_choices(question: Dictionary) -> void:
	var options: Array = question.get("options", [])
	if options.is_empty():
		_round_idx += 1
		_start_next_round()
		return

	# 复用 galgame 对话框显示选择按钮
	var gal: RefCounted = _galgame
	gal.left_dialog_box.visible = true
	gal.left_dialog_box.modulate.a = 1.0
	gal.left_dialog_text.visible = false

	if is_instance_valid(gal._gal_choice_container):
		gal._gal_choice_container.queue_free()

	gal._gal_choice_container = VBoxContainer.new()
	gal._gal_choice_container.name = "SFChoiceContainer"
	gal._gal_choice_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	gal._gal_choice_container.offset_left = 20
	gal._gal_choice_container.offset_top = 12
	gal._gal_choice_container.offset_right = -16
	gal._gal_choice_container.offset_bottom = -12
	gal._gal_choice_container.add_theme_constant_override("separation", 8)
	gal.left_dialog_box.add_child(gal._gal_choice_container)

	# 回合指示器
	var round_label := Label.new()
	round_label.text = "【第 %d / %d 回合】%s" % [_round_idx + 1, _total_rounds, question.get("speaker", "")]
	round_label.add_theme_font_size_override("font_size", 14)
	round_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	gal._gal_choice_container.add_child(round_label)

	# 创建选项按钮
	for option in options:
		var btn := Button.new()
		btn.text = option.get("text", "...")
		btn.add_theme_font_size_override("font_size", 18)
		btn.custom_minimum_size.y = 44

		# 样式：正常态
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.2, 0.85)
		style.set_corner_radius_all(10.0)
		style.set_content_margin_all(12)
		style.border_color = Color(0.5, 0.5, 0.6, 0.6)
		style.set_border_width_all(1)
		btn.add_theme_stylebox_override("normal", style)

		# 样式：悬停态
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.25, 0.28, 0.38, 0.92)
		hover_style.set_corner_radius_all(10.0)
		hover_style.set_content_margin_all(12)
		hover_style.border_color = Color(0.7, 0.75, 0.9, 0.8)
		hover_style.set_border_width_all(1)
		btn.add_theme_stylebox_override("hover", hover_style)

		# 属性门控
		var req_stat: String = option.get("req_stat", "")
		var req_val: int = int(option.get("req_val", 0))
		if req_stat != "" and GameManager.get(req_stat) < req_val:
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 0.7))
			var dis_style := StyleBoxFlat.new()
			dis_style.bg_color = Color(0.1, 0.1, 0.12, 0.5)
			dis_style.set_corner_radius_all(10.0)
			dis_style.set_content_margin_all(12)
			btn.add_theme_stylebox_override("disabled", dis_style)
			var stat_cn: String = GameManager.stat_names.get(req_stat, req_stat)
			btn.text += "  [需要 %s >= %d]" % [stat_cn, req_val]
		else:
			btn.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95, 1))

		var captured_option: Dictionary = option
		btn.pressed.connect(func() -> void: _on_round_choice(captured_option))
		gal._gal_choice_container.add_child(btn)


## 选择结果处理
func _on_round_choice(option: Dictionary) -> void:
	var gal: RefCounted = _galgame

	# 清理选择按钮
	if is_instance_valid(gal._gal_choice_container):
		gal._gal_choice_container.queue_free()
		gal._gal_choice_container = null
	gal.left_dialog_text.visible = true

	# 统计情绪变化
	var sanity_change: int = int(option.get("sanity", 0))
	_total_sanity_cost += sanity_change

	# 额外属性变化
	var extra_stats: Dictionary = option.get("stat_changes", {})
	for stat_name in extra_stats:
		GameManager.modify_stat(stat_name, int(extra_stats[stat_name]))

	# 金钱变化（如红包）
	var money_change: int = int(option.get("money", 0))
	if money_change != 0:
		GameManager.modify_stat("money", money_change)

	# 显示结果
	var result_pages: Array = []
	var outcome: String = option.get("outcome", "")
	if outcome != "":
		result_pages.append(outcome)

	if result_pages.size() > 0:
		_galgame.show_galgame_dialog(result_pages, func() -> void:
			_round_idx += 1
			_start_next_round()
		)
	else:
		_round_idx += 1
		_start_next_round()


## 显示春节总结
func _show_summary() -> void:
	var savings_bonus: String = ""
	if GameManager.money - _money_cost >= 50000:
		savings_bonus = "\n存款丰厚，在亲戚面前倍儿有面子！(情绪 +30)"
	elif GameManager.money - _money_cost < 10000:
		savings_bonus = "\n兜里没什么钱，心里也没底气。(情绪 -20)"

	var summary_pages: Array = []
	summary_pages.append("── 春节总结 ──")
	summary_pages.append("人情往来与车马费：-%d 元" % _money_cost)

	if _total_sanity_cost < 0:
		summary_pages.append("情绪损耗：%d（亲戚的关怀真是沉重啊）" % _total_sanity_cost)
	elif _total_sanity_cost > 0:
		summary_pages.append("情绪变化：+%d（今年居然应付得不错！）" % _total_sanity_cost)
	else:
		summary_pages.append("情绪变化：不功不过。")

	if savings_bonus != "":
		summary_pages.append(savings_bonus)

	summary_pages.append("新的一年开始了。加油吧。")

	_galgame.show_galgame_dialog(summary_pages, func() -> void:
		_on_complete.call(_total_sanity_cost, _money_cost)
	)
