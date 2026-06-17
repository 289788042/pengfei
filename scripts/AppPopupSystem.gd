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
var btn_food_low: Button
var btn_food_mid: Button
var btn_food_high: Button
var btn_work_normal: Button
var btn_work_slack: Button
var btn_work_overtime: Button
var btn_emo_bag: Button
var btn_emo_sleep: Button

# 日记本过滤
var _diary_filter: String = "全部"
var _diary_filter_buttons: Dictionary = {}
var _diary_summary_label: Label
var _heavy_app_layers: Array = []
# 深夜失眠：当前抽中的冲动消费选项
var _pending_impulse: Dictionary = {}
# 冲动消费选项池
var _impulse_pool: Array = [
	{"text": "被直播间洗脑，分期拿下轻奢包包 (花呗+5000, 情绪+40)", "huabei": 5000, "sanity": 40, "charm": 0, "desc": "深夜失眠，被直播间洗脑分期买了轻奢包"},
	{"text": "深夜emo，疯狂网购一堆无用盲盒 (花呗+800, 情绪+15)", "huabei": 800, "sanity": 15, "charm": 0, "desc": "深夜emo，疯狂网购了一堆无用盲盒"},
	{"text": "刷到前任秀恩爱，怒点昂贵医美套餐 (花呗+10000, 颜值+10, 情绪+30)", "huabei": 10000, "sanity": 30, "charm": 10, "desc": "深夜刷到前任秀恩爱，怒点昂贵医美套餐"},
]
# 滑动交友：随机名字池
var _dating_names: Array = [
	"王大壮", "李富贵", "张天宇", "赵子龙", "刘星",
	"陈浩南", "周杰", "吴彦组", "孙小宝", "马赛克",
	"钱多多", "郑经", "冯提莫", "何老师", "罗永亮",
]
# 滑动交友：随机签名池
var _dating_bios: Array = [
	"身高180，腹肌，寻找有趣的灵魂",
	"币圈创业中，懂的来",
	"有车有房，就缺一个你",
	"年入百万，但不想透露太多",
	"健身爱好者，每天打卡",
	"文艺青年，喜欢旅行和咖啡",
	"程序员，头发还在",
	"海归硕士，寻找真爱",
	"热爱生活，阳光向上",
	"不是渣男，真的不是",
	"月入5k但很有上进心",
	"佛系男，随缘吧",
	"创业合伙人，带你飞",
	"摄影师，只拍女朋友",
	"摩托车爱好者，带你兜风",
]
# 城市碎片事件池
var _city_fragments: Dictionary = {}
# NPC邂逅冷却（替代永久失败的 encounter_failed_ids）
var _encounter_cooldowns: Dictionary = {}  # npc_id -> turn_count 可重试
var _park_visited_week: int = -999
var _frag_choice_container: VBoxContainer = null
var _pending_fragment_base_changes: Dictionary = {}
var _pending_fragment_applied_changes: Dictionary = {}
var _location_event_hold_count: int = 0
# NPC重逢台词模板
var _reunion_lines: Array = [
	"在{loc}又遇到了{name}，ta冲你笑了笑。你们聊了几句。",
	"{name}看到你，主动走了过来打招呼。",
	"远远看到{name}在做自己的事，你过去打了个招呼。",
	"和{name}撞了个正着，两个人都笑了。",
	"{name}递给你一瓶水，说看你气色不太好。",
	"你帮{name}捡起了掉在地上的东西，ta说了声谢谢。",
	"和{name}聊起了最近的工作，ta给了你一些建议。",
	"今天在{loc}和{name}待了会儿，感觉心情好了不少。",
	"{name}请你喝了一杯东西，你们聊得很开心。",
	"碰巧和{name}坐在了一起，度过了愉快的一段时光。",
	"{name}给你看了看ta手机上的照片，最近去了不少地方。",
	"你和{name}交换了对某个话题的看法，聊得很投机。",
	"{name}看起来心情不错，说最近发生了点好事。",
	"你们聊起了深圳的生活，{name}说已经习惯了。",
	"和{name}告别的时候，ta说下次再约。",
	"{name}夸你今天看起来气色不错，你心里美滋滋的。",
]


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
	btn_food_low = main.btn_food_low
	btn_food_mid = main.btn_food_mid
	btn_food_high = main.btn_food_high
	btn_work_normal = main.btn_work_normal
	btn_work_slack = main.btn_work_slack
	btn_work_overtime = main.btn_work_overtime
	btn_emo_bag = main.btn_emo_bag
	btn_emo_sleep = main.btn_emo_sleep
	_setup_phone_app_layers()
	_setup_diary_heavy_ui()

	# 加载城市碎片事件
	var frag_file = FileAccess.open("res://Data/city_fragments.json", FileAccess.READ)
	if frag_file:
		var json = JSON.new()
		if json.parse(frag_file.get_as_text()) == OK:
			_city_fragments = json.data
		frag_file.close()


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
	GameManager.stats_updated.emit()
	if is_instance_valid(_main) and _main.has_method("_refresh_ui"):
		_main._refresh_ui()


func _remove_colored_result_segments(line: String) -> String:
	var cleaned := line
	var start := cleaned.find("[color=")
	while start >= 0:
		var end := cleaned.find("[/color]", start)
		if end < 0:
			break
		cleaned = (cleaned.substr(0, start) + cleaned.substr(end + 8)).strip_edges()
		start = cleaned.find("[color=")
	return cleaned


func _strip_embedded_result_lines(text: String) -> String:
	var kept: Array = []
	for line in text.split("\n"):
		if line.find("[color=90EE90]") >= 0 or line.find("[color=E88080]") >= 0 or line.find("[color=red]") >= 0:
			var cleaned_line := _remove_colored_result_segments(line)
			if cleaned_line != "":
				kept.append(cleaned_line)
			continue
		kept.append(line)
	return "\n".join(kept).strip_edges()


func _format_result(changes: Dictionary, title: String = "【结算】") -> String:
	if is_instance_valid(_main) and _main.has_method("format_stat_result"):
		return _main.format_stat_result(changes, title)
	var parts: Array = []
	for stat_name in changes:
		var val: int = int(changes[stat_name])
		if val == 0:
			continue
		var cn: String = GameManager.stat_names.get(stat_name, stat_name)
		if val > 0:
			parts.append("%s +%d" % [cn, val])
		else:
			parts.append("%s %d" % [cn, val])
	return "" if parts.is_empty() else title + "\n" + "  ".join(parts)


func _format_npc_result(changes: Dictionary, npc_name: String, title: String = "【结算】") -> String:
	var text := _format_result(changes, title)
	if npc_name.strip_edges() == "" or not changes.has("affection"):
		return text
	return text.replace("好感 ", "%s好感 " % npc_name)


func _show_result(result_text: String, after: Callable = Callable()) -> void:
	var clean_text := result_text.strip_edges()
	if clean_text != "" and not clean_text.begins_with("【"):
		clean_text = "【结算】\n" + clean_text
	if is_instance_valid(_main) and _main.has_method("show_result_text"):
		_main.show_result_text(clean_text, after)
		return
	if clean_text != "":
		main_node().galgame.show_galgame_dialog([clean_text], after)
	elif after.is_valid():
		after.call()


func _begin_location_event() -> void:
	_location_event_hold_count += 1
	var gal: RefCounted = main_node().galgame
	if gal and gal.has_method("hold_location_bg"):
		gal.hold_location_bg()


func _end_location_event() -> void:
	if _location_event_hold_count <= 0:
		return
	_location_event_hold_count -= 1
	var gal: RefCounted = main_node().galgame
	if gal and gal.has_method("release_location_bg"):
		gal.release_location_bg()
	elif main_node().has_method("return_to_home_environment"):
		main_node().return_to_home_environment("location_event_end")


func _finish_location_event_after(after: Callable = Callable()) -> Callable:
	return func() -> void:
		if after.is_valid():
			after.call()
		_end_location_event()


func _show_story_then_result(story_text: String, result_text: String, after: Callable = Callable()) -> void:
	var clean_story := _strip_embedded_result_lines(story_text)
	if clean_story != "":
		main_node().galgame.show_galgame_dialog([clean_story], func() -> void:
			_show_result(result_text, after)
		)
	else:
		_show_result(result_text, after)


func _show_story_then_changes(story_text: String, changes: Dictionary, after: Callable = Callable(), title: String = "【结算】") -> void:
	_show_story_then_result(story_text, _format_result(changes, title), after)


func _show_story_then_apply_changes(story_text: String, pending_changes: Dictionary, already_applied_changes: Dictionary = {}, after: Callable = Callable(), title: String = "【结算】") -> void:
	var clean_story := _strip_embedded_result_lines(story_text)
	var safe_pending_changes := _drop_unbound_affection(pending_changes)
	var show_and_apply := func() -> void:
		var display_changes := _merge_change_dicts(already_applied_changes, safe_pending_changes)
		_show_result(_format_result(display_changes, title), func() -> void:
			_apply_location_changes(safe_pending_changes)
			if after.is_valid():
				after.call()
		)
	if clean_story != "":
		main_node().galgame.show_galgame_dialog([clean_story], show_and_apply)
	else:
		show_and_apply.call()


func _show_story_then_apply_npc_changes(story_text: String, pending_changes: Dictionary, already_applied_changes: Dictionary, npc_name: String, after: Callable = Callable(), title: String = "【结算】", npc_id: String = "", npc_pending_changes: Dictionary = {}) -> void:
	var clean_story := _strip_embedded_result_lines(story_text)
	var safe_pending_changes := _drop_unbound_affection(pending_changes)
	var safe_npc_changes := _drop_unbound_affection(npc_pending_changes, npc_id)
	var show_and_apply := func() -> void:
		var pending_display := _merge_change_dicts(safe_npc_changes, safe_pending_changes)
		var display_changes := _merge_change_dicts(already_applied_changes, pending_display)
		_show_result(_format_npc_result(display_changes, npc_name, title), func() -> void:
			if safe_npc_changes.size() > 0:
				_apply_npc_bonus_changes(npc_id, safe_npc_changes)
			_apply_location_changes(safe_pending_changes)
			if after.is_valid():
				after.call()
		)
	if clean_story != "":
		main_node().galgame.show_galgame_dialog([clean_story], show_and_apply)
	else:
		show_and_apply.call()


