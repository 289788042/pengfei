## WeChatSystem.gd - 微信系统管理器
## 负责：微信聊天、联系人、朋友圈、家庭群、NPC约会等全部微信UI逻辑
## 通过 _main 引用 MainGame 节点访问 UI 节点和工具函数
class_name WeChatSystem
extends RefCounted

# ==================== 微信颜色常量 ====================

const WC_GREEN: Color = Color(0.027, 0.757, 0.376, 1)
const WC_BUBBLE_SELF: Color = Color(0.584, 0.925, 0.412, 1)
const WC_BG: Color = Color(0.929, 0.929, 0.929, 1)
const WC_TAB_BG: Color = Color(0.969, 0.969, 0.969, 1)
const WC_RED: Color = Color(0.98, 0.318, 0.318, 1)
const WC_TEXT_PRIMARY: Color = Color(0.1, 0.1, 0.1, 1)
const WC_TEXT_SECONDARY: Color = Color(0.55, 0.55, 0.55, 1)

# ==================== 状态变量 ====================

## 当前打开的聊天NPC ID
var _current_chat_npc: String = ""
var _chat_menu_panel: PanelContainer = null
var _current_tab: int = 0
## 动态生成的回复选项按钮容器
var _reply_btn_container: VBoxContainer = null
## 存储每个NPC的聊天条目UI节点引用
var _chat_items: Dictionary = {}
## 手机桌面微信图标的未读角标
var _app_badge: Label = null

