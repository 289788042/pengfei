extends ColorRect

## 滑块解锁控制器
## 玩家向右拖动手柄到轨道末端即解锁

signal unlock_success

@onready var handle: Button = $SliderTrack/SliderHandle
@onready var track: Panel = $SliderTrack
@onready var hint: Label = $SliderTrack/SliderHint
@onready var sweep: Control = $SliderTrack/SweepReveal

var is_dragging := false
var is_unlocked := false
var handle_min_x := 2.0
var handle_max_x: float
var track_width: float

func _ready() -> void:
	handle_max_x = track.size.x - handle.size.x - 2.0
	track_width = track.size.x
	handle.position.x = handle_min_x
	handle.gui_input.connect(_on_handle_input)
	_start_glow_sweep()


func _start_glow_sweep() -> void:
	var dur = 2.5
	_run_sweep_cycle(dur)
	_run_text_breath(dur)


func _run_sweep_cycle(dur: float) -> void:
	sweep.size.x = 0.0
	var t = create_tween()
	t.tween_property(sweep, "size:x", track_width, dur * 0.6).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(sweep, "size:x", 0.0, dur * 0.25).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(0.3)
	t.tween_callback(_run_sweep_cycle.bind(dur))


func _run_text_breath(dur: float) -> void:
	var t = create_tween()
	t.set_loops()
	t.tween_property(hint, "modulate:a", 0.5, dur * 0.5).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(hint, "modulate:a", 1.0, dur * 0.5).set_ease(Tween.EASE_IN_OUT)


func _on_handle_input(event: InputEvent) -> void:
	if is_unlocked:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = true
			accept_event()
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = false
			if not is_unlocked:
				_snap_back()
			accept_event()
	elif event is InputEventMouseMotion and is_dragging:
		var new_x = clampf(handle.position.x + event.relative.x, handle_min_x, handle_max_x)
		handle.position.x = new_x
		if new_x >= handle_max_x - 5.0:
			_unlock()
		accept_event()


func _snap_back() -> void:
	create_tween().tween_property(handle, "position:x", handle_min_x, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _unlock() -> void:
	is_unlocked = true
	is_dragging = false
	handle.position.x = handle_max_x
	hint.text = "解锁成功!"
	hint.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4))
	sweep.visible = false
	var tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): unlock_success.emit())
	tween.tween_callback(queue_free)