func _show_location_result(location: String, fallback_text: String, changes: Dictionary, after: Callable = Callable()) -> void:
	var story := GameManager.get_location_narrative(location, fallback_text)
	_show_story_then_result(story, _format_result(changes), after)


func _action_service():
	if is_instance_valid(_main):
		return main_node().get("action_service")
	return null


func _show_action_result(story_text: String, changes: Dictionary, after: Callable = Callable()) -> void:
	var service = _action_service()
	if service and service.has_method("show_deferred_action_result"):
		service.show_deferred_action_result(story_text, changes, after)
	else:
		_show_story_then_apply_changes(story_text, changes, {}, after)


# ==================== 地图/地点 ====================

func _on_close_loc() -> void:
	_set_layer_visible(location_menu, false)


func _on_app_map() -> void:
	if not _can_open_phone_app():
		return
	if not _ensure_app_unlocked("map"):
		return
	_close_all_menus()
	_restore_map_to_phone_layer()
	for child in location_menu.get_children():
		child.queue_free()

	var outer := MarginContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 10)
	outer.add_theme_constant_override("margin_top", 28)
	outer.add_theme_constant_override("margin_right", 10)
	outer.add_theme_constant_override("margin_bottom", 10)
	location_menu.add_child(outer)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_flat_style(Color(0.955, 0.980, 0.965, 1), Color(0.42, 0.62, 0.54, 0.45), 1, 13))
	outer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 7)
	vbox.add_child(header_row)

	var app_mark := PanelContainer.new()
	app_mark.custom_minimum_size = Vector2(34, 34)
	app_mark.add_theme_stylebox_override("panel", _make_flat_style(Color(0.08, 0.55, 0.43, 1), Color(1, 1, 1, 0.10), 1, 9))
	header_row.add_child(app_mark)

	var app_mark_label := Label.new()
	app_mark_label.text = "高"
	app_mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app_mark_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	app_mark_label.add_theme_font_size_override("font_size", 18)
	app_mark_label.add_theme_color_override("font_color", Color.WHITE)
	app_mark.add_child(app_mark_label)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 0)
	header_row.add_child(title_box)

	var title_lbl := Label.new()
	title_lbl.text = "高德地图"
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", Color(0.05, 0.18, 0.15, 1))
	title_box.add_child(title_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "深圳 · 周末路线"
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.add_theme_font_size_override("font_size", 10)
	status_lbl.add_theme_color_override("font_color", Color(0.34, 0.48, 0.43, 1))
	title_box.add_child(status_lbl)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(34, 34)
	_style_text_button(close_btn, Color(0.80, 0.90, 0.85, 1), Color(0.70, 0.84, 0.77, 1), Color(0.05, 0.25, 0.20, 1))
	close_btn.pressed.connect(_on_close_loc)
	header_row.add_child(close_btn)

	vbox.add_child(_make_map_route_summary())

	var metric_row := HBoxContainer.new()
	metric_row.add_theme_constant_override("separation", 5)
	vbox.add_child(metric_row)
	metric_row.add_child(_make_map_metric_chip("精力", "%d/%d" % [GameManager.energy, GameManager.max_energy], Color(0.08, 0.55, 0.35, 1)))
	metric_row.add_child(_make_map_metric_chip("现金", str(GameManager.money), Color(0.17, 0.39, 0.78, 1)))
	metric_row.add_child(_make_map_metric_chip("花呗", str(GameManager.huabei_debt + GameManager.huabei_installment_debt), Color(0.78, 0.24, 0.22, 1)))

	var section_row := HBoxContainer.new()
	section_row.add_theme_constant_override("separation", 6)
	vbox.add_child(section_row)

	var section_lbl := Label.new()
	section_lbl.text = "附近地点"
	section_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_lbl.add_theme_font_size_override("font_size", 13)
	section_lbl.add_theme_color_override("font_color", Color(0.08, 0.20, 0.17, 1))
	section_row.add_child(section_lbl)

	var count_lbl := Label.new()
	count_lbl.text = _map_available_count_text()
	count_lbl.add_theme_font_size_override("font_size", 10)
	count_lbl.add_theme_color_override("font_color", Color(0.35, 0.48, 0.43, 1))
	section_row.add_child(count_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var loc_list := VBoxContainer.new()
	loc_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loc_list.add_theme_constant_override("separation", 7)
	scroll.add_child(loc_list)

	for location_id: String in _map_location_order():
		_add_small_map_location_button(loc_list, location_id)

	_set_layer_visible(location_menu, true)


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


func _map_location_order() -> Array[String]:
	return ["library", "gym", "bar", "home", "park", "cafe", "market", "overtime"]


func _add_small_map_location_button(parent: VBoxContainer, location_id: String) -> void:
	var config := _location_config(location_id)
	if config.is_empty():
		return
	var state := _map_location_state(location_id, config)
	var can_go := bool(state.get("can_go", false))
	var req_text := _map_requirement_summary(config)
	var meta := _map_location_meta(location_id)
	var accent_color: Color = meta.get("color", Color(0.12, 0.48, 0.40, 1))

	var card := PanelContainer.new()
	card.name = "MapCard_" + location_id
	card.custom_minimum_size = Vector2(0, 104 if req_text == "无" else 122)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.tooltip_text = "点击前往%s" % str(config.get("name", location_id)) if can_go else "点击查看不能前往的原因"
	var card_bg := Color(1, 1, 1, 0.96) if can_go else Color(0.92, 0.94, 0.93, 0.94)
	card.add_theme_stylebox_override("panel", _make_flat_style(card_bg, Color(0.70, 0.82, 0.76, 0.70), 1, 11))
	parent.add_child(card)
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			card.accept_event()
			_activate_map_location(location_id, can_go, config)
	)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 8)
	card_margin.add_theme_constant_override("margin_right", 8)
	card_margin.add_theme_constant_override("margin_top", 8)
	card_margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(card_margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card_margin.add_child(row)

	var marker := PanelContainer.new()
	marker.custom_minimum_size = Vector2(34, 34)
	marker.add_theme_stylebox_override("panel", _make_flat_style(accent_color, accent_color.darkened(0.05), 1, 999))
	row.add_child(marker)

	var marker_label := Label.new()
	marker_label.text = str(meta.get("mark", "去"))
	marker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker_label.add_theme_font_size_override("font_size", 14)
	marker_label.add_theme_color_override("font_color", Color.WHITE)
	marker.add_child(marker_label)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 2)
	row.add_child(body)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 5)
	body.add_child(top_row)

	var name_lbl := Label.new()
	name_lbl.text = str(config.get("name", location_id))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.06, 0.17, 0.15, 1))
	top_row.add_child(name_lbl)
	top_row.add_child(_make_map_tag(str(state.get("text", "")), state.get("bg", Color(0.50, 0.50, 0.50, 1)), state.get("fg", Color.WHITE)))

	var note_lbl := Label.new()
	note_lbl.text = "%s · %s" % [str(meta.get("role", "地点")), str(meta.get("note", ""))]
	note_lbl.add_theme_font_size_override("font_size", 10)
	note_lbl.add_theme_color_override("font_color", Color(0.35, 0.45, 0.41, 1))
	note_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body.add_child(note_lbl)

	_add_small_map_line(body, "消耗", _map_cost_summary(location_id, config), Color(0.55, 0.25, 0.18, 1))
	_add_small_map_line(body, "收益", _map_change_summary(config.get("changes", {}), true, location_id), Color(0.08, 0.42, 0.30, 1))
	if req_text != "无":
		_add_small_map_line(body, "条件", req_text, Color(0.56, 0.42, 0.14, 1))

	var action_btn := Button.new()
	action_btn.name = "LocBtn_" + location_id
	action_btn.text = "去" if can_go else "原因"
	action_btn.custom_minimum_size = Vector2(50, 34)
	action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if can_go:
		_style_text_button(action_btn, Color(0.08, 0.55, 0.43, 1), Color(0.10, 0.64, 0.50, 1), Color.WHITE)
	else:
		_style_text_button(action_btn, Color(0.72, 0.76, 0.74, 1), Color(0.80, 0.84, 0.82, 1), Color(0.12, 0.18, 0.16, 1))
	row.add_child(action_btn)

	action_btn.pressed.connect(func() -> void:
		_activate_map_location(location_id, can_go, config)
	)


func _activate_map_location(location_id: String, can_go: bool, config: Dictionary) -> void:
	if can_go:
		_start_location(location_id)
	else:
		_can_start_location(location_id, config)


func _make_map_route_summary() -> PanelContainer:
	var route := PanelContainer.new()
	route.custom_minimum_size = Vector2(0, 48)
	route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route.add_theme_stylebox_override("panel", _make_flat_style(Color(0.86, 0.95, 0.90, 1), Color(0.42, 0.68, 0.55, 0.55), 1, 11))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	route.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)

	var title := Label.new()
	title.text = "从城中村出租屋出发"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.05, 0.24, 0.18, 1))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "点卡片或右侧按钮前往，事件结算后回家。"
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color(0.28, 0.42, 0.36, 1))
	box.add_child(sub)
	return route


func _make_map_metric_chip(title: String, value: String, accent: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 42)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_theme_stylebox_override("panel", _make_flat_style(Color(1, 1, 1, 0.92), accent.lightened(0.32), 1, 9))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	chip.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	margin.add_child(box)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 9)
	title_lbl.add_theme_color_override("font_color", Color(0.38, 0.48, 0.44, 1))
	box.add_child(title_lbl)

	var value_lbl := Label.new()
	value_lbl.text = value
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	value_lbl.add_theme_font_size_override("font_size", 12)
	value_lbl.add_theme_color_override("font_color", accent.darkened(0.05))
	box.add_child(value_lbl)
	return chip


func _map_available_count_text() -> String:
	var total := 0
	var available := 0
	for location_id: String in _map_location_order():
		var config := _location_config(location_id)
		if config.is_empty():
			continue
		total += 1
		if bool(_map_location_state(location_id, config).get("can_go", false)):
			available += 1
	return "可前往 %d/%d" % [available, total]


func _map_location_meta(location_id: String) -> Dictionary:
	for item: Dictionary in _map_location_defs():
		if str(item.get("id", "")) == location_id:
			var meta := item.duplicate()
			if not meta.has("mark"):
				meta["mark"] = _map_location_mark(location_id)
			return meta
	return {
		"id": location_id,
		"color": Color(0.12, 0.48, 0.40, 1),
		"role": "地点",
		"note": "周末行动",
		"mark": _map_location_mark(location_id),
	}


