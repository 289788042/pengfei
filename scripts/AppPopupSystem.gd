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


# ==================== 地图/地点 ====================

func _on_close_loc() -> void:
	location_menu.visible = false


func _on_app_map() -> void:
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
		{"name": "图书馆", "icon_color": Color(0.2, 0.5, 0.9), "cost": "-20精力 | +2学识 +5情绪", "action": _on_loc_library},
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
		var row := PanelContainer.new()
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(1, 1, 1, 1)
		row_style.set_content_margin_all(0)
		row.add_theme_stylebox_override("panel", row_style)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		loc_list.add_child(row)
		var row_hbox := HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 12)
		row_hbox.custom_minimum_size = Vector2(0, 72)
		row.add_child(row_hbox)
		## 左侧图标占位
		var icon_ml := Control.new()
		icon_ml.custom_minimum_size = Vector2(16, 0)
		row_hbox.add_child(icon_ml)
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.color = loc["icon_color"]
		pass  # rounded placeholder
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
		row.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_close_loc()
				captured_action.call()
		)
	location_menu.visible = true


func _on_app_diary() -> void:
	_refresh_diary_ui()
	diary_popup.visible = true


func _on_app_baotao() -> void:
	for child in baotao_menu.get_children():
		child.queue_free()
	var debt_info := "花呗欠款：%d 元" % (GameManager.huabei_debt + GameManager.huabei_installment_debt)
	var items := [
		{"name": "大牌护肤套装", "icon_color": Color(0.95, 0.45, 0.6), "cost": "800 元 | +5颜值 +5情绪", "action": _on_bt_skincare},
		{"name": "快时尚穿搭", "icon_color": Color(0.3, 0.7, 0.9), "cost": "1500 元 | +8颜值 +10情绪", "action": _on_bt_fashion},
	]
	_build_app_overlay(baotao_menu, "宝淘", Color(0.95, 0.35, 0.35, 1), debt_info, items)
	baotao_menu.visible = true


func _on_app_tuanmei() -> void:
	for child in tuanmei_menu.get_children():
		child.queue_free()
	var debt_info := "花呗欠款：%d 元" % (GameManager.huabei_debt + GameManager.huabei_installment_debt)
	var items := [
		{"name": "水光针+热玛吉", "icon_color": Color(0.8, 0.4, 0.8), "cost": "6000 元 | +15颜值 | 需颜值<30", "action": _on_tm_injection},
		{"name": "全脸微调手术", "icon_color": Color(0.6, 0.2, 0.8), "cost": "20000 元 | +30颜值 | 需颜值<20", "action": _on_tm_surgery},
	]
	_build_app_overlay(tuanmei_menu, "团美医美", Color(0.6, 0.3, 0.8, 1), debt_info, items)
	tuanmei_menu.visible = true


func _on_app_zodiac() -> void:
	label_zodiac_content.text = "亲爱的%s宝宝，本周运势：\n请注意控制消费，警惕烂桃花哦！" % GameManager.player_zodiac
	zodiac_popup.visible = true


func _on_app_house() -> void:
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
	house_menu.visible = true