## 家庭群随机事件池
var _family_events: Array = [
	{
		"title": "无效的相亲局",
		"desc": "妈：隔壁王阿姨的儿子在深圳当程序员，年薪50万，人很老实的！

你妈兴冲冲地推来了一个微信名片。你点开朋友圈一看——全是'奋斗逼语录'和健身自拍。再一看共同好友：你的高中同学、你前男友、还有你老板。",
		"choices": [
			{"label": "加微信聊聊看吧", "effects": {"eq": 5, "sanity": -20}, "affection_gain": 0, "msg": "加了微信，对方第一句话就是：'你月薪多少？能接受异地吗？'
（情商 +5, 情绪 -20）"},
			{"label": "明确拒绝，别烦我", "effects": {"sanity": -10}, "affection_gain": -5, "msg": "你妈沉默了五秒：'行吧，你自己的事自己决定。'
（亲情 -5, 情绪 -10）"},
		],
	},
	{
		"title": "坏掉的冰箱",
		"desc": "妈：家里的冰箱又坏了，你爸说修修还能用，但我觉得也该换了...

你看着视频里妈妈笑嘻嘻的脸，突然注意到她身后那个用了十年的老冰箱，门关不严，用胶带缠着。",
		"choices": [
			{"label": "转5000块换个新的", "effects": {"money": -5000, "sanity": 30}, "affection_gain": 30, "msg": "妈妈发了个哭泣的表情包，说：'闺女长大了！'
（金钱 -5000, 亲情 +30, 情绪 +30）"},
			{"label": "让他们自己想办法", "effects": {"sanity": -10}, "affection_gain": -10, "msg": "你挂了电话，心里堵得慌。
（亲情 -10, 情绪 -10）"},
		],
	},
]



## 家庭群随机闲聊旁白（10条）
var _family_chat_chats: Array = [
	"群里一帮七大姑八姨在扯老婆舌，你看了看，跟你没半毛钱关系。",
	"群里在聊泡脚可以治百病，你爸说他试了确实有效。",
	"群里在讨论不孝子女的十大特征，你感觉在内涵你。",
	"二舅在群里转发《震惊！这个东西竟然致癌》，已经是今周第三次了。",
	"表姐在群里晒娃，九宫格刷屏，你默默关掉了通知。",
	"大伯在群里发中年男性养生文章，标题是《男人四十一朵花》。",
	"群里在讨论谁家孩子工资最高，你假装没看到。",
	"三姨在群里卖保险，已经私发你三次了。",
	"群里在转发《女人过了30岁就贬值了》，你感觉被内涵了。",
	"表哥在群里借钱，说是要创业。你已经装死了。",
]

## 家庭群正面事件（点击后增加情绪）
var _family_positive_events: Array = [
	{"label": "群里在心疼孩子们在外的艰辛", "sanity": 5, "money": 0, "msg": "你妈说：“孩子在外面不容易，要是累了就回家。”你看着屏幕，鼻子有点酸。"},
	{"label": "大姨发了个红包，抢到了！", "sanity": 5, "money": 8, "msg": "大姨发了一个50元红包，你手气好抢到了8.88元！这大概是今周最开心的事了。"},
	{"label": "大家感慨生活的来之不易", "sanity": 5, "money": 0, "msg": "你爸难得说了句感性的话：“一家人平平安安的就是福气。”你觉得他说得对。"},
]


## MainGame 节点引用
var _main: Control


# ==================== 初始化 ====================

func init(main: Control) -> void:
	_main = main


# ==================== 辅助方法 ====================

func is_visible() -> bool:
	return _main.wechat_menu.visible

func force_close() -> void:
	_main.wechat_menu.visible = false
	_main.wc_chat_view.visible = false


## 更新手机桌面微信图标的红色角标
func _update_app_badge() -> void:
	var total: int = GameManager.get_total_unread()
	## 查找或创建角标
	if _app_badge == null or not is_instance_valid(_app_badge):
		_app_badge = Label.new()
		_app_badge.name = "AppBadge"
		_app_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_app_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_app_badge.add_theme_font_size_override("font_size", 12)
		_app_badge.add_theme_color_override("font_color", Color.WHITE)
		_app_badge.custom_minimum_size = Vector2(22, 22)
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = WC_RED
		badge_style.set_corner_radius_all(11)
		badge_style.set_content_margin_all(4)
		_app_badge.add_theme_stylebox_override("normal", badge_style)
		_main.btn_app_wechat.add_child(_app_badge)
	if total > 0:
		_app_badge.text = str(total) if total <= 99 else "99+"
		_app_badge.visible = true
	else:
		_app_badge.visible = false


# ==================== UI 刷新 ====================

func _refresh_wechat_ui() -> void:
	for npc_id in _chat_items:
		var npc_data: Dictionary = GameManager.npcs[npc_id]
		var item: Dictionary = _chat_items[npc_id]
		var unread: int = npc_data.get("unread", 0)
		var is_unlocked: bool = npc_data["unlocked"] and not npc_data.get("blocked", false)
		item["root"].visible = is_unlocked
		if not is_unlocked:
			continue
		## 更新聊天列表项的预览文字
		var preview_text: String = ""
		if npc_id == "family_group":
			var family_msgs: Array = npc_data.get("messages", [])
			if unread > 0 and family_msgs.size() > 0:
				preview_text = family_msgs[-1]["text"]
				if preview_text.length() > 15:
					preview_text = preview_text.substr(0, 15) + "..."
			else:
				preview_text = "亲情: %d" % npc_data["affection"]
		elif npc_id == "wang_teacher":
			var teacher_msgs: Array = npc_data.get("messages", [])
			if unread > 0 and teacher_msgs.size() > 0:
				preview_text = teacher_msgs[-1]["text"]
				if preview_text.length() > 20:
					preview_text = preview_text.substr(0, 20) + "..."
			elif GameManager.night_school_progress >= 12:
				preview_text = "已毕业 ✅ 恭喜！"
			else:
				preview_text = "学分: %d/12" % GameManager.night_school_progress
		else:
			preview_text = "进度: %d/50" % npc_data["affection"]
			if npc_data["warning_msg"] != "" and GameManager.eq >= 30:
				preview_text = "[⚠] " + npc_data["warning_msg"]
			## 有消息记录时显示最后一条（家庭群除外）
			var msgs: Array = npc_data.get("messages", [])
			if msgs.size() > 0 and npc_id != "family_group":
				preview_text = msgs[-1]["text"]
				## 截断过长消息
				if preview_text.length() > 20:
					preview_text = preview_text.substr(0, 20) + "..."
		item["label_preview"].text = preview_text
		## 更新未读红标
		var badge_panel: PanelContainer = item.get("badge_label") as PanelContainer
		if badge_panel:
			var badge_text: Label = badge_panel.get_child(0) as Label if badge_panel.get_child_count() > 0 else null
			if unread > 0 and badge_text:
				badge_text.text = str(unread) if unread <= 99 else "99+"
				badge_panel.visible = true
			else:
				badge_panel.visible = false
	var unlocked_count: int = 0
	for npc_id in GameManager.npcs:
		if GameManager.npcs[npc_id]["unlocked"] and not GameManager.npcs[npc_id].get("blocked", false):
			unlocked_count += 1
	_main.label_wc_title.text = "微信 (%d)" % unlocked_count
	_update_app_badge()


# ==================== 聊天列表构建 ====================

func _build_chat_items() -> void:
	for child in _main.chat_list_container.get_children():
		child.queue_free()
	_chat_items.clear()
	var sorted_ids: Array = GameManager.npcs.keys()
	sorted_ids.erase("family_group")
	sorted_ids.push_front("family_group")
	for npc_id in sorted_ids:
		var npc_data: Dictionary = GameManager.npcs[npc_id]
		var item := _create_chat_item(npc_id, npc_data)
		_main.chat_list_container.add_child(item)
		var info_vbox: VBoxContainer = item.get_child(1).get_child(2)
		var name_hbox: HBoxContainer = info_vbox.get_child(0) as HBoxContainer
		var badge: PanelContainer = name_hbox.get_child(2) as PanelContainer if name_hbox.get_child_count() >= 3 else null
		_chat_items[npc_id] = {
			"root": item,
			"label_name": name_hbox.get_child(0) as Label,
			"label_preview": info_vbox.get_child(1) as Label,
			"badge_label": badge,
		}
	_refresh_wechat_ui()


func _create_chat_item(npc_id: String, npc_data: Dictionary) -> PanelContainer:
	var root := PanelContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color.WHITE
	row_style.set_content_margin_all(0)
	root.add_theme_stylebox_override("panel", row_style)
	root.custom_minimum_size = Vector2(0, 70)

	var click_btn := Button.new()
	click_btn.flat = true
	click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	root.add_child(click_btn)
	click_btn.pressed.connect(func() -> void:
		if npc_id == "family_group":
			var unread: int = GameManager.npcs["family_group"].get("unread", 0)
			if unread > 0:
				_on_family_interact()
			else:
				_main.show_message("最近家里没啥新鲜事。")
		else:
			_open_chat_view(npc_id)
	)

	var content_hbox := HBoxContainer.new()
	content_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_hbox.add_theme_constant_override("separation", 10)
	root.add_child(content_hbox)

	var left_margin := Control.new()
	left_margin.custom_minimum_size = Vector2(10, 0)
	content_hbox.add_child(left_margin)

	var avatar := ColorRect.new()
	avatar.custom_minimum_size = Vector2(48, 48)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar.color = NPCManager.get_avatar_color(npc_id)
	content_hbox.add_child(avatar)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	content_hbox.add_child(info_vbox)

	var name_hbox := HBoxContainer.new()
	info_vbox.add_child(name_hbox)

	var label_name := Label.new()
	label_name.add_theme_color_override("font_color", WC_TEXT_PRIMARY)
	label_name.add_theme_font_size_override("font_size", 15)
	label_name.text = npc_data["name"]
	name_hbox.add_child(label_name)

	## 未读消息红标（右侧红色小圆标）
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_hbox.add_child(spacer)

	var badge_panel := PanelContainer.new()
	badge_panel.name = "UnreadBadge"
	badge_panel.custom_minimum_size = Vector2(22, 22)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = WC_RED
	badge_style.set_corner_radius_all(11)
	badge_style.set_content_margin_all(3)
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	var badge_label := Label.new()
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_size_override("font_size", 11)
	badge_label.add_theme_color_override("font_color", Color.WHITE)
	badge_panel.add_child(badge_label)
	badge_panel.visible = false
	name_hbox.add_child(badge_panel)

	var label_preview := Label.new()
	label_preview.add_theme_color_override("font_color", WC_TEXT_SECONDARY)
	label_preview.add_theme_font_size_override("font_size", 12)
	label_preview.text = ""
	label_preview.clip_text = true
	info_vbox.add_child(label_preview)

	var right_margin := Control.new()
	right_margin.custom_minimum_size = Vector2(10, 0)
	content_hbox.add_child(right_margin)

	## 让所有内容子元素忽略鼠标，只有click_btn接收点击
	for child in content_hbox.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return root


# ==================== 微信面板开关 ====================

func _on_wechat_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if _main.wc_chat_view.visible:
			_on_chat_back()
			return
		_on_close_wechat()

func _on_close_wechat() -> void:
	if _main.wc_chat_view.visible:
		_on_chat_back()
		return
	_main.wechat_menu.visible = false


# ==================== 微信 Tab 切换 ====================

func _on_wc_tab(tab_idx: int) -> void:
	_current_tab = tab_idx
	_main.wc_chat_list_view.visible = (tab_idx == 0)
	_main.wc_moments_content.visible = (tab_idx == 1)
	## 更新tab栏高亮颜色
	for i in [_main.tab_contacts, _main.tab_moments]:
		i.add_theme_color_override("font_color", WC_TEXT_SECONDARY)
	match tab_idx:
		0: _main.tab_contacts.add_theme_color_override("font_color", WC_GREEN)
		1:
			_main.tab_moments.add_theme_color_override("font_color", WC_GREEN)
			_build_moments()
	## 隐藏子视图
	_main.wc_chat_view.visible = false


# ==================== 聊天视图 ====================

func _open_chat_view(npc_id: String) -> void:
	_current_chat_npc = npc_id
	## 清除未读
	GameManager.clear_unread(npc_id)
	_refresh_wechat_ui()
	var npc_data: Dictionary = GameManager.npcs[npc_id]
	if npc_id == "family_group":
		_main.label_chat_name.text = npc_data["name"] + "  亲情: %d" % npc_data["affection"]
	else:
		_main.label_chat_name.text = npc_data["name"] + "  好感: %d" % npc_data["affection"]
	## 渲染消息气泡
	while _main.chat_msg_container.get_child_count() > 0:
		var c = _main.chat_msg_container.get_child(0)
		_main.chat_msg_container.remove_child(c)
		c.free()
	var msgs: Array = npc_data.get("messages", [])
	for msg in msgs:
		var parts: Array = msg["text"].split("\n")
		for part in parts:
			if part.strip_edges() != "":
				_add_chat_bubble(msg["sender"], part)
	## 显示聊天视图
	_main.wc_chat_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_main.wc_chat_view.visible = true
	## 压暗背景
	var bg_overlay := ColorRect.new()
	bg_overlay.name = "ChatBgOverlay"
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = Color(0, 0, 0, 0.25)
	_main.wc_chat_view.add_child(bg_overlay)
	_main.wc_chat_view.move_child(bg_overlay, 0)

func _add_chat_bubble(sender: String, text: String) -> void:
	var is_self: bool = (sender == "self")
	var bubble := PanelContainer.new()
	var bubble_style := StyleBoxFlat.new()
	if is_self:
		bubble_style.bg_color = WC_BUBBLE_SELF
	else:
		bubble_style.bg_color = Color.WHITE
	bubble_style.set_corner_radius_all(6)
	bubble.add_theme_stylebox_override("panel", bubble_style)
	bubble.add_theme_constant_override("separation", 0)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", WC_TEXT_PRIMARY)
	bubble.add_child(label)

	## 头像
	var avatar := ColorRect.new()
	avatar.custom_minimum_size = Vector2(40, 40)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar.size_flags_stretch_ratio = 0.0
	if is_self:
		avatar.color = Color(0.3, 0.7, 0.9, 1)
	else:
		avatar.color = _get_npc_avatar_color(_current_chat_npc)

	## 对齐方向
	var wrapper := HBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 8)
	if is_self:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.size_flags_stretch_ratio = 1
		wrapper.add_child(spacer)
		wrapper.add_child(bubble)
		bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bubble.size_flags_stretch_ratio = 2.5
		wrapper.add_child(avatar)
	else:
		wrapper.add_child(avatar)
		wrapper.add_child(bubble)
		bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bubble.size_flags_stretch_ratio = 2.5
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.size_flags_stretch_ratio = 1
		wrapper.add_child(spacer)

	_main.chat_msg_container.add_child(wrapper)


func _get_npc_avatar_color(npc_id: String) -> Color:
	return NPCManager.get_avatar_color(npc_id)

func _on_chat_back() -> void:
	var old_bg: Node = _main.wc_chat_view.get_node_or_null("ChatBgOverlay")
	if old_bg != null:
		old_bg.queue_free()
	_main.wc_chat_view.visible = false
	_current_chat_npc = ""

func _on_chat_send() -> void:
	if _current_chat_npc == "":
		return
	_show_chat_action_menu()


# ==================== 聊天菜单 ====================

func _show_chat_action_menu() -> void:
	## 清除旧菜单
	if is_instance_valid(_chat_menu_panel):
		_chat_menu_panel.get_parent().remove_child(_chat_menu_panel)
		_chat_menu_panel.free()
		_chat_menu_panel = null
	var npc_data: Dictionary = GameManager.npcs[_current_chat_npc]
	_chat_menu_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.95, 0.95, 1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(4)
	_chat_menu_panel.add_theme_stylebox_override("panel", style)
	_chat_menu_panel.z_index = 20
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_chat_menu_panel.add_child(vbox)
	## 剧本NPC日常闲聊
	if GameManager.is_npc_unlocked(_current_chat_npc):
		_add_menu_btn(vbox, "日常闲聊 (-10精力)", func() -> void: _on_daily_chat())
	## 根据 NPC 添加选项
	match _current_chat_npc:
		"family_group":
			_add_menu_btn(vbox, "查看家庭消息", func() -> void: _on_family_interact())
		"wang_teacher":
			if GameManager.night_school_progress >= 12:
				_add_menu_btn(vbox, "已毕业 ✅", func() -> void: pass)
			else:
				_add_menu_btn(vbox, "报名冲刺班 (-50精力, -1000金)", func() -> void: _on_chat_wang_teacher())
			if npc_data["level"] >= 2:
				_add_menu_btn(vbox, "约会", func() -> void: _on_date_npc(_current_chat_npc))
		_:
			if npc_data["level"] >= 2:
				_add_menu_btn(vbox, "约会", func() -> void: _on_date_npc(_current_chat_npc))
	## 删除好友
	_add_menu_btn(vbox, "删除好友", func() -> void: _do_delete_friend(), Color(1, 0.2, 0.2, 1))
	## 取消
	_add_menu_btn(vbox, "取消", func() -> void:
		if is_instance_valid(_chat_menu_panel):
			_chat_menu_panel.queue_free()
			_chat_menu_panel = null)
	## 显示菜单
	_main.chat_view_bg.add_child(_chat_menu_panel)
	_chat_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_chat_menu_panel.size.x = _main.chat_input_field.size.x
	_chat_menu_panel.z_index = 30
	## 获取输入框在chat_view_bg本地坐标
	var input_local: Vector2 = (_main.chat_view_bg.get_global_transform().affine_inverse() * _main.chat_input_field.global_position)
	var final_pos := Vector2(input_local.x, input_local.y - _chat_menu_panel.size.y - 8)
	_chat_menu_panel.position = Vector2(final_pos.x, input_local.y)
	_chat_menu_panel.modulate.a = 0.0
	var tween := _main.create_tween()
	tween.tween_property(_chat_menu_panel, "position:y", final_pos.y, 0.15).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_chat_menu_panel, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_LINEAR)


# ==================== 日常闲聊（防重复抽卡）====================

func _on_daily_chat() -> void:
	## 消耗精力
	if GameManager.energy < 10:
		_main.show_message("精力不足，没力气聊天了！")
		return
	GameManager.modify_stat("energy", -10)
	## 关闭菜单
	if is_instance_valid(_chat_menu_panel):
		_chat_menu_panel.queue_free()
		_chat_menu_panel = null

	var npc_id: String = _current_chat_npc
	var static_data: Dictionary = GameManager.get_npc_data(npc_id)
	if static_data.is_empty():
		_main.show_message("[系统] 该NPC暂无对话数据。")
		return

	var runtime: Dictionary = GameManager.get_npc_runtime(npc_id)
	var all_chats: Array = static_data.get("daily_chats", [])
	var used_ids: Array = runtime.get("used_daily_chats", [])

	## 【防重过滤核心】
	var available_chats: Array = []
	for chat in all_chats:
		if not used_ids.has(chat.get("id", "")):
			available_chats.append(chat)

	## 【兜底逻辑】
	if available_chats.is_empty():
		GameManager.modify_stat("energy", -5)
		_add_chat_bubble("npc", "[对方无回复]")
		var npc_data_dict: Dictionary = GameManager.npcs[_current_chat_npc]
		npc_data_dict["messages"].append({"sender": "npc", "text": "[对方无回复]"})
		_main.show_floating_text("他似乎很忙，没有回复你的消息。", Color.GRAY, _main.get_global_mouse_position())
		return

	## 【抽取与记录】
	var selected: Dictionary = available_chats[randi() % available_chats.size()]
	runtime["used_daily_chats"].append(selected["id"])

	## 显示 NPC 发来的文本
	var text_lines: Array = selected.get("text_lines", [])
	var npc_msg: String = ""
	for line in text_lines:
		npc_msg += line + "\n"
		npc_msg = npc_msg.strip_edges()
	var _npc_name: String = static_data.get("name", npc_id)  # npc display name
	_add_chat_bubble("npc", npc_msg)
	var npc_data_dict2: Dictionary = GameManager.npcs[_current_chat_npc]
	npc_data_dict2["messages"].append({"sender": "npc", "text": npc_msg})

	## 隐藏输入按钮，动态生成回复选项
	_main.chat_input_field.visible = false
	_reply_btn_container = VBoxContainer.new()
	_reply_btn_container.add_theme_constant_override("separation", 4)
	_main.chat_view_bg.add_child(_reply_btn_container)
	## 定位到输入框位置
	var input_local: Vector2 = (_main.chat_view_bg.get_global_transform().affine_inverse() * _main.chat_input_field.global_position)
	_reply_btn_container.position = input_local + Vector2(0, -_reply_btn_container.size.y)
	_reply_btn_container.size.x = _main.chat_input_field.size.x
	_reply_btn_container.z_index = 25

	var reply_options: Array = selected.get("reply_options", [])
	for option in reply_options:
		var opt_btn := Button.new()
		opt_btn.text = option.get("text", "...")
		opt_btn.add_theme_font_size_override("font_size", 13)
		opt_btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1))
		var opt_style := StyleBoxFlat.new()
		opt_style.bg_color = Color(0.95, 0.95, 0.95, 1)
		opt_style.set_corner_radius_all(6)
		opt_style.set_content_margin_all(8)
		opt_btn.add_theme_stylebox_override("normal", opt_style)
		## 检查属性门槛
		var req_stat: String = option.get("req_stat", "")
		var req_val: int = int(option.get("req_val", 0))
		if req_stat != "" and GameManager.get(req_stat) < req_val:
			opt_btn.disabled = true
			opt_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
			opt_btn.tooltip_text = "需要 %s >= %d" % [GameManager.stat_names.get(req_stat, req_stat), req_val]
		## 绑定选项数据
		var captured_option: Dictionary = option
		opt_btn.pressed.connect(func() -> void: _on_reply_selected(captured_option))
		_reply_btn_container.add_child(opt_btn)

	## 等一帧后重新定位选项容器
	await _main.get_tree().process_frame
	_reply_btn_container.position = Vector2(input_local.x, input_local.y - _reply_btn_container.size.y - 4)


