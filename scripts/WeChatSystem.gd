## WeChatSystem.gd - 微信系统管理器
## 负责：微信聊天、联系人、朋友圈、家庭群、NPC约会等全部微信UI逻辑
## 通过 _main 引用 MainGame 节点访问 UI 节点和工具函数
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
var _pending_daily_chat_changes: Dictionary = {}
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


func _set_layer_visible(layer: Control, value: bool, exclusive: bool = true) -> void:
	if not is_instance_valid(layer):
		return
	if is_instance_valid(_main) and _main.has_method("set_ui_layer_visible"):
		_main.set_ui_layer_visible(layer, value, exclusive)
	else:
		layer.visible = value


func _set_main_wechat_panel_visible(value: bool) -> void:
	if not is_instance_valid(_main):
		return
	var panel_parent := _main.wc_panel_container.get_parent() as Control
	if is_instance_valid(panel_parent):
		panel_parent.visible = value
		panel_parent.mouse_filter = Control.MOUSE_FILTER_PASS if value else Control.MOUSE_FILTER_IGNORE
	_main.wc_panel_container.visible = value
	_main.wc_panel_container.mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE


func force_close() -> void:
	_set_main_wechat_panel_visible(true)
	_set_layer_visible(_main.wc_chat_view, false)
	_set_layer_visible(_main.wechat_menu, false)


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


func _strip_embedded_result_text(text: String) -> String:
	var kept: Array = []
	for line in text.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("（") and (trimmed.find("+") >= 0 or trimmed.find("-") >= 0):
			continue
		if trimmed.find("[color=90EE90]") >= 0 or trimmed.find("[color=E88080]") >= 0:
			var cleaned_line := _remove_colored_result_segments(line)
			if cleaned_line != "":
				kept.append(cleaned_line)
			continue
		kept.append(line)
	return "\n".join(kept).strip_edges()


func _show_stat_result(changes: Dictionary, on_complete: Callable = Callable()) -> void:
	if is_instance_valid(_main) and _main.has_method("show_stat_result"):
		_main.show_stat_result(changes, on_complete)
	elif on_complete.is_valid():
		on_complete.call()


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


func _take_pending_daily_chat_changes() -> Dictionary:
	var changes := _pending_daily_chat_changes.duplicate()
	_pending_daily_chat_changes.clear()
	return changes


func _is_contact_visible(npc_id: String) -> bool:
	if not GameManager.npcs.has(npc_id):
		return false
	var npc_data: Dictionary = GameManager.npcs[npc_id]
	return bool(npc_data.get("unlocked", false)) and not bool(npc_data.get("blocked", false))


func _contact_summary(npc_id: String) -> Dictionary:
	if GameManager.has_method("get_npc_contact_summary"):
		return GameManager.get_npc_contact_summary(npc_id)
	return {}


func _short_relation(npc_id: String) -> String:
	var summary := _contact_summary(npc_id)
	var relation := str(summary.get("relation", GameManager.npcs.get(npc_id, {}).get("relation", ""))).strip_edges()
	if relation == "":
		return "联系人"
	return relation.split("/")[0].strip_edges()


func _source_label(npc_id: String) -> String:
	var summary := _contact_summary(npc_id)
	return str(summary.get("source_label", GameManager.npcs.get(npc_id, {}).get("source_label", "未知来源"))).strip_edges()


func _source_detail(npc_id: String) -> String:
	var summary := _contact_summary(npc_id)
	return str(summary.get("source_detail", GameManager.npcs.get(npc_id, {}).get("source_detail", ""))).strip_edges()


func _active_moment_for(npc_id: String) -> Dictionary:
	if GameManager.has_method("get_next_available_npc_moment"):
		return GameManager.get_next_available_npc_moment(npc_id)
	var static_data: Dictionary = GameManager.get_npc_data(npc_id)
	var moments: Array = static_data.get("moments", [])
	if moments.size() > 0 and moments[0] is Dictionary:
		return moments[0]
	return {}


func _moment_text_for(npc_id: String) -> String:
	var static_data: Dictionary = GameManager.get_npc_data(npc_id)
	var moment: Dictionary = _active_moment_for(npc_id)
	if not moment.is_empty():
		var lines: Array = moment.get("text_lines", [])
		return _join_lines(lines)
	if static_data.get("moments", []).size() > 0:
		return ""
	var fallback := NPCManager.get_moments_text(npc_id)
	if fallback == "...":
		return ""
	return fallback


func _moment_likes_for(npc_id: String) -> int:
	if GameManager.npcs.has(npc_id):
		var affection_likes: int = int(float(GameManager.npcs[npc_id].get("affection", 0)) / 2.0)
		var base_likes: int = int(float(NPCManager.get_moments_likes(npc_id)) / 4.0)
		return maxi(1, affection_likes + base_likes)
	return NPCManager.get_moments_likes(npc_id)


func _truncate_text(text: String, max_len: int) -> String:
	if text.length() <= max_len:
		return text
	return text.substr(0, max_len) + "..."


func _join_lines(lines: Array) -> String:
	var text := ""
	for line in lines:
		text += str(line) + "\n"
	return text.strip_edges()


func _first_line(lines: Array, fallback: String = "") -> String:
	for line in lines:
		var text := str(line).strip_edges()
		if text != "":
			return text
	return fallback


func _stat_label(stat_name: String) -> String:
	return str(GameManager.stat_names.get(stat_name, stat_name))


func _next_available_milestone(npc_id: String) -> Dictionary:
	if GameManager.has_method("get_next_available_npc_milestone"):
		return GameManager.get_next_available_npc_milestone(npc_id)
	return {}


