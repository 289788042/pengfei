## AppPopupSystem.gd - APP弹窗/地点/食物/交友/求职/日记系统
## 负责：高德地图、宝淘、团美、星座、贝壳、滑动交友、BOSS弯聘、日记本、深夜失眠等
## 通过 _main 引用 MainGame 节点访问 UI 节点和工具函数
extends RefCounted

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


func _set_layer_visible(layer: Control, is_visible: bool) -> void:
	if not is_instance_valid(layer):
		return
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


func _show_story_then_result(story_text: String, result_text: String, after: Callable = Callable()) -> void:
	var clean_story := _strip_embedded_result_lines(story_text)
	if clean_story != "":
		main_node().galgame.show_galgame_dialog([clean_story], func() -> void:
			_show_result(result_text, after)
		)
	else:
		_show_result(result_text, after)


func _show_location_result(location: String, fallback_text: String, changes: Dictionary, after: Callable = Callable()) -> void:
	var story := GameManager.get_location_narrative(location, fallback_text)
	_show_story_then_result(story, _format_result(changes), after)


func _action_service():
	if is_instance_valid(_main):
		return main_node().get("action_service")
	return null


func _show_action_result(story_text: String, changes: Dictionary, after: Callable = Callable()) -> void:
	var service = _action_service()
	if service and service.has_method("show_action_result"):
		service.show_action_result(story_text, changes, after)
	elif is_instance_valid(_main) and _main.has_method("show_stat_result"):
		_main.show_stat_result(changes, after)
	elif after.is_valid():
		after.call()


# ==================== 地图/地点 ====================

func _on_close_loc() -> void:
	_set_layer_visible(location_menu, false)


