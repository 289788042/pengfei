## GalgameSystem.gd - 分页对话、飘字、消息提示系统
## 从 MainGame.gd 提取，负责所有对话框和飘字动画
extends RefCounted

var _main: Node  ## MainGame 引用

## 飘字 / 消息 相关的 @onready 引用
var dialog_box: Panel
var dialog_text: RichTextLabel

## 对话框淡出 tween
var dialog_tween: Tween

## Galgame 分页对话状态
var _gal_pages: Array = []
var _gal_page_idx: int = 0
var _gal_char_idx: int = 0
var _gal_typing: bool = false
var _gal_full_text: String = ""
var _gal_tween: Tween = null
var _gal_on_complete: Callable = Callable()
var _gal_encounter_data: Dictionary = {}
var _gal_npc_id: String = ""
var _gal_choice_container: VBoxContainer = null

## 箭头指示器
var _arrow_label: Label = null
var _arrow_tween: Tween = null


func init(main: Node) -> void:
	_main = main
	dialog_box = main.dialog_box
	dialog_text = main.dialog_text


# ==================== 飘字系统 ====================

func show_floating_text(text: String, color: Color, start_pos: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 22)
	if main_node().wechat.is_visible() or main_node().alipay_popup.visible:
		label.z_index = 200
		label.position = Vector2(1570, 30.0)
		main_node().add_child(label)
	else:
		label.z_index = 100
		label.position = start_pos
		main_node().add_child(label)

	var tween := main_node().create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(label.queue_free)


func float_stat(text: String, amount: int, pos: Vector2) -> void:
	var color := Color.GREEN if amount >= 0 else Color.RED
	show_floating_text(text, color, pos)


# ==================== 消息提示 ====================

func show_message(text: String, galgame: bool = false) -> void:
	if dialog_tween and dialog_tween.is_running():
		dialog_tween.kill()
	dialog_text.text = text
	dialog_box.visible = true
	dialog_box.modulate.a = 1.0
	if not galgame:
		dialog_tween = main_node().create_tween()
		dialog_tween.tween_interval(3.0)
		dialog_tween.tween_property(dialog_box, "modulate:a", 0.0, 0.5)
		dialog_tween.tween_callback(func(): dialog_box.visible = false)


## 醒目红色提示（用于春节等重大事件）
func show_urgent_message(text: String) -> void:
	if dialog_tween and dialog_tween.is_running():
		dialog_tween.kill()
	dialog_text.text = "[color=red]" + text + "[/color]"
	dialog_box.visible = true
	dialog_box.modulate.a = 1.0
	dialog_tween = main_node().create_tween()
	dialog_tween.tween_interval(4.0)
	dialog_tween.tween_property(dialog_box, "modulate:a", 0.0, 0.5)
	dialog_tween.tween_callback(func(): dialog_box.visible = false)


## 点击对话框立即关闭
func dismiss_dialog() -> void:
	if dialog_tween and dialog_tween.is_running():
		dialog_tween.kill()
	dialog_box.modulate.a = 0.0
	dialog_box.visible = false


# ==================== Galgame 分页对话系统 ====================

## 启动 Galgame 分页对话（pages: 每页一个字符串）
func show_galgame_dialog(pages: Array, on_complete: Callable = Callable()) -> void:
	if _gal_tween and _gal_tween.is_valid():
		_gal_tween.kill()
	_gal_pages = pages
	_gal_page_idx = 0
	_gal_on_complete = on_complete
	dialog_box.visible = true
	dialog_box.modulate.a = 1.0
	if is_instance_valid(_gal_choice_container):
		_gal_choice_container.visible = false
	dialog_text.visible = true
	_gal_start_page()


## 开始打字当前页
func _gal_start_page() -> void:
	_gal_full_text = _gal_pages[_gal_page_idx]
	_gal_char_idx = 0
	_gal_typing = true
	dialog_text.text = ""
	_apply_page_color(_gal_full_text)
	_stop_arrow_anim()
	_gal_type_char()


## 打字机核心：逐字输出
func _gal_type_char() -> void:
	if _gal_char_idx >= _gal_full_text.length():
		_gal_typing = false
		dialog_text.text = _gal_full_text
		_start_arrow_anim()
		return
	_gal_char_idx += 1
	dialog_text.text = _gal_full_text.substr(0, _gal_char_idx)
	_gal_tween = main_node().create_tween()
	_gal_tween.tween_interval(0.03)
	_gal_tween.tween_callback(_gal_type_char)


## 点击处理：跳过打字 or 翻页
func gal_on_click() -> void:
	if _gal_typing:
		if _gal_tween and _gal_tween.is_valid():
			_gal_tween.kill()
		_gal_typing = false
		dialog_text.text = _gal_full_text
		_start_arrow_anim()
	else:
		_gal_page_idx += 1
		if _gal_page_idx < _gal_pages.size():
			_gal_start_page()
		else:
			_gal_end()


## 根据内容设置对话框颜色：旁白白色，对话黄色
func _apply_page_color(raw: String) -> void:
	if raw.begins_with('陌生男子：') or raw.begins_with('我：'):
		dialog_text.add_theme_color_override('default_color', Color(1.0, 0.9, 0.3, 1.0))
	elif raw.begins_with("'"):
		dialog_text.add_theme_color_override('default_color', Color(1.0, 0.9, 0.3, 1.0))
	else:
		dialog_text.add_theme_color_override('default_color', Color(0.94, 0.94, 0.94, 1.0))


