## AppPopupSystem.gd - APP弹窗/地点/食物/交友/求职/日记系统
## 负责：高德地图、宝淘、团美、星座、贝壳、滑动交友、BOSS弯聘、日记本、深夜失眠等
## 通过 _main 引用 MainGame 节点访问 UI 节点和工具函数
extends RefCounted

const HeavyAppUI = preload("res://scripts/HeavyAppUI.gd")

# ==================== 成员变量 ====================

var _main: Node

# UI 节点引用
var location_menu: ColorRect
var baotao_menu: ColorRect
var tuanmei_menu: ColorRect
var zodiac_popup: ColorRect
var label_zodiac_content: Label
var house_menu: ColorRect
var dating_popup: ColorRect
var label_date_name: Label
var label_date_age: Label
var label_date_bio: Label
var job_menu: ColorRect
var diary_popup: ColorRect
var diary_log_container: VBoxContainer
var late_night_popup: ColorRect
var btn_emo_bag: Button
var btn_emo_sleep: Button

var _heavy_app_layers: Array = []
# 城市碎片事件池
var _city_fragments: Dictionary = {}
# NPC邂逅冷却（替代永久失败的 encounter_failed_ids）
var _encounter_cooldowns: Dictionary = {}  # npc_id -> turn_count 可重试
var _location_event_hold_count: int = 0
var _result_flow: RefCounted
var _city_events: RefCounted
var _encounters: RefCounted
var _location_runner: RefCounted
var _map_app: RefCounted
var _career_app: RefCounted
var _diary_app: RefCounted
var _consumer_app: RefCounted
var _light_social_app: RefCounted


# ==================== 初始化 ====================

func init(main: Node) -> void:
	_main = main
	location_menu = main.location_menu
	baotao_menu = main.baotao_menu
	tuanmei_menu = main.tuanmei_menu
	zodiac_popup = main.zodiac_popup
	label_zodiac_content = main.label_zodiac_content
	house_menu = main.house_menu
	dating_popup = main.dating_popup
	label_date_name = main.label_date_name
	label_date_age = main.label_date_age
	label_date_bio = main.label_date_bio
	job_menu = main.job_menu
	diary_popup = main.diary_popup
	diary_log_container = main.diary_log_container
	late_night_popup = main.late_night_popup
	btn_emo_bag = main.btn_emo_bag
	btn_emo_sleep = main.btn_emo_sleep
	_setup_phone_app_layers()
	_diary_app = _new_diary_app()
	_setup_diary_heavy_ui()
	_result_flow = _new_action_results()
	_city_events = _new_city_events()
	if _city_events and _city_events.has_method("fragments"):
		_city_fragments = _city_events.fragments()
	_encounters = _new_encounters()
	_location_runner = _new_location_runner()
	_map_app = _new_map_app()
	_career_app = _new_career_app()
	_consumer_app = _new_consumer_app()
	_light_social_app = _new_light_social_app()


func _new_action_results() -> RefCounted:
	var script := ResourceLoader.load("res://scripts/ActionResultController.gd", "", ResourceLoader.CACHE_MODE_REPLACE) as Script
	var controller := script.new() as RefCounted
	controller.init(_main)
	return controller


func _new_city_events() -> RefCounted:
	var script := ResourceLoader.load("res://scripts/CityEventController.gd", "", ResourceLoader.CACHE_MODE_REPLACE) as Script
	var controller := script.new() as RefCounted
	controller.init(_main, self)
	return controller


func _new_encounters() -> RefCounted:
	var script := ResourceLoader.load("res://scripts/EncounterController.gd", "", ResourceLoader.CACHE_MODE_REPLACE) as Script
	var controller := script.new() as RefCounted
	controller.init(_main, self, _encounter_cooldowns)
	return controller


func _new_location_runner() -> RefCounted:
	var script := ResourceLoader.load("res://scripts/LocationActionRunner.gd", "", ResourceLoader.CACHE_MODE_REPLACE) as Script
	var runner := script.new() as RefCounted
	runner.init(_main, self)
	return runner


func _new_map_app() -> RefCounted:
	var script := ResourceLoader.load("res://scripts/MapAppController.gd", "", ResourceLoader.CACHE_MODE_REPLACE) as Script
	var map_controller := script.new() as RefCounted
	map_controller.init(_main, self)
	return map_controller


func _new_career_app() -> RefCounted:
	var script := ResourceLoader.load("res://scripts/CareerAppController.gd", "", ResourceLoader.CACHE_MODE_REPLACE) as Script
	var controller := script.new() as RefCounted
	controller.init(_main, self)
	return controller