func _on_app_map() -> void:
	if main_node().current_phase == main_node().Phase.WEEKEND and GameManager.weekend_actions <= 0:
		main_node().show_message("本周行动次数已用完！")
		return
	_close_all_menus()
	## 清除旧子节点
	for child in location_menu.get_children():
		child.queue_free()
	## 地点面板
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 0)
	## 用锚点居中，上下各留 40px 边距
	## 全屏锚点 + 居中对齐
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.05
	panel.anchor_bottom = 0.95
	panel.offset_left = 20
	panel.offset_right = -20
	panel.offset_top = 0
	panel.offset_bottom = 0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.95, 0.95, 0.95, 1)
	panel_style.set_corner_radius_all(12.0)
	panel_style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", panel_style)
	location_menu.add_child(panel)
	## 主VBox
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)
	## 顶部蓝色栏
	var top_bar := PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 50)
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.15, 0.55, 0.95, 1)
	top_style.corner_radius_top_left = 12.0
	top_style.corner_radius_top_right = 12.0
	top_style.set_content_margin_all(0)
	top_bar.add_theme_stylebox_override("panel", top_style)
	vbox.add_child(top_bar)
	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 0)
	top_bar.add_child(top_hbox)
	var title_ml := Control.new()
	title_ml.custom_minimum_size = Vector2(16, 0)
	top_hbox.add_child(title_ml)
	var title_lbl := Label.new()
	title_lbl.text = "高德地图"
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	top_hbox.add_child(title_lbl)
	var title_sp := Control.new()
	title_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(title_sp)
	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.flat = true
	close_btn.pressed.connect(_on_close_loc)
	top_hbox.add_child(close_btn)
	var title_mr := Control.new()
	title_mr.custom_minimum_size = Vector2(12, 0)
	top_hbox.add_child(title_mr)
	## 地点列表（可滚动）
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	var loc_list := VBoxContainer.new()
	loc_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loc_list.add_theme_constant_override("separation", 0)
	scroll.add_child(loc_list)
	## 地点数据
	var map_locs: Array = [
		{"name": "图书馆", "icon_color": Color(0.2, 0.5, 0.9), "cost": "-20精力 | +3学识 +5情绪", "action": _on_loc_library},
		{"name": "健身房", "icon_color": Color(0.2, 0.75, 0.3), "cost": "-45精力 -200金 | +2颜值 +5情绪 体力上限+1", "action": _on_loc_gym},
		{"name": "高档酒吧", "icon_color": Color(0.6, 0.3, 0.8), "cost": "-20精力 -500金 | +2情商 +25情绪 | 需情商>=10", "action": _on_loc_bar},
		{"name": "宅家刷手机", "icon_color": Color(0.55, 0.55, 0.55), "cost": "-10精力 | +20情绪", "action": _on_loc_home},
		{"name": "公园·深圳湾", "icon_color": Color(0.1, 0.7, 0.4), "cost": "0精力 0金 | +3情绪 精力+10", "action": _on_loc_park},
		{"name": "咖啡厅", "icon_color": Color(0.55, 0.35, 0.15), "cost": "-5精力 -60金 | +2学识 +3情商", "action": _on_loc_cafe},
		{"name": "夜市·大排档", "icon_color": Color(0.85, 0.55, 0.1), "cost": "0精力 -100金 | +15情绪", "action": _on_loc_market},
		{"name": "公司加班", "icon_color": Color(0.3, 0.3, 0.7), "cost": "-40精力 | +500~800金", "action": _on_loc_overtime},
	]
	## 构建每行
	for loc in map_locs:
		var wrapper := Control.new()
		wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wrapper.custom_minimum_size = Vector2(0, 72)
		loc_list.add_child(wrapper)
		var row := Panel.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(1, 1, 1, 1)
		row_style.set_content_margin_all(0)
		row.add_theme_stylebox_override("panel", row_style)
		wrapper.add_child(row)
		var row_hbox := HBoxContainer.new()
		row_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		row_hbox.add_theme_constant_override("separation", 12)
		row.add_child(row_hbox)
		## 左侧图标占位
		var icon_ml := Control.new()
		icon_ml.custom_minimum_size = Vector2(16, 0)
		row_hbox.add_child(icon_ml)
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.color = loc["icon_color"]
		row_hbox.add_child(icon)
		## 右侧信息
		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)
		info_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row_hbox.add_child(info_vbox)
		var name_lbl := Label.new()
		name_lbl.text = loc["name"]
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15, 1))
		info_vbox.add_child(name_lbl)
		var cost_lbl := Label.new()
		cost_lbl.text = loc["cost"]
		cost_lbl.add_theme_font_size_override("font_size", 12)
		cost_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1))
		info_vbox.add_child(cost_lbl)
		## 右侧箭头
		var arrow_sp := Control.new()
		arrow_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_hbox.add_child(arrow_sp)
		var arrow_lbl := Label.new()
		arrow_lbl.text = ">"
		arrow_lbl.add_theme_font_size_override("font_size", 20)
		arrow_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1))
		arrow_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row_hbox.add_child(arrow_lbl)
		var arrow_mr := Control.new()
		arrow_mr.custom_minimum_size = Vector2(12, 0)
		row_hbox.add_child(arrow_mr)
		## 点击事件
		var captured_action: Callable = loc["action"]
		var click_btn := Button.new()
		click_btn.name = "LocBtn_" + loc["name"]
		click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		click_btn.flat = true
		click_btn.focus_mode = Control.FOCUS_NONE
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0, 0, 0, 0)
		btn_style.set_content_margin_all(0)
		click_btn.add_theme_stylebox_override("normal", btn_style)
		click_btn.add_theme_stylebox_override("hover", btn_style)
		click_btn.add_theme_stylebox_override("pressed", btn_style)
		wrapper.add_child(click_btn)
		click_btn.pressed.connect(func() -> void:
			_on_close_loc()
			captured_action.call()
		)
	_set_layer_visible(location_menu, true)


func _close_all_menus() -> void:
	for m in [location_menu, baotao_menu, tuanmei_menu, zodiac_popup, house_menu, dating_popup, job_menu, diary_popup, late_night_popup]:
		if is_instance_valid(m):
			_set_layer_visible(m, false)


func _on_app_diary() -> void:
	_close_all_menus()
	_refresh_diary_ui()
	_set_layer_visible(diary_popup, true)


func _on_app_baotao() -> void:
	_close_all_menus()
	for child in baotao_menu.get_children():
		child.queue_free()
	var debt_info := "花呗欠款：%d 元" % (GameManager.huabei_debt + GameManager.huabei_installment_debt)
	var items := [
		{"name": "大牌护肤套装", "icon_color": Color(0.95, 0.45, 0.6), "cost": "800 元 | +5颜值 +5情绪", "action": _on_bt_skincare},
		{"name": "快时尚穿搭", "icon_color": Color(0.3, 0.7, 0.9), "cost": "1500 元 | +8颜值 +10情绪", "action": _on_bt_fashion},
	]
	_build_app_overlay(baotao_menu, "宝淘", Color(0.95, 0.35, 0.35, 1), debt_info, items)
	_set_layer_visible(baotao_menu, true)