func _visible_contact_count() -> int:
	var count := 0
	for npc_id in GameManager.npcs:
		if _is_contact_visible(npc_id):
			count += 1
	return count


func _moments_post_count() -> int:
	var count := 0
	for npc_id in GameManager.npcs:
		if _is_contact_visible(npc_id) and _moment_text_for(npc_id) != "":
			count += 1
	return count


func _update_wechat_title() -> void:
	match _current_tab:
		1:
			_main.label_wc_title.text = "通讯录 (%d)" % _visible_contact_count()
		2:
			var count := _moments_post_count()
			_main.label_wc_title.text = "朋友圈 (%d)" % count if count > 0 else "朋友圈"
		_:
			var total_unread: int = GameManager.get_total_unread()
			_main.label_wc_title.text = "微信 (%d)" % total_unread if total_unread > 0 else "微信"


func _action_service():
	if is_instance_valid(_main):
		return _main.get("action_service")
	return null


func _apply_wechat_changes(changes: Dictionary, affection_npc_id: String = "") -> Dictionary:
	var applied: Dictionary = {}
	var stat_changes: Dictionary = {}
	for key in changes:
		var amount := int(changes[key])
		if amount == 0:
			continue
		match str(key):
			"affection":
				if affection_npc_id != "":
					GameManager.add_npc_affection(affection_npc_id, amount)
					applied[key] = int(applied.get(key, 0)) + amount
			"family_affection":
				GameManager.add_npc_affection("family_group", amount)
				applied[key] = int(applied.get(key, 0)) + amount
			_:
				stat_changes[key] = amount
	if not stat_changes.is_empty():
		var service = _action_service()
		var service_applied: Dictionary = {}
		if service and service.has_method("apply_stat_changes"):
			service_applied = service.apply_stat_changes(stat_changes)
		else:
			for stat_name in stat_changes:
				var amount := int(stat_changes[stat_name])
				match str(stat_name):
					"night_school_progress":
						GameManager.night_school_progress = clampi(GameManager.night_school_progress + amount, 0, 12)
					"degree":
						GameManager.degree = clampi(GameManager.degree + amount, 0, 1)
					_:
						GameManager.modify_stat(str(stat_name), amount)
				service_applied[stat_name] = amount
		applied = _merge_change_dicts(applied, service_applied)
	_refresh_wechat_ui()
	return applied


func _show_story_then_apply_changes(story_text: String, pending_changes: Dictionary, already_applied_changes: Dictionary = {}, after: Callable = Callable(), affection_npc_id: String = "", title: String = "【结算】") -> void:
	var clean_story := _strip_embedded_result_text(story_text)
	var show_result_then_apply := func() -> void:
		var display_changes := _merge_change_dicts(already_applied_changes, pending_changes)
		_show_stat_result(display_changes, func() -> void:
			_apply_wechat_changes(pending_changes, affection_npc_id)
			if after.is_valid():
				after.call()
		)
	if clean_story != "":
		_main.show_galgame_dialog([clean_story], show_result_then_apply)
	else:
		show_result_then_apply.call()


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
	# Rebuild chat items if new NPCs were added
	var current_npc_count: int = 0
	for npc_id in GameManager.npcs:
		if _is_contact_visible(npc_id):
			current_npc_count += 1
	if _chat_items.size() != current_npc_count:
		_build_chat_items()
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
			preview_text = "%s｜好感 %d" % [_source_label(npc_id), int(npc_data["affection"])]
			if npc_data["warning_msg"] != "" and GameManager.eq >= 30:
				preview_text = "[⚠] " + npc_data["warning_msg"]
			## 有消息记录时显示最后一条（家庭群除外）
			var msgs: Array = npc_data.get("messages", [])
			if msgs.size() > 0 and npc_id != "family_group":
				var last_msg: Dictionary = msgs[-1]
				if str(last_msg.get("type", "")) == "contact_intro":
					preview_text = _source_label(npc_id)
				else:
					preview_text = str(last_msg.get("text", ""))
				## 截断过长消息
				preview_text = _truncate_text(preview_text, 20)
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
	_update_wechat_title()
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
		if not _is_contact_visible(npc_id):
			continue
		var npc_data: Dictionary = GameManager.npcs[npc_id]
		var item := _create_chat_item(npc_id, npc_data)
		_main.chat_list_container.add_child(item)
		var info_vbox: VBoxContainer = item.get_child(1).get_child(2)
		var name_hbox: HBoxContainer = info_vbox.get_child(0) as HBoxContainer
		var badge: PanelContainer = name_hbox.get_node_or_null("UnreadBadge") as PanelContainer
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
	click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
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

	if npc_id != "family_group":
		var relation_tag := Label.new()
		relation_tag.text = "  %s" % _short_relation(npc_id)
		relation_tag.add_theme_color_override("font_color", Color(0.36, 0.46, 0.58, 1))
		relation_tag.add_theme_font_size_override("font_size", 11)
		relation_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_hbox.add_child(relation_tag)

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
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_LEFT and _main.wc_chat_view.visible:
		if handle_chat_mouse_shortcut(event.global_position):
			_main.get_viewport().set_input_as_handled()
			return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if _main.wc_chat_view.visible:
			_on_chat_back()
			return
		_on_close_wechat()


