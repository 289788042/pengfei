## GalgameSystem.gd - 分页对话、飘字、消息提示系统
## 从 MainGame.gd 提取，负责所有对话框和飘字动画
extends RefCounted

var _main: Node  ## MainGame 引用

## 飘字 / 消息 相关的 @onready 引用
var dialog_box: Panel
var dialog_text: RichTextLabel
## 左侧 Galgame 对话框
var left_dialog_box: Panel
var left_dialog_text: RichTextLabel
var portrait: TextureRect
var scene_bg: ColorRect

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

## 打字机嘟嘟音效
var _beep_player: AudioStreamPlayer = null
var _beep_pitch_base: float = 1.0


func init(main: Node) -> void:
	_main = main
	# 创建打字机音效播放器
	_beep_player = AudioStreamPlayer.new()
	_beep_player.volume_db = -12.0
	main.add_child(_beep_player)
	_beep_player.stream = _generate_beep()
	dialog_box = main.dialog_box
	dialog_text = main.dialog_text
	left_dialog_box = main.left_dialog_box
	left_dialog_text = main.left_dialog_text
	portrait = main.character_portrait
	scene_bg = main.left_bg


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
	_hide_phone_dim()


# ==================== Galgame 分页对话系统 ====================

## 启动 Galgame 分页对话（pages: 每页一个字符串）
func show_galgame_dialog(pages: Array, on_complete: Callable = Callable()) -> void:
	if _gal_tween and _gal_tween.is_valid():
		_gal_tween.kill()
	_gal_pages = pages
	_gal_page_idx = 0
	_gal_on_complete = on_complete
	left_dialog_box.visible = true
	left_dialog_box.modulate.a = 1.0
	# 暗化手机区域
	var dim: ColorRect = main_node().get("_phone_dim") as ColorRect
	if dim:
		dim.visible = true
		dim.color.a = 0.0
		var t := main_node().create_tween()
		t.tween_property(dim, "color:a", 0.65, 0.3)
	if is_instance_valid(_gal_choice_container):
		_gal_choice_container.visible = false
	left_dialog_text.visible = true
	var _skip_btn: Button = main_node().get_node_or_null("HBoxContainer/RightMargin/RightSystemArea/Btn_NextWeek")
	if _skip_btn:
		_skip_btn.set_deferred("disabled", true)
	_gal_start_page()


## 开始打字当前页
func _gal_start_page() -> void:
	_gal_full_text = _gal_pages[_gal_page_idx]
	_apply_page_color(_gal_full_text)
	_stop_arrow_anim()
	if _gal_full_text.find("[color=") >= 0:
		_gal_typing = false
		left_dialog_text.text = _gal_full_text
		_start_arrow_anim()
	else:
		_gal_char_idx = 0
		_gal_typing = true
		left_dialog_text.text = ""
		_gal_type_char()


## 打字机核心：逐字输出
func _gal_type_char() -> void:
	if _gal_char_idx >= _gal_full_text.length():
		_gal_typing = false
		left_dialog_text.text = _gal_full_text
		_start_arrow_anim()
		return
	_gal_char_idx += 1
	left_dialog_text.text = _gal_full_text.substr(0, _gal_char_idx)
	# 嘟嘟音效（每两个字响一次，跳过空格/标点/换行）
	if _beep_player and _gal_char_idx % 2 == 0:
		var ch: String = _gal_full_text[_gal_char_idx - 1]
		if ch != ' ' and ch != '
' and ch != '，' and ch != '。' and ch != '！' and ch != '？' and ch != '、' and ch != '…' and ch != '—':
			_beep_player.pitch_scale = _beep_pitch_base
			_beep_player.play()
	_gal_tween = main_node().create_tween()
	_gal_tween.tween_interval(0.03)
	_gal_tween.tween_callback(_gal_type_char)


## 点击处理：跳过打字 or 翻页
func gal_on_click() -> void:
	if _gal_typing:
		if _gal_tween and _gal_tween.is_valid():
			_gal_tween.kill()
		_gal_typing = false
		left_dialog_text.text = _gal_full_text
		_start_arrow_anim()
	else:
		_gal_page_idx += 1
		if _gal_page_idx < _gal_pages.size():
			_gal_start_page()
		else:
			_gal_end()


## 跳过所有对话页（测试用，Ctrl键触发）
func skip_all() -> void:
	_gal_end()



func _apply_page_color(raw: String) -> void:
	if raw.begins_with("陌生男子：") or raw.begins_with("我：") or raw.begins_with("沈逸："):
		left_dialog_text.add_theme_color_override("default_color", Color(1.0, 0.9, 0.3, 1.0))
	elif raw.begins_with("'"):
		left_dialog_text.add_theme_color_override("default_color", Color(1.0, 0.9, 0.3, 1.0))
	else:
		left_dialog_text.add_theme_color_override("default_color", Color(0.94, 0.94, 0.94, 1.0))