func _on_app_tuanmei() -> void:
	_close_all_menus()
	for child in tuanmei_menu.get_children():
		child.queue_free()
	var debt_info := "花呗欠款：%d 元" % (GameManager.huabei_debt + GameManager.huabei_installment_debt)
	var items := [
		{"name": "水光针+热玛吉", "icon_color": Color(0.8, 0.4, 0.8), "cost": "6000 元 | +15颜值 | 需颜值<30", "action": _on_tm_injection},
		{"name": "全脸微调手术", "icon_color": Color(0.6, 0.2, 0.8), "cost": "20000 元 | +30颜值 | 需颜值<20", "action": _on_tm_surgery},
	]
	_build_app_overlay(tuanmei_menu, "团美医美", Color(0.6, 0.3, 0.8, 1), debt_info, items)
	_set_layer_visible(tuanmei_menu, true)


func _on_app_zodiac() -> void:
	_close_all_menus()
	label_zodiac_content.text = "亲爱的%s宝宝，本周运势：\n请注意控制消费，警惕烂桃花哦！" % GameManager.player_zodiac
	_set_layer_visible(zodiac_popup, true)


func _on_app_house() -> void:
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
	_close_all_menus()
	if GameManager.charm < 10:
		main_node().show_message("颜值太低（需>=10），没有匹配对象！先提升自己吧~")
		return
	_refresh_dating_card()
	_set_layer_visible(dating_popup, true)


# ==================== 通用App覆盖层构建器 ====================

func _build_app_overlay(parent: ColorRect, title: String, top_color: Color, subtitle: String, items: Array) -> void:
	## 外层圆角面板
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 10
	panel.offset_right = -10
	panel.offset_top = 0
	panel.offset_bottom = 0
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
	close_btn.text = "关闭"
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.custom_minimum_size = Vector2(50, 30)
	close_btn.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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
			row.mouse_filter = Control.MOUSE_FILTER_STOP
			for child in row_hbox.get_children():
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_set_layer_visible(parent, false)
					captured_action.call()
			)


# ==================== 城市碎片 & 重逢系统 ====================

## 从指定地点的碎片池中随机抽取一条并触发
func _trigger_city_fragment(location: String, bonus_text: String = "") -> void:
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
			_show_result(bonus_text, func() -> void:
				_show_fragment_choices(choices)
			)
		)
		return
	# 原有逻辑：无选项，直接应用效果
	var effects: Dictionary = frag.get("effect", {})
	var effect_parts: Array = []
	for stat_name in effects:
		var val: int = effects[stat_name]
		if val == 0:
			continue
		var cn: String = GameManager.stat_names.get(stat_name, stat_name)
		GameManager.modify_stat(stat_name, val)
		if val > 0:
			effect_parts.append("[color=90EE90]%s+%d[/color]" % [cn, val])
		else:
			effect_parts.append("[color=E88080]%s%d[/color]" % [cn, val])
	var all_effects: String = bonus_text
	if effect_parts.size() > 0:
		if all_effects != "":
			all_effects += "  "
		all_effects += "  ".join(effect_parts)
	_show_story_then_result(text, all_effects)


## 显示碎片选项按钮
func _show_fragment_choices(choices: Array) -> void:
	var gal: RefCounted = main_node().galgame
	var box: Panel = gal.left_dialog_box
	box.visible = true
	box.modulate.a = 1.0
	gal.left_dialog_text.visible = false
	# 禁用下一周按钮防止跳过
	var skip_btn: Button = main_node().get_node_or_null("HBoxContainer/RightMargin/RightSystemArea/Btn_NextWeek")
	if skip_btn:
		skip_btn.disabled = true
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
	# 应用花费
	var cost: Dictionary = choice.get("cost", {})
	var cost_parts: Array = []
	for stat_name in cost:
		var val: int = int(cost[stat_name])
		GameManager.modify_stat(stat_name, -val)
		var cn: String = GameManager.stat_names.get(stat_name, stat_name)
		cost_parts.append("[color=E88080]%s-%d[/color]" % [cn, val])
	# 应用效果
	var effects: Dictionary = choice.get("effect", {})
	var effect_parts: Array = []
	for stat_name in effects:
		var val: int = int(effects[stat_name])
		if val == 0:
			continue
		GameManager.modify_stat(stat_name, val)
		var cn: String = GameManager.stat_names.get(stat_name, stat_name)
		if val > 0:
			effect_parts.append("[color=90EE90]%s+%d[/color]" % [cn, val])
		else:
			effect_parts.append("[color=E88080]%s%d[/color]" % [cn, val])
	# 清理选项按钮
	if is_instance_valid(_frag_choice_container):
		_frag_choice_container.queue_free()
		_frag_choice_container = null
	gal.left_dialog_text.visible = true
	# 显示结果
	var result: String = choice.get("result", "")
	var all_parts: Array = cost_parts + effect_parts
	var result_text := ""
	if all_parts.size() > 0:
		result_text = "  ".join(all_parts)
	if result != "":
		gal.show_galgame_dialog([_strip_embedded_result_lines(result)], func() -> void:
			_show_result(result_text)
		)
	else:
		_show_result(result_text)

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
	var runtime = GameManager.get_npc_runtime(npc_id)
	if runtime:
		runtime["affection"] = runtime.get("affection", 0) + 3
	GameManager.modify_stat("sanity", 3)
	GameManager.modify_stat("eq", 1)
	GameManager.add_activity("社交", "在%s遇到了%s，聊了几句" % [loc_cn, npc_name])
	_show_story_then_result(text, _format_result({"affection": 3, "sanity": 3, "eq": 1}))


