## MainGame.gd - 主游戏界面控制器 
## 负责：智能手机桌面App系统、双阶段时间循环、飘字动画、月度账单、过渡黑屏、微信社交、家庭群、春节、结局
extends Control

enum Phase { WEEKDAY, WEEKEND, EVENT, MONTH_END, TRANSITION, ENDING, GAME_OVER }

# ==================== 节点引用 ====================

@onready var label_week: Label = %LabelWeek
@onready var label_player_info: Label = %LabelPlayerInfo
@onready var left_dialog_text: RichTextLabel = %LeftDialogText
@onready var left_dialog_box: Panel = %LeftDialogBox
@onready var character_portrait: TextureRect = %CharacterPortrait
@onready var left_bg: ColorRect = %BgImage
@onready var bg_texture: TextureRect = %BgTexture
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

@onready var label_event_desc: Label = %LabelEventDesc

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
var spring_festival: RefCounted  ## SpringFestivalSystem (loaded dynamically)
var _debug_panel: Control  ## DebugPanel (F1 toggle)
var ui_state: RefCounted
var action_service: RefCounted
var environment: RefCounted

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
var label_pressure_summary: Label
var label_pressure_hint: Label
var label_early_goal: Label
var _skip_week_confirm: bool = false
var _phone_dim: ColorRect = null
var _runtime_disposed: bool = false
var _transition_token: int = 0
var _first_week_app_gate: String = ""
var _first_week_app_tutorial_done: bool = false
var _first_week_alipay_tutorial_shown: bool = false
var _first_week_overtime_tutorial_done: bool = false
var _first_week_wechat_tutorial_done: bool = false
var _first_week_beach_unlocked: bool = false
var _phone_focus_button: Button = null
var _phone_focus_tween: Tween = null
var _phone_focus_halo: Panel = null
var _stats_panel_focus_halo: Panel = null
var _stats_panel_focus_tween: Tween = null
var _alipay_tutorial_overlay: Control = null
var _tutorial_flash_tweens: Array = []
var _tutorial_flash_targets: Array = []
var current_phase: Phase = Phase.WEEKDAY
# ==================== 生命周期 ====================


func _new_refcounted_script(path: String) -> RefCounted:
	var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as Script
	return script.new() as RefCounted


func _new_control_script(path: String) -> Control:
	var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as Script
	return script.new() as Control


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
	GameManager.spring_festival_boss.connect(_on_spring_festival_boss)

	btn_work_normal.pressed.connect(_on_work_normal)
	btn_work_slack.pressed.connect(_on_work_slack)
	btn_work_overtime.pressed.connect(_on_work_overtime)
	btn_next_week.pressed.connect(_on_btn_next_week)
	# 微信系统初始化
	galgame = _new_refcounted_script("res://scripts/GalgameSystem.gd")
	galgame.init(self)
	left_dialog_box.gui_input.connect(_on_left_dialog_box_gui_input)
	left_dialog_box.mouse_filter = Control.MOUSE_FILTER_STOP
	left_dialog_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alipay = _new_refcounted_script("res://scripts/AlipaySystem.gd")
	alipay.init(self)
	app = _new_refcounted_script("res://scripts/AppPopupSystem.gd")
	app.init(self)
	wechat = _new_refcounted_script("res://scripts/WeChatSystem.gd")
	wechat.init(self)
	spring_festival = _new_refcounted_script("res://scripts/SpringFestivalSystem.gd")
	spring_festival.init(self)
	# 调试面板
	_debug_panel = get_node_or_null("DebugPanel")
	if _debug_panel == null:
		_debug_panel = _new_control_script("res://scripts/DebugPanel.gd")
		add_child(_debug_panel)
	btn_close_wechat.pressed.connect(wechat._on_close_wechat)
	wechat._build_chat_items()
	## 初始推送一批未读消息（模拟游戏开始前已有的消息）
	_push_npc_unread_messages()
	pass
	btn_wc_back.pressed.connect(wechat._on_close_wechat)
	tab_chats.pressed.connect(wechat._on_wc_tab.bind(0))
	tab_contacts.pressed.connect(wechat._on_wc_tab.bind(1))
	tab_moments.pressed.connect(wechat._on_wc_tab.bind(2))
	btn_chat_back.pressed.connect(wechat._on_chat_back)
	chat_input_field.pressed.connect(wechat._on_chat_send)
	btn_pay_rent.pressed.connect(_on_pay_rent)


	btn_app_map.pressed.connect(_on_app_map_pressed)
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
		_btn_close_diary.pressed.connect(func() -> void: set_ui_layer_visible(diary_popup, false))

	label_player_info.text = "姓名：%s | 星座：%s" % [GameManager.player_name, GameManager.player_zodiac]
	# 创建手机暗化遮罩
	var phone_case: Control = get_node_or_null("HBoxContainer/RightMargin/RightSystemArea/PhoneCase")
	if phone_case:
		_phone_dim = ColorRect.new()
		_phone_dim.name = "PhoneDim"
		_phone_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		_phone_dim.color = Color(0, 0, 0, 0.45)
		_phone_dim.z_index = 50
		_phone_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_phone_dim.visible = false
	phone_case.add_child(_phone_dim)
	_setup_stat_bars()
	_setup_finance_widgets()
	_setup_phone_home_layout()
	_refresh_action_tooltips()
	left_bg = find_child("BgImage", true, false) as ColorRect
	_setup_foundation_services()
	pass
	_refresh_ui()
	pass
	if GameManager.skip_opening_intro_once:
		GameManager.skip_opening_intro_once = false
		call_deferred("_enter_weekend")
	elif GameManager.turn_count == 1 and GameManager.week_in_month == 1 and GameManager.month == 1 and GameManager.age == 23:
		call_deferred("_show_opening_intro")
	else:
		_enter_weekday()
	pass


func _setup_phone_home_layout() -> void:
	var grid := btn_app_map.get_parent() as GridContainer
	if is_instance_valid(grid):
		grid.columns = 3
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 24)
		var wrapper := grid.get_parent() as MarginContainer
		if is_instance_valid(wrapper):
			wrapper.add_theme_constant_override("margin_left", 16)
			wrapper.add_theme_constant_override("margin_top", 18)
			wrapper.add_theme_constant_override("margin_right", 16)
			wrapper.add_theme_constant_override("margin_bottom", 10)
	_style_phone_icon(btn_app_map, Color(0.11, 0.56, 0.95, 1))
	_style_phone_icon(btn_app_wechat, Color(0.07, 0.72, 0.17, 1))
	_style_phone_icon(btn_app_alipay, Color(0.12, 0.48, 0.95, 1))
	_style_phone_icon(btn_app_diary, Color(0.66, 0.40, 0.19, 1))
	_style_phone_icon(btn_app_job, Color(0.12, 0.39, 0.78, 1))
	_style_phone_icon(btn_app_baotao, Color(0.88, 0.25, 0.32, 1))
	_style_phone_icon(btn_app_dating, Color(0.74, 0.24, 0.60, 1))
	_style_phone_icon(btn_app_tuanmei, Color(0.77, 0.17, 0.42, 1))
	_style_phone_icon(btn_app_zodiac, Color(0.42, 0.24, 0.78, 1))
	_style_phone_icon(btn_app_house, Color(0.10, 0.56, 0.68, 1))


func _make_phone_icon_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(1, 1, 1, 0.12)
	style.set_border_width_all(1)
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