func _new_diary_app() -> RefCounted:
	var script := ResourceLoader.load("res://scripts/DiaryAppController.gd", "", ResourceLoader.CACHE_MODE_REPLACE) as Script
	var controller := script.new() as RefCounted
	controller.init(_main, self)
	return controller


func _new_consumer_app() -> RefCounted:
	var script := ResourceLoader.load("res://scripts/ConsumerAppController.gd", "", ResourceLoader.CACHE_MODE_REPLACE) as Script
	var controller := script.new() as RefCounted
	controller.init(_main, self)
	return controller


func _new_light_social_app() -> RefCounted:
	var script := ResourceLoader.load("res://scripts/LightSocialAppController.gd", "", ResourceLoader.CACHE_MODE_REPLACE) as Script
	var controller := script.new() as RefCounted
	controller.init(_main, self)
	return controller

# ==================== 辅助方法 ====================

func main_node() -> Node:
	return _main


func _setup_phone_app_layers() -> void:
	for layer in [location_menu, baotao_menu, tuanmei_menu, zodiac_popup, house_menu, dating_popup, job_menu, late_night_popup]:
		_setup_phone_layer(layer)


func _setup_phone_layer(layer: Control, z: int = 50) -> void:
	if not is_instance_valid(layer):
		return
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.offset_left = 0
	layer.offset_top = 0
	layer.offset_right = 0
	layer.offset_bottom = 0
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = z
	if layer is ColorRect and layer.color.a < 0.45:
		layer.color = Color(0, 0, 0, 0.58)


func _setup_heavy_app_layer(layer: Control, z: int = 80, panel_min_size: Vector2 = Vector2(960, 760)) -> void:
	if not is_instance_valid(layer):
		return
	if not _heavy_app_layers.has(layer):
		_heavy_app_layers.append(layer)
	HeavyAppUI.setup_layer(layer, main_node(), z, panel_min_size)


func _is_heavy_app_layer(layer: Control) -> bool:
	return _heavy_app_layers.has(layer)


func _detach_from_parent(node: Node) -> void:
	HeavyAppUI.detach_from_parent(node)


func _make_flat_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	return HeavyAppUI.make_flat_style(bg, border, border_width, radius)


func _style_text_button(button: Button, normal: Color, hover: Color, font_color: Color = Color.WHITE) -> void:
	HeavyAppUI.style_text_button(button, normal, hover, font_color)


func _can_open_phone_app() -> bool:
	if is_instance_valid(_main) and _main.has_method("can_open_phone_app"):
		return _main.can_open_phone_app()
	return true


func _ensure_app_unlocked(app_id: String) -> bool:
	if app_id == "" or GameManager.is_app_unlocked(app_id):
		return true
	var hint := GameManager.get_app_unlock_hint(app_id)
	main_node().show_message(hint if hint != "" else "这个 App 还没有解锁。")
	return false


func _set_layer_visible(layer: Control, is_visible: bool) -> void:
	if not is_instance_valid(layer):
		return
	if not is_visible:
		_reset_layer_visual_state(layer)
	if is_visible:
		if _is_heavy_app_layer(layer):
			var panel_size := Vector2(1040, 720) if layer == location_menu else Vector2(960, 760)
			_setup_heavy_app_layer(layer, 80, panel_size)
		else:
			_setup_phone_layer(layer)
	if is_instance_valid(_main) and _main.has_method("set_ui_layer_visible"):
		_main.set_ui_layer_visible(layer, is_visible)
	else:
		layer.visible = is_visible


func _refresh_main_ui() -> void:
	if _result_flow and _result_flow.has_method("refresh_main_ui"):
		_result_flow.refresh_main_ui()
		return
	GameManager.stats_updated.emit()
	if is_instance_valid(_main) and _main.has_method("_refresh_ui"):
		_main._refresh_ui()


func _remove_colored_result_segments(line: String) -> String:
	if _result_flow and _result_flow.has_method("remove_colored_result_segments"):
		return str(_result_flow.remove_colored_result_segments(line))
	return line


func _strip_embedded_result_lines(text: String) -> String:
	if _result_flow and _result_flow.has_method("strip_embedded_result_lines"):
		return str(_result_flow.strip_embedded_result_lines(text))
	return text.strip_edges()


func _format_result(changes: Dictionary, title: String = "【结算】") -> String:
	if _result_flow and _result_flow.has_method("format_result"):
		return str(_result_flow.format_result(changes, title))
	return ""