# ==================== 周末行动次数 ====================

func _use_weekend_action(label: String = "weekend") -> bool:
	if main_node().get("action_service") and main_node().action_service.has_method("spend_weekend_action"):
		return main_node().action_service.spend_weekend_action(label)
	if GameManager.weekend_actions <= 0:
		main_node().show_message("本周行动次数已用完：" + label)
		return false
	GameManager.weekend_actions = maxi(GameManager.weekend_actions - 1, 0)
	main_node()._update_weekend_ui()
	GameManager.stats_updated.emit()
	return true


# ==================== 地点逻辑 ====================

## 每个地点的访问次数（用于首次判断）
var _loc_visit_count: Dictionary = {}

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
				"energy_req": 20,
				"payment_cost": 500,
				"payment_desc": "酒吧消费",
				"req_stats": {"eq": 10},
				"changes": {"energy": -20, "eq": 2, "sanity": 25},
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
				"energy_req": 5,
				"payment_cost": 60,
				"payment_desc": "咖啡厅消费",
				"changes": {"energy": -5, "intellect": 2, "eq": 3},
				"fallback": "在咖啡厅坐了一下午。",
				"activity": "在咖啡厅学习，学识+2，情商+3",
			}
		"market":
			return {
				"name": "夜市·大排档",
				"category": "美食",
				"payment_cost": 100,
				"payment_desc": "夜市消费",
				"changes": {"sanity": 15},
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


func _apply_location_changes(changes: Dictionary) -> Dictionary:
	var service = _action_service()
	if service and service.has_method("apply_stat_changes"):
		return service.apply_stat_changes(changes)
	var applied: Dictionary = {}
	for stat_name in changes:
		var amount := int(changes[stat_name])
		if amount == 0:
			continue
		match str(stat_name):
			"max_energy":
				GameManager.max_energy = maxi(GameManager.max_energy + amount, 1)
				GameManager.energy = clampi(GameManager.energy, 0, GameManager.max_energy)
			"weekend_actions":
				GameManager.weekend_actions = clampi(GameManager.weekend_actions + amount, 0, GameManager.max_weekend_actions)
			"credit_debt":
				GameManager.huabei_debt = maxi(GameManager.huabei_debt + amount, 0)
				GameManager.credit_debt = GameManager.huabei_debt
			_:
				GameManager.modify_stat(str(stat_name), amount)
		applied[stat_name] = int(applied.get(stat_name, 0)) + amount
	_refresh_main_ui()
	return applied


func _apply_npc_bonus_changes(npc_id: String, changes: Dictionary) -> Dictionary:
	var applied: Dictionary = {}
	for stat_name in changes:
		var amount := int(changes[stat_name])
		if amount == 0:
			continue
		if stat_name == "affection" and npc_id != "":
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


func _show_location_result_from_config(location: String, config: Dictionary, display_changes: Dictionary, after: Callable = Callable()) -> void:
	_show_story_then_result(_location_story(location, config), _format_result(display_changes), after)


func _can_start_location(location: String, config: Dictionary) -> bool:
	if not is_instance_valid(_main):
		return false
	if main_node().current_phase != main_node().Phase.WEEKEND:
		main_node().show_message("现在不是周末，不能安排地点行动。")
		return false
	if GameManager.weekend_actions <= 0:
		main_node().show_message("本周行动次数已用完！")
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
	_show_location_background(location)
	var applied := _apply_location_changes(config.get("changes", {}))
	var display_changes := _merge_change_dicts({"weekend_actions": -1}, payment_changes)
	display_changes = _merge_change_dicts(display_changes, applied)

	var encounter_npc := _check_encounter(location)
	if encounter_npc.size() > 0:
		_handle_encounter(encounter_npc, location, config, display_changes)
		return

	var roll := randf()
	if roll < 0.20:
		var reunion := _check_reunion(location)
		if reunion.size() > 0:
			_show_reunion_result(reunion, location, display_changes)
			GameManager.add_activity(config.get("category", "日常"), config.get("activity", config.get("name", location)))
			return

	if location == "overtime" and roll < 0.50:
		var event := GameManager.roll_random_event("overtime")
		if event.size() > 0:
			main_node()._show_event(event, func() -> void:
				_show_location_result_from_config(location, config, display_changes)
			)
			GameManager.add_activity(config.get("category", "日常"), config.get("activity", config.get("name", location)))
			return

	if roll < 0.50 and _city_fragments.get(location, []).size() > 0:
		_trigger_city_fragment(location, _format_result(display_changes))
	else:
		_show_location_result_from_config(location, config, display_changes)
	GameManager.add_activity(config.get("category", "日常"), config.get("activity", config.get("name", location)))


func _show_reunion_result(npc: Dictionary, location: String, base_changes: Dictionary) -> void:
	var npc_id: String = npc.get("id", "")
	var npc_name: String = npc.get("name", "")
	var loc_cn: String = {"gym": "健身房", "library": "图书馆", "bar": "酒吧", "home": "家里", "park": "公园", "cafe": "咖啡厅", "market": "夜市"}.get(location, location)
	var template: String = _reunion_lines[randi() % _reunion_lines.size()]
	var text: String = template.replace("{name}", npc_name).replace("{loc}", loc_cn)
	var bonus := _apply_npc_bonus_changes(npc_id, {"affection": 3, "sanity": 3, "eq": 1})
	_show_story_then_result(text, _format_result(_merge_change_dicts(base_changes, bonus)))
	GameManager.add_activity("社交", "在%s遇到了%s，聊了几句" % [loc_cn, npc_name])


## 处理邂逅场景（通用版）
func _handle_encounter(npc: Dictionary, location: String, config: Dictionary, base_changes: Dictionary) -> void:
	var enc: Dictionary = npc.get("encounter", {})
	var npc_id: String = npc.get("id", "")
	var npc_name: String = npc.get("name", "")
	_encounter_cooldowns[npc_id] = GameManager.turn_count + 99
	if _meets_encounter_requirements(enc):
		var pass_changes := _apply_npc_bonus_changes(npc_id, enc.get("pass_stat_changes", {}))
		var display_changes := _merge_change_dicts(base_changes, pass_changes)
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
				_show_result(_format_result(display_changes), main_node().galgame.start_wechat_request_phase)
			)
		else:
			main_node().galgame.show_galgame_dialog(pages, func() -> void:
				_show_result(_format_result(display_changes))
			)
		GameManager.add_activity("社交", "在%s邂逅了%s" % [location, npc_name])
	else:
		var fail_pages: Array = []
		for line in enc.get("scene_lines", []):
			fail_pages.append(line)
		for line in enc.get("dialogue_lines", []):
			fail_pages.append(npc_name + "：" + line)
		fail_pages.append("（你的属性不满足邂逅条件，擦肩而过...）")
		_encounter_cooldowns[npc_id] = GameManager.turn_count + 4
		main_node().galgame.show_galgame_dialog(fail_pages, func() -> void:
			_show_location_result_from_config(location, config, base_changes)
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
	var changes: Dictionary = {}
	if main_node().get("action_service") and main_node().action_service.has_method("add_monthly_food"):
		changes = main_node().action_service.add_monthly_food(300, "low_food", -5, 0)
	else:
		GameManager.monthly_food_cost += 300
		GameManager.modify_stat("sanity", -5)
		changes = {"monthly_food_cost": 300, "sanity": -5}
	GameManager.add_activity("日常", "吃了挂逼生存套餐（沙县/拉面），花费300元")
	GameManager.consecutive_poor_food += 1
	GameManager.consecutive_overtime = 0
	# 连续吃土死法检查
	var death: Dictionary = GameManager.check_behavior_death()
	if death.size() > 0:
		GameManager.game_over.emit(death["title"], death["desc"])
		return
	_show_action_result("这周先靠沙县和拉面撑过去，把钱省下来。", changes, Callable(self, "_unlock_work_buttons"))

func _on_food_mid() -> void:
	btn_food_low.disabled = true
	btn_food_mid.disabled = true
	btn_food_high.disabled = true
	var changes: Dictionary = {}
	if main_node().get("action_service") and main_node().action_service.has_method("add_monthly_food"):
		changes = main_node().action_service.add_monthly_food(800, "mid_food", 0, 10)
	else:
		GameManager.monthly_food_cost += 800
		GameManager.modify_stat("energy", 10)
		changes = {"monthly_food_cost": 800, "energy": 10}
	GameManager.add_activity("日常", "吃了打工人标配（肯德基/火锅），花费800元")
	GameManager.consecutive_poor_food = 0
	GameManager.consecutive_overtime = 0
	_show_action_result("你按打工人标配解决了本周吃饭问题。", changes, Callable(self, "_unlock_work_buttons"))

func _on_food_high() -> void:
	btn_food_low.disabled = true
	btn_food_mid.disabled = true
	btn_food_high.disabled = true
	var changes: Dictionary = {}
	if main_node().get("action_service") and main_node().action_service.has_method("add_monthly_food"):
		changes = main_node().action_service.add_monthly_food(2000, "high_food", 20, 15)
	else:
		GameManager.monthly_food_cost += 2000
		GameManager.modify_stat("sanity", 20)
		GameManager.modify_stat("energy", 15)
		changes = {"monthly_food_cost": 2000, "sanity": 20, "energy": 15}
	GameManager.add_activity("日常", "吃了小资高档（日料/西餐），花费2000元")
	GameManager.consecutive_poor_food = 0
	GameManager.consecutive_overtime = 0
	_show_action_result("你决定这周吃好一点，至少别把自己逼得太紧。", changes, Callable(self, "_unlock_work_buttons"))

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
		GameManager.modify_stat("charm", 5)
		GameManager.modify_stat("sanity", 5)
		main_node().float_stat("+5 颜值 +5 情绪", 5, main_node().get_global_mouse_position())
		main_node().show_message("大牌护肤到货！颜值+5，心情好好~")
	)

