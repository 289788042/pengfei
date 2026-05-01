## MainGame.gd - 主游戏界面控制器 
## 负责：智能手机桌面App系统、双阶段时间循环、飘字动画、月度账单、过渡黑屏、微信社交、家庭群、春节、结局
extends Control

enum Phase { WEEKDAY, WEEKEND, EVENT, MONTH_END, TRANSITION, ENDING, GAME_OVER }

# ==================== 节点引用 ====================

@onready var label_week: Label = %LabelWeek
@onready var label_player_info: Label = %LabelPlayerInfo
@onready var dialog_text: RichTextLabel = %DialogText
@onready var dialog_box: Panel = %DialogBox
@onready var label_game_over: Label = %LabelGameOver
@onready var label_money: Label = %LabelMoney
@onready var label_energy: Label = %LabelEnergy
@onready var label_sanity: Label = %LabelSanity
@onready var label_charm: Label = %LabelCharm
@onready var label_intellect: Label = %LabelIntellect
@onready var label_eq: Label = %LabelEQ
@onready var label_psalary: Label = %LabelPSalaryValue

@onready var btn_next_week: Button = %Btn_NextWeek

@onready var location_menu: ColorRect = %LocationMenu

## 微信面板
@onready var wechat_menu: ColorRect = %WeChatMenu
@onready var wc_panel_container: PanelContainer = %WCPanelContainer
@onready var chat_list_container: VBoxContainer = %ChatListContainer
@onready var label_wc_title: Label = %LabelWCTitle
@onready var btn_close_wechat: Button = %Btn_CloseWeChat

## 微信新版 UI 节点
@onready var btn_wc_back: Button = %Btn_WCBack
@onready var btn_wc_search: Button = %Btn_WCSearch
@onready var wc_chat_list_view: VBoxContainer = %WCChatListView
@onready var wc_contacts_view: VBoxContainer = %WCContactsView
@onready var wc_contact_list: VBoxContainer = %WCContactList
@onready var wc_moments_content: ScrollContainer = %WCMomentsContent
@onready var tab_chats: Button = %TabChats
@onready var tab_contacts: Button = %TabContacts
@onready var tab_moments: Button = %TabMoments
@onready var wc_chat_view: Control = %WCChatView
@onready var chat_view_bg: PanelContainer = %ChatViewBG
@onready var label_chat_name: Label = %LabelChatName
@onready var chat_msg_container: VBoxContainer = %ChatMsgContainer
@onready var chat_input_field: Button = %ChatInputField
@onready var btn_chat_back: Button = %Btn_ChatBack
@onready var moments_list: VBoxContainer = %MomentsList

## 手机桌面App图标按钮
@onready var btn_app_map: Button = %BtnApp_Map
@onready var btn_app_wechat: Button = %BtnApp_WeChat
@onready var btn_app_alipay: Button = %BtnApp_Alipay
@onready var btn_app_baotao: Button = %BtnApp_BaoTao
@onready var btn_app_tuanmei: Button = %BtnApp_TuanMei
@onready var btn_app_zodiac: Button = %BtnApp_Zodiac
@onready var btn_app_house: Button = %BtnApp_House
@onready var btn_app_dating: Button = %BtnApp_Dating
@onready var btn_app_diary: Button = %BtnApp_Diary

## BOSS弯聘 / 淘宝 / 团美 / 贝壳 覆盖层容器
@onready var btn_app_job: Button = %BtnApp_Job
@onready var job_menu: ColorRect = %JobMenu
@onready var baotao_menu: ColorRect = %BaoTaoMenu
@onready var tuanmei_menu: ColorRect = %TuanMeiMenu
@onready var house_menu: ColorRect = %HouseMenu

@onready var weekday_panel: ColorRect = %WeekdayPanel
@onready var btn_work_normal: Button = %Btn_Work_Normal
@onready var btn_work_slack: Button = %Btn_Work_Slack
@onready var btn_work_overtime: Button = %Btn_Work_Overtime

@onready var event_popup: ColorRect = %EventPopup
@onready var label_event_desc: Label = %LabelEventDesc
@onready var btn_event_confirm: Button = %Btn_EventConfirm

@onready var ending_panel: ColorRect = %EndingPanel
@onready var label_ending_title: Label = %LabelEndingTitle
@onready var label_ending_content: Label = %LabelEndingContent
@onready var label_ending_age: Label = %LabelEndingAge

@onready var month_end_popup: ColorRect = %MonthEndPopup
@onready var label_me_content: Label = %LabelMEContent
@onready var btn_pay_rent: Button = %Btn_PayRent

@onready var transition_screen: ColorRect = %TransitionScreen
@onready var label_trans_text: Label = %LabelTransText

## 对话框淡出动画