func _on_reply_selected(option: Dictionary) -> void:
	## 资源校验
	var cost: Dictionary = option.get("cost", {})
	var cost_energy: int = int(cost.get("energy", 0))
	var cost_money: int = int(cost.get("money", 0))
	if cost_energy > 0 and GameManager.energy < cost_energy:
		_main.show_floating_text("太累了，没精力回复...", Color.RED, _main.get_global_mouse_position())
		return
	if cost_money > 0 and GameManager.money < cost_money:
		_main.show_floating_text("金钱不足...", Color.RED, _main.get_global_mouse_position())
		return

	## 扣除资源
	if cost_energy > 0:
		GameManager.modify_stat("energy", -cost_energy)
	if cost_money > 0:
		GameManager.modify_stat("money", -cost_money)

	## 应用属性变化
	var stat_changes: Dictionary = option.get("stat_changes", {})
	for stat_name in stat_changes:
		var val: int = int(stat_changes[stat_name])
		if stat_name == "affection":
			GameManager.get_npc_runtime(_current_chat_npc)["affection"] += val
		else:
			GameManager.modify_stat(stat_name, val)

	## 显示玩家回复
	var player_text: String = option.get("text", "")
	_add_chat_bubble("self", player_text)
	var npc_data_dict: Dictionary = GameManager.npcs[_current_chat_npc]
	npc_data_dict["messages"].append({"sender": "self", "text": player_text})

	## 显示男主回复
	var reply_lines: Array = option.get("reply_lines", [])
	var reply_text: String = ""
	for line in reply_lines:
		reply_text += line + "\n"
	reply_text = reply_text.strip_edges()
	if reply_text != "":
		_add_chat_bubble("npc", reply_text)
		npc_data_dict["messages"].append({"sender": "npc", "text": reply_text})

	## 记录 flag
	var flag: String = option.get("flag", "")
	if flag != "":
		var runtime: Dictionary = GameManager.get_npc_runtime(_current_chat_npc)
		if not runtime["flags"].has(flag):
			runtime["flags"].append(flag)

	## 销毁选项按钮，恢复常驻按钮
	_clear_reply_buttons()
	_refresh_wechat_ui()


