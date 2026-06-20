## PhoneAppController.gd
## Single doorway for opening/closing phone app layers.
extends RefCounted

var _main: Node


func init(main: Node) -> void:
	_main = main


func open_alipay() -> bool:
	if not _can_open_phone_app():
		return false
	close_all_apps()
	_main.alipay._refresh_alipay_ui()
	_show_layer(_main.get("alipay_popup") as Control, true)
	return true


func open_wechat() -> bool:
	if not _can_open_phone_app():
		return false
	close_all_apps()
	_main.wechat._build_chat_items()
	_main.wechat._on_wc_tab(0)
	var wechat_menu := _main.get("wechat_menu") as Control
	var wc_panel_container := _main.get("wc_panel_container") as Control
	if is_instance_valid(wechat_menu):
		wechat_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	if is_instance_valid(wc_panel_container):
		wc_panel_container.mouse_filter = Control.MOUSE_FILTER_STOP
	if is_instance_valid(wechat_menu) and not wechat_menu.gui_input.is_connected(_main.wechat._on_wechat_gui_input):
		wechat_menu.gui_input.connect(_main.wechat._on_wechat_gui_input)
	_show_layer(wechat_menu, true)
	return true


func close_all_apps() -> void:
	if not is_instance_valid(_main):
		return
	if _main.has_method("set_dialog_focus_active"):
		_main.set_dialog_focus_active(false)
	if _main.has_method("_hide_phone_dim_overlay"):
		_main.call("_hide_phone_dim_overlay")
	if _main.has_method("_clear_alipay_tutorial_callouts"):
		_main.call("_clear_alipay_tutorial_callouts")
	var wechat_system: Variant = _main.get("wechat")
	if wechat_system and wechat_system.has_method("force_close"):
		wechat_system.force_close()
	for layer in _phone_app_layers():
		_hide_layer(layer)
	if _main.has_method("sync_ui_state"):
		_main.sync_ui_state()


func hide_layer(layer: Control) -> void:
	_hide_layer(layer)


func reset_layer_visual_state(layer: CanvasItem) -> void:
	if not is_instance_valid(layer):
		return
	var ui_focus: Variant = _main.get("ui_focus") if is_instance_valid(_main) else null
	if ui_focus and ui_focus.has_method("reset_layer_visual_state"):
		ui_focus.reset_layer_visual_state(layer)
		return
	layer.modulate = Color(1, 1, 1, 1)
	layer.self_modulate = Color(1, 1, 1, 1)


func _can_open_phone_app() -> bool:
	if is_instance_valid(_main) and _main.has_method("can_open_phone_app"):
		return _main.can_open_phone_app()
	return true


func _show_layer(layer: Control, visible: bool, exclusive: bool = true) -> void:
	if not is_instance_valid(layer):
		return
	reset_layer_visual_state(layer)
	if _main.has_method("set_ui_layer_visible"):
		_main.set_ui_layer_visible(layer, visible, exclusive)
	else:
		layer.visible = visible


func _hide_layer(layer: Control) -> void:
	if not is_instance_valid(layer):
		return
	reset_layer_visual_state(layer)
	if _main.has_method("set_ui_layer_visible"):
		_main.set_ui_layer_visible(layer, false)
	else:
		layer.visible = false


func _phone_app_layers() -> Array[Control]:
	var layers: Array[Control] = []
	for layer_name in [
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
	]:
		var layer := _main.find_child(layer_name, true, false) as Control
		if is_instance_valid(layer) and not layers.has(layer):
			layers.append(layer)
	return layers