## Galgame 分页对话状态

## 支服了宝弹窗
@onready var alipay_popup: ColorRect = %AlipayPopup
@onready var label_alipay_balance: Label = %LabelAlipayBalance
@onready var label_alipay_huabei: Label = %LabelAlipayHuabei
@onready var label_al_fin_safe: Label = %LabelAlFinSafe
@onready var label_al_fin_risk: Label = %LabelAlFinRisk
@onready var btn_al_fin_safe_in: Button = %BtnAlFinSafeIn
@onready var btn_al_fin_risk_in: Button = %BtnAlFinRiskIn
@onready var btn_al_fin_safe_out: Button = %BtnAlFinSafeOut
@onready var btn_al_fin_risk_out: Button = %BtnAlFinRiskOut
@onready var label_al_summary: Label = %LabelAlSummary
@onready var alipay_log_container: VBoxContainer = %AlipayLogContainer
@onready var btn_close_alipay: Button = %Btn_CloseAlipay
@onready var label_al_installment: Label = %LabelAlInstallment
@onready var input_repay_amount: LineEdit = %Input_RepayAmount
@onready var btn_repay_huabei: Button = %Btn_RepayHuabei
@onready var btn_installment: Button = %Btn_Installment
@onready var btn_pay_mix: Button = %BtnPayMix
@onready var btn_pay_huabei: Button = %BtnPayHuabei
@onready var btn_pay_cancel: Button = %BtnPayCancel
@onready var label_payment_cost: Label = %LabelPaymentCost

## 日记本弹窗
@onready var diary_popup: ColorRect = %DiaryPopup
@onready var diary_log_container: VBoxContainer = %DiaryLogContainer

## 通用支付拦截弹窗
@onready var payment_popup: ColorRect = %PaymentPopup

## 饮食按钮
@onready var btn_food_low: Button = %Btn_Food_Low
@onready var btn_food_mid: Button = %Btn_Food_Mid
@onready var btn_food_high: Button = %Btn_Food_High

## 宝淘弹窗 (覆盖层模式)

## 团美医美弹窗 (覆盖层模式)

## 星座弹窗
@onready var zodiac_popup: ColorRect = %ZodiacPopup
@onready var label_zodiac_content: Label = %LabelZContent
@onready var btn_close_zodiac: Button = %Btn_CloseZodiac

## 贝壳找房弹窗 (覆盖层模式)

## 滑动交友弹窗
@onready var dating_popup: ColorRect = %DatingPopup
@onready var label_date_name: Label = %LabelDateName
@onready var label_date_age: Label = %LabelDateAge
@onready var label_date_bio: Label = %LabelDateBio
@onready var btn_pass: Button = %Btn_Pass
@onready var btn_like: Button = %Btn_Like
@onready var btn_close_dating: Button = %Btn_CloseDating

## 深夜网抑云弹窗
@onready var late_night_popup: ColorRect = %LateNightPopup
@onready var btn_emo_bag: Button = %Btn_Emo_Bag
@onready var btn_emo_sleep: Button = %Btn_Emo_Sleep


var galgame: RefCounted  ## GalgameSystem (loaded dynamically)
var alipay: RefCounted  ## AlipaySystem (loaded dynamically)
var app: RefCounted  ## AppPopupSystem (loaded dynamically)
var wechat: RefCounted  ## WeChatSystem (loaded dynamically)

## 属性进度条（金钱不用进度条）
var progress_energy: ProgressBar
var progress_sanity: ProgressBar
var progress_charm: ProgressBar
var progress_intellect: ProgressBar
var progress_eq: ProgressBar
## 属性数值标签（进度条旁边）
var label_energy_val: Label
var label_sanity_val: Label
var label_charm_val: Label
var label_intellect_val: Label
var label_eq_val: Label
var current_phase: Phase = Phase.WEEKDAY
var _pending_event: Dictionary = {}
var _pending_callback: Callable = Callable()
# ==================== 生命周期 ====================