func _on_bt_fashion() -> void:
	main_node().alipay.request_payment(1500, "快时尚穿搭", "消费", func() -> void:
		GameManager.modify_stat("charm", 8)
		GameManager.modify_stat("sanity", 10)
		main_node().float_stat("+8 颜值 +10 情绪", 8, main_node().get_global_mouse_position())
		main_node().show_message("快时尚穿搭好评！颜值+8，情绪+10")
	)


# ==================== 团美医美App（消费陷阱）====================

func _on_tm_injection() -> void:
	if GameManager.charm >= 30:
		main_node().show_message("你颜值已经>=30了，医生说不需要做这个项目~")
		return
	main_node().alipay.request_payment(6000, "水光针热玛吉", "消费", func() -> void:
		GameManager.modify_stat("charm", 25)
		GameManager.modify_stat("sanity", 20)
		main_node().float_stat("+25 颜值 +20 情绪", 25, main_node().get_global_mouse_position())
		main_node().show_message("水光针热玛吉做完！颜值暴涨，照镜子心情都变好了！")
	)

func _on_tm_surgery() -> void:
	if GameManager.charm >= 20:
		main_node().show_message("你颜值已经>=20了，做全脸微调太浪费钱了！")
		return
	main_node().alipay.request_payment(20000, "全脸微调手术", "消费", func() -> void:
		GameManager.modify_stat("charm", 50)
		GameManager.modify_stat("eq", -10)
		GameManager.modify_stat("sanity", 30)
		main_node().float_stat("+50 颜值 +30 情绪", 50, main_node().get_global_mouse_position())
		main_node().show_message("全脸微调完成！颜值飙升！虽然情商-10（有人说你假），但自己看着超开心！")
	)


