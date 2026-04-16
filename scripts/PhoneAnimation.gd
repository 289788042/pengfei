extends TextureRect

## 手机显示尺寸 1920x1080（源文件 688x384 放大显示）
var phone_width := 1920.0
var phone_height := 1080.0
var peek_amount := 120.0    ## 初始只露出多少像素
var bounce_height := 15.0   ## 跳动幅度
var float_height := 8.0     ## 弹出后浮动幅度
var float_duration := 2.0   ## 浮动一个周期的时间

var is_popped_up := false
var bounce_tween: Tween
var float_tween: Tween
var initial_y: float

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


func _gui_input(event: InputEvent) -> void:
	if is_popped_up:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pop_up()
		accept_event()


func pop_up() -> void:
	is_popped_up = true
	
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