func _ready() -> void:
	GameManager.stats_updated.connect(_on_stats_updated)
	GameManager.week_advanced.connect(_on_week_advanced)
	GameManager.game_over.connect(_on_game_over)
	GameManager.npc_unlocked.connect(_on_npc_unlocked)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.month_ended.connect(_on_month_ended)
	GameManager.monthly_settled.connect(_on_monthly_settled)
	GameManager.aging_decayed.connect(_on_aging_decayed)
	GameManager.invest_settled.connect(_on_invest_settled)
	GameManager.spring_festival.connect(_on_spring_festival)

	btn_work_normal.pressed.connect(_on_work_normal)
	btn_work_slack.pressed.connect(_on_work_slack)
	btn_work_overtime.pressed.connect(_on_work_overtime)
	btn_event_confirm.pressed.connect(_on_event_confirmed)
	btn_next_week.pressed.connect(_on_btn_next_week)
	# 微信系统初始化
	galgame = load("res://scripts/GalgameSystem.gd").new()
	galgame.init(self)
	alipay = load("res://scripts/AlipaySystem.gd").new()
	alipay.init(self)
	app = load("res://scripts/AppPopupSystem.gd").new()
	app.init(self)
	wechat = load("res://scripts/WeChatSystem.gd").new()
	wechat.init(self)
	btn_close_wechat.pressed.connect(wechat._on_close_wechat)
	wechat._build_chat_items()
	## 初始推送一批未读消息（模拟游戏开始前已有的消息）
	_push_npc_unread_messages()
	btn_wc_back.pressed.connect(wechat._on_close_wechat)
	tab_chats.pressed.connect(wechat._on_wc_tab.bind(0))
	tab_contacts.pressed.connect(wechat._on_wc_tab.bind(1))
	tab_moments.pressed.connect(wechat._on_wc_tab.bind(2))
	btn_chat_back.pressed.connect(wechat._on_chat_back)
	chat_input_field.pressed.connect(wechat._on_chat_send)
	btn_pay_rent.pressed.connect(_on_pay_rent)


	btn_app_map.pressed.connect(app._on_app_map)
	btn_app_wechat.pressed.connect(_on_app_wechat)
	btn_app_alipay.pressed.connect(_on_app_alipay)
	btn_app_diary.pressed.connect(app._on_app_diary)
	btn_app_baotao.pressed.connect(app._on_app_baotao)
	btn_app_tuanmei.pressed.connect(app._on_app_tuanmei)
	btn_app_zodiac.pressed.connect(app._on_app_zodiac)
	btn_app_house.pressed.connect(app._on_app_house)
	btn_app_dating.pressed.connect(app._on_app_dating)

	btn_app_job.pressed.connect(app._on_app_job)

	btn_food_low.pressed.connect(app._on_food_low)
	btn_food_mid.pressed.connect(app._on_food_mid)
	btn_food_high.pressed.connect(app._on_food_high)

	btn_close_zodiac.pressed.connect(app._on_close_zodiac)

	btn_pass.pressed.connect(app._on_pass)
	btn_like.pressed.connect(app._on_like)
	btn_close_dating.pressed.connect(app._on_close_dating)

	# 支付宝按钮
	btn_al_fin_safe_in.pressed.connect(alipay._on_al_fin_safe_in)
	btn_al_fin_risk_in.pressed.connect(alipay._on_al_fin_risk_in)
	btn_al_fin_safe_out.pressed.connect(alipay._on_al_fin_safe_out)
	btn_al_fin_risk_out.pressed.connect(alipay._on_al_fin_risk_out)
	btn_close_alipay.pressed.connect(alipay._on_close_alipay)
	btn_repay_huabei.pressed.connect(alipay._on_repay_huabei)
	btn_installment.pressed.connect(alipay._on_installment)

	btn_pay_mix.pressed.connect(alipay._on_pay_mix)
	btn_pay_huabei.pressed.connect(alipay._on_pay_huabei)
	btn_pay_cancel.pressed.connect(alipay._on_pay_cancel)

	# 深夜网抑云按钮
	btn_emo_bag.pressed.connect(app._on_emo_bag)
	btn_emo_sleep.pressed.connect(app._on_emo_sleep)

	# 日记过滤按钮（通过 find_child 深层搜索）
	for cat in ["全部", "日常", "提升", "社交", "消费"]:
		var btn: Button = find_child("Btn_DiaryFilter_" + cat, true, false)
		if btn:
			btn.pressed.connect(app._on_diary_filter.bind(cat))
	# 日记关闭按钮
	var _btn_close_diary: Button = find_child("BtnCloseDiary", true, false)
	if _btn_close_diary:
		_btn_close_diary.pressed.connect(func() -> void: diary_popup.visible = false)

	label_player_info.text = "姓名：%s | 星座：%s" % [GameManager.player_name, GameManager.player_zodiac]
	_setup_stat_bars()
	_refresh_ui()
	_enter_weekday()


func _on_app_wechat() -> void:
	wechat._refresh_wechat_ui()
	wechat._on_wc_tab(0)
	wechat_menu.mouse_filter = Control.MOUSE_FILTER_PASS
	wc_panel_container.mouse_filter = Control.MOUSE_FILTER_PASS
	if not wechat_menu.gui_input.is_connected(wechat._on_wechat_gui_input):
		wechat_menu.gui_input.connect(wechat._on_wechat_gui_input)
	wechat_menu.visible = true


