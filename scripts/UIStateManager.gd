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
	var blocking := false
	for layer in _layers:
		if not is_instance_valid(layer):
			continue
		var active := layer.visible and layer.is_visible_in_tree()
		_set_tree_buttons_enabled(layer, active)
		if active and _blocking_layers.has(layer):
			blocking = true
	_set_background_buttons_enabled(not blocking)


func show_layer(layer: Control, exclusive: bool = true) -> void:
	if not is_instance_valid(layer):
		return
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
		"PaymentPopup",
		"DiaryPopup",
		"BaoTaoMenu",
		"TuanMeiMenu",
		"ZodiacPopup",
		"HouseMenu",
		"DatingPopup",
		"JobMenu",
		"JobPopup",
		"LateNightPopup",
		"WeekdayPanel",
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