## 箭头指示器动画：上下轻微浮动
func _start_arrow_anim() -> void:
	if not is_instance_valid(_arrow_label):
		_arrow_label = Label.new()
		_arrow_label.name = 'ArrowIndicator'
		_arrow_label.text = '▼'
		_arrow_label.add_theme_font_size_override('font_size', 22)
		_arrow_label.add_theme_color_override('font_color', Color(1, 1, 1, 0.7))
		dialog_box.add_child(_arrow_label)
		_arrow_label.position = Vector2(dialog_box.size.x - 50, dialog_box.size.y - 35)
	_arrow_label.visible = true
	_arrow_label.modulate.a = 1.0
	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()
	var base_y: float = _arrow_label.position.y
	_arrow_tween = main_node().create_tween().set_loops()
	_arrow_tween.tween_property(_arrow_label, 'position:y', base_y - 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_arrow_tween.tween_property(_arrow_label, 'position:y', base_y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_arrow_anim() -> void:
	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()
		_arrow_tween = null
	if is_instance_valid(_arrow_label):
		_arrow_label.visible = false


## 结束 Galgame 对话
func _gal_end() -> void:
	if _gal_tween and _gal_tween.is_valid():
		_gal_tween.kill()
	_gal_pages.clear()
	_gal_typing = false
	_stop_arrow_anim()
	var cb: Callable = _gal_on_complete
	_gal_on_complete = Callable()
	var has_encounter: bool = _gal_encounter_data.size() > 0
	_gal_tween = main_node().create_tween()
	_gal_tween.tween_property(dialog_box, "modulate:a", 0.0, 0.4)
	_gal_tween.tween_callback(func() -> void:
		dialog_box.visible = false
		if cb.is_valid():
			cb.call()
		elif has_encounter:
			_gal_encounter_data = {}
			show_message("在图书馆度过了一个充实的下午。\n[color=90EE90]学识+3 情绪+5[/color]", true)
	)


# ==================== 邂逅系统 ====================

## 邂逅第二阶段：NPC 请求加微信
func start_wechat_request_phase() -> void:
	var wc_data: Dictionary = _gal_encounter_data.get("wechat_request", {})
	if wc_data.size() == 0:
		dialog_box.modulate.a = 0.0
		dialog_box.visible = false
		return
	var pages: Array = []
	for line in wc_data.get("his_lines", []):
		pages.append("陌生男子：" + line)
	show_galgame_dialog(pages, _show_wechat_choices_phase)


## 邂逅第三阶段：显示玩家选择按钮
func _show_wechat_choices_phase() -> void:
	var wc_data: Dictionary = _gal_encounter_data.get("wechat_request", {})
	var options: Array = wc_data.get("player_options", [])
	if options.size() == 0:
		dialog_box.modulate.a = 0.0
		dialog_box.visible = false
		return
	dialog_box.visible = true
	dialog_box.modulate.a = 1.0
	dialog_text.visible = false
	if is_instance_valid(_gal_choice_container):
		_gal_choice_container.queue_free()
	_gal_choice_container = VBoxContainer.new()
	_gal_choice_container.name = "GalChoiceContainer"
	_gal_choice_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_gal_choice_container.offset_left = 20
	_gal_choice_container.offset_top = 12
	_gal_choice_container.offset_right = -16
	_gal_choice_container.offset_bottom = -12
	_gal_choice_container.add_theme_constant_override("separation", 8)
	dialog_box.add_child(_gal_choice_container)
	for option in options:
		var btn := Button.new()
		btn.text = option.get("text", "...")
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
		else:
			btn.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95, 1))
		var captured_option: Dictionary = option
		btn.pressed.connect(func() -> void: _on_encounter_choice(captured_option))
		_gal_choice_container.add_child(btn)


## 邂逅选择回调
func _on_encounter_choice(option: Dictionary) -> void:
	var cost: Dictionary = option.get("cost", {})
	var cost_energy: int = int(cost.get("energy", 0))
	var cost_money: int = int(cost.get("money", 0))
	if cost_energy > 0:
		GameManager.modify_stat("energy", -cost_energy)
	if cost_money > 0:
		GameManager.modify_stat("money", -cost_money)
	var stat_changes: Dictionary = option.get("stat_changes", {})
	for stat_name in stat_changes:
		var val: int = int(stat_changes[stat_name])
		if stat_name == "affection" and _gal_npc_id != "":
			GameManager.get_npc_runtime(_gal_npc_id)["affection"] += val
		else:
			GameManager.modify_stat(stat_name, val)
	var flag: String = option.get("flag", "")
	if flag != "" and _gal_npc_id != "":
		var runtime: Dictionary = GameManager.get_npc_runtime(_gal_npc_id)
		if not runtime["flags"].has(flag):
			runtime["flags"].append(flag)
	if is_instance_valid(_gal_choice_container):
		_gal_choice_container.queue_free()
		_gal_choice_container = null
	dialog_text.visible = true
	var pages: Array = []
	pages.append("我：" + option.get("text", ""))
	for line in option.get("reply_lines", []):
		if line.begins_with("'"):
			pages.append("陌生男子：" + line)
		else:
			pages.append(line)
	if option.get("note", "") != "":
		pages.append(option["note"])
	show_galgame_dialog(pages)


# ==================== 公共访问 ====================

func is_visible() -> bool:
	return dialog_box.visible and dialog_box.modulate.a > 0.5


func main_node() -> Node:
	return _main