func _on_app_alipay() -> void:
	alipay._refresh_alipay_ui()
	alipay_popup.visible = true


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_close_top_popup()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if dialog_box.visible and dialog_box.modulate.a > 0.5:
				if dialog_box.get_global_rect().has_point(event.global_position):
					if galgame._gal_pages.size() > 0:
						galgame.gal_on_click()
						get_viewport().set_input_as_handled()
					elif is_instance_valid(galgame._gal_choice_container):
						pass  # 选择按钮自行处理点击，不消耗事件
					else:
						galgame.dismiss_dialog()
						get_viewport().set_input_as_handled()

## 右键返回：按优先级关闭当前最上层弹窗
func _close_top_popup() -> void:
	if payment_popup.visible:
		payment_popup.visible = false
		return
	if alipay_popup.visible:
		alipay_popup.visible = false
		return
	if diary_popup.visible:
		diary_popup.visible = false
	if baotao_menu.visible:
		baotao_menu.visible = false
		return
	if tuanmei_menu.visible:
		tuanmei_menu.visible = false
		return
	if house_menu.visible:
		house_menu.visible = false
		return
	if dating_popup.visible:
		dating_popup.visible = false
		return
	if job_menu.visible:
		job_menu.visible = false
		return
	if zodiac_popup.visible:
		zodiac_popup.visible = false
		return
	if wechat.is_visible():
		if wc_chat_view.visible:
			wechat._on_chat_back()
			return
		wechat_menu.visible = false
		return
	if location_menu.visible:
		location_menu.visible = false
		return
	if late_night_popup.visible:
		late_night_popup.visible = false
		return



# ==================== 转发 galgame 方法（供其他系统调用） ====================

func show_floating_text(text: String, color: Color, start_pos: Vector2) -> void:
	galgame.show_floating_text(text, color, start_pos)

func float_stat(text: String, amount: int, pos: Vector2) -> void:
	galgame.float_stat(text, amount, pos)

func show_message(text: String, galgame_mode: bool = false) -> void:
	galgame.show_message(text, galgame_mode)

func show_urgent_message(text: String) -> void:
	galgame.show_urgent_message(text)

func show_galgame_dialog(pages: Array, on_complete: Callable = Callable()) -> void:
	galgame.show_galgame_dialog(pages, on_complete)

func _start_wechat_request_phase() -> void:
	galgame.start_wechat_request_phase()


# ==================== 阶段状态机 ====================

func _enter_weekday() -> void:
	current_phase = Phase.WEEKDAY
	btn_next_week.visible = false
	_hide_all_popups()
	_disable_app_grid()
	weekday_panel.visible = true
	btn_food_low.disabled = false
	btn_food_mid.disabled = false
	btn_food_high.disabled = false
	btn_work_normal.disabled = true
	btn_work_slack.disabled = true
	btn_work_overtime.disabled = true


func _enter_weekend() -> void:
	current_phase = Phase.WEEKEND
	btn_next_week.visible = true
	_enable_app_grid()


func _enable_app_grid() -> void:
	btn_app_map.disabled = false
	btn_app_wechat.disabled = false
	btn_app_baotao.disabled = false
	btn_app_tuanmei.disabled = false
	btn_app_zodiac.disabled = false
	btn_app_house.disabled = false
	btn_app_dating.disabled = false
	btn_app_job.disabled = false


func _disable_app_grid() -> void:
	btn_app_map.disabled = true
	btn_app_wechat.disabled = true
	btn_app_baotao.disabled = true
	btn_app_tuanmei.disabled = true
	btn_app_zodiac.disabled = true
	btn_app_house.disabled = true
	btn_app_dating.disabled = true
	btn_app_job.disabled = true


func _hide_all_popups() -> void:
	baotao_menu.visible = false
	tuanmei_menu.visible = false
	zodiac_popup.visible = false
	location_menu.visible = false
	house_menu.visible = false
	dating_popup.visible = false
	wechat.force_close()
	alipay_popup.visible = false
	diary_popup.visible = false
	job_menu.visible = false


func _show_event(event: Dictionary, after_callback: Callable) -> void:
	current_phase = Phase.EVENT
	var full_text: String = event["desc"] + "\n\n【结算】："
	for key in event:
		if key == "desc":
			continue
		var cn_name: String = GameManager.stat_names.get(key, key)
		var val: int = event[key]
		var sign_str := "+" if val >= 0 else ""
		full_text += "\n%s %s%d" % [cn_name, sign_str, val]

	label_event_desc.text = full_text
	_pending_event = event
	_pending_callback = after_callback
	event_popup.visible = true


func _on_event_confirmed() -> void:
	for key in _pending_event:
		if key == "desc":
			continue
		GameManager.modify_stat(key, _pending_event[key])
	event_popup.visible = false
	_pending_event = {}
	if _pending_callback.is_valid():
		_pending_callback.call()
		_pending_callback = Callable()