# ==================== 星座App ====================

func _on_close_zodiac() -> void:
	zodiac_popup.visible = false


# ==================== 贝壳找房App ====================

func _on_house_village() -> void:
	if GameManager.money < 3000:
		main_node().show_message("余额不足，城中村押金需要 3000 元。")
		return
	GameManager.modify_stat("money", -3000)
	GameManager.base_rent = 1500
	GameManager.housing_level = 0
	GameManager.housing_buff_sanity = 0
	main_node().float_stat("搬家->城中村 押金-3000", -3000, main_node().get_global_mouse_position())
	main_node().show_message("搬家成功！押金 3000 已扣，下月开始交房租 1500。")

func _on_house_apartment() -> void:
	if GameManager.money < 8000:
		main_node().show_message("余额不足，精装公寓押金需要 8000 元。")
		return
	GameManager.modify_stat("money", -8000)
	GameManager.base_rent = 4000
	GameManager.housing_level = 1
	GameManager.housing_buff_sanity = 10
	GameManager.modify_stat("charm", 5)
	main_node().float_stat("搬家->精装公寓 押金-8000 +5颜值", 5, main_node().get_global_mouse_position())
	main_node().show_message("搬家成功！押金 8000 已扣，精装公寓每周恢复10情绪，颜值+5！")