func _format_npc_result(changes: Dictionary, npc_name: String, title: String = "【结算】") -> String:
	if _result_flow and _result_flow.has_method("format_npc_result"):
		return str(_result_flow.format_npc_result(changes, npc_name, title))
	return _format_result(changes, title)


func _show_result(result_text: String, after: Callable = Callable()) -> void:
	if _result_flow and _result_flow.has_method("show_result"):
		_result_flow.show_result(result_text, after)
	elif after.is_valid():
		after.call()


func _begin_location_event() -> void:
	if _location_runner and _location_runner.has_method("begin_location_event"):
		_location_runner.begin_location_event()
		_location_event_hold_count = int(_location_runner.hold_count())
		return
	_location_event_hold_count += 1


func _end_location_event() -> void:
	if _location_runner and _location_runner.has_method("end_location_event"):
		_location_runner.end_location_event()
		_location_event_hold_count = int(_location_runner.hold_count())
		return
	if _location_event_hold_count > 0:
		_location_event_hold_count -= 1


func _finish_location_event_after(after: Callable = Callable()) -> Callable:
	if _location_runner and _location_runner.has_method("finish_after"):
		return _location_runner.finish_after(after)
	return func() -> void:
		if after.is_valid():
			after.call()
		_end_location_event()
		if is_instance_valid(_main) and main_node().current_phase == main_node().Phase.EVENT:
			main_node().current_phase = main_node().Phase.WEEKEND
			if main_node().has_method("sync_ui_state"):
				main_node().sync_ui_state()
			if main_node().has_method("_refresh_ui"):
				main_node()._refresh_ui()


func _show_story_then_result(story_text: String, result_text: String, after: Callable = Callable()) -> void:
	if _result_flow and _result_flow.has_method("show_story_then_result"):
		_result_flow.show_story_then_result(story_text, result_text, after)
	else:
		_show_result(result_text, after)


func _show_story_then_changes(story_text: String, changes: Dictionary, after: Callable = Callable(), title: String = "【结算】") -> void:
	if _result_flow and _result_flow.has_method("show_story_then_changes"):
		_result_flow.show_story_then_changes(story_text, changes, after, title)
	else:
		_show_story_then_result(story_text, _format_result(changes, title), after)


func _show_story_then_apply_changes(story_text: String, pending_changes: Dictionary, already_applied_changes: Dictionary = {}, after: Callable = Callable(), title: String = "【结算】") -> void:
	if _result_flow and _result_flow.has_method("show_story_then_apply_changes"):
		_result_flow.show_story_then_apply_changes(story_text, pending_changes, already_applied_changes, after, title)
	elif after.is_valid():
		after.call()


func _show_story_then_apply_npc_changes(story_text: String, pending_changes: Dictionary, already_applied_changes: Dictionary, npc_name: String, after: Callable = Callable(), title: String = "【结算】", npc_id: String = "", npc_pending_changes: Dictionary = {}) -> void:
	if _result_flow and _result_flow.has_method("show_story_then_apply_npc_changes"):
		_result_flow.show_story_then_apply_npc_changes(story_text, pending_changes, already_applied_changes, npc_name, after, title, npc_id, npc_pending_changes)
	elif after.is_valid():
		after.call()


func _show_location_result(location: String, fallback_text: String, changes: Dictionary, after: Callable = Callable()) -> void:
	if _result_flow and _result_flow.has_method("show_location_result"):
		_result_flow.show_location_result(location, fallback_text, changes, after)
	else:
		_show_story_then_result(fallback_text, _format_result(changes), after)


func _action_service():
	if _result_flow and _result_flow.has_method("action_service"):
		return _result_flow.action_service()
	if is_instance_valid(_main):
		return main_node().get("action_service")
	return null


func _show_action_result(story_text: String, changes: Dictionary, after: Callable = Callable()) -> void:
	if _result_flow and _result_flow.has_method("show_action_result"):
		_result_flow.show_action_result(story_text, changes, after)
	else:
		_show_story_then_apply_changes(story_text, changes, {}, after)


# ==================== 地图/地点 ====================

func _on_close_loc() -> void:
	if _map_app and _map_app.has_method("close_map"):
		_map_app.close_map()
		return
	_set_layer_visible(location_menu, false)


func _on_app_map() -> void:
	if _map_app and _map_app.has_method("open_map"):
		_map_app.open_map()
		return
	_render_map_menu()


