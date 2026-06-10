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
var _skip_week_confirm: bool = false
var _phone_dim: ColorRect = null
var _runtime_disposed: bool = false
var current_phase: Phase = Phase.WEEKDAY
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
	GameManager.spring_festival_boss.connect(_on_spring_festival_boss)

	btn_work_normal.pressed.connect(_on_work_normal)
	btn_work_slack.pressed.connect(_on_work_slack)
	btn_work_overtime.pressed.connect(_on_work_overtime)
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
	spring_festival = load("res://scripts/SpringFestivalSystem.gd").new()
	spring_festival.init(self)
	# 调试面板
	_debug_panel = get_node_or_null("DebugPanel")
	if _debug_panel == null:
		_debug_panel = load("res://scripts/DebugPanel.gd").new()
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
	left_bg = find_child("BgImage", true, false) as ColorRect
	_setup_foundation_services()
	pass
	_refresh_ui()
	pass
	if GameManager.turn_count == 1 and GameManager.week_in_month == 1 and GameManager.month == 1 and GameManager.age == 23:
		call_deferred("_show_opening_intro")
	else:
		_enter_weekday()
	pass


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
	_hide_all_popups()
	wechat._build_chat_items()
	wechat._on_wc_tab(0)
	wechat_menu.mouse_filter = Control.MOUSE_FILTER_PASS
	wc_panel_container.mouse_filter = Control.MOUSE_FILTER_PASS
	if not wechat_menu.gui_input.is_connected(wechat._on_wechat_gui_input):
		wechat_menu.gui_input.connect(wechat._on_wechat_gui_input)
	set_ui_layer_visible(wechat_menu, true)


func _on_app_alipay() -> void:
	_hide_all_popups()
	alipay._refresh_alipay_ui()
	set_ui_layer_visible(alipay_popup, true)


func _process(_delta: float) -> void:
	if ui_state and ui_state.has_method("sync_all"):
		ui_state.sync_all()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_close_top_popup()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# 左侧galgame对话框点击
			if galgame.is_visible():
				if left_dialog_box.get_global_rect().has_point(event.global_position):
					if galgame._gal_pages.size() > 0:
						galgame.gal_on_click()
						get_viewport().set_input_as_handled()
					elif is_instance_valid(galgame._gal_choice_container):
						pass  # 选择按钮自行处理点击，不消耗事件
					else:
						galgame.dismiss_dialog()
						get_viewport().set_input_as_handled()
				# 右侧系统消息框点击（关闭）
			elif left_dialog_box.visible and left_dialog_box.modulate.a > 0.5:
				if left_dialog_box.get_global_rect().has_point(event.global_position):
					galgame.dismiss_dialog()
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
			if galgame.is_visible():
				if galgame._gal_pages.size() > 0:
					galgame.gal_on_click()
					get_viewport().set_input_as_handled()
				else:
					galgame.dismiss_dialog()
					get_viewport().set_input_as_handled()
			elif left_dialog_box.visible and left_dialog_box.modulate.a > 0.5:
				galgame.dismiss_dialog()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_CTRL:
			if galgame.is_visible():
				if galgame._gal_pages.size() > 0:
					galgame.skip_all()
					get_viewport().set_input_as_handled()
				else:
					galgame.dismiss_dialog()
					get_viewport().set_input_as_handled()
			elif left_dialog_box.visible and left_dialog_box.modulate.a > 0.5:
				galgame.dismiss_dialog()
				get_viewport().set_input_as_handled()

## 右键返回：按优先级关闭当前最上层弹窗
func _close_top_popup() -> void:
	if payment_popup.visible:
		set_ui_layer_visible(payment_popup, false)
		return
	if alipay_popup.visible:
		set_ui_layer_visible(alipay_popup, false)
		return
	if diary_popup.visible:
		set_ui_layer_visible(diary_popup, false)
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
		set_ui_layer_visible(late_night_popup, false)
		return


func _setup_foundation_services() -> void:
	environment = load("res://scripts/EnvironmentController.gd").new()
	environment.init(self)
	action_service = load("res://scripts/ActionService.gd").new()
	action_service.init(self)
	ui_state = load("res://scripts/UIStateManager.gd").new()
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
		"weekend_actions": "行动",
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
	galgame.show_galgame_dialog([clean_text], on_complete)


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
	_enable_app_grid()
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


func _enter_weekend() -> void:
	current_phase = Phase.WEEKEND
	return_to_home_environment("weekend")
	btn_next_week.visible = true
	_enable_app_grid()
	# 重置周末行动次数
	GameManager.weekend_actions = GameManager.max_weekend_actions
	_update_weekend_ui()
	_refresh_ui()
	sync_ui_state()
	btn_next_week.disabled = false


