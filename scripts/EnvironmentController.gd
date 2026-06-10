## EnvironmentController.gd
## Keeps the left world area anchored to home or the active location.
extends RefCounted

const HOME_BG_PATH := "res://Assets/title_bg2.png"

var _main: Node
var _left_color: ColorRect
var _bg_texture: TextureRect
var _current_context := "home"


func init(main: Node) -> void:
	_main = main
	_left_color = main.get("left_bg") as ColorRect
	_bg_texture = main.get("bg_texture") as TextureRect
	if is_instance_valid(_bg_texture):
		_bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_bg_texture.visible = true
	show_home("init")


func show_home(reason: String = "") -> void:
	_current_context = "home"
	_show_texture(HOME_BG_PATH, _home_color())


func show_location(texture_path: String, context: String = "location") -> void:
	_current_context = context
	if texture_path == "":
		show_home("empty_location")
		return
	_show_texture(texture_path, _home_color())


func clear_to_home(reason: String = "") -> void:
	show_home(reason)


func current_context() -> String:
	return _current_context


func _show_texture(texture_path: String, fallback_color: Color) -> void:
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