func _render_map_menu() -> void:
	if _map_app and _map_app.has_method("render_map_menu"):
		_map_app.render_map_menu()


func _restore_map_to_phone_layer() -> void:
	if _heavy_app_layers.has(location_menu):
		_heavy_app_layers.erase(location_menu)
	var phone_screen := main_node().find_child("PhoneScreen", true, false) as Control
	if is_instance_valid(phone_screen) and location_menu.get_parent() != phone_screen:
		var old_parent := location_menu.get_parent()
		if old_parent:
			old_parent.remove_child(location_menu)
		phone_screen.add_child(location_menu)
	_setup_phone_layer(location_menu, 55)
	_reset_layer_visual_state(location_menu)


func _clear_phone_focus_overlays() -> void:
	if not is_instance_valid(_main):
		return
	if main_node().has_method("set_dialog_focus_active"):
		main_node().set_dialog_focus_active(false)
	if main_node().has_method("_hide_phone_dim_overlay"):
		main_node().call("_hide_phone_dim_overlay")


func _reset_layer_visual_state(layer: CanvasItem) -> void:
	if not is_instance_valid(layer):
		return
	layer.modulate = Color(1, 1, 1, 1)
	layer.self_modulate = Color(1, 1, 1, 1)


func _close_all_menus() -> void:
	if is_instance_valid(_main):
		var phone_apps: Variant = main_node().get("phone_apps")
		if phone_apps and phone_apps.has_method("close_all_apps"):
			phone_apps.close_all_apps()
			return
	if is_instance_valid(_main):
		if main_node().has_method("_clear_alipay_tutorial_callouts"):
			main_node().call("_clear_alipay_tutorial_callouts")
		var wechat_system: Variant = main_node().get("wechat")
		if wechat_system and wechat_system.has_method("force_close"):
			wechat_system.force_close()
	var menus: Array[Control] = [location_menu, baotao_menu, tuanmei_menu, zodiac_popup, house_menu, dating_popup, job_menu, diary_popup, late_night_popup]
	for layer_name in ["WeChatMenu", "WCChatView", "AlipayPopup", "PaymentPopup"]:
		var layer := main_node().find_child(layer_name, true, false) as Control if is_instance_valid(_main) else null
		if is_instance_valid(layer) and not menus.has(layer):
			menus.append(layer)
	for m in menus:
		if is_instance_valid(m):
			_set_layer_visible(m, false)


func _on_app_diary() -> void:
	if _diary_app and _diary_app.has_method("open_diary"):
		_diary_app.open_diary()


func _on_app_baotao() -> void:
	if _consumer_app and _consumer_app.has_method("open_baotao"):
		_consumer_app.open_baotao()

func _on_app_tuanmei() -> void:
	if _consumer_app and _consumer_app.has_method("open_tuanmei"):
		_consumer_app.open_tuanmei()

func _on_app_zodiac() -> void:
	if _light_social_app and _light_social_app.has_method("open_zodiac"):
		_light_social_app.open_zodiac()


func _on_app_house() -> void:
	if _consumer_app and _consumer_app.has_method("open_house"):
		_consumer_app.open_house()

func _on_app_dating() -> void:
	if _light_social_app and _light_social_app.has_method("open_dating"):
		_light_social_app.open_dating()


# ==================== 通用App覆盖层构建器 ====================