# ==================== UI 刷新 ====================

func _refresh_ui() -> void:
	label_week.text = "%d岁 | 第%d月 | 第%d周" % [GameManager.age, GameManager.month, GameManager.week_in_month]
	label_money.text = str(GameManager.money)
	label_psalary.text = str(GameManager.pending_salary)
	# 更新进度条 + 数值标签
	if progress_energy:
		progress_energy.max_value = GameManager.max_energy
		progress_energy.value = GameManager.energy
		if label_energy_val:
			label_energy_val.text = "%d/%d" % [GameManager.energy, GameManager.max_energy]
	if progress_sanity:
		progress_sanity.max_value = GameManager.max_sanity
		progress_sanity.value = GameManager.sanity
		if label_sanity_val:
			label_sanity_val.text = "%d/%d" % [GameManager.sanity, GameManager.max_sanity]
	if progress_charm:
		progress_charm.max_value = maxf(GameManager.charm, 100)
		progress_charm.value = GameManager.charm
		if label_charm_val:
			label_charm_val.text = "%d/100" % GameManager.charm
	if progress_intellect:
		progress_intellect.max_value = maxf(GameManager.intellect, 100)
		progress_intellect.value = GameManager.intellect
		if label_intellect_val:
			label_intellect_val.text = "%d/100" % GameManager.intellect
	if progress_eq:
		progress_eq.max_value = maxf(GameManager.eq, 100)
		progress_eq.value = GameManager.eq
		if label_eq_val:
			label_eq_val.text = "%d/100" % GameManager.eq
	wechat._refresh_wechat_ui()


func _setup_stat_bars() -> void:
	var grid: GridContainer = find_child("StatsGrid", true, false)
	grid.columns = 2
	# 用 HBox(进度条+数值) 替换数值标签：精力、情绪、颜值、学识、情商
	progress_energy = _replace_value_with_bar(grid, label_energy, Color(0.30, 0.69, 0.31), "energy")
	label_energy = null
	progress_sanity = _replace_value_with_bar(grid, label_sanity, Color(0.49, 0.30, 1.0), "sanity")
	label_sanity = null
	progress_charm = _replace_value_with_bar(grid, label_charm, Color(1.0, 0.25, 0.50), "charm")
	label_charm = null
	progress_intellect = _replace_value_with_bar(grid, label_intellect, Color(1.0, 0.60, 0.0), "intellect")
	label_intellect = null
	progress_eq = _replace_value_with_bar(grid, label_eq, Color(1.0, 0.84, 0.0), "eq")
	label_eq = null


func _replace_value_with_bar(grid: GridContainer, old_label: Label, fill_color: Color, stat_name: String) -> ProgressBar:
	var idx := old_label.get_index()
	grid.remove_child(old_label)
	old_label.queue_free()
	# HBox：进度条 + 数值标签
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bar := _create_stat_bar(fill_color)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(bar)
	var val := Label.new()
	val.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	val.add_theme_font_size_override("font_size", 12)
	val.custom_minimum_size.x = 52
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(val)

	# 右侧留白（给头像腾位置）
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 40
	hbox.add_child(spacer)

	# 存储引用
	match stat_name:
		"energy": label_energy_val = val
		"sanity": label_sanity_val = val
		"charm": label_charm_val = val
		"intellect": label_intellect_val = val
		"eq": label_eq_val = val
	grid.add_child(hbox)
	grid.move_child(hbox, idx)
	return bar


func _create_stat_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(100, 14)
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 填充样式
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_right = 4
	fill.corner_radius_bottom_left = 4
	fill.content_margin_top = 2
	fill.content_margin_bottom = 2
	bar.add_theme_stylebox_override("fill", fill)
	# 背景样式
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_right = 4
	bg.corner_radius_bottom_left = 4
	bg.content_margin_top = 0
	bg.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background", bg)
	return bar


func _on_stats_updated() -> void:
	_refresh_ui()

func _on_week_advanced(_new_week: int) -> void:
	_refresh_ui()
	## 推送NPC未读消息
	_push_npc_unread_messages()