func _style_phone_icon(button: Button, base_color: Color) -> void:
	if not is_instance_valid(button):
		return
	button.custom_minimum_size = Vector2(126, 126)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_phone_icon_style(base_color))
	button.add_theme_stylebox_override("hover", _make_phone_icon_style(base_color.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _make_phone_icon_style(base_color.darkened(0.10)))
	button.add_theme_stylebox_override("disabled", _make_phone_icon_style(base_color.darkened(0.35)))


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_dispose_runtime_systems()


func _exit_tree() -> void:
	_dispose_runtime_systems()


func _dispose_runtime_systems() -> void:
	if _runtime_disposed:
		return
	_runtime_disposed = true
	if galgame and galgame.has_method("dispose"):
		galgame.dispose()
	galgame = null



func _on_app_wechat() -> void:
	if not _allow_first_week_app_open("wechat"):
		return
	if _first_week_app_gate == "wechat":
		_stop_phone_focus_pulse()
	if not can_open_phone_app():
		return
	_hide_all_popups()
	wechat._build_chat_items()
	wechat._on_wc_tab(0)
	wechat_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	wc_panel_container.mouse_filter = Control.MOUSE_FILTER_STOP
	if not wechat_menu.gui_input.is_connected(wechat._on_wechat_gui_input):
		wechat_menu.gui_input.connect(wechat._on_wechat_gui_input)
	set_ui_layer_visible(wechat_menu, true)


func _on_app_alipay() -> void:
	if not _allow_first_week_app_open("alipay"):
		return
	if _first_week_app_gate == "alipay":
		_force_clear_dialog_overlay()
	if not can_open_phone_app():
		return
	_hide_all_popups()
	alipay._refresh_alipay_ui()
	set_ui_layer_visible(alipay_popup, true)
	if _first_week_app_gate == "alipay":
		_stop_phone_focus_pulse()
		_show_first_week_alipay_tutorial()


func _on_app_map_pressed() -> void:
	if not _allow_first_week_app_open("map"):
		return
	var was_first_week_map_gate := _first_week_app_gate == "map"
	var was_first_week_beach_gate := _first_week_app_gate == "map_beach"
	app._on_app_map()
	if was_first_week_map_gate:
		_finish_first_week_app_tutorial()
		_show_tutorial_dialog(["先去[color=FFD700]加班[/color]吧，加班费可能会让我挺过这个月。"])
	elif was_first_week_beach_gate:
		_first_week_app_gate = ""
		_stop_phone_focus_pulse()
		_sync_phone_home_apps(true)


func _is_first_week_app_tutorial_context() -> bool:
	return GameManager.month == 1 and GameManager.week_in_month == 1 and GameManager.turn_count == 1


func _maybe_start_first_week_app_tutorial() -> void:
	if _first_week_app_tutorial_done or _first_week_app_gate != "":
		return
	if not _is_first_week_app_tutorial_context():
		return
	_first_week_app_gate = "alipay"
	_hide_phone_dim_overlay()
	_refresh_first_week_app_focus()


func _allow_first_week_app_open(app_id: String) -> bool:
	if _first_week_app_gate == "":
		return true
	if not _is_first_week_app_tutorial_context():
		return true
	if _first_week_app_gate == "map_beach" and app_id == "map":
		return true
	if app_id == _first_week_app_gate:
		return true
	if _first_week_app_gate == "alipay":
		_show_tutorial_dialog(["先打开支服了宝，看看账单吧"])
	elif _first_week_app_gate == "map":
		_show_tutorial_dialog(["现在打开高德地图，再决定出门去哪。"])
	elif _first_week_app_gate == "wechat":
		_show_tutorial_dialog(["先看看微信吧？别漏掉家人和朋友的信息。"])
	elif _first_week_app_gate == "map_beach":
		_show_tutorial_dialog(["先打开高德地图，去海边散散心。"])
	return false


func _refresh_first_week_app_focus() -> void:
	if _first_week_app_gate == "":
		_stop_phone_focus_pulse()
		return
	var target: Button = null
	match _first_week_app_gate:
		"alipay":
			target = btn_app_alipay
			_keep_tutorial_app_button_normal(btn_app_map)
			_keep_tutorial_app_button_normal(btn_app_wechat)
		"map":
			target = btn_app_map
			_keep_tutorial_app_button_normal(btn_app_alipay)
			_keep_tutorial_app_button_normal(btn_app_wechat)
		"wechat":
			target = btn_app_wechat
			_keep_tutorial_app_button_normal(btn_app_alipay)
			_keep_tutorial_app_button_normal(btn_app_map)
		"map_beach":
			target = btn_app_map
			_keep_tutorial_app_button_normal(btn_app_alipay)
			_keep_tutorial_app_button_normal(btn_app_wechat)
	if is_instance_valid(target):
		target.disabled = false
		target.mouse_filter = Control.MOUSE_FILTER_STOP
		_start_phone_focus_pulse(target)


func _keep_tutorial_app_button_normal(button: Button) -> void:
	if not is_instance_valid(button) or not button.visible:
		return
	button.disabled = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = Color(1, 1, 1, 1)
	button.scale = Vector2.ONE


func _start_phone_focus_pulse(button: Button) -> void:
	if _phone_focus_button == button and is_instance_valid(_phone_focus_halo):
		return
	_stop_phone_focus_pulse()
	_phone_focus_button = button
	button.modulate = Color(1, 1, 1, 1)
	button.pivot_offset = button.size * 0.5
	_phone_focus_halo = _create_phone_focus_halo(button)
	_update_phone_focus_breathing()


func _create_phone_focus_halo(button: Button) -> Panel:
	var halo := Panel.new()
	halo.name = "TutorialFocusHalo"
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.show_behind_parent = false
	halo.set_anchors_preset(Control.PRESET_FULL_RECT)
	halo.offset_left = -10
	halo.offset_top = -10
	halo.offset_right = 10
	halo.offset_bottom = 10
	halo.z_index = 8
	halo.pivot_offset = button.size * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.58, 1.0, 0.0)
	style.border_color = Color(0.72, 0.94, 1.0, 0.82)
	style.set_border_width_all(3)
	style.set_corner_radius_all(38)
	style.shadow_color = Color(0.18, 0.78, 1.0, 0.45)
	style.shadow_size = 18
	style.shadow_offset = Vector2.ZERO
	halo.add_theme_stylebox_override("panel", style)
	halo.scale = Vector2(0.98, 0.98)
	halo.modulate.a = 0.20
	button.add_child(halo)
	return halo


func _update_phone_focus_breathing() -> void:
	if not is_instance_valid(_phone_focus_button):
		return
	var pulse := (sin(float(Time.get_ticks_msec()) * 0.0065) + 1.0) * 0.5
	var button_scale := lerpf(1.0, 1.045, pulse)
	_phone_focus_button.scale = Vector2(button_scale, button_scale)
	_phone_focus_button.modulate = Color(1, 1, 1, 1)
	if is_instance_valid(_phone_focus_halo):
		var halo_scale := lerpf(0.98, 1.045, pulse)
		_phone_focus_halo.scale = Vector2(halo_scale, halo_scale)
		_phone_focus_halo.modulate.a = lerpf(0.18, 0.58, pulse)


func _stop_phone_focus_pulse(restore: bool = true) -> void:
	if _phone_focus_tween and _phone_focus_tween.is_valid():
		_phone_focus_tween.kill()
	_phone_focus_tween = null
	if is_instance_valid(_phone_focus_halo):
		_phone_focus_halo.queue_free()
	_phone_focus_halo = null
	if restore and is_instance_valid(_phone_focus_button):
		_phone_focus_button.modulate = Color(1, 1, 1, 1)
		_phone_focus_button.scale = Vector2.ONE
	_phone_focus_button = null


func _show_first_week_alipay_tutorial() -> void:
	if _first_week_alipay_tutorial_shown:
		return
	_first_week_alipay_tutorial_shown = true
	_stop_tutorial_flash()
	_force_clear_dialog_overlay()
	call_deferred("_show_alipay_tutorial_callouts")


func _show_alipay_tutorial_callouts() -> void:
	_clear_alipay_tutorial_callouts()
	if not is_instance_valid(alipay_popup) or not alipay_popup.visible:
		return
	var overlay := Control.new()
	overlay.name = "AlipayTutorialOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 180
	alipay_popup.add_child(overlay)
	_alipay_tutorial_overlay = overlay

	var overview_tab := _get_alipay_tutorial_tab("overview")
	var bill_tab := _get_alipay_tutorial_tab("bill")
	var huabei_tab := _get_alipay_tutorial_tab("huabei")
	_add_alipay_tutorial_callout(
		overlay,
		overview_tab,
		"总览：这里显示你的资产状况。\n你手里的现金、花呗，和月底预估会剩的钱；",
		"left",
		Vector2(350, 82),
		Vector2(0, -16)
	)
	_add_alipay_tutorial_callout(
		overlay,
		bill_tab,
		"账单：这里会显示你的消费记录，\n包括下月房租等财务详情",
		"left",
		Vector2(350, 74),
		Vector2(0, 3)
	)
	_add_alipay_tutorial_callout(
		overlay,
		huabei_tab,
		"花呗：这里会显示花呗的数额、\n还款/分期等详情；",
		"left",
		Vector2(350, 74),
		Vector2(0, 22)
	)
	_add_alipay_tutorial_callout(
		overlay,
		btn_close_alipay,
		"看完关闭，再去高德地图。",
		"left",
		Vector2(220, 54)
	)


func _get_alipay_tutorial_tab(page_id: String) -> Control:
	if not alipay:
		return null
	var raw_tabs: Variant = alipay.get("_alipay_tab_buttons")
	if typeof(raw_tabs) != TYPE_DICTIONARY:
		return null
	var tabs := raw_tabs as Dictionary
	return tabs.get(page_id, null) as Control


func _clear_alipay_tutorial_callouts() -> void:
	if is_instance_valid(_alipay_tutorial_overlay):
		_alipay_tutorial_overlay.queue_free()
	_alipay_tutorial_overlay = null


func _add_alipay_tutorial_callout(overlay: Control, target: Control, text: String, side: String, bubble_size: Vector2, bubble_offset: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(overlay) or not is_instance_valid(target):
		return
	var target_rect := target.get_global_rect()
	var overlay_rect := overlay.get_global_rect()
	var local_rect := Rect2(target_rect.position - overlay_rect.position, target_rect.size)
	var anchor_rect := _fit_alipay_tutorial_anchor_rect(local_rect)
	_add_alipay_tutorial_frame(overlay, anchor_rect)
	var bubble := _make_alipay_tutorial_bubble(text, bubble_size)
	overlay.add_child(bubble)
	var pos := anchor_rect.position
	match side:
		"left":
			pos.x = anchor_rect.position.x - bubble_size.x - 10
			pos.y = anchor_rect.position.y + anchor_rect.size.y * 0.5 - bubble_size.y * 0.5
		"right":
			pos.x = anchor_rect.position.x + anchor_rect.size.x + 10
			pos.y = anchor_rect.position.y + anchor_rect.size.y * 0.5 - bubble_size.y * 0.5
		"above":
			pos.x = anchor_rect.position.x + anchor_rect.size.x * 0.5 - bubble_size.x * 0.5
			pos.y = anchor_rect.position.y - bubble_size.y - 10
		_:
			pos.x = anchor_rect.position.x + anchor_rect.size.x * 0.5 - bubble_size.x * 0.5
			pos.y = anchor_rect.position.y + anchor_rect.size.y + 10
	bubble.position = _clamp_alipay_tutorial_pos(pos + bubble_offset, bubble_size, overlay.size)
	bubble.size = bubble_size


func _fit_alipay_tutorial_anchor_rect(rect: Rect2) -> Rect2:
	var fitted_size := Vector2(
		clampf(rect.size.x, 44.0, 330.0),
		clampf(rect.size.y, 24.0, 76.0)
	)
	return Rect2(rect.position, fitted_size)


func _add_alipay_tutorial_frame(overlay: Control, local_rect: Rect2) -> void:
	var frame := Panel.new()
	frame.name = "AlipayTutorialFocus"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = local_rect.position - Vector2(6, 6)
	frame.size = local_rect.size + Vector2(12, 12)
	frame.z_index = 1
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.86, 0.28, 0.0)
	style.border_color = Color(1, 0.78, 0.18, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(1, 0.72, 0.16, 0.35)
	style.shadow_size = 10
	style.shadow_offset = Vector2.ZERO
	frame.add_theme_stylebox_override("panel", style)
	overlay.add_child(frame)


func _make_alipay_tutorial_bubble(text: String, bubble_size: Vector2) -> Panel:
	var bubble := Panel.new()
	bubble.name = "AlipayTutorialBubble"
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.custom_minimum_size = Vector2.ZERO
	bubble.size = bubble_size
	bubble.z_index = 2
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.12, 0.16, 0.94)
	style.border_color = Color(0.52, 0.88, 1.0, 0.90)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 2)
	bubble.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.position = Vector2(10, 7)
	label.size = bubble_size - Vector2(20, 14)
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1))
	bubble.add_child(label)
	return bubble


