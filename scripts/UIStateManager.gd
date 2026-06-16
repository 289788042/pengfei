## UIStateManager.gd
## Runtime UI hygiene: hidden layers must not keep clickable buttons alive.
extends RefCounted

var _main: Node
var _layers: Array[Control] = []
var _blocking_layers: Array[Control] = []
var _background_buttons: Array[BaseButton] = []
var _stored_disabled: Dictionary = {}


func init(main: Node) -> void:
	_main = main
	_collect_layers()
	_collect_background_buttons()
	sync_all()


func sync_all() -> void:
	if not is_instance_valid(_main):
		return
	_collect_dynamic_layers()
	_prune_invalid_layers()
	var dialog_blocking: bool = _main.has_method("has_blocking_dialog") and _main.has_blocking_dialog()
	var top_blocking_index := -1
	for i in _layers.size():
		var layer := _layers[i]
		if not is_instance_valid(layer):
			continue
		var active := layer.visible and layer.is_visible_in_tree()
		_apply_layer_input_mode(layer, active)
		if active and _blocking_layers.has(layer):
			top_blocking_index = i
	for i in _layers.size():
		var layer := _layers[i]
		if not is_instance_valid(layer):
			continue
		var active := layer.visible and layer.is_visible_in_tree()
		var can_interact: bool = active and not dialog_blocking and (top_blocking_index < 0 or i >= top_blocking_index)
		_set_tree_buttons_enabled(layer, can_interact)
	_set_background_buttons_enabled(top_blocking_index < 0 and not dialog_blocking)


func show_layer(layer: Control, exclusive: bool = true) -> void:
	if not is_instance_valid(layer):
		return
	register_layer(layer)
	if exclusive:
		for other in _layers:
			if is_instance_valid(other) and other != layer:
				other.visible = false
	layer.visible = true
	sync_all()


func hide_layer(layer: Control) -> void:
	if not is_instance_valid(layer):
		return
	layer.visible = false
	sync_all()


func hide_all() -> void:
	for layer in _layers:
		if is_instance_valid(layer):
			layer.visible = false
	sync_all()


func register_layer(layer: Control, blocks_background: bool = true) -> void:
	if not is_instance_valid(layer):
		return
	if not _layers.has(layer):
		_layers.append(layer)
	if blocks_background and not _blocking_layers.has(layer):
		_blocking_layers.append(layer)


func _collect_layers() -> void:
	_layers.clear()
	_blocking_layers.clear()
	var names := [
		"LocationMenu",
		"WeChatMenu",
		"WCChatView",
		"AlipayPopup",
		"DiaryPopup",
		"BaoTaoMenu",
		"TuanMeiMenu",
		"ZodiacPopup",
		"HouseMenu",
		"DatingPopup",
		"JobMenu",
		"JobPopup",
		"LateNightPopup",
		"PaymentPopup",
		"EventPopup",
		"MonthEndPopup",
		"TransitionScreen",
		"EndingPanel",
		"DebugBG",
	]
	for name in names:
		var node := _main.find_child(name, true, false)
		if node is Control:
			register_layer(node)


func _collect_dynamic_layers() -> void:
	var dynamic_names := [
		"WeekConfirmOverlay",
		"FamilyEventOverlay",
		"FamilyChatOverlay",
		"GraduationOverlay",
		"EndingChoiceOverlay",
		"GameOverOverlay",
		"DebugBG",
	]
	for name in dynamic_names:
		var node := _main.find_child(name, true, false)
		if node is Control:
			register_layer(node)


func _collect_background_buttons() -> void:
	_background_buttons.clear()
	var app_grid := _main.find_child("AppGrid", true, false)
	if app_grid:
		_collect_buttons(app_grid, _background_buttons)
	var next_week := _main.find_child("Btn_NextWeek", true, false)
	if next_week is BaseButton:
		_background_buttons.append(next_week)


func _prune_invalid_layers() -> void:
	for i in range(_layers.size() - 1, -1, -1):
		if not is_instance_valid(_layers[i]):
			_layers.remove_at(i)
	for i in range(_blocking_layers.size() - 1, -1, -1):
		if not is_instance_valid(_blocking_layers[i]):
			_blocking_layers.remove_at(i)


func _apply_layer_input_mode(layer: Control, active: bool) -> void:
	if active and _blocking_layers.has(layer):
		layer.mouse_filter = Control.MOUSE_FILTER_STOP
	elif not active:
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _collect_buttons(root: Node, out: Array[BaseButton]) -> void:
	if root is BaseButton:
		out.append(root)
	for child in root.get_children():
		_collect_buttons(child, out)


func _set_tree_buttons_enabled(root: Control, enabled: bool) -> void:
	var buttons: Array[BaseButton] = []
	_collect_buttons(root, buttons)
	for button in buttons:
		_set_button_enabled(button, enabled)


func _set_background_buttons_enabled(enabled: bool) -> void:
	for button in _background_buttons:
		if is_instance_valid(button):
			_set_button_enabled(button, enabled)


func _set_button_enabled(button: BaseButton, enabled: bool) -> void:
	var id := button.get_instance_id()
	if enabled:
		if _stored_disabled.has(id):
			button.disabled = bool(_stored_disabled[id])
			_stored_disabled.erase(id)
	else:
		if not _stored_disabled.has(id):
			_stored_disabled[id] = button.disabled
		button.disabled = true