func _map_location_mark(location_id: String) -> String:
	match location_id:
		"library":
			return "书"
		"gym":
			return "练"
		"bar":
			return "酒"
		"home":
			return "宅"
		"park":
			return "园"
		"cafe":
			return "咖"
		"market":
			return "夜"
		"overtime":
			return "班"
	return "去"


func _make_map_tag(text: String, bg: Color, fg: Color) -> PanelContainer:
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", _make_flat_style(bg, Color(1, 1, 1, 0.16), 1, 999))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	tag.add_child(margin)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", fg)
	margin.add_child(label)
	return tag


func _add_small_map_line(parent: VBoxContainer, label_text: String, value_text: String, color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(30, 0)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", color)
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	value.add_theme_font_size_override("font_size", 10)
	value.add_theme_color_override("font_color", color)
	row.add_child(value)


func _map_location_defs() -> Array:
	return [
		{"id": "library", "color": Color(0.18, 0.42, 0.78, 1), "role": "成长", "note": "低成本提升学识"},
		{"id": "gym", "color": Color(0.15, 0.62, 0.33, 1), "role": "成长", "note": "颜值与精力上限"},
		{"id": "bar", "color": Color(0.48, 0.30, 0.70, 1), "role": "社交", "note": "高消费换情绪与情商"},
		{"id": "home", "color": Color(0.42, 0.47, 0.50, 1), "role": "恢复", "note": "便宜回血但消耗精力"},
		{"id": "park", "color": Color(0.08, 0.58, 0.40, 1), "role": "恢复", "note": "每周一次的免费散心"},
		{"id": "cafe", "color": Color(0.54, 0.34, 0.18, 1), "role": "成长", "note": "学识与情商的均衡点"},
		{"id": "market", "color": Color(0.82, 0.46, 0.10, 1), "role": "恢复", "note": "便宜情绪补给"},
		{"id": "overtime", "color": Color(0.26, 0.32, 0.66, 1), "role": "收入", "note": "高压换现金"},
	]


func _map_stat_name(stat_name: String) -> String:
	var extra_names := {
		"max_energy": "精力上限",
		"huabei_debt": "花呗欠款",
		"huabei_installment_debt": "花呗分期",
	}
	return GameManager.stat_names.get(stat_name, extra_names.get(stat_name, stat_name))


func _map_change_summary(changes: Dictionary, positive: bool, location: String = "") -> String:
	var parts: Array = []
	if positive and location == "overtime":
		parts.append("金钱 +500~800")
	for stat_name in changes:
		var key := str(stat_name)
		var amount := int(changes[stat_name])
		if amount == 0:
			continue
		if location == "overtime" and positive and key == "money":
			continue
		if positive and amount <= 0:
			continue
		if not positive and amount >= 0:
			continue
		var sign := "+" if amount > 0 else ""
		parts.append("%s %s%d" % [_map_stat_name(key), sign, amount])
	if parts.is_empty():
		return "无直接收益" if positive else "无直接消耗"
	return " / ".join(parts)


func _map_cost_summary(location: String, config: Dictionary) -> String:
	var parts: Array = []
	var payment_cost := int(config.get("payment_cost", 0))
	if payment_cost > 0:
		parts.append("现金 -%d（可花呗）" % payment_cost)
	var change_text := _map_change_summary(config.get("changes", {}), false, location)
	if change_text != "无直接消耗":
		parts.append(change_text)
	if parts.is_empty():
		return "无直接消耗"
	return " / ".join(parts)


func _map_requirement_summary(config: Dictionary) -> String:
	var parts: Array = []
	var req_stats: Dictionary = config.get("req_stats", {})
	for stat_name in req_stats:
		var key := str(stat_name)
		var needed := int(req_stats[stat_name])
		var current := int(GameManager.get(key))
		parts.append("%s≥%d（当前%d）" % [_map_stat_name(key), needed, current])
	if bool(config.get("once_per_week", false)):
		parts.append("每周一次")
	return "无" if parts.is_empty() else " / ".join(parts)


func _map_location_state(location: String, config: Dictionary) -> Dictionary:
	if not is_instance_valid(_main):
		return {"can_go": false, "text": "未就绪", "bg": Color(0.50, 0.50, 0.50, 1), "fg": Color.WHITE}
	if main_node().current_phase != main_node().Phase.WEEKEND:
		return {"can_go": false, "text": "仅周末", "bg": Color(0.58, 0.48, 0.36, 1), "fg": Color.WHITE}
	if bool(config.get("once_per_week", false)) and _park_visited_week == GameManager.turn_count:
		return {"can_go": false, "text": "本周已去", "bg": Color(0.58, 0.48, 0.36, 1), "fg": Color.WHITE}
	var energy_req := int(config.get("energy_req", 0))
	if energy_req > 0 and GameManager.energy < energy_req:
		return {"can_go": false, "text": "精力不足", "bg": Color(0.70, 0.22, 0.20, 1), "fg": Color.WHITE}
	var req_stats: Dictionary = config.get("req_stats", {})
	for stat_name in req_stats:
		var key := str(stat_name)
		var needed := int(req_stats[stat_name])
		var current := int(GameManager.get(key))
		if current < needed:
			return {"can_go": false, "text": "%s不足" % _map_stat_name(key), "bg": Color(0.70, 0.22, 0.20, 1), "fg": Color.WHITE}
	return {"can_go": true, "text": "可前往", "bg": Color(0.08, 0.53, 0.37, 1), "fg": Color.WHITE}


func _make_map_pill(text: String, bg: Color, fg: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _make_flat_style(bg, Color(1, 1, 1, 0.12), 1, 999))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	pill.add_child(margin)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", fg)
	margin.add_child(label)
	return pill


func _add_map_info_label(parent: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)


func _add_map_location_card(parent: VBoxContainer, loc: Dictionary) -> void:
	var location_id := str(loc.get("id", ""))
	var config := _location_config(location_id)
	if config.is_empty():
		return
	var state := _map_location_state(location_id, config)
	var can_go := bool(state.get("can_go", false))
	var accent_color: Color = loc.get("color", Color(0.20, 0.45, 0.40, 1))

	var card := PanelContainer.new()
	card.name = "MapCard_" + location_id
	card.custom_minimum_size = Vector2(0, 156)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_flat_style(Color(1, 1, 1, 1), Color(0.76, 0.86, 0.82, 1), 1, 11))
	parent.add_child(card)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 10)
	card_margin.add_theme_constant_override("margin_right", 10)
	card_margin.add_theme_constant_override("margin_top", 9)
	card_margin.add_theme_constant_override("margin_bottom", 9)
	card.add_child(card_margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	card_margin.add_child(row)

	var accent := PanelContainer.new()
	accent.custom_minimum_size = Vector2(7, 0)
	accent.add_theme_stylebox_override("panel", _make_flat_style(accent_color, accent_color, 0, 999))
	row.add_child(accent)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 5)
	row.add_child(body)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	body.add_child(top)

	var name_lbl := Label.new()
	name_lbl.text = config.get("name", location_id)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 19)
	name_lbl.add_theme_color_override("font_color", Color(0.10, 0.18, 0.16, 1))
	top.add_child(name_lbl)

	top.add_child(_make_map_pill(str(loc.get("role", config.get("category", "地点"))), accent_color.lightened(0.12), Color.WHITE))
	top.add_child(_make_map_pill(str(state.get("text", "")), state.get("bg", Color(0.50, 0.50, 0.50, 1)), state.get("fg", Color.WHITE)))

	var note_lbl := Label.new()
	note_lbl.text = str(loc.get("note", ""))
	note_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_lbl.add_theme_font_size_override("font_size", 14)
	note_lbl.add_theme_color_override("font_color", Color(0.32, 0.42, 0.38, 1))
	body.add_child(note_lbl)

	_add_map_info_label(body, "消耗：" + _map_cost_summary(location_id, config), Color(0.48, 0.24, 0.20, 1))
	_add_map_info_label(body, "收益：" + _map_change_summary(config.get("changes", {}), true, location_id), Color(0.10, 0.42, 0.30, 1))

	var req_text := _map_requirement_summary(config)
	if req_text != "无":
		_add_map_info_label(body, "条件：" + req_text, Color(0.42, 0.34, 0.16, 1))

	var action_btn := Button.new()
	action_btn.name = "LocBtn_" + location_id
	action_btn.text = "前往" if can_go else "查看原因"
	action_btn.custom_minimum_size = Vector2(96, 44)
	action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if can_go:
		_style_text_button(action_btn, Color(0.10, 0.52, 0.42, 1), Color(0.12, 0.62, 0.50, 1), Color.WHITE)
	else:
		_style_text_button(action_btn, Color(0.72, 0.75, 0.72, 1), Color(0.80, 0.82, 0.80, 1), Color(0.10, 0.18, 0.16, 1))
	row.add_child(action_btn)

	action_btn.pressed.connect(func() -> void:
		if can_go:
			_start_location(location_id)
		else:
			_can_start_location(location_id, config)
	)


func _close_all_menus() -> void:
	for m in [location_menu, baotao_menu, tuanmei_menu, zodiac_popup, house_menu, dating_popup, job_menu, diary_popup, late_night_popup]:
		if is_instance_valid(m):
			_set_layer_visible(m, false)


func _on_app_diary() -> void:
	if not _can_open_phone_app():
		return
	if not _ensure_app_unlocked("diary"):
		return
	_close_all_menus()
	_refresh_diary_ui()
	_set_layer_visible(diary_popup, true)


func _on_app_baotao() -> void:
	if not _can_open_phone_app():
		return
	if not _ensure_app_unlocked("baotao"):
		return
	_close_all_menus()
	for child in baotao_menu.get_children():
		child.queue_free()
	var debt_info := "花呗欠款：%d 元" % (GameManager.huabei_debt + GameManager.huabei_installment_debt)
	var items := [
		{"name": "大牌护肤套装", "icon_color": Color(0.95, 0.45, 0.6), "cost": "800 元 | +5颜值 +5情绪", "action": _on_bt_skincare, "close_on_action": false},
		{"name": "快时尚穿搭", "icon_color": Color(0.3, 0.7, 0.9), "cost": "1500 元 | +8颜值 +10情绪", "action": _on_bt_fashion, "close_on_action": false},
	]
	_build_app_overlay(baotao_menu, "宝淘", Color(0.95, 0.35, 0.35, 1), debt_info, items)
	_set_layer_visible(baotao_menu, true)