func _on_house_luxury() -> void:
	if GameManager.money < 24000:
		main_node().show_message("余额不足，CBD大平层押金需要 24000 元。")
		return
	GameManager.modify_stat("money", -24000)
	GameManager.base_rent = 12000
	GameManager.housing_level = 2
	GameManager.housing_buff_sanity = 25
	GameManager.modify_stat("charm", 10)
	main_node().float_stat("搬家->CBD大平层 押金-24000 +10颜值", 10, main_node().get_global_mouse_position())
	main_node().show_message("搬家成功！押金 24000 已扣，CBD大平层每周恢复25情绪，颜值+10！")


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
	GameManager.modify_stat("energy", -5)
	# 颜值+情商越高，被骗概率越低，遇到好结果概率越高
	var score: int = GameManager.charm + GameManager.eq
	var roll: int = randi() % 100
	var scam_chance: int = 70 - score  # 颜值+情商每高1点，被骗概率-1%
	if scam_chance < 20:
		scam_chance = 20
	if roll < scam_chance:
		GameManager.modify_stat("money", -500)
		GameManager.modify_stat("sanity", -15)
		main_node().float_stat("被骗 -500 金钱 -15 情绪", -500, main_node().get_global_mouse_position())
		main_node().show_message("遇到了骗子，被骗走 500 块饭钱，情绪 -15。", true)
	elif roll < scam_chance + 50:
		main_node().show_message("聊了两句互相拉黑，毫无波澜。", true)
	else:
		GameManager.modify_stat("eq", 2)
		main_node().float_stat("+2 情商", 2, main_node().get_global_mouse_position())
		main_node().show_message("遇到个奇葩，但你的防骗经验增加了！(情商 +2)", true)
	_refresh_dating_card()

func _on_close_dating() -> void:
	dating_popup.visible = false


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
	if GameManager.weekend_actions <= 0:
		return "本周行动次数已用完"
	if GameManager.energy < energy_cost:
		return "精力不足：需要%d，当前%d" % [energy_cost, GameManager.energy]
	return ""


func _spend_career_action(label: String, energy_cost: int, sanity_cost: int) -> bool:
	var reason := _career_action_lock_reason(energy_cost)
	if reason != "":
		main_node().show_message(reason)
		return false
	var spent := false
	if main_node().get("action_service") and main_node().action_service.has_method("spend_weekend_action"):
		spent = main_node().action_service.spend_weekend_action(label)
	else:
		if GameManager.weekend_actions <= 0:
			main_node().show_message("周末行动次数不足：" + label)
			return false
		GameManager.weekend_actions = maxi(GameManager.weekend_actions - 1, 0)
		spent = true
		if main_node().has_method("_update_weekend_ui"):
			main_node()._update_weekend_ui()
	if not spent:
		return false
	GameManager.modify_stat("energy", -energy_cost)
	if sanity_cost > 0:
		GameManager.modify_stat("sanity", -sanity_cost)
	return true


func _media_lock_reason() -> String:
	if not _is_weekend_phase():
		return "工作日只能查看，周末才能面试"
	if GameManager.weekend_actions <= 0:
		return "本周行动次数已用完"
	if GameManager.energy < 15:
		return "精力需15（当前%d）" % GameManager.energy
	if GameManager.degree < 1:
		return "需成人本科：微信找尚德夜校王老师上课（%d/12）" % GameManager.night_school_progress
	return ""