func _clear_reply_buttons() -> void:
	if is_instance_valid(_reply_btn_container):
		_reply_btn_container.queue_free()
		_reply_btn_container = null
	_main.chat_input_field.visible = true


func _add_menu_btn(parent: Control, text: String, callback: Callable, color: Color = WC_TEXT_PRIMARY) -> void:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", color)
	btn.pressed.connect(func() -> void:
		if is_instance_valid(_chat_menu_panel):
			_chat_menu_panel.queue_free()
			_chat_menu_panel = null
		callback.call())
	parent.add_child(btn)


func _do_delete_friend() -> void:
	if _current_chat_npc == "":
		return
	var npc_data: Dictionary = GameManager.npcs[_current_chat_npc]
	npc_data["unlocked"] = false
	npc_data["blocked"] = true
	if _chat_menu_panel:
		_chat_menu_panel.queue_free()
		_chat_menu_panel = null
	_on_chat_back()
	_build_chat_items()
	_refresh_wechat_ui()


func _get_npc_auto_reply(npc_id: String) -> String:
	return NPCManager.get_auto_reply(npc_id)


# ==================== 联系人列表 ====================

func _build_contacts_list() -> void:
	for child in _main.wc_contact_list.get_children():
		child.queue_free()
	for npc_id in GameManager.npcs:
		var npc_data: Dictionary = GameManager.npcs[npc_id]
		if not npc_data["unlocked"] or npc_data.get("blocked", false):
			continue
		var row := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color.WHITE
		style.set_content_margin_all(0)
		row.add_theme_stylebox_override("panel", style)
		row.custom_minimum_size = Vector2(0, 60)
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		row.add_child(hbox)
		var margin_l := Control.new()
		margin_l.custom_minimum_size = Vector2(16, 0)
		hbox.add_child(margin_l)
		var avatar := ColorRect.new()
		avatar.custom_minimum_size = Vector2(40, 40)
		avatar.size_flags_stretch_ratio = 0.0
		avatar.size_flags_stretch_ratio = 0.0
		avatar.color = NPCManager.get_avatar_color(npc_id)
		hbox.add_child(avatar)
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(vbox)
		var name_label := Label.new()
		name_label.text = npc_data["name"]
		name_label.add_theme_color_override("font_color", WC_TEXT_PRIMARY)
		name_label.add_theme_font_size_override("font_size", 15)
		vbox.add_child(name_label)
		var level_label := Label.new()
		level_label.text = "Lv.%d  好感: %d" % [npc_data["level"], npc_data["affection"]]
		level_label.add_theme_color_override("font_color", WC_TEXT_SECONDARY)
		level_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(level_label)
		var margin_r := Control.new()
		margin_r.custom_minimum_size = Vector2(16, 0)
		hbox.add_child(margin_r)
		var captured_id: String = npc_id
		row.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_open_chat_view(captured_id)
		)
		_main.wc_contact_list.add_child(row)