func _on_app_tuanmei() -> void:
	if not _can_open_phone_app():
		return
	if not _ensure_app_unlocked("tuanmei"):
		return
	_close_all_menus()
	for child in tuanmei_menu.get_children():
		child.queue_free()
	var debt_info := "花呗欠款：%d 元" % (GameManager.huabei_debt + GameManager.huabei_installment_debt)
	var items := [
		{"name": "水光针+热玛吉", "icon_color": Color(0.8, 0.4, 0.8), "cost": "6000 元 | +15颜值 | 需颜值<30", "action": _on_tm_injection, "close_on_action": false},
		{"name": "全脸微调手术", "icon_color": Color(0.6, 0.2, 0.8), "cost": "20000 元 | +30颜值 | 需颜值<20", "action": _on_tm_surgery, "close_on_action": false},
	]
	_build_app_overlay(tuanmei_menu, "团美医美", Color(0.6, 0.3, 0.8, 1), debt_info, items)
	_set_layer_visible(tuanmei_menu, true)


func _on_app_zodiac() -> void:
	if not _can_open_phone_app():
		return
	if not _ensure_app_unlocked("zodiac"):
		return
	_close_all_menus()
	label_zodiac_content.text = "亲爱的%s宝宝，本周运势：\n请注意控制消费，警惕烂桃花哦！" % GameManager.player_zodiac
	_set_layer_visible(zodiac_popup, true)


func _on_app_house() -> void:
	if not _can_open_phone_app():
		return
	if not _ensure_app_unlocked("house"):
		return
	_close_all_menus()
	for child in house_menu.get_children():
		child.queue_free()
	var housing_names: Array = ["城中村单间", "精装一居室", "CBD大平层"]
	var house_name: String = housing_names[GameManager.housing_level]
	var status := "当前住房：%s (月租 %d) | 押金=2个月房租" % [house_name, GameManager.base_rent]
	var deposits: Array = [3000, 8000, 24000]
	var rents: Array = [1500, 4000, 12000]
	var items := []
	for i in range(3):
		var is_current: bool = (GameManager.housing_level == i)
		var deposit: int = deposits[i]
		var can_afford: bool = GameManager.money >= deposit
		var item := {
			"name": housing_names[i],
			"icon_color": Color(0.2 + i * 0.3, 0.6, 0.9 - i * 0.3),
			"cost": "月租 %d | 押金 %d" % [rents[i], deposit],
			"current": is_current,
		}
		if not is_current and not can_afford:
			item["locked"] = true
			item["lock_reason"] = "押金不足（需 %d，当前余额 %d）" % [deposit, GameManager.money]
		elif not is_current:
			item["action"] = [_on_house_village, _on_house_apartment, _on_house_luxury][i]
		items.append(item)
	_build_app_overlay(house_menu, "贝壳找房", Color(0.15, 0.6, 0.7, 1), status, items)
	_set_layer_visible(house_menu, true)


func _on_app_dating() -> void:
	if not _can_open_phone_app():
		return
	if not _ensure_app_unlocked("dating"):
		return
	_close_all_menus()
	if GameManager.charm < 10:
		main_node().show_message("颜值太低（需>=10），没有匹配对象！先提升自己吧~")
		return
	_refresh_dating_card()
	_set_layer_visible(dating_popup, true)


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

## 从指定地点的碎片池中随机抽取一条并触发
func _trigger_city_fragment(location: String, base_changes: Dictionary = {}, already_applied_changes: Dictionary = {}) -> void:
	var pool: Array = _city_fragments.get(location, [])
	if pool.size() == 0:
		return
	var filtered: Array = []
	for f in pool:
		if f.get("min_turn", 0) <= GameManager.turn_count:
			filtered.append(f)
	if filtered.size() == 0:
		filtered = pool
	var frag: Dictionary = filtered[randi() % filtered.size()]
	var text: String = frag.get("text", "")
	text = _strip_embedded_result_lines(text)
	# 检查是否带选项
	var choices: Array = frag.get("choices", [])
	if choices.size() > 0:
		var pages: Array = [text]
		main_node().galgame.show_galgame_dialog(pages, func() -> void:
			_show_fragment_choices(choices, base_changes, already_applied_changes)
		)
		return
	var effects: Dictionary = frag.get("effect", {})
	var pending_changes := _merge_change_dicts(base_changes, effects)
	_show_story_then_apply_changes(text, pending_changes, already_applied_changes, _finish_location_event_after())


## 显示碎片选项按钮
func _show_fragment_choices(choices: Array, base_changes: Dictionary = {}, already_applied_changes: Dictionary = {}) -> void:
	var gal: RefCounted = main_node().galgame
	var box: Panel = gal.left_dialog_box
	box.visible = true
	box.modulate.a = 1.0
	_pending_fragment_base_changes = base_changes.duplicate()
	_pending_fragment_applied_changes = already_applied_changes.duplicate()
	gal.left_dialog_text.text = ""
	gal.left_dialog_text.visible = false
	# 禁用下一周按钮防止跳过
	_set_next_week_locked(true)
	if is_instance_valid(_frag_choice_container):
		_frag_choice_container.queue_free()
	_frag_choice_container = VBoxContainer.new()
	_frag_choice_container.name = "FragChoiceContainer"
	_frag_choice_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frag_choice_container.offset_left = 20
	_frag_choice_container.offset_top = 12
	_frag_choice_container.offset_right = -16
	_frag_choice_container.offset_bottom = -12
	_frag_choice_container.add_theme_constant_override("separation", 8)
	box.add_child(_frag_choice_container)
	for choice in choices:
		var btn := Button.new()
		btn.text = choice.get("text", "...")
		btn.add_theme_font_size_override("font_size", 20)
		btn.custom_minimum_size.y = 48
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.2, 0.85)
		style.set_corner_radius_all(10.0)
		style.set_content_margin_all(12)
		style.border_color = Color(0.5, 0.5, 0.6, 0.6)
		style.set_border_width_all(1)
		btn.add_theme_stylebox_override("normal", style)
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.25, 0.28, 0.38, 0.92)
		hover_style.set_corner_radius_all(10.0)
		hover_style.set_content_margin_all(12)
		hover_style.border_color = Color(0.7, 0.75, 0.9, 0.8)
		hover_style.set_border_width_all(1)
		btn.add_theme_stylebox_override("hover", hover_style)
		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.3, 0.35, 0.5, 0.95)
		pressed_style.set_corner_radius_all(10.0)
		pressed_style.set_content_margin_all(12)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		var cost: Dictionary = choice.get("cost", {})
		var cost_money: int = int(cost.get("money", 0))
		if cost_money > 0 and GameManager.money < cost_money:
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 0.7))
			var dis_style := StyleBoxFlat.new()
			dis_style.bg_color = Color(0.1, 0.1, 0.12, 0.5)
			dis_style.set_corner_radius_all(10.0)
			dis_style.set_content_margin_all(12)
			btn.add_theme_stylebox_override("disabled", dis_style)
		else:
			btn.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95, 1))
		var captured_choice: Dictionary = choice
		btn.pressed.connect(func() -> void: _on_fragment_choice(captured_choice))
		_frag_choice_container.add_child(btn)


## 碎片选项回调：应用花费和效果，显示结果
func _on_fragment_choice(choice: Dictionary) -> void:
	var gal: RefCounted = main_node().galgame
	var result_changes: Dictionary = {}
	var cost: Dictionary = choice.get("cost", {})
	for stat_name in cost:
		var val: int = int(cost[stat_name])
		if val != 0:
			result_changes[stat_name] = int(result_changes.get(stat_name, 0)) - val
	var effects: Dictionary = choice.get("effect", {})
	for stat_name in effects:
		var val: int = int(effects[stat_name])
		if val == 0:
			continue
		result_changes[stat_name] = int(result_changes.get(stat_name, 0)) + val
	var pending_changes := _merge_change_dicts(_pending_fragment_base_changes, result_changes)
	var already_applied_changes := _pending_fragment_applied_changes.duplicate()
	# 清理选项按钮
	if is_instance_valid(_frag_choice_container):
		_frag_choice_container.queue_free()
		_frag_choice_container = null
	gal.left_dialog_text.visible = true
	# 显示结果
	var result: String = choice.get("result", "")
	_pending_fragment_base_changes.clear()
	_pending_fragment_applied_changes.clear()
	var after_result := func() -> void:
		_set_next_week_locked(false)
		_end_location_event()
	_show_story_then_apply_changes(result, pending_changes, already_applied_changes, after_result)


func _set_next_week_locked(locked: bool) -> void:
	var skip_btn: Button = main_node().get_node_or_null("HBoxContainer/RightMargin/RightSystemArea/Btn_NextWeek")
	if skip_btn:
		skip_btn.disabled = locked
	if not locked and main_node().has_method("sync_ui_state"):
		main_node().sync_ui_state()

## 检查是否有已解锁的NPC可以在该地点重逢
func _check_reunion(location: String) -> Dictionary:
	var candidates: Array = []
	for npc in GameManager.npc_database:
		var enc: Dictionary = npc.get("encounter", {})
		if enc.get("location", "") != location:
			continue
		if enc.get("auto_unlock", false):
			continue
		var npc_id: String = npc.get("id", "")
		if not GameManager.is_npc_unlocked(npc_id):
			continue
		if _has_seen_weekly_reunion(npc_id):
			continue
		candidates.append(npc)
	if candidates.size() == 0:
		return {}
	return candidates[randi() % candidates.size()]

## 处理NPC重逢（简短互动）
func _handle_reunion(npc: Dictionary, location: String) -> void:
	var npc_id: String = npc.get("id", "")
	var npc_name: String = npc.get("name", "")
	var loc_cn: String = {"gym": "健身房", "library": "图书馆", "bar": "酒吧", "home": "家里", "park": "公园", "cafe": "咖啡厅", "market": "夜市"}.get(location, location)
	var template: String = _reunion_lines[randi() % _reunion_lines.size()]
	var text: String = template.replace("{name}", npc_name).replace("{loc}", loc_cn)
	var changes := {"affection": 3, "sanity": 3, "eq": 1}
	GameManager.add_activity("社交", "在%s遇到了%s，聊了几句" % [loc_cn, npc_name])
	_show_story_then_apply_npc_changes(text, {}, {}, npc_name, _finish_location_event_after(), "【结算】", npc_id, changes)


# ==================== 废弃周末资源兼容接口 ====================