func _on_app_dating() -> void:
	if GameManager.charm < 10:
		main_node().show_message("颜值太低（需>=10），没有匹配对象！先提升自己吧~")
		return
	_refresh_dating_card()
	dating_popup.visible = true


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
			parent.visible = false
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
		text_vbox.add_child(cost_lbl)
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
			if item.has("lock_reason"):
				var reason_lbl := Label.new()
				reason_lbl.text = item["lock_reason"]
				reason_lbl.add_theme_font_size_override("font_size", 10)
				reason_lbl.add_theme_color_override("font_color", Color(0.7, 0.3, 0.3, 1))
				row_hbox.add_child(reason_lbl)
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
					parent.visible = false
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
	# 检查是否带选项
	var choices: Array = frag.get("choices", [])
	if choices.size() > 0:
		var pages: Array = [text]
		if bonus_text != "":
			pages.append(bonus_text)
		main_node().galgame.show_galgame_dialog(pages, func() -> void:
			_show_fragment_choices(choices)
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
	var pages: Array = [text]
	var all_effects: String = bonus_text
	if effect_parts.size() > 0:
		if all_effects != "":
			all_effects += "  "
		all_effects += "  ".join(effect_parts)
	if all_effects != "":
		pages.append(all_effects)
	main_node().galgame.show_galgame_dialog(pages)


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
	var pages: Array = []
	if result != "":
		pages.append(result)
	var all_parts: Array = cost_parts + effect_parts
	if all_parts.size() > 0:
		pages.append("  ".join(all_parts))
	if pages.size() > 0:
		gal.show_galgame_dialog(pages)

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
	var loc_cn: String = {"gym": "健身房", "library": "图书馆", "bar": "酒吧", "home": "家里"}.get(location, location)
	var template: String = _reunion_lines[randi() % _reunion_lines.size()]
	var text: String = template.replace("{name}", npc_name).replace("{loc}", loc_cn)
	var runtime = GameManager.get_npc_runtime(npc_id)
	if runtime:
		runtime["affection"] = runtime.get("affection", 0) + 3
	GameManager.modify_stat("sanity", 3)
	GameManager.modify_stat("eq", 1)
	GameManager.add_activity("社交", "在%s遇到了%s，聊了几句" % [loc_cn, npc_name])
	main_node().show_message(text + "
[color=90EE90]好感+3 情绪+3 情商+1[/color]", true)


# ==================== 地点逻辑 ====================

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

## 处理邂逅场景（通用版）
func _handle_encounter(npc: Dictionary, location: String, energy_cost: int, money_cost: int) -> void:
	var enc: Dictionary = npc.get("encounter", {})
	var npc_id: String = npc.get("id", "")
	var npc_name: String = npc.get("name", "")
	var req: Dictionary = enc.get("req_stats", {})

	var all_ok: bool = true
	for stat_name in req:
		var needed: int = int(req[stat_name])
		var current: int = GameManager.get(stat_name) if stat_name != "money" else GameManager.money
		if current < needed:
			all_ok = false
			break

	if energy_cost > 0 and GameManager.energy < energy_cost:
		main_node().show_message("精力不足（需%d）！" % energy_cost)
		return

	GameManager.modify_stat("energy", -energy_cost)
	_encounter_cooldowns[npc_id] = GameManager.turn_count + 99
	location_menu.visible = false

	if all_ok:
		var pass_changes: Dictionary = enc.get("pass_stat_changes", {})
		for stat_name in pass_changes:
			if stat_name == "affection":
				GameManager.get_npc_runtime(npc_id)["affection"] += int(pass_changes[stat_name])
			else:
				GameManager.modify_stat(stat_name, int(pass_changes[stat_name]))

		var pages: Array = []
		for line in enc.get("scene_lines", []):
			pages.append(line)
		for line in enc.get("dialogue_lines", []):
			pages.append(npc_name + "：" + line)

		var wechat_req: Dictionary = enc.get("wechat_request", {})
		if wechat_req.size() > 0:
			main_node().galgame._gal_encounter_data = enc
			main_node().galgame._gal_npc_id = npc_id
			main_node().galgame.show_galgame_dialog(pages, main_node().galgame.start_wechat_request_phase)
		else:
			main_node().galgame.show_galgame_dialog(pages, func() -> void:
				main_node().show_message("邂逅了%s，但没有进一步发展。" % npc_name, true)
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
			if location == "gym":
				_normal_gym()
			elif location == "bar":
				_normal_bar()
			else:
				main_node().show_message("度过了平静的一天。", true)
		)

func _on_loc_library() -> void:
	if GameManager.energy < 20:
		main_node().show_message("精力不足，无法去图书馆！")
		return
	location_menu.visible = false
	var roll := randf()
	if roll < 0.20:
		# 20%: NPC邂逅
		var encounter_npc: Dictionary = {}
		for npc in GameManager.npc_database:
			var enc: Dictionary = npc.get("encounter", {})
			if enc.get("location", "") == "library" and not GameManager.is_npc_unlocked(npc.get("id", "")) and _encounter_cooldowns.get(npc.get("id", ""), 0) <= GameManager.turn_count:
				encounter_npc = npc
				break
		if encounter_npc.size() > 0:
			_handle_encounter(encounter_npc, "library", 20, 0)
			return
		# 尝试重逢
		var reunion = _check_reunion("library")
		if reunion.size() > 0:
			GameManager.modify_stat("energy", -20)
			_handle_reunion(reunion, "library")
			GameManager.modify_stat("intellect", 3)
			GameManager.modify_stat("sanity", 5)
			GameManager.add_activity("提升", "在图书馆读书并遇到了熟人")
			return
	# 正常活动
	GameManager.modify_stat("energy", -20)
	GameManager.modify_stat("intellect", 3)
	GameManager.modify_stat("sanity", 5)
	if roll < 0.50:
		# 30%: 城市碎片
		_trigger_city_fragment("library", "[color=90EE90]学识+3 情绪+5[/color]")
		GameManager.add_activity("提升", "在图书馆读书，学识+3，情绪+5")
	else:
		# 50%: 纯正常
		main_node().show_message("在图书馆度过了一个充实的下午。
[color=90EE90]学识+3 情绪+5[/color]", true)
		GameManager.add_activity("提升", "在图书馆读书，学识+3，情绪+5")

func _on_loc_gym() -> void:
	if GameManager.energy < 45:
		main_node().show_message("精力不足（需45），无法去健身房！")
		return
	location_menu.visible = false
	var roll := randf()
	if roll < 0.20:
		# 20%: NPC邂逅
		var encounter_npc = _check_encounter("gym")
		if encounter_npc.size() > 0:
			_handle_encounter(encounter_npc, "gym", 45, 0)
			return
		var reunion = _check_reunion("gym")
		if reunion.size() > 0:
			main_node().alipay.request_payment(200, "健身房消费", "提升", func() -> void:
				GameManager.modify_stat("energy", -45)
				_handle_reunion(reunion, "gym")
				GameManager.modify_stat("charm", 2)
				GameManager.modify_stat("sanity", 5)
				GameManager.max_energy += 1
				GameManager.add_activity("提升", "去健身房挥汗如雨！颜值+2，精力上限+1（当前%d）" % GameManager.max_energy)
			)
			return
	# 正常活动（30%碎片 / 50%纯正常）
	if roll < 0.50:
		main_node().alipay.request_payment(200, "健身房消费", "提升", func() -> void:
			GameManager.modify_stat("energy", -45)
			GameManager.modify_stat("charm", 2)
			GameManager.modify_stat("sanity", 5)
			GameManager.max_energy += 1
			_trigger_city_fragment("gym", "[color=90EE90]颜值+2 情绪+5 精力上限+1[/color]")
			GameManager.add_activity("提升", "去健身房挥汗如雨！颜值+2，情绪+5，精力上限永久+1（当前%d）" % GameManager.max_energy)
		)
	else:
		_normal_gym()

func _normal_gym() -> void:
	main_node().alipay.request_payment(200, "健身房消费", "提升", func() -> void:
		GameManager.modify_stat("energy", -45)
		GameManager.modify_stat("charm", 2)
		GameManager.modify_stat("sanity", 5)
		GameManager.max_energy += 1
		main_node().float_stat("+2 颜值 +5 情绪 精力上限+1", 5, main_node().get_global_mouse_position())
		_visit_location("gym", "挥汗如雨！颜值+2，精力上限永久+1！")
	)

func _on_loc_bar() -> void:
	if GameManager.energy < 20:
		main_node().show_message("精力不足，无法去酒吧！")
		return
	if GameManager.eq < 10:
		main_node().show_message("情商太低（需>=10），在酒吧也只会尴尬地坐着！")
		return
	location_menu.visible = false
	var roll := randf()
	if roll < 0.20:
		# 20%: NPC邂逅
		var encounter_npc = _check_encounter("bar")
		if encounter_npc.size() > 0:
			_handle_encounter(encounter_npc, "bar", 20, 500)
			return
		var reunion = _check_reunion("bar")
		if reunion.size() > 0:
			main_node().alipay.request_payment(500, "酒吧消费", "社交", func() -> void:
				GameManager.modify_stat("energy", -20)
				_handle_reunion(reunion, "bar")
				GameManager.modify_stat("eq", 2)
				GameManager.modify_stat("sanity", 25)
				GameManager.add_activity("社交", "在酒吧喝酒并遇到了熟人")
			)
			return
	# 正常活动（30%碎片 / 50%纯正常）
	if roll < 0.50:
		main_node().alipay.request_payment(500, "酒吧消费", "社交", func() -> void:
			GameManager.modify_stat("energy", -20)
			GameManager.modify_stat("eq", 2)
			GameManager.modify_stat("sanity", 25)
			_trigger_city_fragment("bar", "[color=90EE90]情商+2 情绪+25[/color]")
			GameManager.add_activity("社交", "在酒吧喝了一杯，感觉心情大好！")
		)
	else:
		_normal_bar()

func _normal_bar() -> void:
	main_node().alipay.request_payment(500, "酒吧消费", "社交", func() -> void:
		GameManager.modify_stat("energy", -20)
		GameManager.modify_stat("eq", 2)
		GameManager.modify_stat("sanity", 25)
		main_node().float_stat("+2 情商 +25 情绪", 25, main_node().get_global_mouse_position())
		_visit_location("bar", "在酒吧喝了一杯，感觉心情大好！")
	)

func _on_loc_home() -> void:
	GameManager.modify_stat("energy", -10)
	location_menu.visible = false
	var roll := randf()
	if roll < 0.20:
		# 20%: 尝试重逢（家里不太可能，但保留统一结构）
		pass
	if roll < 0.50:
		# 30%: 城市碎片
		GameManager.modify_stat("sanity", 20)
		_trigger_city_fragment("home", "[color=90EE90]精力恢复+40[/color]")
		GameManager.add_activity("日常", "宅家刷了一整天手机")
	else:
		# 50%: 正常
		GameManager.modify_stat("sanity", 20)
		main_node().float_stat("+20 情绪", 20, main_node().get_global_mouse_position())
		main_node().show_message("宅家刷了一整天手机，虽然眼睛酸但心情不错~", true)
		GameManager.add_activity("日常", "宅家刷了一整天手机")



func _on_loc_park() -> void:
	if _park_visited_week == GameManager.turn_count:
		main_node().show_message("这周已经去过深圳湾了，来回太远，下周再去吧。")
		return
	location_menu.visible = false
	var roll := randf()
	if roll < 0.20:
		var encounter_npc = _check_encounter("park")
		if encounter_npc.size() > 0:
			_park_visited_week = GameManager.turn_count
			_handle_encounter(encounter_npc, "park", 0, 0)
			return
		var reunion = _check_reunion("park")
		if reunion.size() > 0:
			_park_visited_week = GameManager.turn_count
			GameManager.modify_stat("energy", 10)
			GameManager.modify_stat("sanity", 3)
			_handle_reunion(reunion, "park")
			GameManager.add_activity("日常", "在公园散步并遇到了熟人")
			return
	_park_visited_week = GameManager.turn_count
	GameManager.modify_stat("energy", 10)
	GameManager.modify_stat("sanity", 3)
	if roll < 0.50:
		_trigger_city_fragment("park", "[color=90EE90]精力+10 情绪+3[/color]")
		GameManager.add_activity("日常", "在公园·深圳湾散步，精力+10，情绪+3")
	else:
		main_node().show_message("在深圳湾公园散了一个下午的步，海风吹散了一天的疲惫。
[color=90EE90]精力+10 情绪+3[/color]", true)
		GameManager.add_activity("日常", "在公园·深圳湾散步，精力+10，情绪+3")

func _on_loc_cafe() -> void:
	if GameManager.energy < 5:
		main_node().show_message("精力不足（需5），连去咖啡厅的力气都没有了！")
		return
	location_menu.visible = false
	var roll := randf()
	if roll < 0.20:
		var encounter_npc = _check_encounter("cafe")
		if encounter_npc.size() > 0:
			_handle_encounter(encounter_npc, "cafe", 5, 60)
			return
		var reunion = _check_reunion("cafe")
		if reunion.size() > 0:
			main_node().alipay.request_payment(60, "咖啡厅消费", "提升", func() -> void:
				GameManager.modify_stat("energy", -5)
				_handle_reunion(reunion, "cafe")
				GameManager.modify_stat("intellect", 2)
				GameManager.modify_stat("eq", 3)
				GameManager.add_activity("提升", "在咖啡厅学习并遇到了熟人")
			)
			return
	if roll < 0.50:
		main_node().alipay.request_payment(60, "咖啡厅消费", "提升", func() -> void:
			GameManager.modify_stat("energy", -5)
			GameManager.modify_stat("intellect", 2)
			GameManager.modify_stat("eq", 3)
			_trigger_city_fragment("cafe", "[color=90EE90]学识+2 情商+3[/color]")
			GameManager.add_activity("提升", "在咖啡厅学习，学识+2，情商+3")
		)
	else:
		main_node().alipay.request_payment(60, "咖啡厅消费", "提升", func() -> void:
			GameManager.modify_stat("energy", -5)
			GameManager.modify_stat("intellect", 2)
			GameManager.modify_stat("eq", 3)
			main_node().show_message("在咖啡厅安静地学习了一下午，效率出奇的高。
[color=90EE90]学识+2 情商+3[/color]", true)
			GameManager.add_activity("提升", "在咖啡厅学习，学识+2，情商+3")
		)

func _on_loc_market() -> void:
	location_menu.visible = false
	var roll := randf()
	if roll < 0.20:
		var encounter_npc = _check_encounter("market")
		if encounter_npc.size() > 0:
			_handle_encounter(encounter_npc, "market", 0, 100)
			return
		var reunion = _check_reunion("market")
		if reunion.size() > 0:
			main_node().alipay.request_payment(100, "夜市消费", "美食", func() -> void:
				_handle_reunion(reunion, "market")
				GameManager.modify_stat("sanity", 15)
				GameManager.add_activity("美食", "在夜市吃夜宵并遇到了熟人")
			)
			return
	if roll < 0.50:
		main_node().alipay.request_payment(100, "夜市消费", "美食", func() -> void:
			GameManager.modify_stat("sanity", 15)
			_trigger_city_fragment("market", "[color=90EE90]情绪+15[/color]")
			GameManager.add_activity("美食", "在夜市吃了夜宵，情绪+15")
		)
	else:
		main_node().alipay.request_payment(100, "夜市消费", "美食", func() -> void:
			GameManager.modify_stat("sanity", 15)
			main_node().show_message("烧烤、砂锅粥、炒粉……吃得满足极了！
[color=90EE90]情绪+15[/color]", true)
			GameManager.add_activity("美食", "在夜市吃了夜宵，情绪+15")
		)

func _on_loc_overtime() -> void:
	if GameManager.energy < 40:
		main_node().show_message("精力不足（需40），加不动班了！")
		return
	location_menu.visible = false
	GameManager.modify_stat("energy", -40)
	GameManager.modify_stat("sanity", -35)
	var overtime_pay: int = randi() % 300 + 500
	GameManager.modify_stat("money", overtime_pay)
	var roll := randf()
	if roll < 0.20:
		var event := GameManager.roll_random_event("overtime")
		if event.size() > 0:
			main_node()._show_event(event, func() -> void:
				main_node().show_message("加班到深夜，虽然累但赚了%d元加班费。
[color=90EE90]精力-40 情绪-35 金钱+%d[/color]" % [overtime_pay, overtime_pay], true)
			)
			GameManager.add_activity("工作", "公司加班，赚了%d元加班费" % overtime_pay)
			return
	main_node().show_message("加班到深夜，虽然累但赚了%d元加班费。
[color=90EE90]精力-40 情绪-35 金钱+%d[/color]" % [overtime_pay, overtime_pay], true)
	GameManager.add_activity("工作", "公司加班，赚了%d元加班费" % overtime_pay)


func _visit_location(context: String, success_msg: String) -> void:
	location_menu.visible = false
	var event := GameManager.roll_random_event(context)
	if event.size() > 0:
		main_node()._show_event(event, func() -> void: pass)
	else:
		main_node().show_message(success_msg, true)

# ==================== 饮食系统 ====================

func _on_food_low() -> void:
	GameManager.monthly_food_cost += 300
	GameManager.modify_stat("sanity", -15)
	GameManager.add_activity("日常", "吃了挂逼生存套餐（沙县/拉面），花费300元")
	GameManager.consecutive_poor_food += 1
	GameManager.consecutive_overtime = 0
	main_node().float_stat("+300 餐饮", -300, main_node().get_global_mouse_position())
	# 连续吃土死法检查
	var death: Dictionary = GameManager.check_behavior_death()
	if death.size() > 0:
		GameManager.game_over.emit(death["title"], death["desc"])
		return
	_unlock_work_buttons()

func _on_food_mid() -> void:
	GameManager.monthly_food_cost += 800
	GameManager.modify_stat("energy", 10)
	GameManager.add_activity("日常", "吃了打工人标配（肯德基/火锅），花费800元")
	GameManager.consecutive_poor_food = 0
	GameManager.consecutive_overtime = 0
	main_node().float_stat("+800 餐饮 +10 精力", -800, main_node().get_global_mouse_position())
	_unlock_work_buttons()

func _on_food_high() -> void:
	GameManager.monthly_food_cost += 2000
	GameManager.modify_stat("sanity", 20)
	GameManager.add_activity("日常", "吃了小资高档（日料/西餐），花费2000元")
	GameManager.modify_stat("energy", 15)
	GameManager.consecutive_poor_food = 0
	GameManager.consecutive_overtime = 0
	main_node().float_stat("+2000 餐饮 +20 情绪 +15 精力", -2000, main_node().get_global_mouse_position())
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
	GameManager.money -= 3000
	GameManager.base_rent = 1500
	GameManager.housing_level = 0
	GameManager.housing_buff_sanity = 0
	main_node().float_stat("搬家->城中村 押金-3000", -3000, main_node().get_global_mouse_position())
	main_node().show_message("搬家成功！押金 3000 已扣，下月开始交房租 1500。")

func _on_house_apartment() -> void:
	GameManager.money -= 8000
	GameManager.base_rent = 4000
	GameManager.housing_level = 1
	GameManager.housing_buff_sanity = 10
	GameManager.modify_stat("charm", 5)
	main_node().float_stat("搬家->精装公寓 押金-8000 +5颜值", 5, main_node().get_global_mouse_position())
	main_node().show_message("搬家成功！押金 8000 已扣，精装公寓每周恢复10情绪，颜值+5！")

func _on_house_luxury() -> void:
	GameManager.money -= 24000
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

func _on_app_job() -> void:
	for child in job_menu.get_children():
		child.queue_free()
	var degree_names := ["大专", "成人本科"]
	var job_names := ["初级行政", "新媒体运营", "大客户经理"]
	var status := "职位：%s | 学历：%s | 年龄：%d" % [job_names[GameManager.job_level], degree_names[min(GameManager.degree, 1)], GameManager.age]
	var items := [
		{"name": "初级行政", "icon_color": Color(0.3, 0.65, 0.35), "cost": "底薪 800~2500/周", "action": _on_job_admin, "current": GameManager.job_level == 0},
		{"name": "新媒体运营", "icon_color": Color(0.2, 0.55, 0.9), "cost": "底薪 2000~6000/周", "action": _on_job_media,
			"locked": GameManager.intellect < 30, "current": GameManager.job_level == 1,
			"lock_reason": "学识需达到 30 (当前 %d)" % GameManager.intellect},
		{"name": "大客户经理", "icon_color": Color(0.9, 0.7, 0.15), "cost": "底薪 4000~12000/周", "action": _on_job_client,
			"locked": GameManager.degree < 1 or GameManager.age >= 30, "current": GameManager.job_level == 2,
			"lock_reason": "需本科学历+30岁以下" if GameManager.degree < 1 else "HR：本岗位倾向培养30岁以下年轻人"},
	]
	_build_app_overlay(job_menu, "BOSS弯聘", Color(0.2, 0.55, 0.9, 1), status, items)
	job_menu.visible = true

func _on_job_admin() -> void:
	GameManager.job_level = 0
	main_node().float_stat("入职初级行政", 800, main_node().get_global_mouse_position())
	main_node().show_message("已入职初级行政，底薪 800~2500/周。")

func _on_job_media() -> void:
	GameManager.job_level = 1
	main_node().float_stat("跳槽成功！底薪涨至 4000", 4000, main_node().get_global_mouse_position())
	main_node().show_message("跳槽成功！新媒体运营底薪 2000~6000/周。")

func _on_job_client() -> void:
	GameManager.job_level = 2
	main_node().float_stat("成功跨越阶层！底薪涨至 8000", 8000, main_node().get_global_mouse_position())
	main_node().show_message("成功跨越阶层！大客户经理底薪 4000~12000/周。")


# ==================== 日记本 UI ====================

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
		lbl.text = "[第%d周 - %s] %s" % [entry["week"], entry["category"], entry["desc"]]
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
	main_node()._proceed_next_week()