## 箭头指示器动画：上下轻微浮动
func _start_arrow_anim() -> void:
	if not is_instance_valid(_arrow_label):
		_arrow_label = Label.new()
		_arrow_label.name = 'ArrowIndicator'
		_arrow_label.text = '▼'
		_arrow_label.add_theme_font_size_override('font_size', 22)
		_arrow_label.add_theme_color_override('font_color', Color(1, 1, 1, 0.7))
		left_dialog_box.add_child(_arrow_label)
		_arrow_label.position = Vector2(left_dialog_box.size.x - 50, left_dialog_box.size.y - 35)
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
	var _skip_btn2: Button = main_node().get_node_or_null("HBoxContainer/RightMargin/RightSystemArea/Btn_NextWeek")
	if _skip_btn2:
		_skip_btn2.set_deferred("disabled", false)
	_hide_phone_dim()
	var cb: Callable = _gal_on_complete
	_gal_on_complete = Callable()
	var has_encounter: bool = _gal_encounter_data.size() > 0
	_gal_tween = main_node().create_tween()
	_gal_tween.tween_property(left_dialog_box, "modulate:a", 0.0, 0.4)
	_gal_tween.tween_callback(func() -> void:
		dialog_box.visible = false
		if cb.is_valid():
			cb.call()
		elif has_encounter:
			_gal_encounter_data = {}
			show_message("度过了一段时光。", true)

	)


# ==================== 邂逅系统 ====================

## 邂逅第二阶段：NPC 请求加微信
func start_wechat_request_phase() -> void:
	var wc_data: Dictionary = _gal_encounter_data.get("wechat_request", {})
	if wc_data.size() == 0:
		left_dialog_box.modulate.a = 0.0
		left_dialog_box.visible = false
		return
	var pages: Array = []
	var _npc_name: String = GameManager.get_npc_name(_gal_npc_id) if _gal_npc_id != "" else "陌生男子"
	for line in wc_data.get("his_lines", []):
		pages.append(_npc_name + "：" + line)
	show_galgame_dialog(pages, _show_wechat_choices_phase)


## 邂逅第三阶段：显示玩家选择按钮
func _show_wechat_choices_phase() -> void:
	var wc_data: Dictionary = _gal_encounter_data.get("wechat_request", {})
	var options: Array = wc_data.get("player_options", [])
	if options.size() == 0:
		left_dialog_box.modulate.a = 0.0
		left_dialog_box.visible = false
		return
	left_dialog_box.visible = true
	left_dialog_box.modulate.a = 1.0
	left_dialog_text.visible = false
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
	left_dialog_box.add_child(_gal_choice_container)
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
	## 先判断是否解锁NPC，再处理属性和flag（避免get_npc_runtime误创建条目）
	var should_unlock: bool = option.get("unlock_npc", true) and _gal_npc_id != ""
	if should_unlock:
		if not GameManager.is_npc_unlocked(_gal_npc_id):
			GameManager.unlock_npc(_gal_npc_id)
		## 邂逅加微信后，把初始消息写入NPC聊天记录
		var init_msgs: Array = option.get("wechat_init_messages", [])
		if init_msgs.size() == 0 and _gal_npc_id != "":
			init_msgs = [{"sender": "npc", "text": "刚才太匆忙了，抱歉。你小心点，外面下雨了。"}]
		if GameManager.npcs.has(_gal_npc_id):
			for msg in init_msgs:
				GameManager.npcs[_gal_npc_id]["messages"].append(msg)
			GameManager.add_unread(_gal_npc_id)
	var stat_changes: Dictionary = option.get("stat_changes", {})
	for stat_name in stat_changes:
		var val: int = int(stat_changes[stat_name])
		if stat_name == "affection" and _gal_npc_id != "" and should_unlock:
			GameManager.get_npc_runtime(_gal_npc_id)["affection"] += val
		else:
			GameManager.modify_stat(stat_name, val)
	var flag: String = option.get("flag", "")
	if flag != "" and _gal_npc_id != "" and should_unlock:
		var runtime: Dictionary = GameManager.get_npc_runtime(_gal_npc_id)
		if not runtime["flags"].has(flag):
			runtime["flags"].append(flag)
	if is_instance_valid(_gal_choice_container):
		_gal_choice_container.queue_free()
		_gal_choice_container = null
	left_dialog_text.visible = true
	var pages: Array = []
	pages.append("我：" + option.get("text", ""))
	for line in option.get("reply_lines", []):
		if line.begins_with("'"):
			var _npc_name2: String = GameManager.get_npc_name(_gal_npc_id) if _gal_npc_id != "" else "éçç·å­"
			pages.append(_npc_name2 + "ï¼" + line)
		else:
			pages.append(line)
	if option.get("note", "") != "":
		pages.append(option["note"])
	show_galgame_dialog(pages)


# ==================== 公共访问 ====================

func is_visible() -> bool:
	return left_dialog_box.visible and left_dialog_box.modulate.a > 0.5


func main_node() -> Node:
	return _main


## 生成打字机嘟嘟音效（合成短促正弦波）
## 隐藏手机暗化遮罩
func _hide_phone_dim() -> void:
	var dim: ColorRect = main_node().get("_phone_dim") as ColorRect
	if dim:
		dim.modulate.a = 1.0
		var t := main_node().create_tween()
		t.tween_property(dim, "modulate:a", 0.0, 0.3)
		t.tween_callback(func(): dim.visible = false; dim.modulate.a = 1.0)

func _generate_beep() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var sample_count: int = int(22050 * 0.045)  # 45ms
	var data := PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit = 2 bytes per sample
	for i in range(sample_count):
		var t: float = float(i) / 22050.0
		var envelope: float = 1.0 - (float(i) / float(sample_count))
		envelope = envelope * envelope  # 快速衰减
		var val: float = sin(2.0 * PI * 520.0 * t) * 0.20 * envelope
		var raw: int = int(val * 32767.0)
		# 小端序写入16-bit有符号整数
		data[i * 2] = raw & 0xFF
		data[i * 2 + 1] = (raw >> 8) & 0xFF
	wav.data = data
	return wav