func _use_weekend_action(label: String = "weekend") -> bool:
	if main_node().get("action_service") and main_node().action_service.has_method("spend_weekend_action"):
		main_node().action_service.spend_weekend_action(label)
	return true


# ==================== 地点逻辑 ====================

## 每个地点的访问次数（用于首次判断）
var _loc_visit_count: Dictionary = {}
var _weekly_location_turn: int = -999
var _weekly_location_visits: Dictionary = {}
var _weekly_reunion_seen: Dictionary = {}

func _location_config(location: String) -> Dictionary:
	match location:
		"library":
			return {
				"name": "图书馆",
				"category": "提升",
				"energy_req": 20,
				"changes": {"energy": -20, "intellect": 3, "sanity": 5},
				"fallback": "在图书馆读了一下午。",
				"activity": "在图书馆读书，学识+3，情绪+5",
			}
		"gym":
			return {
				"name": "健身房",
				"category": "提升",
				"energy_req": 45,
				"payment_cost": 200,
				"payment_desc": "健身房消费",
				"changes": {"energy": -45, "charm": 2, "sanity": 5, "max_energy": 1},
				"fallback": "在健身房练到浑身发热。",
				"activity": "去健身房挥汗如雨，颜值+2，情绪+5，精力上限+1",
			}
		"bar":
			return {
				"name": "高档酒吧",
				"category": "社交",
				"energy_req": 30,
				"payment_cost": 500,
				"payment_desc": "酒吧消费",
				"req_stats": {"eq": 10},
				"changes": {"energy": -30, "eq": 2, "sanity": 25},
				"fallback": "在酒吧喝了一杯。",
				"activity": "在酒吧喝了一杯，情商+2，情绪+25",
			}
		"home":
			return {
				"name": "宅家刷手机",
				"category": "日常",
				"energy_req": 10,
				"changes": {"energy": -10, "sanity": 20},
				"fallback": "宅家刷了一整天手机。",
				"activity": "宅家刷了一整天手机，情绪+20",
			}
		"park":
			return {
				"name": "公园·深圳湾",
				"category": "日常",
				"once_per_week": true,
				"changes": {"energy": 10, "sanity": 3},
				"fallback": "在深圳湾吹了会儿海风。",
				"activity": "在公园·深圳湾散步，精力+10，情绪+3",
			}
		"cafe":
			return {
				"name": "咖啡厅",
				"category": "提升",
				"energy_req": 15,
				"payment_cost": 80,
				"payment_desc": "咖啡厅消费",
				"changes": {"energy": -15, "intellect": 2, "eq": 2},
				"fallback": "在咖啡厅坐了一下午。",
				"activity": "在咖啡厅学习，学识+2，情商+2",
			}
		"market":
			return {
				"name": "夜市·大排档",
				"category": "美食",
				"energy_req": 10,
				"payment_cost": 100,
				"payment_desc": "夜市消费",
				"changes": {"energy": -10, "sanity": 15},
				"fallback": "在夜市吃了点热乎东西。",
				"activity": "在夜市吃了夜宵，情绪+15",
			}
		"overtime":
			var overtime_pay: int = randi() % 300 + 500
			return {
				"name": "公司加班",
				"category": "工作",
				"energy_req": 40,
				"changes": {"energy": -40, "sanity": -35, "money": overtime_pay},
				"fallback": "办公室只剩你一个人。你熬到深夜，终于把这版方案交了出去。加班费到账：%d。",
				"format_value": overtime_pay,
				"activity": "公司加班，赚了%d元加班费" % overtime_pay,
			}
	return {}


## 获取地点邂逅背景图路径
func _get_encounter_bg(location: String) -> String:
	if location == "gym":
		_loc_visit_count["gym"] = _loc_visit_count.get("gym", 0) + 1
		if _loc_visit_count["gym"] == 1:
			return "res://Assets/Backgrounds/gym/Gym_bg_rain_morning.jpg"
		var gym_bgs: Array = [
			"res://Assets/Backgrounds/gym/Gym_bg_rain_morning.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_rain_night.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_sunny_morning.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_sunny_noon.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_sunny_evening.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_hazy_afternoon.jpg",
		]
		return gym_bgs[randi() % gym_bgs.size()]
	var bg_map: Dictionary = {
		"library": "res://Assets/Backgrounds/library/Bookshop_bg_day1.png",
	}
	return bg_map.get(location, "")


func _show_location_background(location: String) -> void:
	var bg_path := _get_encounter_bg(location)
	if bg_path != "":
		main_node().galgame.show_location_bg(bg_path)
	else:
		var env = main_node().get("environment")
		if env and env.has_method("show_location_color"):
			env.show_location_color(location)
		elif main_node().has_method("return_to_home_environment"):
			main_node().return_to_home_environment("location_without_bg")


## 检查指定地点是否有NPC邂逅
func _check_encounter(location: String) -> Dictionary:
	for npc in GameManager.npc_database:
		var enc: Dictionary = npc.get("encounter", {})
		if enc.get("location", "") != location:
			continue
		if enc.get("auto_unlock", false):
			continue
		var npc_id: String = npc.get("id", "")
		if GameManager.is_npc_unlocked(npc_id):
			continue
		if _encounter_cooldowns.get(npc_id, 0) > GameManager.turn_count:
			continue
		if not enc.get("first_visit_only", false):
			continue
		return npc
	return {}


func _meets_encounter_requirements(enc: Dictionary) -> bool:
	var req: Dictionary = enc.get("req_stats", {})
	for stat_name in req:
		var needed: int = int(req[stat_name])
		var current: int = GameManager.get(stat_name) if stat_name != "money" else GameManager.money
		if current < needed:
			return false
	return true


func _format_encounter_requirement_hint(enc: Dictionary) -> String:
	var req: Dictionary = enc.get("req_stats", {})
	if req.is_empty():
		return ""
	var parts: Array = []
	for stat_name in req:
		var needed: int = int(req[stat_name])
		var current: int = GameManager.get(stat_name) if stat_name != "money" else GameManager.money
		if current >= needed:
			continue
		var cn: String = GameManager.stat_names.get(stat_name, stat_name)
		parts.append("%s需要%d，当前%d" % [cn, needed, current])
	if parts.is_empty():
		return ""
	return "（邂逅条件不足：%s。）" % "；".join(parts)


func _ensure_weekly_location_state() -> void:
	if _weekly_location_turn == GameManager.turn_count:
		return
	_weekly_location_turn = GameManager.turn_count
	_weekly_location_visits.clear()
	_weekly_reunion_seen.clear()


func _get_weekly_location_visits(location: String) -> int:
	_ensure_weekly_location_state()
	return int(_weekly_location_visits.get(location, 0))


func _record_weekly_location_visit(location: String) -> void:
	_ensure_weekly_location_state()
	_weekly_location_visits[location] = int(_weekly_location_visits.get(location, 0)) + 1


func _has_seen_weekly_reunion(npc_id: String) -> bool:
	_ensure_weekly_location_state()
	return _weekly_reunion_seen.has(npc_id)


func _record_weekly_reunion(npc_id: String) -> void:
	if npc_id == "":
		return
	_ensure_weekly_location_state()
	_weekly_reunion_seen[npc_id] = true


func _location_repeat_scale(visit_index: int) -> float:
	if visit_index <= 0:
		return 1.0
	if visit_index == 1:
		return 0.5
	return 0.25


func _apply_location_repeat_decay(changes: Dictionary, visit_index: int) -> Dictionary:
	if visit_index <= 0:
		return changes.duplicate()
	var scale := _location_repeat_scale(visit_index)
	var tuned: Dictionary = {}
	var growth_stats := ["intellect", "eq", "charm", "max_energy"]
	for stat_name in changes:
		var amount := int(changes[stat_name])
		if amount == 0:
			continue
		var tuned_amount := amount
		var key := str(stat_name)
		if amount > 0 and growth_stats.has(key):
			tuned_amount = int(floor(float(amount) * scale))
		elif amount > 0 and (key == "sanity" or key == "energy"):
			tuned_amount = maxi(1, int(round(float(amount) * scale)))
		if tuned_amount != 0:
			tuned[stat_name] = tuned_amount
	return tuned


func _merge_change_dicts(base: Dictionary, extra: Dictionary) -> Dictionary:
	var merged := base.duplicate()
	for key in extra:
		var amount := int(extra[key])
		if amount == 0:
			continue
		merged[key] = int(merged.get(key, 0)) + amount
	for key in merged.keys():
		if int(merged[key]) == 0:
			merged.erase(key)
	return merged


func _drop_unbound_affection(changes: Dictionary, npc_id: String = "") -> Dictionary:
	var cleaned := changes.duplicate()
	if npc_id == "" and cleaned.has("affection"):
		cleaned.erase("affection")
	return cleaned


func _apply_location_changes(changes: Dictionary) -> Dictionary:
	var safe_changes := _drop_unbound_affection(changes)
	var service = _action_service()
	if service and service.has_method("apply_stat_changes"):
		return service.apply_stat_changes(safe_changes)
	var applied: Dictionary = {}
	for stat_name in safe_changes:
		var amount := int(safe_changes[stat_name])
		if amount == 0:
			continue
		match str(stat_name):
			"max_energy":
				GameManager.max_energy = maxi(GameManager.max_energy + amount, 1)
				GameManager.energy = clampi(GameManager.energy, 0, GameManager.max_energy)
			"weekend_actions":
				continue
			"credit_debt":
				GameManager.huabei_debt = maxi(GameManager.huabei_debt + amount, 0)
				GameManager.credit_debt = GameManager.huabei_debt
			_:
				GameManager.modify_stat(str(stat_name), amount)
		applied[stat_name] = int(applied.get(stat_name, 0)) + amount
	_refresh_main_ui()
	return applied


func _apply_npc_bonus_changes(npc_id: String, changes: Dictionary) -> Dictionary:
	var safe_changes := _drop_unbound_affection(changes, npc_id)
	var applied: Dictionary = {}
	for stat_name in safe_changes:
		var amount := int(safe_changes[stat_name])
		if amount == 0:
			continue
		if stat_name == "affection" and npc_id != "":
			if GameManager.is_npc_unlocked(npc_id):
				GameManager.add_npc_affection(npc_id, amount)
			else:
				GameManager.get_npc_runtime(npc_id)["affection"] += amount
		else:
			_apply_location_changes({stat_name: amount})
		applied[stat_name] = int(applied.get(stat_name, 0)) + amount
	_refresh_main_ui()
	return applied