# ==================== 朋友圈 ====================

func _build_moments() -> void:
	for child in _main.moments_list.get_children():
		child.queue_free()
	## 为每个解锁的NPC生成朋友圈动态
	for npc_id in GameManager.npcs:
		var npc_data: Dictionary = GameManager.npcs[npc_id]
		if not npc_data["unlocked"] or npc_data.get("blocked", false):
			continue
		var moments_text: String = NPCManager.get_moments_text(npc_id)
		var moments_likes: int = NPCManager.get_moments_likes(npc_id)
		## 创建动态卡片
		var post := PanelContainer.new()
		var post_style := StyleBoxFlat.new()
		post_style.bg_color = Color.WHITE
		post_style.set_content_margin_all(0)
		post.add_theme_stylebox_override("panel", post_style)
		var post_vbox := VBoxContainer.new()
		post_vbox.add_theme_constant_override("separation", 0)
		post.add_child(post_vbox)
		## 头部：头像 + 名字
		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 8)
		post_vbox.add_child(header_hbox)
		var h_margin_l := Control.new()
		h_margin_l.custom_minimum_size = Vector2(12, 0)
		header_hbox.add_child(h_margin_l)
		var avatar := ColorRect.new()
		avatar.custom_minimum_size = Vector2(40, 40)
		avatar.size_flags_stretch_ratio = 0.0
		avatar.color = NPCManager.get_avatar_color(npc_id)
		header_hbox.add_child(avatar)
		var name_vbox := VBoxContainer.new()
		name_vbox.add_theme_constant_override("separation", 0)
		header_hbox.add_child(name_vbox)
		var post_name := Label.new()
		post_name.text = npc_data["name"]
		post_name.add_theme_color_override("font_color", Color(0.1, 0.3, 0.7, 1))
		post_name.add_theme_font_size_override("font_size", 14)
		name_vbox.add_child(post_name)
		## 内容文字
		var content_label := Label.new()
		content_label.text = moments_text
		content_label.add_theme_color_override("font_color", WC_TEXT_PRIMARY)
		content_label.add_theme_font_size_override("font_size", 13)
		content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var content_margin := Control.new()
		content_margin.custom_minimum_size = Vector2(0, 6)
		post_vbox.add_child(content_margin)
		var content_hbox := HBoxContainer.new()
		post_vbox.add_child(content_hbox)
		var cm_l := Control.new()
		cm_l.custom_minimum_size = Vector2(60, 0)
		content_hbox.add_child(cm_l)
		content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_hbox.add_child(content_label)
		var cm_r := Control.new()
		cm_r.custom_minimum_size = Vector2(12, 0)
		content_hbox.add_child(cm_r)
		## 点赞
		var like_hbox := HBoxContainer.new()
		post_vbox.add_child(like_hbox)
		var like_margin := Control.new()
		like_margin.custom_minimum_size = Vector2(60, 0)
		like_hbox.add_child(like_margin)
		var like_label := Label.new()
		like_label.text = "❤ %d" % moments_likes
		like_label.add_theme_color_override("font_color", WC_TEXT_SECONDARY)
		like_label.add_theme_font_size_override("font_size", 12)
		like_hbox.add_child(like_label)
		## 底部间距
		var bottom_space := Control.new()
		bottom_space.custom_minimum_size = Vector2(0, 10)
		post_vbox.add_child(bottom_space)
		_main.moments_list.add_child(post)
	## 分隔线
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 1)
	_main.moments_list.add_child(sep)