func handle_chat_mouse_shortcut(global_position: Vector2) -> bool:
	if not is_instance_valid(_main) or not _main.wc_chat_view.visible:
		return false
	if is_instance_valid(_chat_menu_panel):
		for button in _chat_menu_panel.find_children("*", "Button", true, false):
			if button is Button and not button.disabled and _is_point_inside_control(button, global_position):
				button.emit_signal("pressed")
				return true
	if _is_point_inside_control(_main.btn_chat_back, global_position):
		_on_chat_back()
		return true
	if not _main.chat_input_field.disabled and _is_point_inside_control(_main.chat_input_field, global_position):
		_on_chat_send()
		return true
	return false


func _is_point_inside_control(control: Control, global_position: Vector2) -> bool:
	if not is_instance_valid(control) or not control.visible or not control.is_visible_in_tree():
		return false
	var local_pos: Vector2 = control.get_global_transform().affine_inverse() * global_position
	return Rect2(Vector2.ZERO, control.size).has_point(local_pos)

func _on_close_wechat() -> void:
	if _main.wc_chat_view.visible:
		_on_chat_back()
		return
	_set_main_wechat_panel_visible(true)
	_set_layer_visible(_main.wechat_menu, false)


# ==================== 微信 Tab 切换 ====================

func _on_wc_tab(tab_idx: int) -> void:
	_current_tab = tab_idx
	_main.wc_chat_list_view.visible = (tab_idx == 0)
	_main.wc_contacts_view.visible = (tab_idx == 1)
	_main.wc_moments_content.visible = (tab_idx == 2)
	## 更新tab栏高亮颜色
	for i in [_main.tab_chats, _main.tab_contacts, _main.tab_moments]:
		i.add_theme_color_override("font_color", WC_TEXT_SECONDARY)
	match tab_idx:
		0: _main.tab_chats.add_theme_color_override("font_color", WC_GREEN)
		1:
			_main.tab_contacts.add_theme_color_override("font_color", WC_GREEN)
			_build_contacts_list()
		2:
			_main.tab_moments.add_theme_color_override("font_color", WC_GREEN)
			_build_moments()
	## 隐藏子视图
	if _main.wc_chat_view.visible:
		_on_chat_back()
	else:
		_set_layer_visible(_main.wc_chat_view, false)
	_update_wechat_title()


# ==================== 聊天视图 ====================

func _open_chat_view(npc_id: String) -> void:
	_current_chat_npc = npc_id
	if GameManager.has_method("ensure_npc_contact_intro"):
		GameManager.ensure_npc_contact_intro(npc_id, false)
	## 清除未读
	GameManager.clear_unread(npc_id)
	_refresh_wechat_ui()
	var npc_data: Dictionary = GameManager.npcs[npc_id]
	if npc_id == "family_group":
		_main.label_chat_name.text = npc_data["name"] + "  亲情: %d" % npc_data["affection"]
	elif npc_id == "wang_teacher":
		_main.label_chat_name.text = "%s｜%s  学分: %d/12" % [npc_data["name"], _short_relation(npc_id), GameManager.night_school_progress]
	else:
		_main.label_chat_name.text = "%s｜%s  好感: %d" % [npc_data["name"], _short_relation(npc_id), npc_data["affection"]]
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
	_main.btn_chat_back.disabled = false
	_main.btn_chat_back.mouse_filter = Control.MOUSE_FILTER_STOP
	_main.btn_chat_back.z_index = 40
	_main.chat_input_field.disabled = false
	_main.chat_input_field.mouse_filter = Control.MOUSE_FILTER_STOP
	_main.chat_input_field.z_index = 40
	if not _main.btn_chat_back.pressed.is_connected(_on_chat_back):
		_main.btn_chat_back.pressed.connect(_on_chat_back)
	if not _main.wc_chat_view.gui_input.is_connected(_on_wechat_gui_input):
		_main.wc_chat_view.gui_input.connect(_on_wechat_gui_input)
	_set_main_wechat_panel_visible(false)
	_set_layer_visible(_main.wc_chat_view, true, false)
	## 压暗背景
	var old_bg: Node = _main.wc_chat_view.get_node_or_null("ChatBgOverlay")
	if old_bg != null:
		old_bg.queue_free()
	var bg_overlay := ColorRect.new()
	bg_overlay.name = "ChatBgOverlay"
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = Color(0, 0, 0, 0.25)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_main.wc_chat_view.add_child(bg_overlay)
	_main.wc_chat_view.move_child(bg_overlay, 0)

func _add_chat_bubble(sender: String, text: String) -> void:
	var is_self: bool = (sender == "self")
	var is_system: bool = (sender == "system")
	var bubble := PanelContainer.new()
	var bubble_style := StyleBoxFlat.new()
	if is_system:
		bubble_style.bg_color = Color(0.78, 0.80, 0.82, 0.92)
		bubble_style.set_content_margin_all(8)
	elif is_self:
		bubble_style.bg_color = WC_BUBBLE_SELF
	else:
		bubble_style.bg_color = Color.WHITE
	bubble_style.set_corner_radius_all(6)
	bubble.add_theme_stylebox_override("panel", bubble_style)
	bubble.add_theme_constant_override("separation", 0)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13 if is_system else 14)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.18, 0.20, 0.22, 1) if is_system else WC_TEXT_PRIMARY)
	if is_system:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(260, 0)
	bubble.add_child(label)

	if is_system:
		var system_wrapper := HBoxContainer.new()
		system_wrapper.add_theme_constant_override("separation", 8)
		var left_spacer := Control.new()
		left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left_spacer.size_flags_stretch_ratio = 1
		system_wrapper.add_child(left_spacer)
		bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bubble.size_flags_stretch_ratio = 3
		system_wrapper.add_child(bubble)
		var right_spacer := Control.new()
		right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right_spacer.size_flags_stretch_ratio = 1
		system_wrapper.add_child(right_spacer)
		_main.chat_msg_container.add_child(system_wrapper)
		return

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
	var pending_changes := _take_pending_daily_chat_changes()
	if not pending_changes.is_empty():
		_show_stat_result(pending_changes, func() -> void:
			_apply_wechat_changes(pending_changes, _current_chat_npc)
			_close_chat_view_now()
		)
		return
	_close_chat_view_now()