func _build_app_overlay(parent: ColorRect, title: String, top_color: Color, subtitle: String, items: Array) -> void:
	_setup_phone_layer(parent)
	parent.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.color = Color(0, 0, 0, 0.52)
	## 外层圆角面板
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_top = 8
	panel.offset_bottom = -8
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.95, 0.95, 0.95, 1)
	panel_style.set_corner_radius_all(12.0)
	panel_style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", panel_style)
	parent.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)
	## 顶栏
	var top_bar := PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 44)
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = top_color
	top_style.set_corner_radius_all(10.0)
	top_style.set_content_margin_all(8)
	top_style.corner_detail = 8
	top_bar.add_theme_stylebox_override("panel", top_style)
	vbox.add_child(top_bar)
	var top_hbox := HBoxContainer.new()
	top_bar.add_child(top_hbox)
	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(title_lbl)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.custom_minimum_size = Vector2(42, 30)
	close_btn.pressed.connect(func() -> void:
		_set_layer_visible(parent, false)
	)
	top_hbox.add_child(close_btn)
	## 副标题栏（花呗欠款/状态）
	if subtitle != "":
		var sub_bar := PanelContainer.new()
		sub_bar.custom_minimum_size = Vector2(0, 28)
		var sub_style := StyleBoxFlat.new()
		sub_style.bg_color = Color(0.9, 0.9, 0.9, 1)
		sub_style.set_content_margin_all(6)
		sub_bar.add_theme_stylebox_override("panel", sub_style)
		vbox.add_child(sub_bar)
		var sub_lbl := Label.new()
		sub_lbl.text = subtitle
		sub_lbl.add_theme_font_size_override("font_size", 12)
		sub_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sub_bar.add_child(sub_lbl)
	## 滚动区域
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	var scroll_vbox := VBoxContainer.new()
	scroll_vbox.add_theme_constant_override("separation", 4)
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_vbox)
	## 商品行
	for item in items:
		var is_locked: bool = item.get("locked", false)
		var is_current: bool = item.get("current", false)
		var row := PanelContainer.new()
		var row_style := StyleBoxFlat.new()
		if is_locked:
			row_style.bg_color = Color(0.88, 0.88, 0.88, 1)
		elif is_current:
			row_style.bg_color = Color(0.85, 0.95, 0.85, 1)
		else:
			row_style.bg_color = Color.WHITE
		row_style.set_content_margin_all(10)
		row_style.set_corner_radius_all(8.0)
		row.add_theme_stylebox_override("panel", row_style)
		scroll_vbox.add_child(row)
		var row_hbox := HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 8)
		row_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(row_hbox)
		## 图标
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(36, 36)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.color = item.get("icon_color", Color.GRAY)
		row_hbox.add_child(icon)
		## 文字区
		var text_vbox := VBoxContainer.new()
		text_vbox.add_theme_constant_override("separation", 2)
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_hbox.add_child(text_vbox)
		var name_lbl := Label.new()
		name_lbl.text = item["name"]
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1))
		if is_locked:
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		text_vbox.add_child(name_lbl)
		var cost_lbl := Label.new()
		cost_lbl.text = item.get("cost", "")
		cost_lbl.add_theme_font_size_override("font_size", 11)
		cost_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
		cost_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cost_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_child(cost_lbl)
		if is_locked and item.has("lock_reason") and str(item["lock_reason"]).strip_edges() != "":
			var reason_lbl := Label.new()
			reason_lbl.text = item["lock_reason"]
			reason_lbl.add_theme_font_size_override("font_size", 10)
			reason_lbl.add_theme_color_override("font_color", Color(0.72, 0.22, 0.22, 1))
			reason_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			reason_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text_vbox.add_child(reason_lbl)
		## 右侧标记
		if is_current:
			var cur_lbl := Label.new()
			cur_lbl.text = "当前"
			cur_lbl.add_theme_font_size_override("font_size", 13)
			cur_lbl.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2, 1))
			cur_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row_hbox.add_child(cur_lbl)
		elif is_locked:
			var lock_lbl := Label.new()
			lock_lbl.text = "X"
			lock_lbl.add_theme_font_size_override("font_size", 14)
			lock_lbl.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3, 1))
			lock_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row_hbox.add_child(lock_lbl)
		else:
			var arrow_lbl := Label.new()
			arrow_lbl.text = ">"
			arrow_lbl.add_theme_font_size_override("font_size", 20)
			arrow_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1))
			arrow_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row_hbox.add_child(arrow_lbl)
		var arrow_mr := Control.new()
		arrow_mr.custom_minimum_size = Vector2(12, 0)
		row_hbox.add_child(arrow_mr)
		## 点击
		if not is_locked and item.has("action"):
			var captured_action: Callable = item["action"]
			var close_on_action: bool = bool(item.get("close_on_action", true))
			row.mouse_filter = Control.MOUSE_FILTER_STOP
			for child in row_hbox.get_children():
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					if close_on_action:
						_set_layer_visible(parent, false)
					captured_action.call()
			)


# ==================== 城市碎片 & 重逢系统 ====================

func _has_city_fragments(location: String) -> bool:
	if _city_events and _city_events.has_method("has_fragments"):
		return bool(_city_events.has_fragments(location))
	return _city_fragments.get(location, []).size() > 0


func _trigger_city_fragment(location: String, base_changes: Dictionary = {}, already_applied_changes: Dictionary = {}) -> void:
	if _city_events and _city_events.has_method("trigger_fragment"):
		_city_events.trigger_fragment(location, base_changes, already_applied_changes)


func _check_reunion(location: String) -> Dictionary:
	if _encounters and _encounters.has_method("check_reunion"):
		return _encounters.check_reunion(location)
	return {}