func _push_npc_unread_messages() -> void:
	## 家庭群：第1周固定推送相亲局，第5周固定推送冰箱，其他70%随机
	if GameManager.npcs.get("family_group", {}).get("unlocked", false):
		var should_push_event := false
		var event_idx: int = 0
		if GameManager.turn_count == 1:
			should_push_event = true
			event_idx = 0  ## 相亲局
		elif GameManager.turn_count == 5:
			should_push_event = true
			event_idx = 1  ## 冰箱
		elif randi() % 100 < 70:
			should_push_event = true
			event_idx = randi() % wechat._family_events.size()
		if should_push_event:
			var event_desc: String = wechat._family_events[event_idx]["desc"]
			var preview_line: String = event_desc.split("
")[0]
			if preview_line.length() > 20:
				preview_line = preview_line.substr(0, 20) + "..."
			GameManager.npcs["family_group"]["messages"].append({"sender": "npc", "text": preview_line, "event_idx": event_idx})
			GameManager.add_unread("family_group")
	## 王老师：第1周100%推送，之后每4周推送
	if GameManager.npcs.get("wang_teacher", {}).get("unlocked", false):
		if GameManager.night_school_progress < 12:
			var should_push := false
			var push_msg := ""
			if GameManager.turn_count == 1 and GameManager._wang_teacher_last_push_week == 0:
				should_push = true
				push_msg = "尚德夜校成人高考修行班火热报名中！\n只要上满12节课就能获得成人本科学历，\n改变命运从这里开始！"
			elif GameManager.turn_count - GameManager._wang_teacher_last_push_week >= 4:
				should_push = true
				if GameManager.night_school_progress >= 9:
					var left := 12 - GameManager.night_school_progress
					push_msg = "同学，胜利近在咫尺！只要再坚持%d节课就能毕业了，加油啊！" % left
				else:
					push_msg = NPCManager.get_auto_reply("wang_teacher")
			if should_push:
				GameManager.npcs["wang_teacher"]["messages"].append({"sender": "npc", "text": push_msg})
				GameManager.add_unread("wang_teacher")
				GameManager._wang_teacher_last_push_week = GameManager.turn_count

	## 家庭群闲聊：第2周起每4周推送一条（共13条，每条只出现一次）
	if GameManager.turn_count >= 2 and (GameManager.turn_count - 2) % 4 == 0:
		## 合并负面闲聊和正面事件为一个大池子，随机抽取
		var all_chats: Array = []
		for ci in range(wechat._family_chat_chats.size()):
			if ci not in GameManager._family_chat_used_indices:
				all_chats.append({"pool": "chat", "index": ci})
		for pi in range(wechat._family_positive_events.size()):
			var chat_key: int = 100 + pi  ## 用100+区分正面事件索引
			if chat_key not in GameManager._family_chat_used_indices:
				all_chats.append({"pool": "positive", "index": pi})
		if all_chats.size() > 0:
			var pick: Dictionary = all_chats[randi() % all_chats.size()]
			var msg_text: String = ""
			var sanity_effect: int = 0
			var money_effect: int = 0
			var detail_msg: String = ""
			if pick["pool"] == "chat":
				msg_text = wechat._family_chat_chats[pick["index"]]
				sanity_effect = -3
				GameManager._family_chat_used_indices.append(pick["index"])
			else:
				var evt: Dictionary = wechat._family_positive_events[pick["index"]]
				msg_text = evt["label"]
				sanity_effect = evt.get("sanity", 0)
				money_effect = evt.get("money", 0)
				detail_msg = evt.get("msg", "")
				GameManager._family_chat_used_indices.append(100 + pick["index"])
			var preview: String = msg_text
			if preview.length() > 20:
				preview = preview.substr(0, 20) + "..."
			GameManager.npcs["family_group"]["messages"].append({
				"sender": "npc", "text": preview, "full_text": msg_text,
				"type": "family_chat", "sanity": sanity_effect, "money": money_effect,
				"detail_msg": detail_msg,
			})
			GameManager.add_unread("family_group")

func _on_npc_unlocked(_id: String, npc_name: String) -> void:
	show_message("[%s] 通过群聊添加了你的微信！" % npc_name, true)
	wechat._build_chat_items()

func _on_monthly_settled(net_change: int) -> void:
	var sign_str := "+" if net_change >= 0 else ""
	show_message("【月度结算完成】结余 %s%d" % [sign_str, net_change])

func _on_invest_settled(safe_profit: int, risk_profit: int) -> void:
	if safe_profit > 0 or risk_profit != 0:
		var msg := "【理财月报】稳健 +%d | 高风险 %s%d" % [
			safe_profit,
			"+" if risk_profit >= 0 else "",
			risk_profit,
		]
		show_message(msg)

func _on_aging_decayed() -> void:
	show_message("又过了一个月，你感觉皮肤状态变差了。(颜值 -1)")

func _on_spring_festival(msg: String) -> void:
	show_urgent_message(msg)


func _on_game_over(cause_title: String, cause_desc: String) -> void:
	current_phase = Phase.GAME_OVER
	_disable_all()
	label_game_over.visible = false
	label_week.text = "游戏结束"

	# 创建全屏死亡弹窗
	var overlay := ColorRect.new()
	overlay.name = "GameOverOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.95)
	overlay.z_index = 100
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.06, 0.08, 1)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# GAME OVER 标题
	var title_label := Label.new()
	title_label.text = "G A M E   O V E R"
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(1, 0.15, 0.2, 1))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# 死法标题
	var cause_label := Label.new()
	cause_label.text = cause_title
	cause_label.add_theme_font_size_override("font_size", 24)
	cause_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
	cause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cause_label)

	# 分割线
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# 死法描述
	var desc_label := Label.new()
	desc_label.text = cause_desc
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)

	# 终局统计
	var age_label := Label.new()
	age_label.text = "终局统计 | 年龄：%d岁 | 金钱：%d | 花呗欠款：%d" % [
		GameManager.age, GameManager.money,
		GameManager.huabei_debt + GameManager.huabei_installment_debt,
	]
	age_label.add_theme_font_size_override("font_size", 14)
	age_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	age_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(age_label)

	# 重新开始按钮
	var btn_restart := Button.new()
	btn_restart.text = "重新开始"
	btn_restart.custom_minimum_size = Vector2(0, 48)
	var restart_style := StyleBoxFlat.new()
	restart_style.bg_color = Color(0.85, 0.15, 0.2, 1)
	restart_style.set_corner_radius_all(10.0)
	btn_restart.add_theme_stylebox_override("normal", restart_style)
	btn_restart.add_theme_color_override("font_color", Color.WHITE)
	btn_restart.add_theme_font_size_override("font_size", 18)
	btn_restart.pressed.connect(func() -> void:
		# 重新加载场景
		get_tree().reload_current_scene()
	)
	vbox.add_child(btn_restart)