func _close_chat_view_now() -> void:
	if is_instance_valid(_chat_menu_panel):
		_chat_menu_panel.queue_free()
		_chat_menu_panel = null
	_clear_reply_buttons()
	var old_bg: Node = _main.wc_chat_view.get_node_or_null("ChatBgOverlay")
	if old_bg != null:
		old_bg.queue_free()
	_set_layer_visible(_main.wc_chat_view, false)
	_set_main_wechat_panel_visible(true)
	_current_chat_npc = ""

func _on_chat_send() -> void:
	if _current_chat_npc == "":
		return
	_show_chat_action_menu()


# ==================== 聊天菜单 ====================

func _show_chat_action_menu() -> void:
	if _current_chat_npc == "" or not GameManager.npcs.has(_current_chat_npc):
		return
	if is_instance_valid(_chat_menu_panel):
		if _chat_menu_panel.get_parent() != null:
			_chat_menu_panel.get_parent().remove_child(_chat_menu_panel)
		_chat_menu_panel.queue_free()
		_chat_menu_panel = null
	var npc_data: Dictionary = GameManager.npcs.get(_current_chat_npc, {})
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
	if _current_chat_npc == "wang_teacher" and GameManager.night_school_progress < 12:
		_add_menu_btn(vbox, "上课：尚德夜校 (-50精力, -1000金)", func() -> void: _on_chat_wang_teacher())
	var milestone := _next_available_milestone(_current_chat_npc)
	if not milestone.is_empty():
		var milestone_title := str(milestone.get("title", "重要对话"))
		_add_menu_btn(vbox, "重要对话：%s" % _truncate_text(milestone_title, 12), func() -> void: _on_milestone_npc(_current_chat_npc), Color(0.08, 0.28, 0.62, 1))
	if GameManager.is_npc_unlocked(_current_chat_npc):
		_add_menu_btn(vbox, "日常闲聊 (-10精力)", func() -> void: _on_daily_chat())
	match _current_chat_npc:
		"family_group":
			_add_menu_btn(vbox, "查看家庭消息", func() -> void: _on_family_interact())
		"wang_teacher":
			if GameManager.night_school_progress >= 12:
				_add_menu_btn(vbox, "已毕业", func() -> void: pass)
			else:
				pass
			if npc_data["level"] >= 2:
				_add_menu_btn(vbox, "约会", func() -> void: _on_date_npc(_current_chat_npc))
		_:
			if npc_data["level"] >= 2:
				_add_menu_btn(vbox, "约会", func() -> void: _on_date_npc(_current_chat_npc))
	_add_menu_btn(vbox, "删除好友", func() -> void: _do_delete_friend(), Color(1, 0.2, 0.2, 1))
	_add_menu_btn(vbox, "取消", func() -> void:
		if is_instance_valid(_chat_menu_panel):
			_chat_menu_panel.queue_free()
			_chat_menu_panel = null)
	_main.wc_chat_view.add_child(_chat_menu_panel)
	_chat_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_chat_menu_panel.z_index = 60
	var estimated_height := maxf(56.0, float(vbox.get_child_count()) * 38.0 + 12.0)
	var bg_size: Vector2 = _main.chat_view_bg.size
	if bg_size.x <= 0.0 or bg_size.y <= 0.0:
		bg_size = _main.wc_chat_view.size
	var bg_local: Vector2 = (_main.wc_chat_view.get_global_transform().affine_inverse() * _main.chat_view_bg.global_position)
	var panel_width := clampf(maxf(220.0, _main.chat_input_field.size.x), 220.0, maxf(220.0, bg_size.x - 16.0))
	var bottom_gap := maxf(68.0, _main.chat_input_field.size.y + 18.0)
	_chat_menu_panel.custom_minimum_size = Vector2(panel_width, estimated_height)
	_chat_menu_panel.size = Vector2(panel_width, estimated_height)
	var final_pos := Vector2(
		bg_local.x + maxf(8.0, (bg_size.x - panel_width) * 0.5),
		bg_local.y + maxf(8.0, bg_size.y - estimated_height - bottom_gap)
	)
	_chat_menu_panel.position = final_pos
	_chat_menu_panel.modulate.a = 1.0


# ==================== 日常闲聊（防重复抽卡）====================

func _on_daily_chat() -> void:
	## 消耗精力
	if GameManager.energy < 10:
		_main.show_message("精力不足，没力气聊天了！")
		return
	_pending_daily_chat_changes = _merge_change_dicts(_pending_daily_chat_changes, {"energy": -10})
	## 关闭菜单
	if is_instance_valid(_chat_menu_panel):
		_chat_menu_panel.queue_free()
		_chat_menu_panel = null

	var npc_id: String = _current_chat_npc
	var static_data: Dictionary = GameManager.get_npc_data(npc_id)
	if static_data.is_empty():
		_main.show_galgame_dialog(["[系统] 该NPC暂无对话数据。"], func() -> void:
			var pending := _take_pending_daily_chat_changes()
			_show_stat_result(pending, func() -> void:
				_apply_wechat_changes(pending, npc_id)
			)
		)
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
		_add_chat_bubble("npc", "[对方无回复]")
		var npc_data_dict: Dictionary = GameManager.npcs[_current_chat_npc]
		npc_data_dict["messages"].append({"sender": "npc", "text": "[对方无回复]"})
		_main.show_galgame_dialog(["他似乎很忙，没有回复你的消息。"], func() -> void:
			var pending := _take_pending_daily_chat_changes()
			_show_stat_result(pending, func() -> void:
				_apply_wechat_changes(pending, npc_id)
			)
		)
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
	_reply_btn_container.z_index = 25
	_main.wc_chat_view.add_child(_reply_btn_container)
	_position_reply_container()

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
	_position_reply_container()