func _handle_reunion(npc: Dictionary, location: String) -> void:
	if _encounters and _encounters.has_method("handle_reunion"):
		_encounters.handle_reunion(npc, location)


# ==================== 废弃周末资源兼容接口 ====================

func _use_weekend_action(label: String = "weekend") -> bool:
	if main_node().get("action_service") and main_node().action_service.has_method("spend_weekend_action"):
		return main_node().action_service.spend_weekend_action(label)
	return true


# ==================== 地点逻辑 ====================

func _location_config(location: String) -> Dictionary:
	if _location_runner and _location_runner.has_method("location_config"):
		return _location_runner.location_config(location)
	return {}

func _show_location_background(location: String) -> void:
	if _location_runner and _location_runner.has_method("show_location_background"):
		_location_runner.show_location_background(location)
		return
	var gal = main_node().get("galgame")
	if gal and gal.has_method("play_ambient_for_location"):
		gal.play_ambient_for_location(location)


## 检查指定地点是否有NPC邂逅
func _check_encounter(location: String) -> Dictionary:
	if _encounters and _encounters.has_method("check_encounter"):
		return _encounters.check_encounter(location)
	return {}


func _meets_encounter_requirements(enc: Dictionary) -> bool:
	if _encounters and _encounters.has_method("meets_encounter_requirements"):
		return bool(_encounters.meets_encounter_requirements(enc))
	return false


func _format_encounter_requirement_hint(enc: Dictionary) -> String:
	if _encounters and _encounters.has_method("format_encounter_requirement_hint"):
		return str(_encounters.format_encounter_requirement_hint(enc))
	return ""


func _ensure_weekly_location_state() -> void:
	pass


func _get_weekly_location_visits(location: String) -> int:
	if _location_runner and _location_runner.has_method("get_weekly_location_visits"):
		return int(_location_runner.get_weekly_location_visits(location))
	return 0


func _record_weekly_location_visit(location: String) -> void:
	if _location_runner and _location_runner.has_method("record_weekly_location_visit"):
		_location_runner.record_weekly_location_visit(location)


func _has_seen_weekly_reunion(npc_id: String) -> bool:
	if _location_runner and _location_runner.has_method("has_seen_weekly_reunion"):
		return bool(_location_runner.has_seen_weekly_reunion(npc_id))
	return false


func _record_weekly_reunion(npc_id: String) -> void:
	if _location_runner and _location_runner.has_method("record_weekly_reunion"):
		_location_runner.record_weekly_reunion(npc_id)


func _location_repeat_scale(visit_index: int) -> float:
	if _location_runner and _location_runner.has_method("location_repeat_scale"):
		return float(_location_runner.location_repeat_scale(visit_index))
	return 1.0


func _apply_location_repeat_decay(changes: Dictionary, visit_index: int) -> Dictionary:
	if _location_runner and _location_runner.has_method("apply_location_repeat_decay"):
		return _location_runner.apply_location_repeat_decay(changes, visit_index)
	return changes.duplicate()


func _is_once_per_week_location_visited() -> bool:
	if _location_runner and _location_runner.has_method("is_once_per_week_location_visited"):
		return bool(_location_runner.is_once_per_week_location_visited())
	return false


func _merge_change_dicts(base: Dictionary, extra: Dictionary) -> Dictionary:
	if _result_flow and _result_flow.has_method("merge_change_dicts"):
		return _result_flow.merge_change_dicts(base, extra)
	return base.duplicate()


func _drop_unbound_affection(changes: Dictionary, npc_id: String = "") -> Dictionary:
	if _result_flow and _result_flow.has_method("drop_unbound_affection"):
		return _result_flow.drop_unbound_affection(changes, npc_id)
	var cleaned := changes.duplicate()
	if npc_id == "" and cleaned.has("affection"):
		cleaned.erase("affection")
	return cleaned


func _apply_location_changes(changes: Dictionary) -> Dictionary:
	if _result_flow and _result_flow.has_method("apply_location_changes"):
		return _result_flow.apply_location_changes(changes)
	return {}


func _apply_npc_bonus_changes(npc_id: String, changes: Dictionary) -> Dictionary:
	if _result_flow and _result_flow.has_method("apply_npc_bonus_changes"):
		return _result_flow.apply_npc_bonus_changes(npc_id, changes)
	return {}