func _update_weekend_ui() -> void:
	var remaining := GameManager.weekend_actions
	var preview := _get_month_end_preview()
	btn_next_week.text = "⏭ 结束本周｜行动%d｜月底:%d" % [
		remaining,
		int(preview.get("cash_after_all", 0)),
	]
	btn_next_week.tooltip_text = _build_week_confirm_text()
	if remaining <= 0:
		btn_app_map.disabled = true
		btn_app_dating.disabled = true
		btn_app_baotao.disabled = true
		btn_app_tuanmei.disabled = true
	else:
		btn_app_map.disabled = not GameManager.is_app_unlocked("map")
		btn_app_dating.disabled = not GameManager.is_app_unlocked("dating")
		btn_app_baotao.disabled = not GameManager.is_app_unlocked("baotao")
		btn_app_tuanmei.disabled = not GameManager.is_app_unlocked("tuanmei")


func _enable_app_grid() -> void:
	btn_app_map.disabled = not GameManager.is_app_unlocked("map")
	btn_app_wechat.disabled = not GameManager.is_app_unlocked("wechat")
	btn_app_baotao.disabled = not GameManager.is_app_unlocked("baotao")
	btn_app_tuanmei.disabled = not GameManager.is_app_unlocked("tuanmei")
	btn_app_zodiac.disabled = not GameManager.is_app_unlocked("zodiac")
	btn_app_house.disabled = not GameManager.is_app_unlocked("house")
	btn_app_dating.disabled = not GameManager.is_app_unlocked("dating")
	btn_app_job.disabled = not GameManager.is_app_unlocked("job")
	# 检查新解锁的APP并通知
	var new_unlocks := GameManager.get_new_unlocks()
	if new_unlocks.size() > 0:
		galgame.show_message("手机上新装了一个APP..." + "
" + new_unlocks[0], true)


func _show_opening_intro() -> void:
	current_phase = Phase.TRANSITION
	_hide_all_popups()
	_disable_app_grid()
	weekday_panel.visible = false
	btn_next_week.visible = false
	var opening_pages: Array = [
		"墙皮在掉。",
		"绿斑从天花板角落往下蔓延。深圳三月的回南天让人喘不过气。",
		"我坐在城中村的单人床上，盯着手机屏幕。花呗账单页面的红色数字跳了两下：2876.32。",
		"上个月买的那件连衣裙，穿了一次，被奶茶泼了。退不了。",
		"朋友圈里小雅的动态又更新了。定位南山一家私房菜馆，九宫格第一张是个男人的手，腕上一块绿水鬼，正在给小雅夹菜。配文三个字：被投喂。",
		"我把手机扣在床上。",
		"被子和枕头发粘，晾了三天的内衣摸上去也没干。",
		"这个六平米的隔断间实在待不下去了。",
		"我换了条裤子，抓起包往外走。",
		"出了村口，深南大道上车水马龙。",
		"我掏出[color=FFD700]手机[/color]，打开[color=FFD700]高德地图[/color]，看看去哪里逛一逛。",
	]
	galgame.show_galgame_dialog(opening_pages, func() -> void:
		_enter_weekend()
	)


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
	galgame.show_galgame_dialog(pages, func() -> void:
		for key in event:
			if key == "desc":
				continue
			GameManager.modify_stat(key, event[key])
		show_stat_result(stat_changes, after_callback)
	)



# ==================== UI 刷新 ====================

func _refresh_ui() -> void:
	label_week.text = "%d岁 | 第%d月 | 第%d周" % [GameManager.age, GameManager.month, GameManager.week_in_month]
	label_money.text = str(GameManager.money)
	label_psalary.text = str(GameManager.pending_salary)
	label_player_info.text = "姓名:%s | 星座:%s | 行动:%d/%d" % [
		GameManager.player_name,
		GameManager.player_zodiac,
		GameManager.weekend_actions,
		GameManager.max_weekend_actions,
	]
	_update_finance_widgets()
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

	label_pressure_summary = parent.get_node_or_null("LabelPressureSummary") as Label
	if label_pressure_summary == null:
		label_pressure_summary = Label.new()
		label_pressure_summary.name = "LabelPressureSummary"
		parent.add_child(label_pressure_summary)
	label_pressure_summary.add_theme_font_size_override("font_size", 13)
	label_pressure_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_pressure_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	label_pressure_hint = parent.get_node_or_null("LabelPressureHint") as Label
	if label_pressure_hint == null:
		label_pressure_hint = Label.new()
		label_pressure_hint.name = "LabelPressureHint"
		parent.add_child(label_pressure_hint)
	label_pressure_hint.add_theme_font_size_override("font_size", 12)
	label_pressure_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_pressure_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _update_finance_widgets() -> void:
	if not label_pressure_summary or not label_pressure_hint:
		return
	var preview := _get_month_end_preview()
	var pressure := _get_pressure_state(preview)
	var debt_total: int = GameManager.huabei_debt + GameManager.huabei_installment_debt
	var cash_after: int = int(preview.get("cash_after_all", 0))
	var mandatory_cost: int = int(preview.get("mandatory_cost", 0))
	label_pressure_summary.text = "本月压力:%s | 月底现金:%d | 账单:%d | 总债:%d" % [
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
	var growth_text := "成长:%s | %s | 夜校:%d/12" % [
		job_name,
		degree_name,
		GameManager.night_school_progress,
	]
	var pressure_hint := str(pressure.get("hint", ""))
	label_pressure_hint.text = "%s\n%s" % [pressure_hint, growth_text] if pressure_hint != "" else growth_text
	label_pressure_hint.add_theme_color_override("font_color", pressure.get("hint_color", Color(0.62, 0.66, 0.72)))


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
	if huabei_after_interest > 0:
		var before_interest := huabei_after_interest
		huabei_after_interest = int(float(huabei_after_interest) * 1.05)
		huabei_interest = huabei_after_interest - before_interest

	var mandatory_cost := rent + food + installment_due + huabei_min
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
		"min_payment_failed": min_payment_failed,
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
	lines.append("剩余周末行动：%d/%d" % [GameManager.weekend_actions, GameManager.max_weekend_actions])
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


func _build_month_end_bill_text(preview: Dictionary) -> String:
	var lines: Array = []
	lines.append("【本月现金流】")
	lines.append("当前现金：%d" % int(preview.get("current_cash", 0)))
	lines.append("本月工资：+%d" % int(preview.get("salary", 0)))
	lines.append("")
	lines.append("【固定扣款】")
	lines.append("房租：-%d" % int(preview.get("rent", 0)))
	lines.append("餐饮账单：-%d" % int(preview.get("food", 0)))
	if int(preview.get("installment_due", 0)) > 0:
		lines.append("花呗分期：-%d（当前剩余 %d 期）" % [
			int(preview.get("installment_due", 0)),
			int(preview.get("installment_months_left", 0)),
		])
	if int(preview.get("huabei_min", 0)) > 0:
		lines.append("花呗最低还款：-%d" % int(preview.get("huabei_min", 0)))
	lines.append("")
	lines.append("【结算预估】")
	lines.append("刚性支出合计：-%d" % int(preview.get("mandatory_cost", 0)))
	lines.append("结算后现金：%d" % int(preview.get("cash_after_all", 0)))
	if int(preview.get("huabei_interest", 0)) > 0:
		lines.append("未还花呗滚入利息：+%d" % int(preview.get("huabei_interest", 0)))
	lines.append("结算后总债务：%d" % int(preview.get("total_debt_after", 0)))
	if GameManager.invest_safe + GameManager.invest_risk > 0:
		lines.append("理财资产不自动变现：%d" % (GameManager.invest_safe + GameManager.invest_risk))

	var pressure := _get_pressure_state(preview)
	lines.append("")
	lines.append("【风险提示】%s：%s" % [str(pressure.get("name", "未知")), str(pressure.get("hint", ""))])
	if bool(preview.get("min_payment_failed", false)):
		lines.append("注意：当前现金不足以覆盖花呗最低还款，会产生严重情绪惩罚。")
	elif int(preview.get("cash_after_all", 0)) < 0:
		lines.append("注意：结算后现金为负，会进入破产压力判定。")
	return "\n".join(lines)


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
	## 家庭群：未读未清空时不推新消息
	var _family_unread: int = GameManager.npcs.get("family_group", {}).get("unread", 0)
	if _family_unread <= 0 and GameManager.npcs.get("family_group", {}).get("unlocked", false):
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
	var unlock_text := "[%s] 添加了你的微信。" % npc_name
	match _id:
		"zhou_jie":
			unlock_text = "入职第三周，茶水间聊过几次后，[%s] 添加了你的微信。" % npc_name
		_:
			unlock_text = "[%s] 添加了你的微信。" % npc_name
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
	var changes := _apply_action_changes({"energy": -60, "sanity": -30, "pending_salary": amount})
	GameManager.add_activity("日常", "疯狂加班，待发工资 +%d" % amount)
	# 连续加班死法检查
	var death: Dictionary = GameManager.check_behavior_death()
	if death.size() > 0:
		GameManager.game_over.emit(death["title"], death["desc"])
		return
	_show_action_result("你选择继续加班，把这周的时间全压进了工位里。", changes, Callable(self, "_finish_workday"))


func _complete_work_action(label: String, changes: Dictionary, activity_desc: String) -> void:
	var applied := _apply_action_changes(changes)
	GameManager.add_activity("日常", activity_desc)
	_show_action_result("这周你选择了%s。" % label, applied, Callable(self, "_finish_workday"))


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
	if action_service and action_service.has_method("show_action_result"):
		action_service.show_action_result(story_text, changes, after)
	else:
		show_stat_result(changes, after)


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
		_proceed_after_work_event()
	)


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
	_disable_app_grid()

	var preview := _get_month_end_preview(salary, rent, food)
	label_me_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label_me_content.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	label_me_content.text = _build_month_end_bill_text(preview)
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
