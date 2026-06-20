## EnvironmentController.gd
## Keeps the left world area anchored to home or the active location.
extends RefCounted

const HOME_BG_PATH := "res://Assets/title_bg2.png"

var _main: Node
var _left_color: ColorRect
var _bg_texture: TextureRect
var _fade_overlay: ColorRect
var _fade_tween: Tween
var _current_context := "home"
var _current_visual_key := ""


func init(main: Node) -> void:
	_main = main
	_left_color = main.get("left_bg") as ColorRect
	_bg_texture = main.get("bg_texture") as TextureRect
	if is_instance_valid(_bg_texture):
		_bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_bg_texture.visible = true
	_setup_fade_overlay()
	show_home("init")


func show_home(reason: String = "") -> void:
	var key := "texture:" + HOME_BG_PATH
	var use_fade := _should_fade_to(key)
	_current_context = "home"
	_current_visual_key = key
	_show_texture(HOME_BG_PATH, _home_color(), use_fade)


func show_location(texture_path: String, context: String = "location") -> void:
	if texture_path == "":
		show_location_color(context)
		return
	var key := "texture:" + texture_path
	var use_fade := _should_fade_to(key)
	_current_context = context
	_current_visual_key = key
	_show_texture(texture_path, _home_color(), use_fade)


func show_location_color(context: String = "location") -> void:
	var key := "color:" + context
	var use_fade := _should_fade_to(key)
	_current_context = context
	_current_visual_key = key
	_show_texture("", _location_color(context), use_fade)


func clear_to_home(reason: String = "") -> void:
	show_home(reason)


func current_context() -> String:
	return _current_context


func _should_fade_to(next_key: String) -> bool:
	return _current_visual_key != "" and _current_visual_key != next_key


func _show_texture(texture_path: String, fallback_color: Color, use_fade: bool = true) -> void:
	if not is_instance_valid(_fade_overlay) or not use_fade:
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		if is_instance_valid(_fade_overlay):
			_fade_overlay.visible = false
			_fade_overlay.color.a = 0.0
		_apply_texture(texture_path, fallback_color)
		return
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_overlay.visible = true
	_fade_overlay.color.a = 0.0
	_fade_tween = _main.create_tween()
	_fade_tween.tween_property(_fade_overlay, "color:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fade_tween.tween_callback(func() -> void:
		_apply_texture(texture_path, fallback_color)
	)
	_fade_tween.tween_property(_fade_overlay, "color:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fade_tween.tween_callback(func() -> void:
		if is_instance_valid(_fade_overlay):
			_fade_overlay.visible = false
	)


func _apply_texture(texture_path: String, fallback_color: Color) -> void:
	var tex := load(texture_path) as Texture2D
	if tex and is_instance_valid(_bg_texture):
		if is_instance_valid(_left_color):
			_left_color.visible = false
		_bg_texture.texture = tex
		_bg_texture.visible = true
		_bg_texture.modulate.a = 1.0
		return
	if is_instance_valid(_bg_texture):
		_bg_texture.texture = null
		_bg_texture.visible = false
	if is_instance_valid(_left_color):
		_left_color.visible = true
		_left_color.color = fallback_color


func _setup_fade_overlay() -> void:
	var parent := _bg_texture.get_parent() as Control
	if not is_instance_valid(parent):
		return
	_fade_overlay = ColorRect.new()
	_fade_overlay.name = "LocationFadeOverlay"
	_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.color = Color(0.015, 0.018, 0.026, 0.0)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.z_index = 60
	_fade_overlay.visible = false
	parent.add_child(_fade_overlay)


func _home_color() -> Color:
	var level := int(GameManager.get("housing_level"))
	match level:
		0:
			return Color(0.075, 0.073, 0.09, 1.0)
		1:
			return Color(0.09, 0.105, 0.12, 1.0)
		2:
			return Color(0.11, 0.105, 0.13, 1.0)
	return Color(0.075, 0.073, 0.09, 1.0)


func _location_color(context: String) -> Color:
	match context:
		"bar":
			return Color(0.105, 0.045, 0.115, 1.0)
		"cafe":
			return Color(0.135, 0.095, 0.060, 1.0)
		"park":
			return Color(0.045, 0.110, 0.075, 1.0)
		"market":
			return Color(0.130, 0.075, 0.040, 1.0)
		"home":
			return _home_color()
		"overtime":
			return Color(0.070, 0.080, 0.100, 1.0)
	return Color(0.080, 0.085, 0.105, 1.0)