func _client_lock_reason() -> String:
	var missing: Array = []
	if not _is_weekend_phase():
		missing.append("周末面试")
	if GameManager.weekend_actions <= 0:
		missing.append("行动次数")
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
	_close_all_menus()
	for child in job_menu.get_children():
		child.queue_free()
	var phase_text := "周末行动：%d/%d" % [GameManager.weekend_actions, GameManager.max_weekend_actions] if _is_weekend_phase() else "工作日仅查看"
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
		"cost": "面试行动-1 | 精力-15 情绪-10 | 底薪 2000/4000/6000。要求：成人本科。",
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
		"cost": "面试行动-1 | 精力-20 情绪-15 | 底薪 4000/8000/12000。要求：新媒体履历、成人本科、30岁以下。",
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
	GameManager.job_level = 0
	GameManager.add_activity("工作", "调整回初级行政岗位，收入下降但压力也更低。")
	_show_action_result("已转回初级行政，底薪 800/1500/2500。", {}, func() -> void:
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
	GameManager.job_level = 1
	GameManager.add_activity("工作", "通过新媒体运营面试，职位提升。")
	_show_action_result("跳槽成功。下周开始，新媒体运营底薪 2000/4000/6000。", {"weekend_actions": -1, "energy": -15, "sanity": -10}, func() -> void:
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
	GameManager.job_level = 2
	GameManager.add_activity("工作", "拿下大客户经理岗位，正式进入高薪高压轨道。")
	_show_action_result("面试通过。大客户经理底薪 4000/8000/12000，但从下周开始，职场风险也会更重。", {"weekend_actions": -1, "energy": -20, "sanity": -15}, func() -> void:
		_refresh_main_ui()
		_on_app_job()
	)


# ==================== 日记本 UI ====================

func _diary_week_str(entry: Dictionary) -> String:
	if entry.has("age") and entry.has("month") and entry.has("week_in_month"):
		return "%d岁 %d月第%d周" % [entry["age"], entry["month"], entry["week_in_month"]]
	return "第%d周" % entry.get("week", 0)

func _on_diary_filter(category: String) -> void:
	_diary_filter = category
	_refresh_diary_ui()

func _refresh_diary_ui() -> void:
	for child in diary_log_container.get_children():
		child.queue_free()
	var logs: Array = GameManager.activity_log
	for i in range(logs.size()):
		var entry: Dictionary = logs[i]
		if _diary_filter != "全部" and entry.get("category", "") != _diary_filter:
			continue
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text = "[%s - %s] %s" % [_diary_week_str(entry), entry["category"], entry["desc"]]
		match entry.get("category", ""):
			"提升":
				lbl.add_theme_color_override("font_color", Color(0.12, 0.35, 0.75, 1))
			"社交":
				lbl.add_theme_color_override("font_color", Color(0.85, 0.35, 0.1, 1))
			"消费":
				lbl.add_theme_color_override("font_color", Color.RED)
			_:
				lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
		diary_log_container.add_child(lbl)


# ==================== 深夜网抑云失眠系统 ====================

## 进入深夜失眠弹窗（随机抽取一种冲动消费作为诱惑）
func _enter_late_night() -> void:
	_pending_impulse = _impulse_pool[randi() % _impulse_pool.size()]
	btn_emo_bag.text = _pending_impulse["text"]
	btn_emo_sleep.text = "忍住诱惑，强迫自己睡觉 (颜值-2 情绪-10 精力-20)"
	late_night_popup.visible = true

## 按钮 A：冲动消费换取多巴胺
func _on_emo_bag() -> void:
	var imp: Dictionary = _pending_impulse
	GameManager.huabei_debt += imp["huabei"]
	GameManager.credit_debt = GameManager.huabei_debt
	if imp["sanity"] > 0:
		GameManager.modify_stat("sanity", imp["sanity"])
	if imp["charm"] > 0:
		GameManager.modify_stat("charm", imp["charm"])
	GameManager.add_finance(-imp["huabei"], imp["desc"], true)
	GameManager.add_activity("消费", "深夜失眠，冲动消费换取了短暂的安慰。")
	main_node().float_stat("花呗 +%d" % imp["huabei"], -imp["huabei"], main_node().get_global_mouse_position())
	main_node().show_message("下单了...短暂的快乐之后是更深的空虚。", true)
	late_night_popup.visible = false
	main_node()._proceed_next_week()

## 按钮 B：硬抗！强行闭眼到天亮
func _on_emo_sleep() -> void:
	GameManager.modify_stat("charm", -2)
	GameManager.modify_stat("sanity", -10)
	GameManager.modify_stat("energy", -20)
	GameManager.add_activity("日常", "失眠了一整夜，第二天感觉身体被掏空。")
	main_node().float_stat("颜值-2 情绪-10 精力-20", -20, main_node().get_global_mouse_position())
	main_node().show_message("辗转反侧到天亮，气色极差，整个人像被抽空了...", true)
	late_night_popup.visible = false
	if not GameManager.game_finished:
		main_node()._proceed_next_week()
