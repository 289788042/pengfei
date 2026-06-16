extends TextureRect

## 手机显示尺寸 1920x1080（源文件 688x384 放大显示）
var phone_width := 1920.0
var phone_height := 1080.0
var peek_amount := 220.0    ## 初始只露出多少像素
var bounce_height := 15.0   ## 跳动幅度
var float_height := 8.0     ## 弹出后浮动幅度
var float_duration := 2.0   ## 浮动一个周期的时间

var is_popped_up := false
var bounce_tween: Tween
var float_tween: Tween
var initial_y: float
var tap_hint: Label

func _ready() -> void:
	size = Vector2(phone_width, phone_height)
	stretch_mode = TextureRect.STRETCH_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# 初始位置：整体往下移，只露出顶部一点点
	position.x = 0.0
	position.y = phone_height - peek_amount
	
	# 允许接收鼠标点击
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 主UI初始隐藏（等解锁后才显示）
	_hide_main_ui(true)
	_create_tap_hint()
	
	# 开始轻微跳动
	start_bounce()


func start_bounce() -> void:
	initial_y = position.y
	bounce_tween = create_tween()
	bounce_tween.set_loops()
	bounce_tween.tween_property(self, "position:y", initial_y - bounce_height, 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	bounce_tween.tween_property(self, "position:y", initial_y, 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func start_float() -> void:
	float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(self, "position:y", -float_height, float_duration / 2.0)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(self, "position:y", 0.0, float_duration / 2.0)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _hide_main_ui(should_hide: bool) -> void:
	var content = get_node_or_null("ScreenContent")
	if not content:
		return
	for child in content.get_children():
		if child.name != "LockScreen":
			child.visible = not should_hide


func show_main_ui() -> void:
	_hide_main_ui(false)


func _create_tap_hint() -> void:
	var parent_node := get_parent() as Control
	if parent_node == null:
		return
	tap_hint = Label.new()
	tap_hint.text = "点击手机弹出"
	tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tap_hint.add_theme_font_size_override("font_size", 28)
	tap_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.96))
	tap_hint.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	tap_hint.add_theme_constant_override("shadow_offset_x", 2)
	tap_hint.add_theme_constant_override("shadow_offset_y", 2)
	tap_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tap_hint.z_index = 20
	tap_hint.anchor_left = 0.0
	tap_hint.anchor_right = 1.0
	tap_hint.anchor_top = 1.0
	tap_hint.anchor_bottom = 1.0
	tap_hint.offset_left = 0.0
	tap_hint.offset_right = 0.0
	tap_hint.offset_top = -270.0
	tap_hint.offset_bottom = -225.0
	parent_node.add_child.call_deferred(tap_hint)
	call_deferred("_start_tap_hint_anim")

func _start_tap_hint_anim() -> void:
	if not tap_hint or not is_instance_valid(tap_hint):
		return
	var hint_tween := tap_hint.create_tween()
	hint_tween.set_loops()
	hint_tween.tween_property(tap_hint, "modulate:a", 0.35, 0.7).set_trans(Tween.TRANS_SINE)
	hint_tween.tween_property(tap_hint, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)


func _gui_input(event: InputEvent) -> void:
	if is_popped_up:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pop_up()
		accept_event()


func pop_up() -> void:
	is_popped_up = true
	if tap_hint:
		tap_hint.visible = false
	
	# 停止跳动
	if bounce_tween:
		bounce_tween.kill()
	
	# 目标位置：完全显示
	var target_y = 0.0
	
	# 弹出动画，弹出完成后开始缓慢浮动
	var tween = create_tween()
	tween.tween_property(self, "position:y", target_y, 0.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(start_float)