func _location_story(location: String, config: Dictionary) -> String:
	if _location_runner and _location_runner.has_method("location_story"):
		return _location_runner.location_story(location, config)
	var story := GameManager.get_location_narrative(location, config.get("fallback", ""))
	if config.has("format_value"):
		story = story % int(config["format_value"])
	return story


func _record_location_activity(location: String, config: Dictionary, changes: Dictionary, payment_changes: Dictionary, visit_index: int) -> void:
	if _location_runner and _location_runner.has_method("record_location_activity"):
		_location_runner.record_location_activity(location, config, changes, payment_changes, visit_index)


func _show_location_result_from_config(location: String, config: Dictionary, pending_changes: Dictionary, already_applied_changes: Dictionary = {}, after: Callable = Callable()) -> void:
	if _location_runner and _location_runner.has_method("show_location_result_from_config"):
		_location_runner.show_location_result_from_config(location, config, pending_changes, already_applied_changes, after)
		return
	_show_story_then_apply_changes(_location_story(location, config), pending_changes, already_applied_changes, _finish_location_event_after(after))


func _can_start_location(location: String, config: Dictionary) -> bool:
	if _location_runner and _location_runner.has_method("can_start_location"):
		return bool(_location_runner.can_start_location(location, config))
	return false


func _start_map_location(location: String) -> void:
	if _map_app and _map_app.has_method("start_location"):
		_map_app.start_location(location)
		return
	_start_location(location)


func _start_location(location: String) -> void:
	if _location_runner and _location_runner.has_method("start_location"):
		_location_runner.start_location(location)
		_location_event_hold_count = int(_location_runner.hold_count())
		return
	main_node().show_message("地点系统尚未就绪：" + location)


func _run_location_after_payment(location: String, config: Dictionary, payment_changes: Dictionary) -> void:
	if _location_runner and _location_runner.has_method("run_location_after_payment"):
		_location_runner.run_location_after_payment(location, config, payment_changes)
		_location_event_hold_count = int(_location_runner.hold_count())

func _show_reunion_result(npc: Dictionary, location: String, base_changes: Dictionary) -> void:
	if _encounters and _encounters.has_method("show_reunion_result"):
		_encounters.show_reunion_result(npc, location, base_changes)


## 处理邂逅场景（通用版）
func _handle_encounter(npc: Dictionary, location: String, config: Dictionary, pending_changes: Dictionary, already_applied_changes: Dictionary = {}, visit_index: int = 0) -> void:
	if _encounters and _encounters.has_method("handle_encounter"):
		_encounters.handle_encounter(npc, location, config, pending_changes, already_applied_changes, visit_index)


func _on_loc_library() -> void:
	_start_location("library")

func _on_loc_gym() -> void:
	_start_location("gym")

func _normal_gym() -> void:
	_start_location("gym")

func _on_loc_bar() -> void:
	_start_location("bar")

func _normal_bar() -> void:
	_start_location("bar")

func _on_loc_home() -> void:
	_start_location("home")

func _on_loc_park() -> void:
	_start_location("park")

func _on_loc_cafe() -> void:
	_start_location("cafe")

func _on_loc_market() -> void:
	_start_location("market")

func _on_loc_overtime() -> void:
	_start_location("overtime")

# ==================== 饮食系统 ====================

func _on_food_low() -> void:
	var controller := main_node().get("week_planning") as RefCounted
	if controller and controller.has_method("on_food_low"):
		controller.on_food_low()

func _on_food_mid() -> void:
	var controller := main_node().get("week_planning") as RefCounted
	if controller and controller.has_method("on_food_mid"):
		controller.on_food_mid()

func _on_food_high() -> void:
	var controller := main_node().get("week_planning") as RefCounted
	if controller and controller.has_method("on_food_high"):
		controller.on_food_high()

func _unlock_work_buttons() -> void:
	var controller := main_node().get("week_planning") as RefCounted
	if controller and controller.has_method("unlock_work_buttons"):
		controller.unlock_work_buttons()


# ==================== 宝淘App（消费陷阱）====================

func _on_bt_skincare() -> void:
	if _consumer_app and _consumer_app.has_method("on_bt_skincare"):
		_consumer_app.on_bt_skincare()

func _on_bt_fashion() -> void:
	if _consumer_app and _consumer_app.has_method("on_bt_fashion"):
		_consumer_app.on_bt_fashion()

# ==================== 团美医美App（消费陷阱）====================

func _on_tm_injection() -> void:
	if _consumer_app and _consumer_app.has_method("on_tm_injection"):
		_consumer_app.on_tm_injection()