# ==================== 家庭群专属互动 ====================

## 查看家庭消息（根据消息类型：事件 or 闲聊）
func _on_family_interact() -> void:
	var msgs: Array = GameManager.npcs["family_group"].get("messages", [])
	if msgs.size() == 0:
		return
	var last_msg: Dictionary = msgs[-1]
	GameManager.clear_unread("family_group")
	if last_msg.get("type", "") == "family_chat":
		_show_family_chat_display(last_msg)
	else:
		var event_idx: int = last_msg.get("event_idx", randi() % _family_events.size())
		_show_family_event(event_idx)


## 闲聊消息展示（无选项，直接加减数值）
func _show_family_chat_display(msg: Dictionary) -> void:
	var chat_text: String = msg.get("full_text", msg.get("text", ""))
	var sanity_effect: int = msg.get("sanity", 0)
	var money_effect: int = msg.get("money", 0)
	var detail_msg: String = msg.get("detail_msg", "")
	## 应用数值
	if sanity_effect != 0:
		GameManager.modify_stat("sanity", sanity_effect)
	if money_effect != 0:
		GameManager.modify_stat("money", money_effect)
	## 全屏遮罩
	var overlay := ColorRect.new()
	overlay.name = "FamilyChatOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.z_index = 50
	_main.add_child(overlay)
	## 居中容器
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	## 弹窗面板
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.98, 0.97, 0.95, 1)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	## 标题
	var title := Label.new()
	title.text = "相亲相爱一家人"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.BLACK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	## 闲聊内容
	var desc := Label.new()
	var effect_hint: String = ""
	if sanity_effect > 0:
		effect_hint = "\n(情绪 +%d)" % sanity_effect
	elif sanity_effect < 0:
		effect_hint = "\n(情绪 %d)" % sanity_effect
	if money_effect > 0:
		effect_hint += "\n(金钱 +%d)" % money_effect
	elif money_effect < 0:
		effect_hint += "\n(金钱 %d)" % money_effect
	desc.text = chat_text + effect_hint
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	## 详情消息（正面事件有）
	if detail_msg != "":
		var detail := Label.new()
		detail.text = detail_msg
		detail.add_theme_font_size_override("font_size", 13)
		detail.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(detail)
	## 确认按钮
	var btn := Button.new()
	btn.text = "知道了"
	btn.custom_minimum_size = Vector2(0, 40)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.85, 0.85, 0.85, 1)
	btn_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(func() -> void:
		var ov := _main.get_node_or_null("FamilyChatOverlay")
		if ov: ov.queue_free()
	)
	vbox.add_child(btn)