func _location_story(location: String, config: Dictionary) -> String:
	var story := GameManager.get_location_narrative(location, config.get("fallback", ""))
	if config.has("format_value"):
		story = story % int(config["format_value"])
	return story


func _show_location_result_from_config(location: String, config: Dictionary, pending_changes: Dictionary, already_applied_changes: Dictionary = {}, after: Callable = Callable()) -> void:
	_show_story_then_apply_changes(_location_story(location, config), pending_changes, already_applied_changes, _finish_location_event_after(after))


func _can_start_location(location: String, config: Dictionary) -> bool:
	if not is_instance_valid(_main):
		return false
	if main_node().current_phase != main_node().Phase.WEEKEND:
		main_node().show_message("现在不是周末，不能安排地点行动。")
		return false
	if bool(config.get("once_per_week", false)) and _park_visited_week == GameManager.turn_count:
		main_node().show_message("这周已经去过深圳湾了，来回太远，下周再去吧。")
		return false
	var energy_req := int(config.get("energy_req", 0))
	if energy_req > 0 and GameManager.energy < energy_req:
		main_node().show_message("精力不足（需%d），无法前往%s。" % [energy_req, config.get("name", location)])
		return false
	var req_stats: Dictionary = config.get("req_stats", {})
	for stat_name in req_stats:
		var needed := int(req_stats[stat_name])
		var current := int(GameManager.get(stat_name))
		if current < needed:
			var cn: String = GameManager.stat_names.get(stat_name, stat_name)
			main_node().show_message("%s不足（需%d，当前%d），无法前往%s。" % [cn, needed, current, config.get("name", location)])
			return false
	return true


func _start_location(location: String) -> void:
	var config := _location_config(location)
	if config.is_empty():
		main_node().show_message("地点尚未配置：" + location)
		return
	if not _can_start_location(location, config):
		return
	_set_layer_visible(location_menu, false)
	var payment_cost := int(config.get("payment_cost", 0))
	if payment_cost > 0:
		main_node().alipay.request_payment(
			payment_cost,
			config.get("payment_desc", config.get("name", "地点消费")),
			config.get("category", "消费"),
			func() -> void:
				var payment_changes: Dictionary = main_node().alipay.get_last_payment_changes()
				_run_location_after_payment(location, config, payment_changes)
		)
	else:
		_run_location_after_payment(location, config, {})


func _run_location_after_payment(location: String, config: Dictionary, payment_changes: Dictionary) -> void:
	if not _use_weekend_action(config.get("name", location)):
		return
	if bool(config.get("once_per_week", false)):
		_park_visited_week = GameManager.turn_count
	_begin_location_event()
	_show_location_background(location)
	var visit_index := _get_weekly_location_visits(location)
	var tuned_changes := _apply_location_repeat_decay(config.get("changes", {}), visit_index)
	_record_weekly_location_visit(location)
	var encounter_npc := _check_encounter(location)
	if encounter_npc.size() > 0:
		_handle_encounter(encounter_npc, location, config, tuned_changes, payment_changes)
		return

	var roll := randf()

	if location == "overtime" and roll < 0.50:
		var event := GameManager.roll_random_event("overtime")
		if event.size() > 0:
			main_node()._show_event(event, func() -> void:
				_show_location_result_from_config(location, config, tuned_changes, payment_changes)
			)
			GameManager.add_activity(config.get("category", "日常"), config.get("activity", config.get("name", location)))
			return

	if roll < 0.50 and _city_fragments.get(location, []).size() > 0:
		_trigger_city_fragment(location, tuned_changes, payment_changes)
	else:
		_show_location_result_from_config(location, config, tuned_changes, payment_changes)
	GameManager.add_activity(config.get("category", "日常"), config.get("activity", config.get("name", location)))


func _show_reunion_result(npc: Dictionary, location: String, base_changes: Dictionary) -> void:
	var npc_id: String = npc.get("id", "")
	var npc_name: String = npc.get("name", "")
	_record_weekly_reunion(npc_id)
	var loc_cn: String = {"gym": "健身房", "library": "图书馆", "bar": "酒吧", "home": "家里", "park": "公园", "cafe": "咖啡厅", "market": "夜市"}.get(location, location)
	var template: String = _reunion_lines[randi() % _reunion_lines.size()]
	var text: String = template.replace("{name}", npc_name).replace("{loc}", loc_cn)
	var bonus := {"affection": 3, "sanity": 3, "eq": 1}
	_show_story_then_apply_npc_changes(text, base_changes, {}, npc_name, _finish_location_event_after(), "【结算】", npc_id, bonus)
	GameManager.add_activity("社交", "在%s遇到了%s，聊了几句" % [loc_cn, npc_name])


## 处理邂逅场景（通用版）
func _handle_encounter(npc: Dictionary, location: String, config: Dictionary, pending_changes: Dictionary, already_applied_changes: Dictionary = {}) -> void:
	var enc: Dictionary = npc.get("encounter", {})
	var npc_id: String = npc.get("id", "")
	var npc_name: String = npc.get("name", "")
	_encounter_cooldowns[npc_id] = GameManager.turn_count + 99
	if _meets_encounter_requirements(enc):
		var pass_changes: Dictionary = enc.get("pass_stat_changes", {})
		var display_changes := already_applied_changes.duplicate()
		var pages: Array = []
		for line in enc.get("scene_lines", []):
			pages.append(line)
		for line in enc.get("dialogue_lines", []):
			pages.append(npc_name + "：" + line)

		var wechat_req: Dictionary = enc.get("wechat_request", {})
		if wechat_req.size() > 0:
			main_node().galgame._gal_encounter_data = enc
			main_node().galgame._gal_npc_id = npc_id
			main_node().galgame.show_galgame_dialog(pages, func() -> void:
				_show_story_then_apply_npc_changes("", pending_changes, display_changes, npc_name, main_node().galgame.start_wechat_request_phase, "【结算】", npc_id, pass_changes)
			)
		else:
			main_node().galgame.show_galgame_dialog(pages, func() -> void:
				_show_story_then_apply_npc_changes("", pending_changes, display_changes, npc_name, _finish_location_event_after(), "【结算】", npc_id, pass_changes)
			)
		GameManager.add_activity("社交", "在%s邂逅了%s" % [location, npc_name])
	else:
		var fail_pages: Array = []
		for line in enc.get("scene_lines", []):
			fail_pages.append(line)
		for line in enc.get("dialogue_lines", []):
			fail_pages.append(npc_name + "：" + line)
		var requirement_hint := _format_encounter_requirement_hint(enc)
		if requirement_hint != "":
			fail_pages.append(requirement_hint)
		else:
			fail_pages.append("（你的属性不满足邂逅条件，擦肩而过...）")
		_encounter_cooldowns[npc_id] = GameManager.turn_count + 4
		main_node().galgame.show_galgame_dialog(fail_pages, func() -> void:
				_show_location_result_from_config(location, config, pending_changes, already_applied_changes)
		)


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
	btn_food_low.disabled = true
	btn_food_mid.disabled = true
	btn_food_high.disabled = true
	var _changes: Dictionary = {}
	if main_node().get("action_service") and main_node().action_service.has_method("add_monthly_food"):
		_changes = main_node().action_service.add_monthly_food(300, "low_food", -5, 0)
	else:
		GameManager.monthly_food_cost += 300
		GameManager.modify_stat("sanity", -5)
		_changes = {"monthly_food_cost": 300, "sanity": -5}
	GameManager.add_activity("日常", "吃了挂逼生存套餐（沙县/拉面），花费300元")
	GameManager.consecutive_poor_food += 1
	GameManager.consecutive_overtime = 0
	# 连续吃土死法检查
	var death: Dictionary = GameManager.check_behavior_death()
	if death.size() > 0:
		GameManager.game_over.emit(death["title"], death["desc"])
		return
	_unlock_work_buttons()

func _on_food_mid() -> void:
	btn_food_low.disabled = true
	btn_food_mid.disabled = true
	btn_food_high.disabled = true
	var _changes: Dictionary = {}
	if main_node().get("action_service") and main_node().action_service.has_method("add_monthly_food"):
		_changes = main_node().action_service.add_monthly_food(800, "mid_food", 0, 10)
	else:
		GameManager.monthly_food_cost += 800
		GameManager.modify_stat("energy", 10)
		_changes = {"monthly_food_cost": 800, "energy": 10}
	GameManager.add_activity("日常", "吃了打工人标配（肯德基/火锅），花费800元")
	GameManager.consecutive_poor_food = 0
	GameManager.consecutive_overtime = 0
	_unlock_work_buttons()

func _on_food_high() -> void:
	btn_food_low.disabled = true
	btn_food_mid.disabled = true
	btn_food_high.disabled = true
	var _changes: Dictionary = {}
	if main_node().get("action_service") and main_node().action_service.has_method("add_monthly_food"):
		_changes = main_node().action_service.add_monthly_food(2000, "high_food", 20, 15)
	else:
		GameManager.monthly_food_cost += 2000
		GameManager.modify_stat("sanity", 20)
		GameManager.modify_stat("energy", 15)
		_changes = {"monthly_food_cost": 2000, "sanity": 20, "energy": 15}
	GameManager.add_activity("日常", "吃了小资高档（日料/西餐），花费2000元")
	GameManager.consecutive_poor_food = 0
	GameManager.consecutive_overtime = 0
	_unlock_work_buttons()

func _unlock_work_buttons() -> void:
	btn_food_low.disabled = true
	btn_food_mid.disabled = true
	btn_food_high.disabled = true
	btn_work_normal.disabled = false
	btn_work_slack.disabled = false
	btn_work_overtime.disabled = false
	main_node()._refresh_ui()


# ==================== 宝淘App（消费陷阱）====================

func _on_bt_skincare() -> void:
	main_node().alipay.request_payment(800, "大牌护肤套装", "消费", func() -> void:
		var payment_changes: Dictionary = main_node().alipay.get_last_payment_changes()
		_show_story_then_apply_changes("大牌护肤套装到货。你对着镜子认真涂完一整套流程，皮肤状态确实亮了一点。", {"charm": 5, "sanity": 5}, payment_changes)
	)

func _on_bt_fashion() -> void:
	main_node().alipay.request_payment(1500, "快时尚穿搭", "消费", func() -> void:
		var payment_changes: Dictionary = main_node().alipay.get_last_payment_changes()
		_show_story_then_apply_changes("新衣服很快到了。你换上之后拍了几张照，虽然知道它不便宜，但心情确实轻了一点。", {"charm": 8, "sanity": 10}, payment_changes)
	)