func _on_game_ended(ending_type: String) -> void:
	current_phase = Phase.ENDING
	_disable_all()
	label_game_over.visible = false
	ending_panel.visible = true
	label_ending_title.text = "【精英结局】孤独的赢家"
	label_ending_content.text = (
		"35岁这年，你如愿成为了别人眼中的精英。
"
		+ "但看着空荡荡的高级公寓，你想起当年在城中村楼下，那个淋着雨给你送粥的笨蛋。
"
		+ "你赢得了世界，却唯独弄丢了那个能让你安心哭泣的人。"
	)
	var family_lv: int = GameManager.npcs["family_group"]["level"]
	label_ending_age.text = "终局统计 | 年龄：%d岁 | 金钱：%d | 家庭 Lv.%d" % [
		GameManager.age, GameManager.money,
		family_lv,
	]

func _disable_all() -> void:
	weekday_panel.visible = false
	event_popup.visible = false
	location_menu.visible = false
	month_end_popup.visible = false
	transition_screen.visible = false
	btn_next_week.visible = false
	house_menu.visible = false
	dating_popup.visible = false
	alipay_popup.visible = false
	diary_popup.visible = false
	payment_popup.visible = false
	job_menu.visible = false
	wechat.force_close()
	_hide_all_popups()
	_disable_app_grid()


# ==================== 工作日逻辑 ====================

## 摸鱼混日子
func _on_work_slack() -> void:
	GameManager.modify_stat("energy", -10)
	GameManager.modify_stat("sanity", 5)
	GameManager.consecutive_overtime = 0
	var amount: int = _get_salary("slack")
	GameManager.pending_salary += amount
	float_stat("+%d 待发工资" % amount, amount, get_global_mouse_position())
	GameManager.add_activity("日常", "摸鱼混日子，待发工资 +%d" % amount)
	_finish_workday()

## 正常打卡
func _on_work_normal() -> void:
	GameManager.modify_stat("energy", -30)
	GameManager.modify_stat("sanity", -15)
	GameManager.consecutive_overtime = 0
	var amount: int = _get_salary("normal")
	GameManager.pending_salary += amount
	float_stat("+%d 待发工资" % amount, amount, get_global_mouse_position())
	GameManager.add_activity("日常", "正常打卡，待发工资 +%d" % amount)
	_finish_workday()

## 疯狂自愿加班
func _on_work_overtime() -> void:
	GameManager.modify_stat("energy", -60)
	GameManager.modify_stat("sanity", -30)
	GameManager.consecutive_overtime += 1
	var amount: int = _get_salary("overtime")
	GameManager.pending_salary += amount
	float_stat("+%d 待发工资" % amount, amount, get_global_mouse_position())
	GameManager.add_activity("日常", "疯狂加班，待发工资 +%d" % amount)
	# 连续加班死法检查
	var death: Dictionary = GameManager.check_behavior_death()
	if death.size() > 0:
		GameManager.game_over.emit(death["title"], death["desc"])
		return
	_finish_workday()