## 显示家庭事件弹窗
func _show_family_event(event_idx: int) -> void:
	var event: Dictionary = _family_events[event_idx]
	# 全屏遮罩
	var overlay := ColorRect.new()
	overlay.name = "FamilyEventOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.z_index = 50
	_main.add_child(overlay)
	# 居中容器
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	# 弹窗面板
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.98, 0.97, 0.95, 1)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	# 标题
	var title_label := Label.new()
	title_label.text = event["title"]
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color.BLACK)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	# 描述
	var desc_label := Label.new()
	desc_label.text = event["desc"]
	desc_label.add_theme_font_size_override("font_size", 15)
	desc_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	# 选择按钮
	var choices: Array = event["choices"]
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = choice["label"]
		btn.custom_minimum_size = Vector2(0, 44)
		var btn_style := StyleBoxFlat.new()
		if i == 0:
			btn_style.bg_color = Color(0.027, 0.757, 0.376, 1)
		else:
			btn_style.bg_color = Color(1.0, 0.6, 0.4, 1)
		btn_style.set_corner_radius_all(8)
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_family_choice.bind(event_idx, i))
		vbox.add_child(btn)


## 家庭事件选择回调
func _on_family_choice(event_idx: int, choice_idx: int) -> void:
	var event: Dictionary = _family_events[event_idx]
	var choice: Dictionary = event["choices"][choice_idx]
	var effects: Dictionary = choice.get("effects", {})
	# 检查金钱是否足够
	if effects.has("money") and effects["money"] < 0:
		if GameManager.money < abs(effects["money"]):
			_main.show_message("金钱不足，无法这样做！")
			return
	# 应用属性效果
	for stat in effects:
		GameManager.modify_stat(stat, effects[stat])
	# 设置亲情变化
	var affection_gain: int = choice.get("affection_gain", 0)
	if affection_gain != 0:
		GameManager.add_npc_affection("family_group", affection_gain)
	# Buff/Debuff设置
	if choice.get("set_mom_care", 0) > 0:
		GameManager.mom_care_buff_weeks = choice["set_mom_care"]
	if choice.get("set_guilt", 0) > 0:
		GameManager.guilt_debuff_weeks = choice["set_guilt"]
	# 显示结果消息
	_main.show_message(choice["msg"], true)
	# 移除遮罩
	var overlay_node := _main.get_node_or_null("FamilyEventOverlay")
	if overlay_node:
		overlay_node.queue_free()
	_refresh_wechat_ui()