func _on_reply_selected(option: Dictionary) -> void:
	## 资源校验
	var cost: Dictionary = option.get("cost", {})
	var cost_energy: int = int(cost.get("energy", 0))
	var cost_money: int = int(cost.get("money", 0))
	var result_changes: Dictionary = {}
	if cost_energy > 0 and GameManager.energy < cost_energy:
		_main.show_floating_text("太累了，没精力回复...", Color.RED, _main.get_global_mouse_position())
		return
	if cost_money > 0 and GameManager.money < cost_money:
		_main.show_floating_text("金钱不足...", Color.RED, _main.get_global_mouse_position())
		return

	result_changes = _take_pending_daily_chat_changes()
	## 扣除资源
	if cost_energy > 0:
		result_changes["energy"] = int(result_changes.get("energy", 0)) - cost_energy
	if cost_money > 0:
		result_changes["money"] = int(result_changes.get("money", 0)) - cost_money

	## 应用属性变化
	var stat_changes: Dictionary = option.get("stat_changes", {})
	for stat_name in stat_changes:
		var val: int = int(stat_changes[stat_name])
		result_changes[stat_name] = int(result_changes.get(stat_name, 0)) + val

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
	var npc_id := _current_chat_npc

	## 销毁选项按钮，恢复常驻按钮
	_clear_reply_buttons()
	if not result_changes.is_empty():
		_show_stat_result(result_changes, func() -> void:
			_apply_wechat_changes(result_changes, npc_id)
			if flag != "":
				var runtime: Dictionary = GameManager.get_npc_runtime(npc_id)
				if not runtime["flags"].has(flag):
					runtime["flags"].append(flag)
			_refresh_wechat_ui()
		)
	else:
		if flag != "":
			var runtime: Dictionary = GameManager.get_npc_runtime(npc_id)
			if not runtime["flags"].has(flag):
				runtime["flags"].append(flag)
		_refresh_wechat_ui()


func _clear_reply_buttons() -> void:
	if is_instance_valid(_reply_btn_container):
		_reply_btn_container.queue_free()
		_reply_btn_container = null
	_main.chat_input_field.visible = true


func _position_reply_container() -> void:
	if not is_instance_valid(_reply_btn_container):
		return
	var bg_size: Vector2 = _main.chat_view_bg.size
	if bg_size.x <= 0.0 or bg_size.y <= 0.0:
		bg_size = _main.wc_chat_view.size
	var bg_local: Vector2 = (_main.wc_chat_view.get_global_transform().affine_inverse() * _main.chat_view_bg.global_position)
	var width := maxf(180.0, bg_size.x - 16.0)
	_reply_btn_container.custom_minimum_size = Vector2(width, 0)
	_reply_btn_container.size.x = width
	var height := maxf(_reply_btn_container.size.y, _reply_btn_container.get_combined_minimum_size().y)
	_reply_btn_container.position = Vector2(
		bg_local.x + 8.0,
		bg_local.y + maxf(8.0, bg_size.y - height - 14.0)
	)


func _add_menu_btn(parent: Control, text: String, callback: Callable, color: Color = WC_TEXT_PRIMARY) -> void:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", color)
	btn.pressed.connect(func() -> void:
		if is_instance_valid(_chat_menu_panel):
			_chat_menu_panel.queue_free()
			_chat_menu_panel = null
		if _main.get("ui_state") and _main.ui_state.has_method("sync_all"):
			_main.ui_state.sync_all()
		callback.call())
	parent.add_child(btn)


# ==================== 关系里程碑 ====================

func _current_stat_value(stat_name: String) -> int:
	var value = GameManager.get(stat_name)
	if value == null:
		return 0
	return int(value)


func _milestone_option_label(prefix: String, lines: Array, fallback: String) -> String:
	var line := _first_line(lines, fallback)
	return "%s：%s" % [prefix, _truncate_text(line, 18)]