func _clamp_alipay_tutorial_pos(pos: Vector2, bubble_size: Vector2, overlay_size: Vector2) -> Vector2:
	var max_x := maxf(8.0, overlay_size.x - bubble_size.x - 8.0)
	var max_y := maxf(8.0, overlay_size.y - bubble_size.y - 8.0)
	return Vector2(clampf(pos.x, 8.0, max_x), clampf(pos.y, 8.0, max_y))


func _show_tutorial_dialog(pages: Array) -> void:
	if is_instance_valid(left_dialog_box):
		left_dialog_box.z_index = 220
	show_galgame_dialog(pages)
	_hide_phone_dim_overlay()


func _hide_phone_dim_overlay() -> void:
	if galgame and galgame.has_method("_hide_phone_dim"):
		galgame.call("_hide_phone_dim")
	if is_instance_valid(_phone_dim):
		_phone_dim.visible = false
		_phone_dim.modulate.a = 1.0
		_phone_dim.color.a = 0.0


func _start_tutorial_flash(nodes: Array) -> void:
	_stop_tutorial_flash(false)
	for node in nodes:
		if not is_instance_valid(node):
			continue
		_tutorial_flash_targets.append(node)
		node.modulate = Color(1, 1, 1, 1)
		var tween := create_tween().set_loops(6)
		tween.tween_property(node, "modulate", Color(1.0, 0.88, 0.30, 1.0), 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(node, "modulate", Color(1, 1, 1, 1), 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tutorial_flash_tweens.append(tween)


func _stop_tutorial_flash(restore: bool = true) -> void:
	for tween in _tutorial_flash_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_tutorial_flash_tweens.clear()
	if restore:
		for node in _tutorial_flash_targets:
			if is_instance_valid(node):
				node.modulate = Color(1, 1, 1, 1)
	_tutorial_flash_targets.clear()


func on_alipay_closed() -> void:
	_clear_alipay_tutorial_callouts()
	_stop_tutorial_flash()
	if _first_week_app_gate != "alipay":
		return
	_first_week_app_gate = "map"
	_sync_phone_home_apps(true)
	_refresh_first_week_app_focus()


func _finish_first_week_app_tutorial() -> void:
	_first_week_app_gate = ""
	_first_week_app_tutorial_done = true
	_clear_alipay_tutorial_callouts()
	_stop_phone_focus_pulse()
	_sync_phone_home_apps(true)


func on_first_week_location_finished(location: String) -> void:
	if location != "overtime":
		return
	if not _is_first_week_app_tutorial_context():
		return
	if _first_week_overtime_tutorial_done:
		return
	_first_week_overtime_tutorial_done = true
	_first_week_app_gate = "wechat"
	_sync_phone_home_apps(true)
	_refresh_first_week_app_focus()
	_show_tutorial_dialog([
		"加班回来了，钱是多了一点，情绪也是真的掉了。",
		"先打开[color=6BB7FF]微信[/color]看看吧。家人和朋友的信息，也别完全错过。",
	])


func on_wechat_closed() -> void:
	if _first_week_app_gate != "wechat":
		return
	if not _is_first_week_app_tutorial_context():
		return
	if _first_week_wechat_tutorial_done:
		return
	_first_week_wechat_tutorial_done = true
	_first_week_beach_unlocked = true
	_first_week_app_gate = ""
	_stop_phone_focus_pulse()
	_sync_phone_home_apps(true)
	_show_first_week_stats_tutorial()


func is_first_week_beach_route_unlocked() -> bool:
	return _is_first_week_app_tutorial_context() and _first_week_beach_unlocked


func should_pulse_first_week_park_card() -> bool:
	return is_first_week_beach_route_unlocked() and _first_week_app_gate == "map_beach"


func _show_first_week_stats_tutorial() -> void:
	_start_stats_panel_focus_flash()
	if is_instance_valid(left_dialog_box):
		left_dialog_box.z_index = 220
	_hide_phone_dim_overlay()
	galgame.show_galgame_dialog([
		"加班回来，情绪很不好。点开地图，去海边散散心可能是个不错的选择。",
		"[color=6BB7FF]（加班会减少情绪值，请注意自己的情绪，数值过低会导致严重的后果。）[/color]",
		"[color=6BB7FF]（在这个快节奏的城市里，记得好好照顾自己的心理健康。）[/color]",
		"[color=6BB7FF]（关于自己的所有属性数值，可以在右侧手机的数值面板中看到。手机里正在发光的那个框框就是。）[/color]",
		"都了解的话，可以出发去海边散心啦。",
	], func() -> void:
		_first_week_app_gate = "map_beach"
		_sync_phone_home_apps(true)
		_refresh_first_week_app_focus()
	)


func _start_stats_panel_focus_flash() -> void:
	if _stats_panel_focus_tween and _stats_panel_focus_tween.is_valid():
		_stats_panel_focus_tween.kill()
	_stats_panel_focus_tween = null
	if is_instance_valid(_stats_panel_focus_halo):
		_stats_panel_focus_halo.queue_free()
	_stats_panel_focus_halo = null
	var target := find_child("Widget_Profile", true, false) as Control
	if not is_instance_valid(target):
		target = find_child("StatsGrid", true, false) as Control
	var phone_screen := find_child("PhoneScreen", true, false) as Control
	if not is_instance_valid(target) or not is_instance_valid(phone_screen):
		return
	var halo := Panel.new()
	halo.name = "StatsPanelTutorialHalo"
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.z_index = 210
	var local_pos := phone_screen.get_global_transform().affine_inverse() * target.get_global_rect().position
	halo.position = local_pos - Vector2(8, 8)
	halo.size = target.size + Vector2(16, 16)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.35, 0.55, 0.0)
	style.border_color = Color(0.42, 0.76, 1.0, 0.92)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.25, 0.65, 1.0, 0.55)
	style.shadow_size = 8
	style.shadow_offset = Vector2.ZERO
	halo.add_theme_stylebox_override("panel", style)
	halo.modulate.a = 0.0
	phone_screen.add_child(halo)
	_stats_panel_focus_halo = halo
	var tween := create_tween().bind_node(halo)
	for i in range(2):
		tween.tween_property(halo, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(style, "shadow_size", 22, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(halo, "modulate:a", 0.18, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(style, "shadow_size", 8, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(halo, "modulate:a", 0.0, 0.20)
	tween.tween_callback(func() -> void:
		if is_instance_valid(halo):
			halo.queue_free()
		if _stats_panel_focus_halo == halo:
			_stats_panel_focus_halo = null
	)
	_stats_panel_focus_tween = tween


func _process(_delta: float) -> void:
	if ui_state and ui_state.has_method("sync_all"):
		ui_state.sync_all()
	_repair_next_week_button_state()
	_update_phone_focus_breathing()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_close_top_popup()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if wechat and wechat.has_method("handle_chat_mouse_shortcut") and wechat.handle_chat_mouse_shortcut(event.global_position):
				get_viewport().set_input_as_handled()
				return
			# 左侧对话框点击：统一交给 GalgameSystem 推进，避免结算/事件回调丢失
			if left_dialog_box.get_global_rect().has_point(event.global_position) and _advance_left_dialog_input(false):
				get_viewport().set_input_as_handled()
	# Space键：翻页对话 / Ctrl键：跳过所有
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			if _debug_panel and _debug_panel.has_method("_toggle_visible"):
				_debug_panel._toggle_visible()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F2:
			if current_phase == Phase.TRANSITION and galgame.is_visible():
				galgame.skip_all()
				get_viewport().set_input_as_handled()
			elif current_phase == Phase.TRANSITION:
				_enter_weekend()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE:
			if _advance_left_dialog_input(false):
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_CTRL:
			if _advance_left_dialog_input(true):
				get_viewport().set_input_as_handled()

func _on_left_dialog_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _advance_left_dialog_input(false):
			get_viewport().set_input_as_handled()


func _advance_left_dialog_input(skip_all: bool) -> bool:
	if not is_instance_valid(left_dialog_box) or not left_dialog_box.visible or left_dialog_box.modulate.a <= 0.5:
		return false
	if not galgame:
		return false
	if galgame.has_method("is_visible") and galgame.is_visible():
		if is_instance_valid(galgame._gal_choice_container) and galgame._gal_choice_container.visible:
			return false
		if galgame._gal_pages.size() > 0:
			if skip_all:
				galgame.skip_all()
			else:
				galgame.gal_on_click()
			return true
		galgame.dismiss_dialog()
		return true
	galgame.dismiss_dialog()
	return true

## 右键返回：按优先级关闭当前最上层弹窗
func _close_top_popup() -> void:
	if payment_popup.visible:
		set_ui_layer_visible(payment_popup, false)
		return
	if alipay_popup.visible:
		if alipay and alipay.has_method("_on_close_alipay"):
			alipay._on_close_alipay()
		else:
			set_ui_layer_visible(alipay_popup, false)
		return
	if diary_popup.visible:
		set_ui_layer_visible(diary_popup, false)
		return
	if baotao_menu.visible:
		set_ui_layer_visible(baotao_menu, false)
		return
	if tuanmei_menu.visible:
		set_ui_layer_visible(tuanmei_menu, false)
		return
	if house_menu.visible:
		set_ui_layer_visible(house_menu, false)
		return
	if dating_popup.visible:
		set_ui_layer_visible(dating_popup, false)
		return
	if job_menu.visible:
		set_ui_layer_visible(job_menu, false)
		return
	if zodiac_popup.visible:
		set_ui_layer_visible(zodiac_popup, false)
		return
	if wechat.is_visible():
		if wc_chat_view.visible:
			wechat._on_chat_back()
			return
		set_ui_layer_visible(wechat_menu, false)
		return
	if location_menu.visible:
		set_ui_layer_visible(location_menu, false)
		return
	if late_night_popup.visible:
		show_message("先做出选择。", true)
		return


func _setup_foundation_services() -> void:
	environment = _new_refcounted_script("res://scripts/EnvironmentController.gd")
	environment.init(self)
	action_service = _new_refcounted_script("res://scripts/ActionService.gd")
	action_service.init(self)
	ui_state = _new_refcounted_script("res://scripts/UIStateManager.gd")
	ui_state.init(self)


func set_ui_layer_visible(layer: Control, value: bool, exclusive: bool = true) -> void:
	if not is_instance_valid(layer):
		return
	if ui_state and ui_state.has_method("show_layer"):
		if value:
			ui_state.show_layer(layer, exclusive)
		else:
			ui_state.hide_layer(layer)
	else:
		layer.visible = value


func sync_ui_state() -> void:
	if ui_state and ui_state.has_method("sync_all"):
		ui_state.sync_all()


func _force_clear_dialog_overlay() -> void:
	if galgame and galgame.has_method("force_clear_dialog"):
		galgame.force_clear_dialog()
	if is_instance_valid(left_dialog_text):
		left_dialog_text.text = ""
		left_dialog_text.visible = true
	if is_instance_valid(left_dialog_box):
		left_dialog_box.modulate.a = 0.0
		left_dialog_box.visible = false
	if is_instance_valid(_phone_dim):
		_phone_dim.visible = false
		_phone_dim.modulate.a = 1.0
		_phone_dim.color.a = 0.0
	sync_ui_state()


func has_blocking_dialog() -> bool:
	if galgame and galgame.has_method("is_visible") and galgame.is_visible():
		return true
	if is_instance_valid(left_dialog_box) and left_dialog_box.visible and left_dialog_box.modulate.a > 0.05:
		return true
	return false


func can_open_phone_app() -> bool:
	return current_phase == Phase.WEEKEND and not has_blocking_dialog()


func _repair_next_week_button_state() -> void:
	if current_phase != Phase.WEEKEND:
		return
	if not is_instance_valid(btn_next_week) or not btn_next_week.visible:
		return
	if has_blocking_dialog() or _has_active_blocking_layer():
		return
	_sync_phone_home_apps(true)
	btn_next_week.disabled = false


func _has_active_blocking_layer() -> bool:
	var layer_names := [
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
		"WeekdayPanel",
		"EventPopup",
		"MonthEndPopup",
		"TransitionScreen",
		"EndingPanel",
		"WeekConfirmOverlay",
		"FamilyEventOverlay",
		"FamilyChatOverlay",
		"GraduationOverlay",
		"EndingChoiceOverlay",
		"GameOverOverlay",
	]
	for layer_name in layer_names:
		var layer := find_child(layer_name, true, false)
		if layer is Control and layer.visible and layer.is_visible_in_tree():
			return true
	return false


func show_location_bg(texture_path: String, context: String = "location") -> void:
	if environment and environment.has_method("show_location"):
		environment.show_location(texture_path, context)


func return_to_home_environment(reason: String = "") -> void:
	if environment and environment.has_method("clear_to_home"):
		environment.clear_to_home(reason)



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


func format_stat_result(changes: Dictionary, title: String = "【结算】") -> String:
	var parts: Array = []
	var extra_names := {
		"affection": "好感",
		"family_affection": "亲情",
		"max_energy": "精力上限",
		"pending_salary": "待发工资",
		"monthly_food_cost": "餐饮账单",
		"night_school_progress": "夜校学分",
		"degree": "学历",
		"job_level": "职位",
	}
	var bad_when_increased := ["monthly_food_cost", "credit_debt", "huabei_debt", "huabei_installment_debt"]
	for stat_name in changes:
		var val: int = int(changes[stat_name])
		if val == 0:
			continue
		var cn_name: String = GameManager.stat_names.get(stat_name, extra_names.get(stat_name, stat_name))
		var is_bad_increase: bool = bad_when_increased.has(str(stat_name))
		if val > 0:
			var color := "E88080" if is_bad_increase else "90EE90"
			parts.append("[color=%s]%s +%d[/color]" % [color, cn_name, val])
		else:
			var color := "90EE90" if is_bad_increase else "E88080"
			parts.append("[color=%s]%s %d[/color]" % [color, cn_name, val])
	if parts.is_empty():
		return ""
	return title + "\n" + "  ".join(parts)


func show_result_text(text: String, on_complete: Callable = Callable()) -> void:
	var clean_text := text.strip_edges()
	if clean_text == "":
		if on_complete.is_valid():
			on_complete.call()
		return
	if not galgame:
		if on_complete.is_valid():
			on_complete.call()
		return
	galgame.call_deferred("show_galgame_dialog", [clean_text], on_complete)


func show_stat_result(changes: Dictionary, on_complete: Callable = Callable(), title: String = "【结算】") -> void:
	show_result_text(format_stat_result(changes, title), on_complete)

func _start_wechat_request_phase() -> void:
	galgame.start_wechat_request_phase()


# ==================== 阶段状态机 ====================

func _enter_weekday() -> void:
	current_phase = Phase.WEEKDAY
	return_to_home_environment("weekday")
	btn_next_week.visible = false
	_hide_all_popups()
	_disable_app_grid()
	GameManager.check_auto_unlock_npcs()
	# 动态更新工作按钮薪资显示
	btn_work_normal.text = "正常打卡 (精力-30, 情绪-15, 待发工资+%d)" % _get_salary("normal")
	btn_work_slack.text = "摸鱼混日子 (精力-10, 情绪+5, 待发工资+%d)" % _get_salary("slack")
	btn_work_overtime.text = "疯狂自愿加班 (精力-60, 情绪-30, 待发工资+%d)" % _get_salary("overtime")
	weekday_panel.visible = true
	btn_food_low.disabled = false
	btn_food_mid.disabled = false
	btn_food_high.disabled = false
	btn_work_normal.disabled = true
	btn_work_slack.disabled = true
	btn_work_overtime.disabled = true
	_refresh_ui()
	sync_ui_state()


func _enter_weekend() -> void:
	current_phase = Phase.WEEKEND
	weekday_panel.visible = false
	return_to_home_environment("weekend")
	btn_next_week.visible = true
	_enable_app_grid()
	_update_weekend_ui()
	_refresh_ui()
	sync_ui_state()
	btn_next_week.disabled = false
	_maybe_start_first_week_app_tutorial()


func _update_weekend_ui() -> void:
	var preview := _get_month_end_preview()
	btn_next_week.text = "⏭ 结束本周｜月底:%d" % [
		int(preview.get("cash_after_all", 0)),
	]
	btn_next_week.tooltip_text = _build_week_confirm_text()
	_sync_phone_home_apps(true)


func _enable_app_grid() -> void:
	_sync_phone_home_apps(true)
	_refresh_action_tooltips()
	# 检查新解锁的APP并通知
	var new_unlocks := GameManager.get_new_unlocks()
	if new_unlocks.size() > 0:
		galgame.show_message("手机上新装了一个APP...\n" + new_unlocks[0], true)


func _sync_phone_home_apps(interactable: bool) -> void:
	_set_phone_app_state(btn_app_map, "map", interactable)
	_set_phone_app_state(btn_app_wechat, "wechat", interactable)
	_set_phone_app_state(btn_app_alipay, "", interactable)
	_set_phone_app_state(btn_app_diary, "diary", interactable)
	_set_phone_app_state(btn_app_job, "job", interactable)
	_set_phone_app_state(btn_app_baotao, "baotao", interactable)
	_set_phone_app_state(btn_app_dating, "dating", interactable)
	_set_phone_app_state(btn_app_tuanmei, "tuanmei", interactable)
	_set_phone_app_state(btn_app_zodiac, "zodiac", interactable)
	_set_phone_app_state(btn_app_house, "house", interactable)
	if interactable:
		_refresh_first_week_app_focus()


func _set_phone_app_state(button: Button, app_id: String, interactable: bool) -> void:
	if not is_instance_valid(button):
		return
	if not button.has_meta("phone_app_base_text"):
		button.set_meta("phone_app_base_text", button.text)
	var unlocked := app_id == "" or GameManager.is_app_unlocked(app_id)
	if not unlocked:
		button.visible = false
		button.disabled = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.text = str(button.get_meta("phone_app_base_text"))
		return
	button.visible = true
	button.disabled = not interactable
	button.mouse_filter = Control.MOUSE_FILTER_STOP if interactable else Control.MOUSE_FILTER_IGNORE
	button.text = str(button.get_meta("phone_app_base_text"))
	if button != _phone_focus_button:
		button.modulate = Color(1, 1, 1, 1) if interactable else Color(1, 1, 1, 0.48)


func _show_opening_intro() -> void:
	if GameManager.skip_opening_intro_once:
		GameManager.skip_opening_intro_once = false
		_enter_weekend()
		return
	if current_phase == Phase.WEEKEND:
		return
	current_phase = Phase.TRANSITION
	_hide_all_popups()
	_disable_app_grid()
	weekday_panel.visible = false
	btn_next_week.visible = false
	var opening_pages: Array = [
		"墙皮又掉了一块。",
		"深圳三月的回南天黏在被子上，也黏在账单上。",
		"我坐在城中村的单人床上，盯着花呗页面。红色数字跳了一下：[b][color=FFD700]2876.32[/color][/b]。",
		"这不是很多钱。问题是它刚好堵在房租、吃饭和发工资中间。",
		"我把手机扣在床上，躺了十秒，又坐起来。",
		"一直盯着它不会让它变少。",
		"先看[color=FFD700]支付宝[/color]，弄清月底到底差几口气。再打开[color=FFD700]高德地图[/color]，找个能把这口气接上的地方。",
		"这个月的目标很简单：别被第一张账单给劝退回老家。",
	]
	galgame.show_galgame_dialog(opening_pages, func() -> void:
		_enter_weekend()
	)


func _disable_app_grid() -> void:
	_sync_phone_home_apps(false)
	_refresh_action_tooltips()


func _hide_all_popups() -> void:
	_clear_alipay_tutorial_callouts()
	set_ui_layer_visible(baotao_menu, false)
	set_ui_layer_visible(tuanmei_menu, false)
	set_ui_layer_visible(zodiac_popup, false)
	set_ui_layer_visible(location_menu, false)
	set_ui_layer_visible(house_menu, false)
	set_ui_layer_visible(dating_popup, false)
	wechat.force_close()
	set_ui_layer_visible(alipay_popup, false)
	set_ui_layer_visible(diary_popup, false)
	set_ui_layer_visible(job_menu, false)
	set_ui_layer_visible(payment_popup, false)
	sync_ui_state()


func _show_event(event: Dictionary, after_callback: Callable) -> void:
	current_phase = Phase.EVENT
	var desc: String = event["desc"]
	var stat_changes: Dictionary = {}
	for key in event:
		if key == "desc":
			continue
		stat_changes[key] = int(event[key])
	var pages: Array = [desc]
	var finish_event := func() -> void:
		for key in stat_changes:
			GameManager.modify_stat(str(key), int(stat_changes[key]))
		if after_callback.is_valid():
			after_callback.call()
		elif current_phase == Phase.EVENT:
			current_phase = Phase.WEEKEND
			sync_ui_state()
	galgame.show_galgame_dialog(pages, func() -> void:
		if stat_changes.is_empty():
			finish_event.call()
		else:
			show_stat_result(stat_changes, finish_event)
	)



# ==================== UI 刷新 ====================

func _refresh_ui() -> void:
	label_week.text = "%d岁  %d月第%d周" % [GameManager.age, GameManager.month, GameManager.week_in_month]
	label_money.text = str(GameManager.money)
	label_psalary.text = str(GameManager.pending_salary)
	var display_name := GameManager.player_name if GameManager.player_name != "" else "未命名"
	var zodiac_name := GameManager.player_zodiac if GameManager.player_zodiac != "" else "未定星座"
	label_player_info.text = "%s · %s" % [display_name, zodiac_name]
	_update_finance_widgets()
	_refresh_action_tooltips()
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


func _setup_finance_widgets() -> void:
	var parent := label_player_info.get_parent()
	if not parent:
		return
	label_player_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label_player_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_player_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_player_info.add_theme_font_size_override("font_size", 11)
	label_player_info.add_theme_color_override("font_color", Color(0.62, 0.70, 0.78, 1))
	if label_week:
		label_week.add_theme_font_size_override("font_size", 12)
		label_week.add_theme_color_override("font_color", Color(0.82, 0.90, 0.96, 1))

	var profile_area := parent.get_parent() as HBoxContainer
	if is_instance_valid(profile_area):
		var avatar := profile_area.get_node_or_null("PlayerAvatar") as ColorRect
		if is_instance_valid(avatar):
			avatar.visible = false

	label_pressure_summary = parent.get_node_or_null("LabelPressureSummary") as Label
	if label_pressure_summary == null:
		label_pressure_summary = Label.new()
		label_pressure_summary.name = "LabelPressureSummary"
		parent.add_child(label_pressure_summary)
	label_pressure_summary.add_theme_font_size_override("font_size", 11)
	label_pressure_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_pressure_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	label_pressure_hint = parent.get_node_or_null("LabelPressureHint") as Label
	if label_pressure_hint == null:
		label_pressure_hint = Label.new()
		label_pressure_hint.name = "LabelPressureHint"
		parent.add_child(label_pressure_hint)
	label_pressure_hint.add_theme_font_size_override("font_size", 11)
	label_pressure_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_pressure_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	label_early_goal = parent.get_node_or_null("LabelEarlyGoal") as Label
	if label_early_goal == null:
		label_early_goal = Label.new()
		label_early_goal.name = "LabelEarlyGoal"
		parent.add_child(label_early_goal)
	label_early_goal.add_theme_font_size_override("font_size", 11)
	label_early_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_early_goal.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	parent.move_child(label_early_goal, mini(label_player_info.get_index() + 1, parent.get_child_count() - 1))
	parent.move_child(label_pressure_summary, mini(label_early_goal.get_index() + 1, parent.get_child_count() - 1))
	parent.move_child(label_pressure_hint, mini(label_pressure_summary.get_index() + 1, parent.get_child_count() - 1))


func _update_finance_widgets() -> void:
	if not label_pressure_summary or not label_pressure_hint:
		return
	var preview := _get_month_end_preview()
	var pressure := _get_pressure_state(preview)
	var debt_total: int = GameManager.huabei_debt + GameManager.huabei_installment_debt
	var cash_after: int = int(preview.get("cash_after_all", 0))
	var mandatory_cost: int = int(preview.get("mandatory_cost", 0))
	label_pressure_summary.text = "财务｜%s  月底 %d  账单 %d  债 %d" % [
		str(pressure.get("name", "未知")),
		cash_after,
		mandatory_cost,
		debt_total,
	]
	label_pressure_summary.add_theme_color_override("font_color", pressure.get("color", Color(0.8, 0.8, 0.8)))
	var job_names := ["初级行政", "新媒体运营", "大客户经理"]
	var degree_names := ["大专", "成人本科"]
	var job_name: String = job_names[clampi(GameManager.job_level, 0, job_names.size() - 1)]
	var degree_name: String = degree_names[clampi(GameManager.degree, 0, degree_names.size() - 1)]
	var growth_text := "成长:%s/%s | 夜校:%d/12" % [
		job_name,
		degree_name,
		GameManager.night_school_progress,
	]
	var pressure_hint := str(pressure.get("hint", ""))
	label_pressure_hint.text = "%s\n%s" % [growth_text, pressure_hint] if pressure_hint != "" else growth_text
	label_pressure_hint.add_theme_color_override("font_color", pressure.get("hint_color", Color(0.62, 0.66, 0.72)))
	if label_early_goal:
		var story_goal := _get_current_story_goal_text(preview, pressure)
		label_early_goal.text = story_goal
		label_early_goal.visible = story_goal != ""
		label_early_goal.add_theme_color_override("font_color", Color(0.90, 0.78, 0.42))


func _format_home_goal_text(text: String) -> String:
	var clean := text.strip_edges()
	if clean.begins_with("目标："):
		clean = clean.substr("目标：".length()).strip_edges()
	if clean == "":
		return ""
	return "下一步｜" + clean


func _get_current_story_goal_text(preview: Dictionary, pressure: Dictionary) -> String:
	if GameManager.month <= 1:
		return "主线｜活过第一张账单\n本周｜%s" % _get_first_month_week_goal(preview)
	var current_goal := _get_current_goal_hint(preview, pressure)
	return _format_home_goal_text(str(current_goal.get("text", "")))


func _get_first_month_week_goal(preview: Dictionary) -> String:
	var cash_after := int(preview.get("cash_after_all", 0))
	if bool(preview.get("game_over_predicted", false)) or bool(preview.get("min_payment_failed", false)) or cash_after < 0:
		return "账单会压穿现金。先停消费，去支付宝确认缺口，再用加班或低成本行动补救。"
	match GameManager.week_in_month:
		1:
			return "先看支付宝，把月底缺口看清楚。再去公司加班，先止血。"
		2:
			return "身体开始报警。去深圳湾、夜市或回出租屋，把自己捡回来。"
		3:
			return "不能只靠硬扛。图书馆、咖啡厅和健身房会决定下个月的路。"
		_:
			return "发薪日前夜。先查支付宝，再决定补现金还是补状态。"


func _get_current_goal_hint(preview: Dictionary, _pressure: Dictionary) -> Dictionary:
	var cash_after := int(preview.get("cash_after_all", 0))
	if bool(preview.get("game_over_predicted", false)) or bool(preview.get("min_payment_failed", false)) or cash_after < 0:
		return {
			"text": "目标：先保现金流。停止新增花呗，优先工作、还款或降支出。",
			"color": Color(1.0, 0.42, 0.34),
		}
	match current_phase:
		Phase.WEEKDAY:
			if is_instance_valid(btn_work_normal) and not btn_work_normal.disabled:
				return {
					"text": "目标：选择工作态度。加班救现金，摸鱼保状态。",
					"color": Color(0.72, 0.82, 1.0),
				}
			return {
				"text": "目标：先定餐饮预算，再安排工作。餐饮会进月底账单。",
				"color": Color(0.72, 0.82, 1.0),
			}
		Phase.WEEKEND:
			return {
				"text": _get_weekend_goal_text(preview),
				"color": Color(0.70, 0.92, 0.78),
			}
		Phase.MONTH_END:
			return {
				"text": "目标：确认月底账单，重点看房租、餐饮、花呗和结算后现金。",
				"color": Color(0.94, 0.82, 0.48),
			}
		Phase.EVENT:
			return {
				"text": "目标：看完事件和结算，再决定下一步。",
				"color": Color(0.72, 0.82, 1.0),
			}
		Phase.TRANSITION:
			return {
				"text": "目标：等待场景切换完成。",
				"color": Color(0.62, 0.66, 0.72),
			}
		_:
			return {
				"text": "",
				"color": Color(0.62, 0.66, 0.72),
			}


func _get_weekend_goal_text(preview: Dictionary) -> String:
	if GameManager.month <= 1:
		match GameManager.week_in_month:
			1:
				return "目标：先查支付宝，再去公司加班补一口现金。"
			2:
				return "目标：别只硬扛。选一个恢复地点，把精力和情绪拉回来。"
			3:
				return "目标：探索成长线。先变强，再谈换工作和关系。"
			_:
				return "目标：月底前查支付宝，确认该补现金还是补状态。"
	if GameManager.huabei_debt + GameManager.huabei_installment_debt > 0:
		return "目标：先看支付宝，决定还款、分期或停止新增消费。"
	if int(preview.get("cash_after_all", 0)) < 1000:
		return "目标：现金缓冲偏低，优先低成本行动和收入。"
	return "目标：精力耗尽前，安排成长行动或低成本社交。"


func _refresh_action_tooltips() -> void:
	btn_food_low.tooltip_text = "餐饮预算：本月餐饮+300，情绪-5。最省钱，但连续吃太差会有风险。"
	btn_food_mid.tooltip_text = "餐饮预算：本月餐饮+800，精力+10。比较稳的默认选择。"
	btn_food_high.tooltip_text = "餐饮预算：本月餐饮+2000，情绪+20，精力+15。舒服但会明显抬高月底账单。"
	btn_work_normal.tooltip_text = "工作态度：精力-30，情绪-15，待发工资+%d。稳定收入。" % _get_salary("normal")
	btn_work_slack.tooltip_text = "工作态度：精力-10，情绪+5，待发工资+%d。保状态，但收入低。" % _get_salary("slack")
	btn_work_overtime.tooltip_text = "工作态度：精力-60，情绪-30，待发工资+%d。短期救现金，连续加班有风险。" % _get_salary("overtime")
	_set_app_tooltip(btn_app_map, "map", "高德地图：周末地点行动。消耗精力，可能触发事件或邂逅。")
	_set_app_tooltip(btn_app_wechat, "wechat", "微信：查看消息、联系人和上课入口。部分关系会随事件解锁。")
	_set_app_tooltip(btn_app_alipay, "", "支付宝：查看现金、花呗、分期和月底预计。消费前先看这里。")
	_set_app_tooltip(btn_app_diary, "diary", "日记：查看活动流水和数值变化，适合复盘刚才发生了什么。")
	_set_app_tooltip(btn_app_baotao, "baotao", "宝淘：消费提升状态，但会增加花呗或现金压力。先看支付宝。")
	_set_app_tooltip(btn_app_tuanmei, "tuanmei", "团美：医美消费，高花费高收益，容易压垮月底现金。")
	_set_app_tooltip(btn_app_zodiac, "zodiac", "星座：查看星座影响和轻量运势。")
	_set_app_tooltip(btn_app_house, "house", "贝壳：更换居住环境，房租会进入月底账单。")
	_set_app_tooltip(btn_app_dating, "dating", "探探：社交探索，会消耗精力/情绪并影响关系。")
	_set_app_tooltip(btn_app_job, "job", "BOSS弯聘：查看职位门槛和面试机会。职位提升是长期收入线。")


func _set_app_tooltip(button: Button, app_id: String, unlocked_text: String) -> void:
	if not is_instance_valid(button):
		return
	if app_id == "" or GameManager.is_app_unlocked(app_id):
		button.tooltip_text = unlocked_text
	else:
		button.tooltip_text = GameManager.get_app_unlock_hint(app_id)


func _get_huabei_min_payment() -> int:
	if GameManager.huabei_debt <= 0:
		return 0
	return mini(int(GameManager.huabei_debt * 0.1 + 200), GameManager.huabei_debt)


func _get_installment_due() -> int:
	if GameManager.huabei_installment_months_left <= 0:
		return 0
	return GameManager.huabei_installment_monthly_pay


func _get_month_end_preview(salary_override: int = -1, rent_override: int = -1, food_override: int = -1) -> Dictionary:
	var salary := GameManager.pending_salary
	var rent := GameManager.base_rent
	var food := GameManager.monthly_food_cost
	if salary_override >= 0:
		salary = salary_override
	if rent_override >= 0:
		rent = rent_override
	if food_override >= 0:
		food = food_override

	var installment_due := _get_installment_due()
	var installment_debt_after := GameManager.huabei_installment_debt
	if installment_due > 0:
		var principal_this_month := int(float(installment_due) / 1.15)
		installment_debt_after = maxi(installment_debt_after - principal_this_month, 0)
		if GameManager.huabei_installment_months_left <= 1:
			installment_debt_after = 0

	var cash_after_fixed := GameManager.money + salary - rent - food - installment_due
	var cash_after_all := cash_after_fixed
	var huabei_min := _get_huabei_min_payment()
	var huabei_paid := 0
	var huabei_after_payment := GameManager.huabei_debt
	var min_payment_failed := false
	if huabei_after_payment > 0:
		if cash_after_all >= huabei_min:
			huabei_paid = huabei_min
			cash_after_all -= huabei_min
			huabei_after_payment -= huabei_min
		else:
			huabei_paid = maxi(cash_after_all, 0)
			huabei_after_payment = maxi(huabei_after_payment - huabei_paid, 0)
			cash_after_all -= huabei_paid
			min_payment_failed = true

	var huabei_interest := 0
	var huabei_after_interest := huabei_after_payment
	var min_payment_penalty := 0
	var negative_cash_penalty := 0
	var sanity_after_settlement := GameManager.sanity
	var game_over_predicted := false
	var game_over_reason := ""
	if min_payment_failed:
		min_payment_penalty = 50
		sanity_after_settlement -= min_payment_penalty
		if sanity_after_settlement <= 0:
			game_over_predicted = true
			game_over_reason = "花呗最低还款失败，情绪归零"
	if not game_over_predicted and huabei_after_interest > 0:
		var before_interest := huabei_after_interest
		huabei_after_interest = int(float(huabei_after_interest) * 1.05)
		huabei_interest = huabei_after_interest - before_interest
	if not game_over_predicted and cash_after_all < 0:
		negative_cash_penalty = 50
		sanity_after_settlement -= negative_cash_penalty
		if sanity_after_settlement <= 0:
			game_over_predicted = true
			game_over_reason = "现金为负触发破产压力，情绪归零"
	sanity_after_settlement = maxi(sanity_after_settlement, 0)

	var mandatory_cost := rent + food + installment_due + huabei_min
	var actual_cash_cost := rent + food + installment_due + huabei_paid
	return {
		"current_cash": GameManager.money,
		"salary": salary,
		"rent": rent,
		"food": food,
		"installment_due": installment_due,
		"installment_months_left": GameManager.huabei_installment_months_left,
		"installment_debt_after": installment_debt_after,
		"huabei_min": huabei_min,
		"huabei_paid": huabei_paid,
		"huabei_interest": huabei_interest,
		"huabei_after_interest": huabei_after_interest,
		"cash_after_fixed": cash_after_fixed,
		"cash_after_all": cash_after_all,
		"mandatory_cost": mandatory_cost,
		"actual_cash_cost": actual_cash_cost,
		"min_payment_failed": min_payment_failed,
		"min_payment_penalty": min_payment_penalty,
		"negative_cash_penalty": negative_cash_penalty,
		"sanity_before_settlement": GameManager.sanity,
		"sanity_after_settlement": sanity_after_settlement,
		"game_over_predicted": game_over_predicted,
		"game_over_reason": game_over_reason,
		"total_debt_after": huabei_after_interest + installment_debt_after,
	}


func _get_pressure_state(preview: Dictionary) -> Dictionary:
	var cash_after := int(preview.get("cash_after_all", 0))
	var debt_total: int = GameManager.huabei_debt + GameManager.huabei_installment_debt
	var min_failed := bool(preview.get("min_payment_failed", false))
	var food := int(preview.get("food", 0))
	var salary := int(preview.get("salary", 0))

	if min_failed or cash_after < 0:
		return {
			"name": "危险",
			"color": Color(1.0, 0.26, 0.22),
			"hint": "月底现金会穿底；继续消费会触发还款/破产压力。",
			"hint_color": Color(1.0, 0.48, 0.38),
		}
	if cash_after < 1000:
		return {
			"name": "紧绷",
			"color": Color(1.0, 0.66, 0.20),
			"hint": "月底只剩一点缓冲，建议优先工作或减少花呗消费。",
			"hint_color": Color(1.0, 0.78, 0.35),
		}
	if debt_total > 0 or (salary > 0 and food > int(float(salary) * 0.45)):
		return {
			"name": "承压",
			"color": Color(0.98, 0.86, 0.32),
			"hint": "账单还可控，但债务/餐饮正在吃掉工资空间。",
			"hint_color": Color(0.86, 0.78, 0.42),
		}
	return {
		"name": "稳定",
		"color": Color(0.42, 0.95, 0.55),
		"hint": "现金流暂时安全，可以考虑成长行动而不是纯消费。",
		"hint_color": Color(0.55, 0.86, 0.62),
	}


func _build_week_confirm_text() -> String:
	var preview := _get_month_end_preview()
	var pressure := _get_pressure_state(preview)
	var next_step := "月底账单结算" if GameManager.week_in_month >= 4 else "第%d周工作日" % (GameManager.week_in_month + 1)
	var lines: Array = []
	lines.append("下一步：%s" % next_step)
	lines.append("当前现金：%d | 待发工资：+%d" % [GameManager.money, int(preview.get("salary", 0))])
	lines.append("本月账单：房租-%d / 餐饮-%d / 花呗最低-%d / 分期-%d" % [
		int(preview.get("rent", 0)),
		int(preview.get("food", 0)),
		int(preview.get("huabei_min", 0)),
		int(preview.get("installment_due", 0)),
	])
	lines.append("月底预计现金：%d | 结算后总债：%d" % [
		int(preview.get("cash_after_all", 0)),
		int(preview.get("total_debt_after", 0)),
	])
	lines.append("压力状态：%s。%s" % [str(pressure.get("name", "未知")), str(pressure.get("hint", ""))])
	return "\n".join(lines)


func _get_month_end_story_summary(preview: Dictionary) -> String:
	if GameManager.month > 1:
		return ""
	var cash_after := int(preview.get("cash_after_all", 0))
	var total_debt_after := int(preview.get("total_debt_after", 0))
	var sanity_after := int(preview.get("sanity_after_settlement", GameManager.sanity))
	if bool(preview.get("game_over_predicted", false)):
		return "【第一月主线】账单没有给你留体面。不是你不努力，是这个月每一次透支都在这里排队。"
	if cash_after >= 1200 and sanity_after >= 45 and total_debt_after <= 4000:
		return "【第一月主线】你没有赢下深圳，但你稳住了第一张账单。下个月可以开始想：只是活着，还是往上走一点。"
	if cash_after >= 0:
		return "【第一月主线】账单清掉了，但你知道这不是胜利。压力只是被挪到下个月，身体和花呗都记着账。"
	return "【第一月主线】你撑到了月底，却被现金缺口卡住。现在最重要的不是体面，是立刻止血。"


func _build_month_end_bill_text(preview: Dictionary) -> String:
	var lines: Array = []
	var story_summary := _get_month_end_story_summary(preview)
	if story_summary != "":
		lines.append(story_summary)
		lines.append("")
	lines.append("【本月现金流】")
	lines.append("当前现金：%d" % int(preview.get("current_cash", 0)))
	lines.append("本月工资：+%d" % int(preview.get("salary", 0)))
	lines.append("")
	lines.append("【固定扣款】")
	lines.append("房租：-%d" % int(preview.get("rent", 0)))
	var food_cost: int = int(preview.get("food", 0))
	lines.append("餐饮账单：-%d" % food_cost if food_cost > 0 else "餐饮账单：0")
	if int(preview.get("installment_due", 0)) > 0:
		lines.append("花呗分期：-%d（当前剩余 %d 期）" % [
			int(preview.get("installment_due", 0)),
			int(preview.get("installment_months_left", 0)),
		])
	if int(preview.get("huabei_min", 0)) > 0:
		if int(preview.get("huabei_paid", 0)) < int(preview.get("huabei_min", 0)):
			var huabei_paid: int = int(preview.get("huabei_paid", 0))
			var huabei_paid_text: String = "-%d" % huabei_paid if huabei_paid > 0 else "0"
			lines.append("花呗最低应还：-%d（预计实还：%s）" % [
				int(preview.get("huabei_min", 0)),
				huabei_paid_text,
			])
		else:
			lines.append("花呗最低还款：-%d" % int(preview.get("huabei_min", 0)))
	lines.append("")
	lines.append("【结算预估】")
	lines.append("应付账单合计：-%d" % int(preview.get("mandatory_cost", 0)))
	lines.append("预计实际扣款：-%d" % int(preview.get("actual_cash_cost", 0)))
	lines.append("结算后现金：%d" % int(preview.get("cash_after_all", 0)))
	if int(preview.get("huabei_interest", 0)) > 0:
		lines.append("未还花呗滚入利息：+%d" % int(preview.get("huabei_interest", 0)))
	lines.append("结算后总债务：%d" % int(preview.get("total_debt_after", 0)))
	if GameManager.invest_safe + GameManager.invest_risk > 0:
		lines.append("理财资产不自动变现：%d" % (GameManager.invest_safe + GameManager.invest_risk))
	var sanity_penalty: int = int(preview.get("min_payment_penalty", 0)) + int(preview.get("negative_cash_penalty", 0))
	if sanity_penalty > 0:
		lines.append("")
		lines.append("【情绪压力】")
		if int(preview.get("min_payment_penalty", 0)) > 0:
			lines.append("最低还款失败：情绪-%d" % int(preview.get("min_payment_penalty", 0)))
		if int(preview.get("negative_cash_penalty", 0)) > 0:
			lines.append("现金为负：情绪-%d" % int(preview.get("negative_cash_penalty", 0)))
		lines.append("预计情绪：%d -> %d" % [
			int(preview.get("sanity_before_settlement", GameManager.sanity)),
			int(preview.get("sanity_after_settlement", GameManager.sanity)),
		])
		if bool(preview.get("game_over_predicted", false)):
			lines.append("警告：确认结算后会直接进入 Game Over。")
			lines.append("原因：%s" % str(preview.get("game_over_reason", "情绪归零")))

	var pressure := _get_pressure_state(preview)
	lines.append("")
	lines.append("【风险提示】%s：%s" % [str(pressure.get("name", "未知")), str(pressure.get("hint", ""))])
	if bool(preview.get("min_payment_failed", false)):
		lines.append("注意：当前现金不足以覆盖花呗最低还款。")
	elif int(preview.get("cash_after_all", 0)) < 0:
		lines.append("注意：结算后现金为负，会进入破产压力判定。")
	return "\n".join(lines)


func _layout_month_end_bill(text: String) -> void:
	var line_count: int = text.split("\n").size()
	var content_height: float = clamp(float(line_count * 17 + 8), 220.0, 430.0)
	var panel_height: float = clamp(content_height + 210.0, 470.0, 660.0)
	var panel_width: float = 700.0
	var content_width: float = 620.0
	var panel_bg := month_end_popup.find_child("MonthEndPanelBG", true, false) as ColorRect
	if panel_bg:
		panel_bg.offset_left = -panel_width * 0.5
		panel_bg.offset_right = panel_width * 0.5
		panel_bg.offset_top = -panel_height * 0.5
		panel_bg.offset_bottom = panel_height * 0.5
	var vbox := month_end_popup.find_child("MEVBox", true, false) as VBoxContainer
	if vbox:
		var vbox_height: float = panel_height - 70.0
		vbox.offset_left = -content_width * 0.5
		vbox.offset_right = content_width * 0.5
		vbox.offset_top = -vbox_height * 0.5
		vbox.offset_bottom = vbox_height * 0.5
	if is_instance_valid(label_me_content):
		label_me_content.custom_minimum_size = Vector2(content_width, content_height)
		label_me_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if is_instance_valid(btn_pay_rent):
		btn_pay_rent.custom_minimum_size = Vector2(360, 44)
		btn_pay_rent.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


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
	pass

func _on_week_advanced(_new_week: int) -> void:
	_refresh_ui()
	pass
	## 推送NPC未读消息
	_push_npc_unread_messages()
	pass


func _push_npc_unread_messages() -> void:
	if GameManager.month <= 1:
		return
	## 家庭群：未读未清空时不推新消息
	var _family_unread: int = GameManager.npcs.get("family_group", {}).get("unread", 0)
	if _family_unread <= 0 and GameManager.npcs.get("family_group", {}).get("unlocked", false):
		var should_push_event := false
		var event_idx: int = 0
		var available_family_events: Array = []
		for idx in range(wechat._family_events.size()):
			if idx not in GameManager._family_event_used_indices:
				available_family_events.append(idx)
		if GameManager.turn_count == 1 and not GameManager._family_event_used_indices.has(0):
			should_push_event = true
			event_idx = 0  ## 相亲局
		elif GameManager.turn_count == 5 and not GameManager._family_event_used_indices.has(1):
			should_push_event = true
			event_idx = 1  ## 冰箱
		elif available_family_events.size() > 0 and randi() % 100 < 70:
			should_push_event = true
			event_idx = available_family_events[randi() % available_family_events.size()]
		if should_push_event:
			var event_desc: String = wechat._family_events[event_idx]["desc"]
			var preview_line: String = event_desc.split("
")[0]
			if preview_line.length() > 20:
				preview_line = preview_line.substr(0, 20) + "..."
			GameManager.npcs["family_group"]["messages"].append({"sender": "npc", "text": preview_line, "event_idx": event_idx})
			GameManager._family_event_used_indices.append(event_idx)
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

	## 家庭群闲聊：未读未清空时不推新消息，第2周起每4周推送一条
	if _family_unread <= 0 and GameManager.turn_count >= 2 and (GameManager.turn_count - 2) % 4 == 0:
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
	var summary: Dictionary = GameManager.get_npc_contact_summary(_id)
	var relation: String = str(summary.get("relation", "新联系人"))
	var source_label: String = str(summary.get("source_label", "未知来源"))
	var source_detail: String = str(summary.get("source_detail", ""))
	var unlock_text := "【新联系人：%s】\n关系：%s\n来源：%s" % [npc_name, relation, source_label]
	if source_detail != "":
		unlock_text += "\n%s" % source_detail
	show_message(unlock_text, true)
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
	# 不立即显示，延迟到工作日结束后（消息存在 pending_aging_msg 里）
	pass

func _on_spring_festival(msg: String) -> void:
	show_urgent_message(msg)


func _on_spring_festival_boss(age: int) -> void:
	current_phase = Phase.EVENT
	_hide_all_popups()
	_disable_app_grid()
	btn_next_week.visible = false
	weekday_panel.visible = false
	spring_festival.start_boss_fight(age, _on_spring_festival_done)


func _on_spring_festival_done(total_sanity_cost: int, money_cost: int) -> void:
	GameManager.finish_spring_festival(total_sanity_cost, money_cost)
	if not GameManager.game_finished:
		_enter_weekday()
	pass


func _on_game_over(cause_title: String, cause_desc: String) -> void:
	current_phase = Phase.GAME_OVER
	GameManager.game_finished = true
	_disable_all()
	_force_clear_dialog_overlay()
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
		GameManager.reset_game()
		get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")
	)
	vbox.add_child(btn_restart)

func _on_game_ended(ending_type: String) -> void:
	current_phase = Phase.ENDING
	_disable_all()
	_force_clear_dialog_overlay()
	label_game_over.visible = false
	ending_panel.visible = false
	var ending: Dictionary = GameManager.last_ending
	if ending.is_empty():
		ending = GameManager.evaluate_ending()
	# 结局颜色映射
	var ending_colors: Dictionary = {
		"true_love": Color(1.0, 0.42, 0.42),
		"bankrupt": Color(0.6, 0.6, 0.6),
		"corporate_slave": Color(0.85, 0.65, 0.13),
		"influencer": Color(1.0, 0.56, 0.78),
		"scholar": Color(0.4, 0.69, 0.96),
		"elite": Color(1.0, 0.84, 0.0),
		"homecoming": Color(0.4, 0.87, 0.54),
		"ordinary": Color(0.7, 0.7, 0.7),
	}
	var accent: Color = ending_colors.get(ending_type, Color(1.0, 0.84, 0.0))
	# 创建全屏结局弹窗
	var overlay := ColorRect.new()
	overlay.name = "EndingOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.97)
	overlay.z_index = 100
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.04, 0.06, 1)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(36)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)
	# 终章标题
	var chapter_label := Label.new()
	chapter_label.text = "终  章"
	chapter_label.add_theme_font_size_override("font_size", 16)
	chapter_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(chapter_label)
	# 结局标题
	var title_label := Label.new()
	title_label.text = ending.get("title", "【结局】")
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", accent)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	# 分割线
	var sep1 := HSeparator.new()
	sep1.add_theme_stylebox_override("separator", _create_line_style(accent))
	vbox.add_child(sep1)
	# 结局内容
	var content_label := Label.new()
	content_label.text = ending.get("content", "")
	content_label.add_theme_font_size_override("font_size", 15)
	content_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(content_label)
	# 分割线
	var sep2 := HSeparator.new()
	vbox.add_child(sep2)
	# 终局统计
	var romance_info: String = ""
	for npc_id in GameManager.npcs:
		if npc_id == "family_group" or npc_id == "wang_teacher":
			continue
		if GameManager.npcs[npc_id].get("level", 1) >= 2:
			var nname: String = GameManager.npcs[npc_id].get("name", npc_id)
			var nlv: int = GameManager.npcs[npc_id].get("level", 1)
			romance_info += "%s(Lv.%d) " % [nname, nlv]
	var stats_text: String = (
		"终局统计
"
		+ "年龄：%d岁 | 金钱：%d | 花呗：%d
" % [
			GameManager.age,
			GameManager.money,
			GameManager.huabei_debt + GameManager.huabei_installment_debt,
		]
		+ "精力：%d/%d | 情绪：%d/%d
" % [
			GameManager.energy, GameManager.max_energy,
			GameManager.sanity, GameManager.max_sanity,
		]
		+ "颜值：%d | 学识：%d | 情商：%d
" % [
			GameManager.charm, GameManager.intellect, GameManager.eq,
		]
		+ "职位等级：%d | 学历：%s" % [
			GameManager.job_level,
			"本科" if GameManager.degree >= 1 else "大专",
		]
	)
	if romance_info != "":
		stats_text += "