# ==================== 团美医美App（消费陷阱）====================

func _on_tm_injection() -> void:
	if GameManager.charm >= 30:
		main_node().show_message("你颜值已经>=30了，医生说不需要做这个项目~")
		return
	main_node().alipay.request_payment(6000, "水光针热玛吉", "消费", func() -> void:
		var payment_changes: Dictionary = main_node().alipay.get_last_payment_changes()
		_show_story_then_apply_changes("项目做完后，你盯着镜子看了很久。变化很明显，账单也很明显。", {"charm": 15, "sanity": 20}, payment_changes)
	)

func _on_tm_surgery() -> void:
	if GameManager.charm >= 20:
		main_node().show_message("你颜值已经>=20了，做全脸微调太浪费钱了！")
		return
	main_node().alipay.request_payment(20000, "全脸微调手术", "消费", func() -> void:
		var payment_changes: Dictionary = main_node().alipay.get_last_payment_changes()
		_show_story_then_apply_changes("恢复期比你想象中难熬。拆线那天，你看着镜子里的自己，熟悉又陌生。", {"charm": 30, "eq": -10, "sanity": 30}, payment_changes)
	)


# ==================== 星座App ====================

func _on_close_zodiac() -> void:
	_set_layer_visible(zodiac_popup, false)


# ==================== 贝壳找房App ====================

func _on_house_village() -> void:
	if GameManager.money < 3000:
		main_node().show_message("余额不足，城中村押金需要 3000 元。")
		return
	_show_story_then_apply_changes("你重新签了城中村的小房间。空间不大，但至少账单还算能喘气。下月起房租 1500。", {"money": -3000}, {}, func() -> void:
		GameManager.base_rent = 1500
		GameManager.housing_level = 0
		GameManager.housing_buff_sanity = 0
	)

func _on_house_apartment() -> void:
	if GameManager.money < 8000:
		main_node().show_message("余额不足，精装公寓押金需要 8000 元。")
		return
	_show_story_then_apply_changes("精装公寓的灯光很柔和，电梯也不再有怪味。你换上拖鞋，第一次觉得回家像回家。下月起房租 4000。", {"money": -8000, "charm": 5}, {}, func() -> void:
		GameManager.base_rent = 4000
		GameManager.housing_level = 1
		GameManager.housing_buff_sanity = 10
	)

func _on_house_luxury() -> void:
	if GameManager.money < 24000:
		main_node().show_message("余额不足，CBD大平层押金需要 24000 元。")
		return
	_show_story_then_apply_changes("CBD 大平层的落地窗外就是夜景。你站在窗边看了很久，知道自己正在买一种很贵的体面。下月起房租 12000。", {"money": -24000, "charm": 10}, {}, func() -> void:
		GameManager.base_rent = 12000
		GameManager.housing_level = 2
		GameManager.housing_buff_sanity = 25
	)


# ==================== 滑动交友App ====================

func _refresh_dating_card() -> void:
	var name_idx: int = randi() % _dating_names.size()
	var bio_idx: int = randi() % _dating_bios.size()
	var age_val: int = 25 + (randi() % 11)
	label_date_name.text = _dating_names[name_idx]
	label_date_age.text = "年龄：%d岁 | 身高：%dcm" % [age_val, 170 + (randi() % 16)]
	label_date_bio.text = "「%s」" % _dating_bios[bio_idx]

func _on_pass() -> void:
	if GameManager.energy < 5:
		main_node().show_message("精力不足，没力气滑了！")
		return
	GameManager.modify_stat("energy", -5)
	_refresh_dating_card()

func _on_like() -> void:
	if GameManager.energy < 5:
		main_node().show_message("精力不足，没力气滑了！")
		return
	# 颜值+情商越高，被骗概率越低，遇到好结果概率越高
	var score: int = GameManager.charm + GameManager.eq
	var roll: int = randi() % 100
	var scam_chance: int = 70 - score  # 颜值+情商每高1点，被骗概率-1%
	if scam_chance < 20:
		scam_chance = 20
	var changes := {"energy": -5}
	var story := ""
	if roll < scam_chance:
		changes["money"] = -500
		changes["sanity"] = -15
		story = "你以为对面是真心聊天，结果对方绕了几句就开始要红包。反应过来的时候，钱已经转出去了。"
	elif roll < scam_chance + 50:
		story = "聊了两句，你们都意识到不是一路人。对方沉默，你也顺手划掉了聊天框。"
	else:
		changes["eq"] = 2
		story = "这次遇到的人有点奇怪，但你没有被带着走。聊完以后，你反而更懂怎么识别套路。"
	_show_story_then_apply_changes(story, changes, {}, func() -> void:
		_refresh_dating_card()
	)

func _on_close_dating() -> void:
	_set_layer_visible(dating_popup, false)


# ==================== BOSS弯聘App ====================

func _get_job_name(level: int = GameManager.job_level) -> String:
	var names := ["初级行政", "新媒体运营", "大客户经理"]
	return names[clampi(level, 0, names.size() - 1)]


func _get_degree_name(level: int = GameManager.degree) -> String:
	var names := ["大专", "成人本科"]
	return names[clampi(level, 0, names.size() - 1)]


func _is_weekend_phase() -> bool:
	if not is_instance_valid(_main):
		return false
	return main_node().current_phase == main_node().Phase.WEEKEND


func _career_action_lock_reason(energy_cost: int) -> String:
	if not _is_weekend_phase():
		return "工作日只能查看，周末再安排"
	if GameManager.energy < energy_cost:
		return "精力不足：需要%d，当前%d" % [energy_cost, GameManager.energy]
	return ""


func _spend_career_action(label: String, energy_cost: int, sanity_cost: int) -> bool:
	var reason := _career_action_lock_reason(energy_cost)
	if reason != "":
		main_node().show_message(reason)
		return false
	if main_node().get("action_service") and main_node().action_service.has_method("spend_weekend_action"):
		main_node().action_service.spend_weekend_action(label)
	return true


func _media_lock_reason() -> String:
	if not _is_weekend_phase():
		return "工作日只能查看，周末才能面试"
	if GameManager.energy < 15:
		return "精力需15（当前%d）" % GameManager.energy
	if GameManager.degree < 1:
		return "需成人本科：微信找尚德夜校王老师上课（%d/12）" % GameManager.night_school_progress
	return ""


func _client_lock_reason() -> String:
	var missing: Array = []
	if not _is_weekend_phase():
		missing.append("周末面试")
	if GameManager.energy < 20:
		missing.append("精力20(当前%d)" % GameManager.energy)
	if GameManager.job_level < 1:
		missing.append("新媒体运营履历")
	if GameManager.degree < 1:
		missing.append("成人本科")
	if GameManager.age >= 30:
		missing.append("年龄30岁以下")
	if missing.is_empty():
		return ""
	return "缺：" + "、".join(missing)


func _on_app_job() -> void:
	if not _can_open_phone_app():
		return
	if not _ensure_app_unlocked("job"):
		return
	_close_all_menus()
	for child in job_menu.get_children():
		child.queue_free()
	var phase_text := "周末可安排面试" if _is_weekend_phase() else "工作日仅查看"
	var status := "职位：%s | 学历：%s | 夜校：%d/12 | 年龄：%d | %s" % [
		_get_job_name(),
		_get_degree_name(),
		GameManager.night_school_progress,
		GameManager.age,
		phase_text,
	]
	var items: Array = []

	var admin_item := {
		"name": "初级行政",
		"icon_color": Color(0.3, 0.65, 0.35),
		"cost": "底薪 800/1500/2500。低门槛、低天花板、低风险。",
		"current": GameManager.job_level == 0,
	}
	if GameManager.job_level != 0:
		if _is_weekend_phase():
			admin_item["action"] = _on_job_admin
		else:
			admin_item["locked"] = true
			admin_item["lock_reason"] = "周末再处理离职/降岗"
	items.append(admin_item)

	var media_reason := _media_lock_reason()
	var media_item := {
		"name": "投递：新媒体运营",
		"icon_color": Color(0.2, 0.55, 0.9),
		"cost": "精力-15 情绪-10 | 底薪 2000/4000/6000。要求：成人本科。",
		"current": GameManager.job_level == 1,
		"locked": media_reason != "" and GameManager.job_level != 1,
		"lock_reason": media_reason,
	}
	if GameManager.job_level != 1 and media_reason == "":
		media_item["action"] = _on_job_media
	items.append(media_item)

	var client_reason := _client_lock_reason()
	var client_item := {
		"name": "投递：大客户经理",
		"icon_color": Color(0.9, 0.7, 0.15),
		"cost": "精力-20 情绪-15 | 底薪 4000/8000/12000。要求：新媒体履历、成人本科、30岁以下。",
		"current": GameManager.job_level == 2,
		"locked": client_reason != "" and GameManager.job_level != 2,
		"lock_reason": client_reason,
	}
	if GameManager.job_level != 2 and client_reason == "":
		client_item["action"] = _on_job_client
	items.append(client_item)

	_build_app_overlay(job_menu, "BOSS弯聘", Color(0.2, 0.55, 0.9, 1), status, items)
	_set_layer_visible(job_menu, true)

func _on_job_admin() -> void:
	if GameManager.job_level == 0:
		main_node().show_message("你已经在初级行政岗位上。")
		_on_app_job()
		return
	GameManager.add_activity("工作", "调整回初级行政岗位，收入下降但压力也更低。")
	_show_action_result("已转回初级行政，底薪 800/1500/2500。", {"job_level": -GameManager.job_level}, func() -> void:
		_refresh_main_ui()
		_on_app_job()
	)

func _on_job_media() -> void:
	if GameManager.job_level == 1:
		main_node().show_message("你已经是新媒体运营。")
		_on_app_job()
		return
	var reason := _media_lock_reason()
	if reason != "":
		main_node().show_message(reason)
		return
	if not _spend_career_action("新媒体运营面试", 15, 10):
		return
	GameManager.add_activity("工作", "通过新媒体运营面试，职位提升。")
	_show_action_result("跳槽成功。下周开始，新媒体运营底薪 2000/4000/6000。", {"energy": -15, "sanity": -10, "job_level": 1 - GameManager.job_level}, func() -> void:
		_refresh_main_ui()
		_on_app_job()
	)