## 根据职位等级获取薪资
func _get_salary(work_type: String) -> int:
	match GameManager.job_level:
		0:
			match work_type:
				"slack": return 800
				"normal": return 1500
				"overtime": return 2500
		1:
			match work_type:
				"slack": return 2000
				"normal": return 4000
				"overtime": return 6000
		2:
			match work_type:
				"slack": return 4000
				"normal": return 8000
				"overtime": return 12000
	return 1000


func _finish_workday() -> void:
	_refresh_ui()
	weekday_panel.visible = false
	_play_transition("5天的牛马生活结束了，终于熬到了周末...")


func _play_transition(trans_text: String) -> void:
	current_phase = Phase.TRANSITION
	label_trans_text.text = trans_text
	transition_screen.visible = true
	transition_screen.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(transition_screen, "modulate:a", 1.0, 0.4)
	tween.tween_interval(1.0)
	tween.tween_property(transition_screen, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		transition_screen.visible = false
		var event := GameManager.roll_random_event("work")
		if event.size() > 0:
			_show_event(event, _enter_weekend)
		else:
			_enter_weekend()
	)


# ==================== 月度账单 ====================

func _on_month_ended(salary: int, rent: int, debt: int, food: int) -> void:
	current_phase = Phase.MONTH_END
	weekday_panel.visible = false
	btn_next_week.visible = false
	_hide_all_popups()
	_disable_app_grid()

	var installment_pay: int = GameManager.huabei_installment_monthly_pay if GameManager.huabei_installment_months_left > 0 else 0
	var total_cost: int = rent + debt + food + installment_pay
	var net: int = salary - total_cost
	var content := (
		"【月度账单】

"
		+ "本月工资：+%d

" % salary
		+ "── 扣除明细 ──
"
		+ "房租：-%d
" % rent
		+ "餐饮：-%d
" % food
		+ "花呗最低还款：-%d
" % debt
	)
	if installment_pay > 0:
		content += "分期固定扣款：-%d（剩余 %d 期）
" % [installment_pay, GameManager.huabei_installment_months_left]
	content += "──────────
"
	if net >= 0:
		content += "实际结余：+%d" % net
	else:
		content += "实际结余：%d（入不敷出！）" % net

	label_me_content.text = content
	month_end_popup.visible = true


func _on_pay_rent() -> void:
	month_end_popup.visible = false
	GameManager.start_new_month()
	if GameManager.awaiting_ending_choice:
		return
	if not GameManager.game_finished:
		_enter_weekday()


# ==================== 周末按钮 ====================

func _on_btn_next_week() -> void:
	_show_week_confirm_popup()


## 周末确认弹窗：确认结束本周 or 返回继续活动
func _show_week_confirm_popup() -> void:
	var overlay := ColorRect.new()
	overlay.name = "WeekConfirmOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.z_index = 80
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.98, 0.97, 0.95, 1)
	panel_style.set_corner_radius_all(12.0)
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "确认结束本周？"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.BLACK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "结束后将恢复全部精力，进入新一周的工作日。\n你还有没有想做的事？"
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	var btn_confirm := Button.new()
	btn_confirm.text = "确认，结束本周"
	btn_confirm.custom_minimum_size = Vector2(0, 44)
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = Color(0.027, 0.757, 0.376, 1)
	confirm_style.set_corner_radius_all(8)
	btn_confirm.add_theme_stylebox_override("normal", confirm_style)
	btn_confirm.add_theme_color_override("font_color", Color.WHITE)
	btn_confirm.add_theme_font_size_override("font_size", 16)
	btn_confirm.pressed.connect(_on_week_confirm.bind(overlay))
	vbox.add_child(btn_confirm)

	var btn_back := Button.new()
	btn_back.text = "返回，再逛逛"
	btn_back.custom_minimum_size = Vector2(0, 44)
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = Color(0.5, 0.5, 0.5, 1)
	back_style.set_corner_radius_all(8)
	btn_back.add_theme_stylebox_override("normal", back_style)
	btn_back.add_theme_color_override("font_color", Color.WHITE)
	btn_back.add_theme_font_size_override("font_size", 16)
	btn_back.pressed.connect(func() -> void: overlay.queue_free())
	vbox.add_child(btn_back)


## 确认结束本周回调
func _on_week_confirm(overlay: ColorRect) -> void:
	overlay.queue_free()
	# 深夜失眠拦截：情绪低于30时有50%概率触发
	if GameManager.sanity < 30 and randf() < 0.5:
		app._enter_late_night()
		return
	_proceed_next_week()

## 实际推进下一周（失眠弹窗成功睡觉或冲动消费后也调用此函数）
func _proceed_next_week() -> void:
	GameManager.advance_week()
	if GameManager.awaiting_month_settle:
		return
	if not GameManager.game_finished:
		_enter_weekday()