重要的人：" + romance_info
	var stats_label := Label.new()
	stats_label.text = stats_text
	stats_label.add_theme_font_size_override("font_size", 13)
	stats_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)
	# 重新开始按钮
	var btn_restart := Button.new()
	btn_restart.text = "再来一次"
	btn_restart.custom_minimum_size = Vector2(0, 48)
	var restart_style := StyleBoxFlat.new()
	restart_style.bg_color = Color(accent.r, accent.g, accent.b, 1)
	restart_style.set_corner_radius_all(10.0)
	btn_restart.add_theme_stylebox_override("normal", restart_style)
	btn_restart.add_theme_color_override("font_color", Color.WHITE)
	btn_restart.add_theme_font_size_override("font_size", 18)
	btn_restart.pressed.connect(func() -> void:
		GameManager.reset_game()
		get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")
	)
	vbox.add_child(btn_restart)


func _create_line_style(line_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(line_color.r, line_color.g, line_color.b, 0.4)
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _disable_all() -> void:
	weekday_panel.visible = false
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
	sync_ui_state()


# ==================== 工作日逻辑 ====================

## 摸鱼混日子
func _on_work_slack() -> void:
	GameManager.consecutive_overtime = 0
	var amount: int = _get_salary("slack")
	_complete_work_action("摸鱼混日子", {"energy": -10, "sanity": 5, "pending_salary": amount}, "摸鱼混日子，待发工资 +%d" % amount)

## 正常打卡
func _on_work_normal() -> void:
	GameManager.consecutive_overtime = 0
	var amount: int = _get_salary("normal")
	_complete_work_action("正常打卡", {"energy": -30, "sanity": -15, "pending_salary": amount}, "正常打卡，待发工资 +%d" % amount)

## 疯狂自愿加班
func _on_work_overtime() -> void:
	GameManager.consecutive_overtime += 1
	var amount: int = _get_salary("overtime")
	var changes := {"energy": -60, "sanity": -30, "pending_salary": amount}
	GameManager.add_activity("日常", "疯狂加班，待发工资 +%d" % amount, changes)
	_show_action_result("你选择继续加班，把这周的时间全压进了工位里。", changes, Callable(self, "_finish_workday"))


func _complete_work_action(label: String, changes: Dictionary, activity_desc: String) -> void:
	GameManager.add_activity("日常", activity_desc, changes)
	_show_action_result("这周你选择了%s。" % label, changes, Callable(self, "_finish_workday"))


func _apply_action_changes(changes: Dictionary) -> Dictionary:
	if action_service and action_service.has_method("apply_stat_changes"):
		return action_service.apply_stat_changes(changes)
	var applied: Dictionary = {}
	for stat_name in changes:
		var amount := int(changes[stat_name])
		if amount == 0:
			continue
		match str(stat_name):
			"pending_salary":
				GameManager.pending_salary += amount
			_:
				GameManager.modify_stat(str(stat_name), amount)
		applied[stat_name] = amount
	return applied


func _show_action_result(story_text: String, changes: Dictionary, after: Callable = Callable()) -> void:
	weekday_panel.visible = false
	if action_service and action_service.has_method("show_deferred_action_result"):
		action_service.show_deferred_action_result(story_text, changes, func() -> void:
			var death: Dictionary = GameManager.check_behavior_death()
			if death.size() > 0:
				GameManager.game_over.emit(death["title"], death["desc"])
				return
			if after.is_valid():
				after.call()
		)
	elif action_service and action_service.has_method("show_action_result"):
		var applied := _apply_action_changes(changes)
		action_service.show_action_result(story_text, applied, after)
	else:
		var applied := _apply_action_changes(changes)
		show_stat_result(applied, after)


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
	pass
	weekday_panel.visible = false
	# 显示延迟的衰老消息（在玩家做完选择后）
	if GameManager.pending_aging_msg != "":
		var aging_text = GameManager.pending_aging_msg
		GameManager.pending_aging_msg = ""
		galgame.show_message(aging_text, true)
		_play_transition_after_aging()
	else:
		_play_transition("5天的牛马生活结束了，终于熬到了周末...")


func _play_transition_after_aging() -> void:
	# 等衰老消息打字完成后，再播放过渡
	await get_tree().create_timer(3.5).timeout
	_play_transition("5天的牛马生活结束了，终于熬到了周末...")


func _play_transition(trans_text: String) -> void:
	_transition_token += 1
	var token := _transition_token
	current_phase = Phase.TRANSITION
	label_trans_text.text = trans_text
	transition_screen.visible = true
	transition_screen.modulate.a = 0.0
	var finish_transition := Callable(self, "_finish_transition").bind(token)

	var tween := create_tween()
	tween.tween_property(transition_screen, "modulate:a", 1.0, 0.4)
	tween.tween_interval(1.0)
	tween.tween_property(transition_screen, "modulate:a", 0.0, 0.4)
	tween.tween_callback(finish_transition)
	get_tree().create_timer(2.2).timeout.connect(finish_transition)
	call_deferred("_finish_transition", token)


func _finish_transition(token: int) -> void:
	if token != _transition_token:
		return
	_transition_token += 1
	transition_screen.visible = false
	_proceed_after_work_event()


func _proceed_after_work_event() -> void:
	if GameManager.turn_count == 1:
		_enter_weekend()
		return
	var event := GameManager.roll_workplace_event()
	if event.size() > 0:
		_show_event(event, _enter_weekend)
	else:
		_enter_weekend()


# ==================== 月度账单 ====================

func _on_month_ended(salary: int, rent: int, debt: int, food: int) -> void:
	current_phase = Phase.MONTH_END
	weekday_panel.visible = false
	btn_next_week.visible = false
	_hide_all_popups()
	_force_clear_dialog_overlay()
	_disable_app_grid()

	var preview := _get_month_end_preview(salary, rent, food)
	var bill_text := _build_month_end_bill_text(preview)
	label_me_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label_me_content.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	label_me_content.text = bill_text
	_layout_month_end_bill(bill_text)
	btn_pay_rent.text = "确认结算，进入下个月"
	month_end_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	set_ui_layer_visible(month_end_popup, true)


func _on_pay_rent() -> void:
	set_ui_layer_visible(month_end_popup, false)
	GameManager.start_new_month()
	if GameManager.awaiting_ending_choice:
		return
	if not GameManager.game_finished:
		_enter_weekday()
	pass


# ==================== 周末按钮 ====================

func _on_btn_next_week() -> void:
	if _skip_week_confirm:
		_proceed_next_week()
		return
	_show_week_confirm_popup()


## 周末确认弹窗：确认结束本周 or 返回继续活动
func _show_week_confirm_popup() -> void:
	var overlay := ColorRect.new()
	overlay.name = "WeekConfirmOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.z_index = 80
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	sync_ui_state()

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
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
	desc.text = _build_week_confirm_text()
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(desc)

	var no_remind := CheckBox.new()
	no_remind.text = "不再提醒"
	no_remind.add_theme_font_size_override("font_size", 13)
	no_remind.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	no_remind.add_theme_icon_override("checked", null)
	no_remind.add_theme_icon_override("unchecked", null)
	var hbox_remind := HBoxContainer.new()
	hbox_remind.add_theme_constant_override("separation", 4)
	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_remind.add_child(spacer_l)
	hbox_remind.add_child(no_remind)
	vbox.add_child(hbox_remind)

	var btn_confirm := Button.new()
	btn_confirm.text = "确认，结束本周"
	btn_confirm.custom_minimum_size = Vector2(0, 44)
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = Color(0.027, 0.757, 0.376, 1)
	confirm_style.set_corner_radius_all(8)
	btn_confirm.add_theme_stylebox_override("normal", confirm_style)
	btn_confirm.add_theme_color_override("font_color", Color.WHITE)
	btn_confirm.add_theme_font_size_override("font_size", 16)
	btn_confirm.pressed.connect(_on_week_confirm.bind(overlay, no_remind))
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
	btn_back.pressed.connect(func() -> void:
		overlay.queue_free()
		call_deferred("sync_ui_state")
	)
	vbox.add_child(btn_back)


## 确认结束本周回调
func _on_week_confirm(overlay: ColorRect, no_remind: CheckBox) -> void:
	if no_remind.button_pressed:
		_skip_week_confirm = true
	overlay.queue_free()
	call_deferred("sync_ui_state")
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
	pass