func _on_tm_surgery() -> void:
	if _consumer_app and _consumer_app.has_method("on_tm_surgery"):
		_consumer_app.on_tm_surgery()

# ==================== 星座App ====================

func _on_close_zodiac() -> void:
	if _light_social_app and _light_social_app.has_method("close_zodiac"):
		_light_social_app.close_zodiac()


# ==================== 贝壳找房App ====================

func _on_house_village() -> void:
	if _consumer_app and _consumer_app.has_method("on_house_village"):
		_consumer_app.on_house_village()

func _on_house_apartment() -> void:
	if _consumer_app and _consumer_app.has_method("on_house_apartment"):
		_consumer_app.on_house_apartment()

func _on_house_luxury() -> void:
	if _consumer_app and _consumer_app.has_method("on_house_luxury"):
		_consumer_app.on_house_luxury()

# ==================== 滑动交友App ====================

func _refresh_dating_card() -> void:
	if _light_social_app and _light_social_app.has_method("refresh_dating_card"):
		_light_social_app.refresh_dating_card()

func _on_pass() -> void:
	if _light_social_app and _light_social_app.has_method("on_pass"):
		_light_social_app.on_pass()

func _on_like() -> void:
	if _light_social_app and _light_social_app.has_method("on_like"):
		_light_social_app.on_like()

func _on_close_dating() -> void:
	if _light_social_app and _light_social_app.has_method("close_dating"):
		_light_social_app.close_dating()


# ==================== BOSS弯聘App ====================

func _get_job_name(level: int = GameManager.job_level) -> String:
	if _career_app and _career_app.has_method("get_job_name"):
		return str(_career_app.get_job_name(level))
	return ""


func _get_degree_name(level: int = GameManager.degree) -> String:
	if _career_app and _career_app.has_method("get_degree_name"):
		return str(_career_app.get_degree_name(level))
	return ""


func _is_weekend_phase() -> bool:
	if _career_app and _career_app.has_method("is_weekend_phase"):
		return bool(_career_app.is_weekend_phase())
	return false


func _career_action_lock_reason(energy_cost: int) -> String:
	if _career_app and _career_app.has_method("career_action_lock_reason"):
		return str(_career_app.career_action_lock_reason(energy_cost))
	return "职业系统尚未就绪"


func _spend_career_action(label: String, energy_cost: int, sanity_cost: int) -> bool:
	if _career_app and _career_app.has_method("spend_career_action"):
		return bool(_career_app.spend_career_action(label, energy_cost, sanity_cost))
	return false


func _media_lock_reason() -> String:
	if _career_app and _career_app.has_method("media_lock_reason"):
		return str(_career_app.media_lock_reason())
	return "职业系统尚未就绪"


func _client_lock_reason() -> String:
	if _career_app and _career_app.has_method("client_lock_reason"):
		return str(_career_app.client_lock_reason())
	return "职业系统尚未就绪"


func _on_app_job() -> void:
	if _career_app and _career_app.has_method("open_job_app"):
		_career_app.open_job_app()

func _on_job_admin() -> void:
	if _career_app and _career_app.has_method("on_job_admin"):
		_career_app.on_job_admin()

func _on_job_media() -> void:
	if _career_app and _career_app.has_method("on_job_media"):
		_career_app.on_job_media()

func _on_job_client() -> void:
	if _career_app and _career_app.has_method("on_job_client"):
		_career_app.on_job_client()


# ==================== 日记本 UI ====================

func _setup_diary_heavy_ui() -> void:
	if _diary_app and _diary_app.has_method("setup_heavy_ui"):
		_diary_app.setup_heavy_ui()


func _on_diary_filter(category: String) -> void:
	if _diary_app and _diary_app.has_method("on_filter"):
		_diary_app.on_filter(category)


func _refresh_diary_ui() -> void:
	if _diary_app and _diary_app.has_method("refresh_ui"):
		_diary_app.refresh_ui()

# ==================== 深夜网抑云失眠系统 ====================

## 进入深夜失眠弹窗（随机抽取一种冲动消费作为诱惑）
func _enter_late_night() -> void:
	if _consumer_app and _consumer_app.has_method("enter_late_night"):
		_consumer_app.enter_late_night()

func _on_emo_bag() -> void:
	if _consumer_app and _consumer_app.has_method("on_emo_bag"):
		_consumer_app.on_emo_bag()

func _on_emo_sleep() -> void:
	if _consumer_app and _consumer_app.has_method("on_emo_sleep"):
		_consumer_app.on_emo_sleep()