func _add_milestone_reply_button(parent: Control, text: String, disabled: bool, tooltip: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.disabled = disabled
	btn.set_meta("milestone_locked", disabled)
	btn.set_deferred("disabled", disabled)
	btn.tooltip_text = tooltip
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.custom_minimum_size = Vector2(0, 40)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.12, 0.12, 0.12, 1) if not disabled else Color(0.45, 0.45, 0.45, 1))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.94, 0.98, 1) if not disabled else Color(0.82, 0.82, 0.82, 1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("disabled", style)
	if not disabled:
		btn.pressed.connect(callback)
	parent.add_child(btn)


func _on_milestone_npc(npc_id: String) -> void:
	var milestone := _next_available_milestone(npc_id)
	if milestone.is_empty():
		_main.show_message("现在还没有新的关系事件。")
		return
	if is_instance_valid(_chat_menu_panel):
		_chat_menu_panel.queue_free()
		_chat_menu_panel = null
	_clear_reply_buttons()

	var npc_msg := _join_lines(milestone.get("text_lines", []))
	if npc_msg == "":
		npc_msg = str(milestone.get("title", "对方发来一条消息。"))
	_add_chat_bubble("npc", npc_msg)
	GameManager.npcs[npc_id]["messages"].append({
		"sender": "npc",
		"text": npc_msg,
		"type": "milestone",
		"milestone_id": str(milestone.get("id", "")),
	})

	_main.chat_input_field.visible = false
	_reply_btn_container = VBoxContainer.new()
	_reply_btn_container.add_theme_constant_override("separation", 4)
	_reply_btn_container.z_index = 65
	_main.wc_chat_view.add_child(_reply_btn_container)
	_position_reply_container()

	var req_stat := str(milestone.get("req_stat", ""))
	var req_val := int(milestone.get("req_val", 0))
	var pass_disabled := false
	var pass_tip := ""
	if req_stat != "" and _current_stat_value(req_stat) < req_val:
		pass_disabled = true
		pass_tip = "需要 %s >= %d，当前 %d" % [_stat_label(req_stat), req_val, _current_stat_value(req_stat)]
	_add_milestone_reply_button(
		_reply_btn_container,
		_milestone_option_label("边界回复", milestone.get("pass_lines", []), "冷静回应"),
		pass_disabled,
		pass_tip,
		func() -> void: _on_milestone_reply_selected(milestone, "pass")
	)
	_add_milestone_reply_button(
		_reply_btn_container,
		_milestone_option_label("顺着回应", milestone.get("fail_lines", []), "先顺着对方"),
		false,
		"",
		func() -> void: _on_milestone_reply_selected(milestone, "fail")
	)
	if milestone.has("ignore_punish_lines") or milestone.has("ignore_stat_changes"):
		_add_milestone_reply_button(
			_reply_btn_container,
			"暂时不回",
			false,
			"",
			func() -> void: _on_milestone_reply_selected(milestone, "ignore")
		)

	await _main.get_tree().process_frame
	if is_instance_valid(_reply_btn_container):
		_position_reply_container()
		for child in _reply_btn_container.get_children():
			if child is Button:
				child.disabled = bool(child.get_meta("milestone_locked", false))
				child.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_milestone_reply_selected(milestone: Dictionary, outcome: String) -> void:
	var npc_id := _current_chat_npc
	if npc_id == "":
		return
	var cost_key := "%s_cost" % outcome
	var stat_key := "%s_stat_changes" % outcome
	var lines_key := "%s_lines" % outcome
	var reply_key := "%s_reply_lines" % outcome
	if outcome == "ignore":
		lines_key = ""
		reply_key = "ignore_punish_lines"

	var cost: Dictionary = milestone.get(cost_key, {})
	var cost_energy := int(cost.get("energy", 0))
	var cost_money := int(cost.get("money", 0))
	if cost_energy > 0 and GameManager.energy < cost_energy:
		_main.show_floating_text("精力不足，回不了这条消息。", Color.RED, _main.get_global_mouse_position())
		return
	if cost_money > 0 and GameManager.money < cost_money:
		_main.show_floating_text("金钱不足，无法这样回应。", Color.RED, _main.get_global_mouse_position())
		return

	var result_changes: Dictionary = {}
	if cost_energy > 0:
		result_changes["energy"] = int(result_changes.get("energy", 0)) - cost_energy
	if cost_money > 0:
		result_changes["money"] = int(result_changes.get("money", 0)) - cost_money
	var stat_changes: Dictionary = milestone.get(stat_key, {})
	for stat_name in stat_changes:
		result_changes[str(stat_name)] = int(result_changes.get(str(stat_name), 0)) + int(stat_changes[stat_name])

	var player_text := "（你暂时没有回复）"
	if lines_key != "":
		player_text = _join_lines(milestone.get(lines_key, []))
	if player_text != "":
		_add_chat_bubble("self", player_text)
		GameManager.npcs[npc_id]["messages"].append({
			"sender": "self",
			"text": player_text,
			"type": "milestone_reply",
			"milestone_id": str(milestone.get("id", "")),
			"outcome": outcome,
		})

	var npc_reply := _join_lines(milestone.get(reply_key, []))
	if npc_reply != "":
		var reply_sender := "system" if outcome == "ignore" else "npc"
		_add_chat_bubble(reply_sender, npc_reply)
		GameManager.npcs[npc_id]["messages"].append({
			"sender": reply_sender,
			"text": npc_reply,
			"type": "milestone_result",
			"milestone_id": str(milestone.get("id", "")),
			"outcome": outcome,
		})
	var note := str(milestone.get("%s_note" % outcome, "")).strip_edges()
	if note != "":
		_add_chat_bubble("system", note)
		GameManager.npcs[npc_id]["messages"].append({
			"sender": "system",
			"text": note,
			"type": "milestone_note",
			"milestone_id": str(milestone.get("id", "")),
			"outcome": outcome,
		})

	_clear_reply_buttons()
	var after_apply := func() -> void:
		var milestone_id := str(milestone.get("id", ""))
		if GameManager.has_method("mark_npc_milestone_used"):
			GameManager.mark_npc_milestone_used(npc_id, milestone_id, outcome)
		if outcome == "pass":
			var pass_flag := str(milestone.get("pass_flag", ""))
			if pass_flag != "" and GameManager.has_method("add_npc_flag"):
				GameManager.add_npc_flag(npc_id, pass_flag)
		GameManager.add_activity("社交", "%s：%s" % [GameManager.npcs[npc_id]["name"], str(milestone.get("title", "重要对话"))])
		_refresh_wechat_ui()
	if not result_changes.is_empty():
		_show_stat_result(result_changes, func() -> void:
			_apply_wechat_changes(result_changes, npc_id)
			after_apply.call()
		)
	else:
		after_apply.call()


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
		if not _is_contact_visible(npc_id):
			continue
		var row := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color.WHITE
		style.set_content_margin_all(0)
		row.add_theme_stylebox_override("panel", style)
		row.custom_minimum_size = Vector2(0, 76)
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
		var relation_label := Label.new()
		if npc_id == "family_group":
			relation_label.text = "关系：家人｜亲情 %d" % int(npc_data["affection"])
		elif npc_id == "wang_teacher":
			relation_label.text = "关系：%s｜学分 %d/12" % [_short_relation(npc_id), GameManager.night_school_progress]
		else:
			relation_label.text = "关系：%s｜好感 %d" % [_short_relation(npc_id), int(npc_data["affection"])]
		relation_label.add_theme_color_override("font_color", WC_TEXT_SECONDARY)
		relation_label.add_theme_font_size_override("font_size", 12)
		relation_label.clip_text = true
		vbox.add_child(relation_label)
		var source_label := Label.new()
		source_label.text = "来源：%s" % _source_label(npc_id)
		source_label.add_theme_color_override("font_color", Color(0.42, 0.48, 0.56, 1))
		source_label.add_theme_font_size_override("font_size", 11)
		source_label.clip_text = true
		vbox.add_child(source_label)
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
		if not _is_contact_visible(npc_id):
			continue
		var moment_data: Dictionary = _active_moment_for(npc_id)
		var moments_text: String = _moment_text_for(npc_id)
		if moments_text == "":
			continue
		var moments_likes: int = _moment_likes_for(npc_id)
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
		post_name.text = "%s  ·  %s" % [npc_data["name"], _short_relation(npc_id)]
		post_name.add_theme_color_override("font_color", Color(0.1, 0.3, 0.7, 1))
		post_name.add_theme_font_size_override("font_size", 14)
		name_vbox.add_child(post_name)
		var source := Label.new()
		source.text = _source_label(npc_id)
		source.add_theme_color_override("font_color", WC_TEXT_SECONDARY)
		source.add_theme_font_size_override("font_size", 11)
		name_vbox.add_child(source)
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
		if not moment_data.is_empty():
			var inspect_btn := Button.new()
			var req_stat := str(moment_data.get("req_stat", ""))
			var req_val := int(moment_data.get("req_val", 0))
			if req_stat != "":
				inspect_btn.text = "解读这条动态（%s %d）" % [_stat_label(req_stat), req_val]
			else:
				inspect_btn.text = "解读这条动态"
			inspect_btn.custom_minimum_size = Vector2(0, 32)
			inspect_btn.add_theme_font_size_override("font_size", 12)
			inspect_btn.add_theme_color_override("font_color", Color(0.1, 0.25, 0.48, 1))
			var btn_style := StyleBoxFlat.new()
			btn_style.bg_color = Color(0.90, 0.93, 0.98, 1)
			btn_style.set_corner_radius_all(5)
			btn_style.set_content_margin_all(6)
			inspect_btn.add_theme_stylebox_override("normal", btn_style)
			var btn_hbox := HBoxContainer.new()
			post_vbox.add_child(btn_hbox)
			var btn_margin := Control.new()
			btn_margin.custom_minimum_size = Vector2(60, 0)
			btn_hbox.add_child(btn_margin)
			inspect_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn_hbox.add_child(inspect_btn)
			var btn_right := Control.new()
			btn_right.custom_minimum_size = Vector2(12, 0)
			btn_hbox.add_child(btn_right)
			var captured_id: String = npc_id
			var captured_moment: Dictionary = moment_data
			inspect_btn.pressed.connect(func() -> void: _on_moment_inspect(captured_id, captured_moment))
		## 底部间距
		var bottom_space := Control.new()
		bottom_space.custom_minimum_size = Vector2(0, 10)
		post_vbox.add_child(bottom_space)
		_main.moments_list.add_child(post)
	## 分隔线
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 1)
	_main.moments_list.add_child(sep)