func _on_job_client() -> void:
	if GameManager.job_level == 2:
		main_node().show_message("你已经是大客户经理。")
		_on_app_job()
		return
	var reason := _client_lock_reason()
	if reason != "":
		main_node().show_message(reason)
		return
	if not _spend_career_action("大客户经理面试", 20, 15):
		return
	GameManager.add_activity("工作", "拿下大客户经理岗位，正式进入高薪高压轨道。")
	_show_action_result("面试通过。大客户经理底薪 4000/8000/12000，但从下周开始，职场风险也会更重。", {"energy": -20, "sanity": -15, "job_level": 2 - GameManager.job_level}, func() -> void:
		_refresh_main_ui()
		_on_app_job()
	)


# ==================== 日记本 UI ====================

func _setup_diary_heavy_ui() -> void:
	if not is_instance_valid(diary_popup):
		return
	_setup_heavy_app_layer(diary_popup, 80, Vector2(960, 760))
	if bool(diary_popup.get_meta("heavy_diary_built", false)):
		return
	var vbox := diary_popup.find_child("DiaryVBox", true, false) as VBoxContainer
	var filter_hbox := diary_popup.find_child("DiaryFilterHBox", true, false) as HBoxContainer
	var scroll := diary_popup.find_child("DiaryScroll", true, false) as ScrollContainer
	var close_btn := diary_popup.find_child("BtnCloseDiary", true, false) as Button
	if not is_instance_valid(vbox) or not is_instance_valid(filter_hbox) or not is_instance_valid(scroll) or not is_instance_valid(close_btn):
		return

	_detach_from_parent(filter_hbox)
	_detach_from_parent(scroll)
	_detach_from_parent(close_btn)
	for child: Node in vbox.get_children():
		child.queue_free()

	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_make_heavy_header("日记本", "活动流水、数值变化和关键选择复盘", close_btn))

	_diary_summary_label = _make_body_label("")
	vbox.add_child(_make_heavy_card("本月回顾", [_diary_summary_label]))

	filter_hbox.add_theme_constant_override("separation", 8)
	filter_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_make_heavy_card("筛选", [filter_hbox]))
	_collect_diary_filter_buttons()
	_style_diary_filter_buttons()

	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_theme_stylebox_override("panel", _make_flat_style(Color(1, 1, 1, 0), Color(1, 1, 1, 0), 0, 0))
	diary_log_container.add_theme_constant_override("separation", 8)
	diary_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var log_card := _make_heavy_card("最近记录（最新在上）", [scroll])
	log_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(log_card)
	diary_popup.set_meta("heavy_diary_built", true)


func _make_heavy_header(title: String, subtitle: String, close_btn: Button) -> Control:
	var header := PanelContainer.new()
	header.name = "HeavyAppHeader"
	header.custom_minimum_size = Vector2(0, 72)
	header.add_theme_stylebox_override("panel", _make_flat_style(Color(0.11, 0.28, 0.24, 1), Color(0.25, 0.55, 0.48, 0.55), 1, 12))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	header.add_child(margin)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	hbox.add_child(title_box)
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_box.add_child(title_label)
	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.add_theme_font_size_override("font_size", 13)
	subtitle_label.add_theme_color_override("font_color", Color(0.82, 0.92, 0.88, 1))
	title_box.add_child(subtitle_label)
	_detach_from_parent(close_btn)
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(46, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_btn.tooltip_text = "关闭日记"
	_style_text_button(close_btn, Color(0.86, 0.92, 0.90, 1), Color(0.76, 0.86, 0.82, 1), Color(0.08, 0.20, 0.17, 1))
	hbox.add_child(close_btn)
	return header


func _make_body_label(text: String) -> Label:
	return HeavyAppUI.make_body_label(text, 14, Color(0.14, 0.22, 0.20, 1))


func _make_heavy_card(title: String, controls: Array) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_flat_style(Color(0.975, 0.985, 0.980, 1), Color(0.76, 0.86, 0.82, 1), 1, 9))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(box)
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color(0.07, 0.28, 0.23, 1))
	box.add_child(title_label)
	for control_variant in controls:
		var control := control_variant as Control
		if not is_instance_valid(control):
			continue
		_detach_from_parent(control)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(control)
	return card


func _collect_diary_filter_buttons() -> void:
	_diary_filter_buttons.clear()
	for cat: String in ["全部", "日常", "提升", "社交", "消费"]:
		var btn := diary_popup.find_child("Btn_DiaryFilter_" + cat, true, false) as Button
		if is_instance_valid(btn):
			_diary_filter_buttons[cat] = btn


func _style_diary_filter_buttons() -> void:
	if _diary_filter_buttons.is_empty():
		_collect_diary_filter_buttons()
	for cat: String in _diary_filter_buttons.keys():
		var btn := _diary_filter_buttons[cat] as Button
		if not is_instance_valid(btn):
			continue
		btn.custom_minimum_size = Vector2(72, 36)
		if cat == _diary_filter:
			_style_text_button(btn, Color(0.10, 0.52, 0.42, 1), Color(0.12, 0.62, 0.50, 1), Color.WHITE)
		else:
			_style_text_button(btn, Color(0.86, 0.93, 0.90, 1), Color(0.78, 0.88, 0.84, 1), Color(0.08, 0.24, 0.20, 1))


func _diary_category_color(category: String) -> Color:
	match category:
		"提升":
			return Color(0.12, 0.35, 0.75, 1)
		"社交":
			return Color(0.85, 0.35, 0.10, 1)
		"消费":
			return Color(0.76, 0.12, 0.10, 1)
		"工作":
			return Color(0.34, 0.25, 0.70, 1)
		_:
			return Color(0.14, 0.22, 0.20, 1)


func _diary_week_str(entry: Dictionary) -> String:
	if entry.has("age") and entry.has("month") and entry.has("week_in_month"):
		return "%d岁 %d月第%d周" % [entry["age"], entry["month"], entry["week_in_month"]]
	return "第%d周" % entry.get("week", 0)

func _on_diary_filter(category: String) -> void:
	_diary_filter = category
	_style_diary_filter_buttons()
	_refresh_diary_ui()

func _refresh_diary_ui() -> void:
	for child in diary_log_container.get_children():
		child.queue_free()
	var logs: Array = GameManager.activity_log
	var counts: Dictionary = {}
	for entry_variant in logs:
		var entry_for_count := entry_variant as Dictionary
		var count_category := str(entry_for_count.get("category", "日常"))
		counts[count_category] = int(counts.get(count_category, 0)) + 1
	_update_diary_summary(logs.size(), counts)
	var shown_count := 0
	for i in range(logs.size() - 1, -1, -1):
		var entry: Dictionary = logs[i]
		if _diary_filter != "全部" and entry.get("category", "") != _diary_filter:
			continue
		_add_diary_log_entry(entry)
		shown_count += 1
	if shown_count == 0:
		var empty_label := _make_body_label("暂无%s记录。去地图、工作、消费或聊天后，这里会留下可复盘的行动流水。" % _diary_filter)
		empty_label.add_theme_color_override("font_color", Color(0.40, 0.50, 0.46, 1))
		diary_log_container.add_child(empty_label)


func _update_diary_summary(total_count: int, counts: Dictionary) -> void:
	if not is_instance_valid(_diary_summary_label):
		return
	var parts: Array = []
	for cat: String in ["日常", "工作", "提升", "社交", "消费"]:
		var count := int(counts.get(cat, 0))
		if count > 0:
			parts.append("%s %d" % [cat, count])
	var count_text := "暂无记录" if parts.is_empty() else " / ".join(parts)
	_diary_summary_label.text = "共 %d 条记录｜当前筛选：%s\n%s\n日记只做复盘，不消耗精力。它应该帮玩家想清楚：刚才做了什么，为什么钱、情绪或关系变了。" % [total_count, _diary_filter, count_text]


func _add_diary_log_entry(entry: Dictionary) -> void:
	var category := str(entry.get("category", "日常"))
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", _make_flat_style(Color(1, 1, 1, 1), Color(0.82, 0.90, 0.86, 1), 1, 8))
	diary_log_container.add_child(row)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	row.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(box)
	var meta_label := Label.new()
	meta_label.text = "%s  ·  %s" % [_diary_week_str(entry), category]
	meta_label.add_theme_font_size_override("font_size", 12)
	meta_label.add_theme_color_override("font_color", _diary_category_color(category))
	box.add_child(meta_label)
	var desc_label := Label.new()
	desc_label.text = str(entry.get("desc", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.12, 0.18, 0.17, 1))
	box.add_child(desc_label)


# ==================== 深夜网抑云失眠系统 ====================

## 进入深夜失眠弹窗（随机抽取一种冲动消费作为诱惑）
func _enter_late_night() -> void:
	_pending_impulse = _impulse_pool[randi() % _impulse_pool.size()]
	btn_emo_bag.text = _pending_impulse["text"]
	btn_emo_sleep.text = "忍住诱惑，强迫自己睡觉 (颜值-2 情绪-10 精力-20)"
	_set_layer_visible(late_night_popup, true)

## 按钮 A：冲动消费换取多巴胺
func _on_emo_bag() -> void:
	var imp: Dictionary = _pending_impulse
	var changes := {"credit_debt": int(imp["huabei"])}
	if int(imp["sanity"]) > 0:
		changes["sanity"] = int(imp["sanity"])
	if int(imp["charm"]) > 0:
		changes["charm"] = int(imp["charm"])
	GameManager.add_activity("消费", "深夜失眠，冲动消费换取了短暂的安慰。")
	_set_layer_visible(late_night_popup, false)
	_show_story_then_apply_changes("下单了。屏幕上弹出支付成功的提示，短暂的快乐之后，是更深的空虚。", changes, {}, func() -> void:
		GameManager.add_finance(-imp["huabei"], imp["desc"], true, "消费")
		main_node()._proceed_next_week()
	)

## 按钮 B：硬抗！强行闭眼到天亮
func _on_emo_sleep() -> void:
	var changes := {"charm": -2, "sanity": -10, "energy": -20}
	GameManager.add_activity("日常", "失眠了一整夜，第二天感觉身体被掏空。")
	_set_layer_visible(late_night_popup, false)
	if not GameManager.game_finished:
		_show_story_then_apply_changes("你辗转反侧到天亮。窗外开始发白的时候，整个人像被抽空了一样。", changes, {}, func() -> void:
			main_node()._proceed_next_week()
		)
