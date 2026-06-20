## UIFocusManager.gd
## Centralizes temporary UI dimming for foreground dialogue.
extends RefCounted

var _main: Node
var _dimmed_layers: Dictionary = {}


func init(main: Node) -> void:
	_main = main


func set_dialog_focus_active(active: bool) -> void:
	if active:
		_dim_dialog_background_layers()
	else:
		restore_dialog_background_layers()
	if is_instance_valid(_main) and _main.get("ui_state") and _main.ui_state.has_method("sync_all"):
		_main.ui_state.sync_all()


func restore_dialog_background_layers() -> void:
	for id in _dimmed_layers.keys():
		var info: Dictionary = _dimmed_layers[id]
		var layer: Control = info.get("node", null)
		if is_instance_valid(layer):
			layer.modulate = info.get("modulate", Color(1, 1, 1, 1))
	_dimmed_layers.clear()


func reset_layer_visual_state(layer: CanvasItem) -> void:
	if not is_instance_valid(layer):
		return
	layer.modulate = Color(1, 1, 1, 1)
	layer.self_modulate = Color(1, 1, 1, 1)


func hide_phone_dim_overlay() -> void:
	if not is_instance_valid(_main):
		return
	var gal = _main.get("galgame")
	if gal and gal.has_method("_hide_phone_dim"):
		gal.call("_hide_phone_dim")
	var phone_dim := _main.get("_phone_dim") as ColorRect
	if is_instance_valid(phone_dim):
		phone_dim.visible = false
		phone_dim.modulate.a = 1.0
		phone_dim.color.a = 0.0


func force_clear_dialog_overlay() -> void:
	if not is_instance_valid(_main):
		return
	var gal = _main.get("galgame")
	if gal and gal.has_method("force_clear_dialog"):
		gal.force_clear_dialog()
	var dialog_text := _main.get("left_dialog_text") as CanvasItem
	if is_instance_valid(dialog_text):
		dialog_text.set("text", "")
		dialog_text.visible = true
	var dialog_box := _main.get("left_dialog_box") as Control
	if is_instance_valid(dialog_box):
		dialog_box.modulate.a = 0.0
		dialog_box.visible = false
	hide_phone_dim_overlay()
	if _main.has_method("sync_ui_state"):
		_main.sync_ui_state()


func _dim_dialog_background_layers() -> void:
	for layer in _dialog_background_layers():
		if not is_instance_valid(layer) or not layer.visible or not layer.is_visible_in_tree():
			continue
		var id := layer.get_instance_id()
		if not _dimmed_layers.has(id):
			_dimmed_layers[id] = {"node": layer, "modulate": layer.modulate}
		var alpha := layer.modulate.a
		layer.modulate = Color(layer.modulate.r * 0.46, layer.modulate.g * 0.46, layer.modulate.b * 0.46, alpha)


func _dialog_background_layers() -> Array[Control]:
	var layers: Array[Control] = []
	for name in [
		"WeChatMenu",
		"WCChatView",
		"AlipayPopup",
		"DiaryPopup",
		"LocationMenu",
		"BaoTaoMenu",
		"TuanMeiMenu",
		"HouseMenu",
		"DatingPopup",
		"JobMenu",
		"ZodiacPopup",
		"WeekdayPanel",
		"PaymentPopup",
		"MonthEndPopup",
	]:
		var layer := _main.find_child(name, true, false) as Control
		if is_instance_valid(layer):
			layers.append(layer)
	return layers