func _on_moment_inspect(npc_id: String, moment: Dictionary) -> void:
	if moment.is_empty() or not GameManager.npcs.has(npc_id):
		return
	var req_stat := str(moment.get("req_stat", ""))
	var req_val := int(moment.get("req_val", 0))
	var passed := req_stat == "" or _current_stat_value(req_stat) >= req_val
	var outcome := "pass" if passed else "fail"
	var result_changes: Dictionary = moment.get("%s_stat_changes" % outcome, {})
	var display_lines: Array = []
	if passed:
		var truth_lines: Array = moment.get("truth_lines", [])
		display_lines = truth_lines.duplicate()
		var note := str(moment.get("pass_note", "")).strip_edges()
		if note != "":
			display_lines.append("")
			display_lines.append(note)
	else:
		display_lines = [
			"你盯着这条朋友圈看了一会儿。",
			"你隐约觉得哪里不对，但暂时说不上来。",
			"它还是成功把你拽进了对方想营造的氛围里。"
		]
	var display_text := _join_lines(display_lines)
	if display_text == "":
		display_text = "你看完了这条朋友圈。"
	var moment_id := str(moment.get("id", ""))
	var after_result := func() -> void:
		if GameManager.has_method("mark_npc_moment_used"):
			GameManager.mark_npc_moment_used(npc_id, moment_id, outcome)
		if passed:
			var pass_flag := str(moment.get("pass_flag", ""))
			if pass_flag != "" and GameManager.has_method("add_npc_flag"):
				GameManager.add_npc_flag(npc_id, pass_flag)
		GameManager.npcs[npc_id]["messages"].append({
			"sender": "system",
			"text": "【朋友圈解读】%s" % display_text,
			"type": "moment_inspect",
			"moment_id": moment_id,
			"outcome": outcome,
		})
		GameManager.add_activity("社交", "%s：解读朋友圈（%s）" % [GameManager.npcs[npc_id]["name"], "看穿" if passed else "误读"])
		_build_moments()
		_update_wechat_title()
		_refresh_wechat_ui()
	_main.show_galgame_dialog([display_text], func() -> void:
		if not result_changes.is_empty():
			_show_stat_result(result_changes, func() -> void:
				_apply_wechat_changes(result_changes, npc_id)
				after_result.call()
			)
		else:
			after_result.call()
	)


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
	var result_changes := {"sanity": sanity_effect, "money": money_effect}
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
	desc.text = chat_text
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
		_show_stat_result(result_changes, func() -> void:
			_apply_wechat_changes(result_changes)
		)
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
	var result_changes: Dictionary = {}
	for stat in effects:
		result_changes[stat] = int(result_changes.get(stat, 0)) + int(effects[stat])
	# 设置亲情变化
	var affection_gain: int = choice.get("affection_gain", 0)
	if affection_gain != 0:
		result_changes["family_affection"] = int(result_changes.get("family_affection", 0)) + affection_gain
	# 移除遮罩
	var overlay_node := _main.get_node_or_null("FamilyEventOverlay")
	if overlay_node:
		overlay_node.queue_free()
	# 显示结果消息，再单独显示数值结算
	var clean_msg := _strip_embedded_result_text(choice["msg"])
	_main.show_galgame_dialog([clean_msg], func() -> void:
		_show_stat_result(result_changes, func() -> void:
			_apply_wechat_changes(result_changes)
			if choice.get("set_mom_care", 0) > 0:
				GameManager.mom_care_buff_weeks = choice["set_mom_care"]
			_refresh_wechat_ui()
		)
	)


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

	var result_changes := {"energy": -10, "sanity": sanity_change}
	if affection_gain != 0:
		result_changes["affection"] = affection_gain
	## 添加聊天消息记录
	var npc_data: Dictionary = GameManager.npcs[npc_id]
	npc_data["messages"].append({"sender": "npc", "text": msg})
	## 在聊天界面显示气泡
	if _current_chat_npc == npc_id and _main.wc_chat_view.visible:
		_add_chat_bubble("npc", msg)
	_main.show_galgame_dialog([msg], func() -> void:
		_show_stat_result(result_changes, func() -> void:
			_apply_wechat_changes(result_changes, npc_id)
			_refresh_wechat_ui()
		)
	)


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
		var payment_changes: Dictionary = {}
		if _main.alipay and _main.alipay.has_method("get_last_payment_changes"):
			payment_changes = _main.alipay.get_last_payment_changes()
		var stat_changes := {"energy": -50, "sanity": the_sanity}
		if the_aff != 0:
			stat_changes["affection"] = the_aff
		var after_date := func() -> void:
			GameManager.add_activity("社交", the_msg)
			_refresh_wechat_ui()
		_show_story_then_apply_changes(the_msg, stat_changes, payment_changes, after_date, the_npc)

	if the_cost > 0:
		_main.alipay.request_payment(the_cost, "%s约会" % npc_name, "社交", do_date)
	else:
		do_date.call()


