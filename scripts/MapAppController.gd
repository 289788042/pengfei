## MapAppController.gd
## Single doorway for Gaode map opening and location card activation.
extends RefCounted

var _main: Node
var _app: RefCounted


func init(main: Node, app_system: RefCounted) -> void:
	_main = main
	_app = app_system


func open_map() -> bool:
	if not _app._can_open_phone_app():
		return false
	if not _app._ensure_app_unlocked("map"):
		return false
	_app._clear_phone_focus_overlays()
	_app._close_all_menus()
	_app._restore_map_to_phone_layer()
	_app._reset_layer_visual_state(_app.location_menu)
	_app._render_map_menu()
	return true


func close_map() -> void:
	_app._set_layer_visible(_app.location_menu, false)


func start_location(location_id: String) -> void:
	_app._start_location(location_id)