func _on_chat_npc(npc_id: String) -> void:
	if GameManager.energy < 10:
		_main.show_message("精力不足，没力气聊天了！")
		return

	var affection_gain: int = 5
	var sanity_change: int = 0
	var msg: String = ""

	match npc_id:
		_:
			sanity_change = 5
			msg = "聊天结束。"

	GameManager.modify_stat("energy", -10)
	GameManager.modify_stat("sanity", sanity_change)
	if affection_gain > 0:
		GameManager.add_npc_affection(npc_id, affection_gain)
	_main.float_stat("+%d 好感 %s%d 情绪" % [affection_gain, "+" if sanity_change >= 0 else "", sanity_change], affection_gain, _main.get_global_mouse_position())
	## 添加聊天消息记录
	var npc_data: Dictionary = GameManager.npcs[npc_id]
	npc_data["messages"].append({"sender": "npc", "text": msg})
	## 在聊天界面显示气泡
	if _current_chat_npc == npc_id and _main.wc_chat_view.visible:
		_add_chat_bubble("npc", msg)
	_main.show_message(msg, true)
	_refresh_wechat_ui()


## 约会（通用逻辑）
func _on_date_npc(npc_id: String) -> void:
	if GameManager.energy < 50:
		_main.show_message("精力不足，无法约会！(需要50精力)")
		return

	var npc_data: Dictionary = GameManager.npcs[npc_id]
	var npc_name: String = npc_data["name"]
	var money_cost: int = 0
	var sanity_change: int = 0
	var affection_gain: int = 0
	var msg: String = ""

	match npc_id:
		_:
			money_cost = 500
			sanity_change = 40
			affection_gain = 30
			msg = "与 %s 浪漫约会，感情升温！" % npc_name

	var the_cost := money_cost
	var the_sanity := sanity_change
	var the_aff := affection_gain
	var the_msg := msg
	var the_npc := npc_id

	var do_date := func() -> void:
		GameManager.modify_stat("energy", -50)
		GameManager.add_npc_affection(the_npc, the_aff)
		GameManager.modify_stat("sanity", the_sanity)
		_main.show_message(the_msg, true)
		GameManager.add_activity("社交", the_msg)
		_refresh_wechat_ui()

	if the_cost > 0:
		_main.request_payment(the_cost, "%s约会" % npc_name, "社交", do_date)
	else:
		do_date.call()


# ==================== 夜校王老师 ====================

func _on_chat_wang_teacher() -> void:
	if GameManager.night_school_progress >= 12:
		_main.show_message("你已经毕业了！快去 BOSS弯聘 看看新机会吧！")
		return
	if GameManager.energy < 50:
		_main.show_message("精力不足（需50），没法上课了！")
		return
	_main.request_payment(1000, "夜校报名冲刺班", "提升", func() -> void:
		GameManager.modify_stat("energy", -50)
		GameManager.modify_stat("sanity", -10)
		GameManager.night_school_progress += 1
		if GameManager.night_school_progress >= 12:
			GameManager.degree = 1
			_show_graduation_popup()
		else:
			_main.show_message("王老师：恭喜完成本周课程！当前学分进度：%d/12。" % GameManager.night_school_progress)
			_main.float_stat("+1 学分 | 进度 %d/12" % GameManager.night_school_progress, 1, _main.get_global_mouse_position())
		_refresh_wechat_ui()
	)


## 夜校毕业弹窗
func _show_graduation_popup() -> void:
	var overlay := ColorRect.new()
	overlay.name = "GraduationOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.z_index = 50
	_main.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(450, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 0.95, 0.9, 1)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "【学历提升】"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.BLACK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "历时小半年，你终于修满学分，获得了【成人本科学历】！\n快去 BOSS弯聘 看看新机会吧！"
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var btn := Button.new()
	btn.text = "确认"
	btn.custom_minimum_size = Vector2(0, 44)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.027, 0.757, 0.376, 1)
	btn_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(func() -> void:
		var node := _main.get_node_or_null("GraduationOverlay")
		if node:
			node.queue_free()
	)
	vbox.add_child(btn)