# ==================== 夜校王老师 ====================

func _close_wechat_for_external_payment() -> void:
	if is_instance_valid(_chat_menu_panel):
		_chat_menu_panel.queue_free()
		_chat_menu_panel = null
	_clear_reply_buttons()
	var old_bg: Node = _main.wc_chat_view.get_node_or_null("ChatBgOverlay")
	if old_bg != null:
		old_bg.queue_free()
	_set_layer_visible(_main.wc_chat_view, false)
	_set_main_wechat_panel_visible(true)
	_set_layer_visible(_main.wechat_menu, false)
	_current_chat_npc = ""


func _on_chat_wang_teacher() -> void:
	if GameManager.night_school_progress >= 12:
		_main.show_message("你已经毕业了！快去 BOSS弯聘 看看新机会吧！")
		return
	if _main.current_phase != _main.Phase.WEEKEND:
		_main.show_message("夜校课程要等周末再安排。")
		return
	var service = _action_service()
	_close_wechat_for_external_payment()
	if GameManager.energy < 50:
		_main.show_message("精力不足（需50），没法上课了！")
		return
	_main.alipay.request_payment(1000, "夜校报名冲刺班", "提升", func() -> void:
		var payment_changes: Dictionary = {}
		if _main.alipay and _main.alipay.has_method("get_last_payment_changes"):
			payment_changes = _main.alipay.get_last_payment_changes()
		if service and service.has_method("spend_weekend_action"):
			service.spend_weekend_action("夜校课程")
		var stat_changes: Dictionary = {"energy": -50, "sanity": -10, "night_school_progress": 1}
		var projected_progress := mini(GameManager.night_school_progress + 1, 12)
		var graduated := projected_progress >= 12 and GameManager.degree < 1
		if graduated:
			stat_changes["degree"] = 1
		var story := "王老师：恭喜完成本周课程！当前学分进度：%d/12。" % GameManager.night_school_progress
		story = story.replace(str(GameManager.night_school_progress) + "/12", str(projected_progress) + "/12")
		if graduated:
			story = "王老师：最后一节课也结了。证书下来了，恭喜你毕业。"
		var after_result := func() -> void:
			_refresh_wechat_ui()
			if graduated:
				_show_graduation_popup()
		_show_story_then_apply_changes(story, stat_changes, payment_changes, after_result)
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
