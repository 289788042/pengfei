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

## BOSS弯聘弹窗
@onready var btn_app_job: Button = %BtnApp_Job
@onready var job_popup: ColorRect = %JobPopup
@onready var label_job_status: Label = %LabelJobStatus
@onready var btn_job_admin: Button = %Btn_Job_Admin
@onready var btn_job_media: Button = %Btn_Job_Media
@onready var btn_job_client: Button = %Btn_Job_Client
@onready var btn_close_job: Button = %Btn_CloseJob

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
var dialog_tween: Tween

## Galgame 分页对话状态
var _gal_pages: Array = []
var _gal_page_idx: int = 0
var _gal_char_idx: int = 0
var _gal_typing: bool = false
var _gal_full_text: String = ""
var _gal_tween: Tween = null
var _gal_on_complete: Callable = Callable()
var _gal_encounter_data: Dictionary = {}
var _gal_npc_id: String = ""
var _gal_choice_container: VBoxContainer = null
var _arrow_label: Label = null
var _arrow_tween: Tween = null

## 支服了宝弹窗
@onready var alipay_popup: ColorRect = %AlipayPopup
@onready var label_alipay_balance: Label = %LabelAlipayBalance
@onready var label_alipay_huabei: Label = %LabelAlipayHuabei
@onready var label_alipay_warning: Label = %LabelAlipayWarning
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

## 日记本弹窗
@onready var diary_popup: ColorRect = %DiaryPopup
@onready var diary_log_container: VBoxContainer = %DiaryLogContainer

## 通用支付拦截弹窗
@onready var payment_popup: ColorRect = %PaymentPopup
@onready var label_payment_cost: Label = %LabelPaymentCost
@onready var btn_pay_mix: Button = %BtnPayMix
@onready var btn_pay_huabei: Button = %BtnPayHuabei
@onready var btn_pay_cancel: Button = %BtnPayCancel

## 饮食按钮
@onready var btn_food_low: Button = %Btn_Food_Low
@onready var btn_food_mid: Button = %Btn_Food_Mid
@onready var btn_food_high: Button = %Btn_Food_High

## 宝淘弹窗
@onready var baotao_popup: ColorRect = %BaoTaoPopup
@onready var label_bt_debt: Label = %LabelBTDebt
@onready var btn_bt_skincare: Button = %Btn_BT_Skincare
@onready var btn_bt_fashion: Button = %Btn_BT_Fashion
@onready var btn_close_bt: Button = %Btn_CloseBT

## 团美医美弹窗
@onready var tuanmei_popup: ColorRect = %TuanMeiPopup
@onready var label_tm_debt: Label = %LabelTMDebt
@onready var btn_tm_injection: Button = %Btn_TM_Injection
@onready var btn_tm_surgery: Button = %Btn_TM_Surgery
@onready var btn_close_tm: Button = %Btn_CloseTM

## 星座弹窗
@onready var zodiac_popup: ColorRect = %ZodiacPopup
@onready var label_zodiac_content: Label = %LabelZContent
@onready var btn_close_zodiac: Button = %Btn_CloseZodiac

## 贝壳找房弹窗
@onready var house_popup: ColorRect = %HousePopup
@onready var label_house_status: Label = %LabelHouseStatus
@onready var btn_house_village: Button = %Btn_House_Village
@onready var btn_house_apartment: Button = %Btn_House_Apartment
@onready var btn_house_luxury: Button = %Btn_House_Luxury
@onready var btn_close_house: Button = %Btn_CloseHouse

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


var wechat: WeChatSystem
var current_phase: Phase = Phase.WEEKDAY
var _pending_event: Dictionary = {}
var _pending_callback: Callable = Callable()

## 支付拦截系统
var _pending_pay_cost: int = 0
var _pending_pay_desc: String = ""
var _pending_pay_category: String = ""
var _pending_pay_callback: Callable = Callable()
## 日记本过滤
var _diary_filter: String = "全部"
## 深夜失眠：当前抽中的冲动消费选项
var _pending_impulse: Dictionary = {}
## 冲动消费选项池
var _impulse_pool: Array = [
	{"text": "被直播间洗脑，分期拿下轻奢包包 (花呗+5000, 情绪+40)", "huabei": 5000, "sanity": 40, "charm": 0, "desc": "深夜失眠，被直播间洗脑分期买了轻奢包"},
	{"text": "深夜emo，疯狂网购一堆无用盲盒 (花呗+800, 情绪+15)", "huabei": 800, "sanity": 15, "charm": 0, "desc": "深夜emo，疯狂网购了一堆无用盲盒"},
	{"text": "刷到前任秀恩爱，怒点昂贵医美套餐 (花呗+10000, 颜值+10, 情绪+30)", "huabei": 10000, "sanity": 30, "charm": 10, "desc": "深夜刷到前任秀恩爱，怒点昂贵医美套餐"},
]
## 滑动交友：随机名字池
var _dating_names: Array = [
	"王大壮", "李富贵", "张天宇", "赵子龙", "刘星",
	"陈浩南", "周杰", "吴彦组", "孙小宝", "马赛克",
	"钱多多", "郑经", "冯提莫", "何老师", "罗永亮",
]
## 滑动交友：随机签名池
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
	wechat = WeChatSystem.new()
	wechat.init(self)
	btn_close_wechat.pressed.connect(wechat._on_close_wechat)
	wechat._build_chat_items()
	## 初始推送一批未读消息（模拟游戏开始前已有的消息）
	_push_npc_unread_messages()
	btn_wc_back.pressed.connect(wechat._on_close_wechat)
	tab_contacts.pressed.connect(wechat._on_wc_tab.bind(0))
	tab_moments.pressed.connect(wechat._on_wc_tab.bind(1))
	btn_chat_back.pressed.connect(wechat._on_chat_back)
	chat_input_field.pressed.connect(wechat._on_chat_send)
	btn_pay_rent.pressed.connect(_on_pay_rent)


	btn_app_map.pressed.connect(_on_app_map)
	btn_app_wechat.pressed.connect(_on_app_wechat)
	btn_app_alipay.pressed.connect(_on_app_alipay)
	btn_app_diary.pressed.connect(_on_app_diary)
	btn_app_baotao.pressed.connect(_on_app_baotao)
	btn_app_tuanmei.pressed.connect(_on_app_tuanmei)
	btn_app_zodiac.pressed.connect(_on_app_zodiac)
	btn_app_house.pressed.connect(_on_app_house)
	btn_app_dating.pressed.connect(_on_app_dating)

	btn_app_job.pressed.connect(_on_app_job)
	btn_job_admin.pressed.connect(_on_job_admin)
	btn_job_media.pressed.connect(_on_job_media)
	btn_job_client.pressed.connect(_on_job_client)
	btn_close_job.pressed.connect(_on_close_job)

	btn_food_low.pressed.connect(_on_food_low)
	btn_food_mid.pressed.connect(_on_food_mid)
	btn_food_high.pressed.connect(_on_food_high)

	btn_bt_skincare.pressed.connect(_on_bt_skincare)
	btn_bt_fashion.pressed.connect(_on_bt_fashion)
	btn_close_bt.pressed.connect(_on_close_bt)

	btn_tm_injection.pressed.connect(_on_tm_injection)
	btn_tm_surgery.pressed.connect(_on_tm_surgery)
	btn_close_tm.pressed.connect(_on_close_tm)

	btn_close_zodiac.pressed.connect(_on_close_zodiac)

	btn_house_village.pressed.connect(_on_house_village)
	btn_house_apartment.pressed.connect(_on_house_apartment)
	btn_house_luxury.pressed.connect(_on_house_luxury)
	btn_close_house.pressed.connect(_on_close_house)

	btn_pass.pressed.connect(_on_pass)
	btn_like.pressed.connect(_on_like)
	btn_close_dating.pressed.connect(_on_close_dating)

	btn_al_fin_safe_in.pressed.connect(_on_al_fin_safe_in)
	btn_al_fin_risk_in.pressed.connect(_on_al_fin_risk_in)
	btn_al_fin_safe_out.pressed.connect(_on_al_fin_safe_out)
	btn_al_fin_risk_out.pressed.connect(_on_al_fin_risk_out)
	btn_close_alipay.pressed.connect(_on_close_alipay)
	btn_repay_huabei.pressed.connect(_on_repay_huabei)
	btn_installment.pressed.connect(_on_installment)

	btn_pay_mix.pressed.connect(_on_pay_mix)
	btn_pay_huabei.pressed.connect(_on_pay_huabei)
	btn_pay_cancel.pressed.connect(_on_pay_cancel)

	# 深夜网抑云按钮
	btn_emo_bag.pressed.connect(_on_emo_bag)
	btn_emo_sleep.pressed.connect(_on_emo_sleep)

	# 日记过滤按钮（通过 find_child 深层搜索）
	for cat in ["全部", "日常", "提升", "社交", "消费"]:
		var btn: Button = find_child("Btn_DiaryFilter_" + cat, true, false)
		if btn:
			btn.pressed.connect(_on_diary_filter.bind(cat))
	# 日记关闭按钮
	var _btn_close_diary: Button = find_child("BtnCloseDiary", true, false)
	if _btn_close_diary:
		_btn_close_diary.pressed.connect(func() -> void: diary_popup.visible = false)

	label_player_info.text = "姓名：%s | 星座：%s" % [GameManager.player_name, GameManager.player_zodiac]
	_refresh_ui()
	_enter_weekday()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_close_top_popup()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if dialog_box.visible and dialog_box.modulate.a > 0.5:
				if dialog_box.get_global_rect().has_point(event.global_position):
					if _gal_pages.size() > 0:
						_gal_on_click()
						get_viewport().set_input_as_handled()
					elif is_instance_valid(_gal_choice_container):
						pass  # 选择按钮自行处理点击，不消耗事件
					else:
						_dismiss_dialog()
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
	if baotao_popup.visible:
		baotao_popup.visible = false
		return
	if tuanmei_popup.visible:
		tuanmei_popup.visible = false
		return
	if house_popup.visible:
		house_popup.visible = false
		return
	if dating_popup.visible:
		dating_popup.visible = false
		return
	if job_popup.visible:
		job_popup.visible = false
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


# ==================== 飘字动画 ====================

func show_floating_text(text: String, color: Color, start_pos: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 22)
	if wechat.is_visible() or alipay_popup.visible:
		label.z_index = 200
		label.position = Vector2(1570, 30.0)
		add_child(label)
	else:
		label.z_index = 100
		label.position = start_pos
		add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(label.queue_free)


func float_stat(text: String, amount: int, pos: Vector2) -> void:
	var color := Color.GREEN if amount >= 0 else Color.RED
	show_floating_text(text, color, pos)


func show_message(text: String, galgame: bool = false) -> void:
	if dialog_tween and dialog_tween.is_running():
		dialog_tween.kill()
	dialog_text.text = text
	dialog_box.visible = true
	dialog_box.modulate.a = 1.0
	if not galgame:
		dialog_tween = create_tween()
		dialog_tween.tween_interval(3.0)
		dialog_tween.tween_property(dialog_box, "modulate:a", 0.0, 0.5)
		dialog_tween.tween_callback(func(): dialog_box.visible = false)

## 醒目红色提示（用于春节等重大事件）
func show_urgent_message(text: String) -> void:
	if dialog_tween and dialog_tween.is_running():
		dialog_tween.kill()
	dialog_text.text = "[color=red]" + text + "[/color]"
	dialog_box.visible = true
	dialog_box.modulate.a = 1.0
	dialog_tween = create_tween()
	dialog_tween.tween_interval(4.0)
	dialog_tween.tween_property(dialog_box, "modulate:a", 0.0, 0.5)
	dialog_tween.tween_callback(func(): dialog_box.visible = false)

## 点击对话框立即关闭
func _dismiss_dialog() -> void:
	if dialog_tween and dialog_tween.is_running():
		dialog_tween.kill()
	dialog_box.modulate.a = 0.0
	dialog_box.visible = false


# ==================== Galgame 分页对话系统 ====================

## 启动 Galgame 分页对话（pages: 每页一个字符串）
func show_galgame_dialog(pages: Array, on_complete: Callable = Callable()) -> void:
	if _gal_tween and _gal_tween.is_valid():
		_gal_tween.kill()
	_gal_pages = pages
	_gal_page_idx = 0
	_gal_on_complete = on_complete
	dialog_box.visible = true
	dialog_box.modulate.a = 1.0
	if is_instance_valid(_gal_choice_container):
		_gal_choice_container.visible = false
	dialog_text.visible = true
	_gal_start_page()

## 开始打字当前页
func _gal_start_page() -> void:
	_gal_full_text = _gal_pages[_gal_page_idx]
	_gal_char_idx = 0
	_gal_typing = true
	dialog_text.text = ""
	_apply_page_color(_gal_full_text)
	_stop_arrow_anim()
	_gal_type_char()

## 打字机核心：逐字输出
func _gal_type_char() -> void:
	if _gal_char_idx >= _gal_full_text.length():
		_gal_typing = false
		dialog_text.text = _gal_full_text
		_start_arrow_anim()
		return
	_gal_char_idx += 1
	dialog_text.text = _gal_full_text.substr(0, _gal_char_idx)
	_gal_tween = create_tween()
	_gal_tween.tween_interval(0.03)
	_gal_tween.tween_callback(_gal_type_char)

## 点击处理：跳过打字 or 翻页
func _gal_on_click() -> void:
	if _gal_typing:
		## 跳过当前页打字，直接显示完整文本
		if _gal_tween and _gal_tween.is_valid():
			_gal_tween.kill()
		_gal_typing = false
		dialog_text.text = _gal_full_text
		_start_arrow_anim()
	else:
		## 翻到下一页
		_gal_page_idx += 1
		if _gal_page_idx < _gal_pages.size():
			_gal_start_page()
		else:
			_gal_end()

## 根据内容设置对话框颜色：旁白白色，对话黄色
func _apply_page_color(raw: String) -> void:
	if raw.begins_with('陌生男子：') or raw.begins_with('我：'):
		dialog_text.add_theme_color_override('default_color', Color(1.0, 0.9, 0.3, 1.0))
	elif raw.begins_with("'"):
		dialog_text.add_theme_color_override('default_color', Color(1.0, 0.9, 0.3, 1.0))
	else:
		dialog_text.add_theme_color_override('default_color', Color(0.94, 0.94, 0.94, 1.0))

## 箭头指示器动画：上下轻微浮动
func _start_arrow_anim() -> void:
	if not is_instance_valid(_arrow_label):
		_arrow_label = Label.new()
		_arrow_label.name = 'ArrowIndicator'
		_arrow_label.text = '▼'
		_arrow_label.add_theme_font_size_override('font_size', 22)
		_arrow_label.add_theme_color_override('font_color', Color(1, 1, 1, 0.7))
		dialog_box.add_child(_arrow_label)
		_arrow_label.position = Vector2(dialog_box.size.x - 50, dialog_box.size.y - 35)
	_arrow_label.visible = true
	_arrow_label.modulate.a = 1.0
	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()
	var base_y: float = _arrow_label.position.y
	_arrow_tween = create_tween().set_loops()
	_arrow_tween.tween_property(_arrow_label, 'position:y', base_y - 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_arrow_tween.tween_property(_arrow_label, 'position:y', base_y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_arrow_anim() -> void:
	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()
		_arrow_tween = null
	if is_instance_valid(_arrow_label):
		_arrow_label.visible = false

## 结束 Galgame 对话
## 结束 Galgame 对话
func _gal_end() -> void:
	if _gal_tween and _gal_tween.is_valid():
		_gal_tween.kill()
	_gal_pages.clear()
	_gal_typing = false
	_stop_arrow_anim()
	## 统一渐隐对话框，再处理回调或完成文案
	var cb: Callable = _gal_on_complete
	_gal_on_complete = Callable()
	var has_encounter: bool = _gal_encounter_data.size() > 0
	_gal_tween = create_tween()
	_gal_tween.tween_property(dialog_box, "modulate:a", 0.0, 0.4)
	_gal_tween.tween_callback(func() -> void:
		dialog_box.visible = false
		if cb.is_valid():
			cb.call()
		elif has_encounter:
			_gal_encounter_data = {}
			show_message("在图书馆度过了一个充实的下午。\n[color=90EE90]学识+3 情绪+5[/color]", true)
	)


	## 邂逅第二阶段：NPC 请求加微信
func _start_wechat_request_phase() -> void:
	var wc_data: Dictionary = _gal_encounter_data.get("wechat_request", {})
	if wc_data.size() == 0:
		dialog_box.modulate.a = 0.0
		dialog_box.visible = false
		return
	var pages: Array = []
	for line in wc_data.get("his_lines", []):
		pages.append("陌生男子：" + line)
	show_galgame_dialog(pages, _show_wechat_choices_phase)

## 邂逅第三阶段：显示玩家选择按钮
func _show_wechat_choices_phase() -> void:
	var wc_data: Dictionary = _gal_encounter_data.get("wechat_request", {})
	var options: Array = wc_data.get("player_options", [])
	if options.size() == 0:
		dialog_box.modulate.a = 0.0
		dialog_box.visible = false
		return
	dialog_box.visible = true
	dialog_box.modulate.a = 1.0
	dialog_text.visible = false
	if is_instance_valid(_gal_choice_container):
		_gal_choice_container.queue_free()
	_gal_choice_container = VBoxContainer.new()
	_gal_choice_container.name = "GalChoiceContainer"
	_gal_choice_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_gal_choice_container.offset_left = 20
	_gal_choice_container.offset_top = 12
	_gal_choice_container.offset_right = -16
	_gal_choice_container.offset_bottom = -12
	_gal_choice_container.add_theme_constant_override("separation", 8)
	dialog_box.add_child(_gal_choice_container)
	for option in options:
		var btn := Button.new()
		btn.text = option.get("text", "...")
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
		var req_stat: String = option.get("req_stat", "")
		var req_val: int = int(option.get("req_val", 0))
		if req_stat != "" and GameManager.get(req_stat) < req_val:
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 0.7))
			var dis_style := StyleBoxFlat.new()
			dis_style.bg_color = Color(0.1, 0.1, 0.12, 0.5)
			dis_style.set_corner_radius_all(10.0)
			dis_style.set_content_margin_all(12)
			btn.add_theme_stylebox_override("disabled", dis_style)
		else:
			btn.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95, 1))
		var captured_option: Dictionary = option
		btn.pressed.connect(func() -> void: _on_encounter_choice(captured_option))
		_gal_choice_container.add_child(btn)

## 邂逅选择回调
func _on_encounter_choice(option: Dictionary) -> void:
	var cost: Dictionary = option.get("cost", {})
	var cost_energy: int = int(cost.get("energy", 0))
	var cost_money: int = int(cost.get("money", 0))
	if cost_energy > 0:
		GameManager.modify_stat("energy", -cost_energy)
	if cost_money > 0:
		GameManager.modify_stat("money", -cost_money)
	var stat_changes: Dictionary = option.get("stat_changes", {})
	for stat_name in stat_changes:
		var val: int = int(stat_changes[stat_name])
		if stat_name == "affection" and _gal_npc_id != "":
			GameManager.get_npc_runtime(_gal_npc_id)["affection"] += val
		else:
			GameManager.modify_stat(stat_name, val)
	var flag: String = option.get("flag", "")
	if flag != "" and _gal_npc_id != "":
		var runtime: Dictionary = GameManager.get_npc_runtime(_gal_npc_id)
		if not runtime["flags"].has(flag):
			runtime["flags"].append(flag)
	if is_instance_valid(_gal_choice_container):
		_gal_choice_container.queue_free()
		_gal_choice_container = null
	dialog_text.visible = true
	var pages: Array = []
	pages.append("我：" + option.get("text", ""))
	for line in option.get("reply_lines", []):
		if line.begins_with("'"):
			pages.append("陌生男子：" + line)
		else:
			pages.append(line)
	if option.get("note", "") != "":
		pages.append(option["note"])
	show_galgame_dialog(pages)


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
	baotao_popup.visible = false
	tuanmei_popup.visible = false
	zodiac_popup.visible = false
	location_menu.visible = false
	house_popup.visible = false
	dating_popup.visible = false
	wechat.force_close()
	alipay_popup.visible = false
	diary_popup.visible = false
	job_popup.visible = false


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
	label_energy.text = str(GameManager.energy)
	label_sanity.text = str(GameManager.sanity)
	label_charm.text = str(GameManager.charm)
	label_intellect.text = str(GameManager.intellect)
	label_eq.text = str(GameManager.eq)
	label_psalary.text = str(GameManager.pending_salary)
	wechat._refresh_wechat_ui()



func _refresh_debt_display() -> void:
	var debt_text := "当前花呗欠款：%d" % GameManager.huabei_debt
	label_bt_debt.text = debt_text
	label_tm_debt.text = debt_text


# ==================== 信号回调 ====================

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
	house_popup.visible = false
	dating_popup.visible = false
	alipay_popup.visible = false
	diary_popup.visible = false
	payment_popup.visible = false
	job_popup.visible = false
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
		_enter_late_night()
		return
	_proceed_next_week()

## 实际推进下一周（失眠弹窗成功睡觉或冲动消费后也调用此函数）
func _proceed_next_week() -> void:
	GameManager.advance_week()
	if GameManager.awaiting_month_settle:
		return
	if not GameManager.game_finished:
		_enter_weekday()

func _on_close_loc() -> void:
	location_menu.visible = false


# ==================== App图标回调 ====================

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
		{"name": "高档酒吧", "icon_color": Color(0.6, 0.3, 0.8), "cost": "-20精力 -500金 | +2情商 +25情绪", "action": _on_loc_bar},
		{"name": "宅家刷手机", "icon_color": Color(0.55, 0.55, 0.55), "cost": "-10精力 | +20情绪", "action": _on_loc_home},
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


func _on_app_wechat() -> void:
	wechat._refresh_wechat_ui()
	wechat._on_wc_tab(0)
	wechat_menu.mouse_filter = Control.MOUSE_FILTER_PASS
	wc_panel_container.mouse_filter = Control.MOUSE_FILTER_PASS
	if not wechat_menu.gui_input.is_connected(wechat._on_wechat_gui_input):
		wechat_menu.gui_input.connect(wechat._on_wechat_gui_input)
	wechat_menu.visible = true

func _on_app_alipay() -> void:
	_refresh_alipay_ui()
	alipay_popup.visible = true

func _on_app_diary() -> void:
	_refresh_diary_ui()
	diary_popup.visible = true

func _on_app_baotao() -> void:
	_refresh_debt_display()
	baotao_popup.visible = true

func _on_app_tuanmei() -> void:
	_refresh_debt_display()
	tuanmei_popup.visible = true

func _on_app_zodiac() -> void:
	label_zodiac_content.text = "亲爱的%s宝宝，本周运势：\n请注意控制消费，警惕烂桃花哦！" % GameManager.player_zodiac
	zodiac_popup.visible = true

func _on_app_house() -> void:
	_refresh_house_status()
	house_popup.visible = true

func _on_app_dating() -> void:
	_refresh_dating_card()
	dating_popup.visible = true


# ==================== 地点逻辑 ====================

func _on_loc_library() -> void:
	if GameManager.energy < 20:
		show_message("精力不足，无法去图书馆！")
		return

	## 邂逅判定：遍历剧本库寻找 location=library 的 NPC
	var encounter_npc: Dictionary = {}
	var encounter_data: Dictionary = {}
	for npc in GameManager.npc_database:
		var enc: Dictionary = npc.get("encounter", {})
		if enc.get("location", "") == "library" and not GameManager.is_npc_unlocked(npc.get("id", "")) and not npc.get("id", "") in GameManager.encounter_failed_ids:
			encounter_npc = npc
			encounter_data = enc
			break

	if encounter_npc.size() > 0:
		var npc_id: String = encounter_npc["id"]
		var npc_name: String = encounter_npc["name"]
		var req: Dictionary = encounter_data.get("req_stats", {})
		var cost: Dictionary = encounter_data.get("cost", {})
		var energy_cost: int = cost.get("energy", 0)
		var money_cost: int = cost.get("money", 0)

		## 检查属性门槛
		var charm_ok: bool = GameManager.charm >= req.get("charm", 0)
		var intellect_ok: bool = GameManager.intellect >= req.get("intellect", 0)
		var money_ok: bool = GameManager.money >= req.get("money", 0)

		## 扣除基础精力 + 额外消耗
		var total_energy: int = 20 + energy_cost
		if GameManager.energy < total_energy:
			show_message("精力不足（需%d），无法去图书馆！" % total_energy)
			return
		if money_cost > 0 and GameManager.money < money_cost:
			show_message("金钱不足（需%d元）！" % money_cost)
			return

		GameManager.modify_stat("energy", -total_energy)
		if money_cost > 0:
			GameManager.modify_stat("money", -money_cost)

		location_menu.visible = false

		if charm_ok and intellect_ok and money_ok:
			## 邂逅成功
			GameManager.unlock_npc(npc_id)
			var pass_changes: Dictionary = encounter_data.get("pass_stat_changes", {})
			for stat_name in pass_changes:
				if stat_name == "affection":
					GameManager.get_npc_runtime(npc_id)["affection"] += pass_changes[stat_name]
				else:
					GameManager.modify_stat(stat_name, pass_changes[stat_name])

			## 保存邂逅数据供回调使用
			_gal_encounter_data = encounter_data
			_gal_npc_id = npc_id

			## Phase 1：场景 + 对话 + 考验 + 通过
			var pages: Array = []
			## 旁白：场景描写（scene_lines）
			for line in encounter_data.get("scene_lines", []):
				pages.append(line)
			## 陌生男子：对话台词（dialogue_lines）
			for line in encounter_data.get("dialogue_lines", []):
				pages.append("陌生男子：" + line)
			## 陌生男子：考验问题
			if encounter_data.get("test_question", "") != "":
				for seg in encounter_data["test_question"].split("\n"):
					if seg.strip_edges() != "":
						pages.append("陌生男子：" + seg)
			## 我：玩家通过台词（pass_lines）
			for line in encounter_data.get("pass_lines", []):
				pages.append("我：" + line)
			## 混合旁白+对话（pass_result_lines）
			for line in encounter_data.get("pass_result_lines", []):
				if line.begins_with("'"):
					pages.append("陌生男子：" + line)
				else:
					pages.append(line)
			show_galgame_dialog(pages, _start_wechat_request_phase)
			GameManager.add_activity("社交", "在图书馆邂逅了%s" % npc_name)
		else:
			## 邂逅失败
			var fail_changes: Dictionary = encounter_data.get("fail_stat_changes", {})
			for stat_name in fail_changes:
				GameManager.modify_stat(stat_name, fail_changes[stat_name])
			## Galgame 逐句分页：场景 + 对话 + 失败台词
			var fail_pages: Array = []
			for line in encounter_data.get("scene_lines", []):
				fail_pages.append(line)
			for line in encounter_data.get("dialogue_lines", []):
				fail_pages.append("陌生男子：" + line)
			if encounter_data.get("test_question", "") != "":
				for seg in encounter_data["test_question"].split("\n"):
					if seg.strip_edges() != "":
						fail_pages.append("陌生男子：" + seg)
			for line in encounter_data.get("fail_lines", []):
				fail_pages.append("我：" + line)
			for line in encounter_data.get("fail_result_lines", []):
				if line.begins_with("'"):
					fail_pages.append("陌生男子：" + line)
				else:
					fail_pages.append(line)
			GameManager.encounter_failed_ids.append(npc_id)
			show_galgame_dialog(fail_pages, func() -> void:
				show_message("在图书馆度过了一个充实的下午。\n[color=90EE90]学识+3 情绪+5[/color]", true)
			)
			GameManager.add_activity("提升", "在图书馆读书（与某人擦肩而过）")
		return

	## 正常图书馆逻辑（无邂逅或已解锁）
	GameManager.modify_stat("energy", -20)
	GameManager.modify_stat("intellect", 3)
	GameManager.modify_stat("sanity", 5)
	GameManager.add_activity("提升", "在图书馆读书，学识+3，情绪+5")
	show_message("在图书馆度过了一个充实的下午。\n[color=90EE90]学识+3 情绪+5[/color]", true)
	location_menu.visible = false

func _on_loc_gym() -> void:
	if GameManager.energy < 45:
		show_message("精力不足（需45），无法去健身房！")
		return
	request_payment(200, "健身房消费", "提升", func() -> void:
		GameManager.modify_stat("energy", -45)
		GameManager.modify_stat("charm", 2)
		GameManager.modify_stat("sanity", 5)
		# 永久提升精力上限+1
		GameManager.max_energy += 1
		float_stat("+2 颜值 +5 情绪 精力上限+1", 5, get_global_mouse_position())
		GameManager.add_activity("提升", "去健身房挥汗如雨！颜值+2，情绪+5，精力上限永久+1（当前%d）" % GameManager.max_energy)
		_visit_location("gym", "挥汗如雨！颜值+2，精力上限永久+1！")
	)

func _on_loc_bar() -> void:
	if GameManager.energy < 20:
		show_message("精力不足，无法去酒吧！")
		return
	request_payment(500, "酒吧消费", "社交", func() -> void:
		GameManager.modify_stat("energy", -20)
		GameManager.modify_stat("eq", 2)
		GameManager.modify_stat("sanity", 25)
		float_stat("+2 情商 +25 情绪", 25, get_global_mouse_position())
		_visit_location("bar", "在酒吧喝了一杯，感觉心情大好！")
	)

## 宅家刷手机
func _on_loc_home() -> void:
	GameManager.modify_stat("energy", -10)
	GameManager.modify_stat("sanity", 20)
	float_stat("+20 情绪", 20, get_global_mouse_position())
	show_message("宅家刷了一整天手机，虽然眼睛酸但心情不错~", true)
	location_menu.visible = false


func _visit_location(context: String, success_msg: String) -> void:
	var event := GameManager.roll_random_event(context)
	if event.size() > 0:
		location_menu.visible = false
		show_message(success_msg, true)
		_show_event(event, func() -> void: pass)
	else:
		show_message(success_msg, true)
		location_menu.visible = false


# ==================== 家庭群专属互动 ====================

## 查看家庭消息（触发随机家庭事件）


# ==================== 饮食系统 ====================

func _on_food_low() -> void:
	GameManager.monthly_food_cost += 300
	GameManager.modify_stat("sanity", -15)
	GameManager.consecutive_poor_food += 1
	GameManager.consecutive_overtime = 0
	float_stat("+300 餐饮", -300, get_global_mouse_position())
	# 连续吃土死法检查
	var death: Dictionary = GameManager.check_behavior_death()
	if death.size() > 0:
		GameManager.game_over.emit(death["title"], death["desc"])
		return
	_unlock_work_buttons()

func _on_food_mid() -> void:
	GameManager.monthly_food_cost += 800
	GameManager.modify_stat("energy", 10)
	GameManager.consecutive_poor_food = 0
	GameManager.consecutive_overtime = 0
	float_stat("+800 餐饮 +10 精力", -800, get_global_mouse_position())
	_unlock_work_buttons()

func _on_food_high() -> void:
	GameManager.monthly_food_cost += 2000
	GameManager.modify_stat("sanity", 20)
	GameManager.modify_stat("energy", 15)
	GameManager.consecutive_poor_food = 0
	GameManager.consecutive_overtime = 0
	float_stat("+2000 餐饮 +20 情绪 +15 精力", -2000, get_global_mouse_position())
	_unlock_work_buttons()

func _unlock_work_buttons() -> void:
	btn_food_low.disabled = true
	btn_food_mid.disabled = true
	btn_food_high.disabled = true
	btn_work_normal.disabled = false
	btn_work_slack.disabled = false
	btn_work_overtime.disabled = false
	_refresh_ui()

# ==================== 宝淘App（消费陷阱：0精力，只加花呗）====================

func _on_bt_skincare() -> void:
	request_payment(800, "大牌护肤套装", "消费", func() -> void:
		GameManager.modify_stat("charm", 5)
		GameManager.modify_stat("sanity", 5)
		float_stat("+5 颜值 +5 情绪", 5, get_global_mouse_position())
		show_message("大牌护肤到货！颜值+5，心情好好~")
		_refresh_debt_display()
	)

func _on_bt_fashion() -> void:
	request_payment(1500, "快时尚穿搭", "消费", func() -> void:
		GameManager.modify_stat("charm", 8)
		GameManager.modify_stat("sanity", 10)
		float_stat("+8 颜值 +10 情绪", 8, get_global_mouse_position())
		show_message("快时尚穿搭好评！颜值+8，情绪+10")
		_refresh_debt_display()
	)

func _on_close_bt() -> void:
	baotao_popup.visible = false


# ==================== 团美医美App（消费陷阱：0精力，只加花呗）====================

func _on_tm_injection() -> void:
	request_payment(6000, "水光针热玛吉", "消费", func() -> void:
		GameManager.modify_stat("charm", 25)
		GameManager.modify_stat("sanity", 20)
		float_stat("+25 颜值 +20 情绪", 25, get_global_mouse_position())
		show_message("水光针热玛吉做完！颜值暴涨，照镜子心情都变好了！")
		_refresh_debt_display()
	)

func _on_tm_surgery() -> void:
	request_payment(20000, "全脸微调手术", "消费", func() -> void:
		GameManager.modify_stat("charm", 50)
		GameManager.modify_stat("eq", -10)
		GameManager.modify_stat("sanity", 30)
		float_stat("+50 颜值 +30 情绪", 50, get_global_mouse_position())
		show_message("全脸微调完成！颜值飙升！虽然情商-10（有人说你假），但自己看着超开心！")
		_refresh_debt_display()
	)

func _on_close_tm() -> void:
	tuanmei_popup.visible = false


# ==================== 星座App ====================

func _on_close_zodiac() -> void:
	zodiac_popup.visible = false


# ==================== 贝壳找房App ====================

func _refresh_house_status() -> void:
	var housing_names: Array = ["城中村单间", "精装一居室", "CBD大平层"]
	var house_name: String = housing_names[GameManager.housing_level]
	label_house_status.text = "当前住房：%s (月租 %d)" % [house_name, GameManager.base_rent]

func _on_house_village() -> void:
	GameManager.base_rent = 1500
	GameManager.housing_level = 0
	GameManager.housing_buff_sanity = 0
	float_stat("搬家 -> 城中村", -1500, get_global_mouse_position())
	show_message("搬家成功！下个月开始交新房租 1500。")
	_refresh_house_status()

func _on_house_apartment() -> void:
	GameManager.base_rent = 4000
	GameManager.housing_level = 1
	GameManager.housing_buff_sanity = 10
	GameManager.modify_stat("charm", 5)
	float_stat("+5 颜值 搬家->精装公寓", 5, get_global_mouse_position())
	show_message("搬家成功！精装公寓，每周额外恢复 10 情绪，颜值+5！下月房租 4000。")
	_refresh_house_status()

func _on_house_luxury() -> void:
	GameManager.base_rent = 12000
	GameManager.housing_level = 2
	GameManager.housing_buff_sanity = 25
	GameManager.modify_stat("charm", 10)
	float_stat("+10 颜值 搬家->CBD大平层", 10, get_global_mouse_position())
	show_message("搬家成功！CBD大平层，每周恢复 25 情绪！下月房租 12000。")
	_refresh_house_status()

func _on_close_house() -> void:
	house_popup.visible = false


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
		show_message("精力不足，没力气滑了！")
		return
	GameManager.modify_stat("energy", -5)
	_refresh_dating_card()

func _on_like() -> void:
	if GameManager.energy < 5:
		show_message("精力不足，没力气滑了！")
		return
	GameManager.modify_stat("energy", -5)

	var roll: int = randi() % 100
	if roll < 70:
		GameManager.modify_stat("money", -500)
		GameManager.modify_stat("sanity", -15)
		float_stat("被骗 -500 金钱 -15 情绪", -500, get_global_mouse_position())
		show_message("遇到了骗子，被骗走 500 块饭钱，情绪 -15。", true)
	elif roll < 90:
		show_message("聊了两句互相拉黑，毫无波澜。", true)
	else:
		GameManager.modify_stat("eq", 2)
		float_stat("+2 情商", 2, get_global_mouse_position())
		show_message("遇到个奇葩，但你的防骗经验增加了！(情商 +2)", true)
	_refresh_dating_card()

func _on_close_dating() -> void:
	dating_popup.visible = false


# ==================== BOSS弯聘App ====================

func _on_app_job() -> void:
	_refresh_job_ui()
	job_popup.visible = true

func _refresh_job_ui() -> void:
	var degree_names: Array = ["大专", "成人本科"]
	var job_names: Array = ["初级行政", "新媒体运营", "大客户经理"]
	label_job_status.text = "当前职位：%s | 当前学历：%s | 年龄：%d岁" % [job_names[GameManager.job_level], degree_names[GameManager.degree], GameManager.age]

	## 职位A：初级行政（始终可入职）
	if GameManager.job_level == 0:
		btn_job_admin.text = "✅ 已入职 | 初级行政 (底薪 800~2500/周)"
		btn_job_admin.disabled = true
	else:
		btn_job_admin.text = "初级行政 (底薪 800~2500/周)"
		btn_job_admin.disabled = GameManager.job_level > 0

	## 职位B：新媒体运营（需学识30）
	if GameManager.job_level == 1:
		btn_job_media.text = "✅ 已入职 | 新媒体运营 (底薪 2000~6000/周)"
		btn_job_media.disabled = true
		btn_job_media.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5, 1))
	elif GameManager.intellect < 30:
		btn_job_media.text = "🔒 新媒体运营 | 学识需达到 30 (当前 %d)" % GameManager.intellect
		btn_job_media.disabled = true
		btn_job_media.add_theme_color_override("font_disabled_color", Color(0.8, 0.3, 0.3, 1))
	else:
		btn_job_media.text = "新媒体运营 (底薪 2000~6000/周) | 立即沟通"
		btn_job_media.disabled = false

	## 职位C：大客户经理（需本科学历 + 年龄<30）
	if GameManager.job_level == 2:
		btn_job_client.text = "✅ 已入职 | 大客户经理 (底薪 4000~12000/周)"
		btn_job_client.disabled = true
		btn_job_client.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5, 1))
	elif GameManager.degree < 1:
		btn_job_client.text = "🔒 大客户经理 | 硬性要求：国家承认本科学历！"
		btn_job_client.disabled = true
		btn_job_client.add_theme_color_override("font_disabled_color", Color(0.9, 0.1, 0.1, 1))
	elif GameManager.age >= 30:
		btn_job_client.text = "🔒 大客户经理 | HR已读：抱歉，本岗位倾向于培养 30 岁以下的年轻人，且您面临婚育风险。"
		btn_job_client.disabled = true
		btn_job_client.add_theme_color_override("font_disabled_color", Color(0.9, 0.1, 0.1, 1))
	else:
		btn_job_client.text = "大客户经理 (底薪 4000~12000/周) | 立即沟通"
		btn_job_client.disabled = false

func _on_job_admin() -> void:
	GameManager.job_level = 0
	float_stat("入职初级行政", 800, get_global_mouse_position())
	show_message("已入职初级行政，底薪 800~2500/周。")
	_refresh_job_ui()

func _on_job_media() -> void:
	GameManager.job_level = 1
	float_stat("跳槽成功！底薪涨至 4000", 4000, get_global_mouse_position())
	show_message("跳槽成功！新媒体运营底薪 2000~6000/周。")
	_refresh_job_ui()

func _on_job_client() -> void:
	GameManager.job_level = 2
	float_stat("成功跨越阶层！底薪涨至 8000", 8000, get_global_mouse_position())
	show_message("成功跨越阶层！大客户经理底薪 4000~12000/周。")
	_refresh_job_ui()

func _on_close_job() -> void:
	job_popup.visible = false


# ==================== 通用支付拦截系统 ====================

func request_payment(cost: int, desc: String, category: String, on_success: Callable) -> void:
	_pending_pay_cost = cost
	_pending_pay_desc = desc
	_pending_pay_category = category
	_pending_pay_callback = on_success
	label_payment_cost.text = "请选择支付方式\n（本次消费：%d 元）" % cost
	payment_popup.visible = true

func _on_pay_mix() -> void:
	var cost := _pending_pay_cost
	GameManager.money -= cost
	GameManager.add_finance(-cost, _pending_pay_desc, false)
	GameManager.add_activity(_pending_pay_category, _pending_pay_desc + "现金支付")
	_finish_payment()
func _on_pay_huabei() -> void:
	GameManager.huabei_debt += _pending_pay_cost
	GameManager.credit_debt = GameManager.huabei_debt
	GameManager.add_finance(-_pending_pay_cost, _pending_pay_desc, true)
	GameManager.add_activity(_pending_pay_category, _pending_pay_desc + "（花呗透支）")
	_finish_payment()

func _on_pay_cancel() -> void:
	payment_popup.visible = false
	_pending_pay_callback = Callable()

func _finish_payment() -> void:
	payment_popup.visible = false
	var cb := _pending_pay_callback
	_pending_pay_callback = Callable()
	if cb.is_valid():
		cb.call()
	_refresh_ui()


# ==================== 支服了宝 UI ====================

func _refresh_alipay_ui() -> void:
	label_alipay_balance.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	label_alipay_balance.text = "\u6d3b\u671f\u4f59\u989d\uff1a%d" % GameManager.money
	#花呗总欠款 = 未分期 + 分期未还本金
	var combined_debt := GameManager.huabei_debt + GameManager.huabei_installment_debt
	if combined_debt > 0:
		label_alipay_huabei.add_theme_color_override("font_color", Color(0.85, 0.15, 0.15, 1))
		var huabei_min := mini(int(GameManager.huabei_debt * 0.1 + 200), GameManager.huabei_debt)
		var debt_detail := "花呗总欠：%d" % combined_debt
		if GameManager.huabei_debt > 0:
			debt_detail += " | 未分期：%d（最低还：%d）" % [GameManager.huabei_debt, huabei_min]
		if GameManager.huabei_installment_debt > 0:
			debt_detail += " | 分期剩余本金：%d" % GameManager.huabei_installment_debt
		label_alipay_huabei.text = debt_detail
	else:
		label_alipay_huabei.add_theme_color_override("font_color", Color(0.027, 0.757, 0.376, 1))
		label_alipay_huabei.text = "花呗欠款：0（信用良好）"
	label_al_fin_safe.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	label_al_fin_safe.text = "\u7a33\u5065\u5b9d(\u7ea6+5%%/\u6708)\uff1a%d" % GameManager.invest_safe
	label_al_fin_risk.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	label_al_fin_risk.text = "\u6bd4\u7279\u5e01/\u9ad8\u98ce\u9669(-30%%~+40%%)\uff1a%d" % GameManager.invest_risk
	var proj := GameManager.get_projected_balance()

	# 分期信息显示和按钮状态
	var total_debt := GameManager.huabei_debt + GameManager.huabei_installment_debt
	label_al_summary.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	label_al_summary.text = "【预计月末资产】：%d
房租：%d | 餐饮累计：%d | 花呗总欠：%d" % [proj, GameManager.base_rent, GameManager.monthly_food_cost, total_debt]

	if GameManager.huabei_installment_months_left > 0:
		var total_installment := GameManager.huabei_installment_monthly_pay * 12
		var installment_fee := total_installment - GameManager.huabei_installment_debt
		label_al_installment.text = "【分期进行中】剩余 %d / 12 期
每月固定扣款：%d 元 | 分期本金：%d 元
手续费：%d 元 | 总还款额：%d 元" % [GameManager.huabei_installment_months_left, GameManager.huabei_installment_monthly_pay, GameManager.huabei_installment_debt, installment_fee, total_installment]
		label_al_installment.visible = true
		btn_installment.disabled = true
		btn_installment.text = "分期进行中... 剩余 %d 期" % GameManager.huabei_installment_months_left
	else:
		if GameManager.huabei_debt >= 3000:
			btn_installment.disabled = false
			btn_installment.text = "压力太大？办理 12 期账单分期 (含 15%% 总手续费)"
		else:
			btn_installment.disabled = true
			btn_installment.text = "花呗欠款不足 3000，无法办理分期"
		label_al_installment.text = "分期信息：无"

	_refresh_alipay_log()

func _refresh_alipay_log() -> void:
	for child in alipay_log_container.get_children():
		child.queue_free()
	var logs: Array = GameManager.financial_log
	var start_idx := maxi(0, logs.size() - 50)
	for i in range(start_idx, logs.size()):
		var entry: Dictionary = logs[i]
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 13)
		var sign_str := "+" if entry["amount"] >= 0 else ""
		var hb_tag := " [花呗]" if entry.get("is_huabei", false) else ""
		lbl.text = "[第%d周] %s%s：¥%s%d" % [entry["week"], entry["desc"], hb_tag, sign_str, entry["amount"]]
		if entry["amount"] >= 0:
			lbl.add_theme_color_override("font_color", Color(0.09, 0.55, 0.27, 1))
		else:
			lbl.add_theme_color_override("font_color", Color.RED)
		alipay_log_container.add_child(lbl)

func _on_close_alipay() -> void:
	alipay_popup.visible = false

# 支服了宝 - 理财操作
func _on_al_fin_safe_in() -> void:
	if GameManager.money < 500:
		show_message("活期余额不足 500，无法存入！")
		return
	GameManager.money -= 500
	GameManager.invest_safe += 500
	GameManager.add_finance(-500, "存入稳健宝", false)
	float_stat("-500 存入稳健宝", -500, get_global_mouse_position())
	show_message("成功存入 500 到稳健宝！")
	_refresh_alipay_ui()

func _on_al_fin_risk_in() -> void:
	if GameManager.money < 500:
		show_message("活期余额不足 500，无法存入！")
		return
	GameManager.money -= 500
	GameManager.invest_risk += 500
	GameManager.add_finance(-500, "存入高风险基金", false)
	float_stat("-500 存入高风险", -500, get_global_mouse_position())
	show_message("成功存入 500 到高风险基金！祝你好运...")
	_refresh_alipay_ui()

func _on_al_fin_safe_out() -> void:
	if GameManager.invest_safe <= 0:
		show_message("稳健宝里没有钱可以取出！")
		return
	var amount := GameManager.invest_safe
	GameManager.money += amount
	GameManager.invest_safe = 0
	GameManager.add_finance(amount, "取出稳健宝", false)
	float_stat("+%d 取出稳健宝" % amount, amount, get_global_mouse_position())
	show_message("已从稳健宝取出 %d" % amount)
	_refresh_alipay_ui()

func _on_al_fin_risk_out() -> void:
	if GameManager.invest_risk <= 0:
		show_message("高风险基金里没有钱可以取出！")
		return
	var amount := GameManager.invest_risk
	GameManager.money += amount
	GameManager.invest_risk = 0
	GameManager.add_finance(amount, "取出高风险基金", false)
	float_stat("+%d 取出高风险" % amount, amount, get_global_mouse_position())
	show_message("已从高风险基金取出 %d" % amount)
	_refresh_alipay_ui()



# ==================== 花呗还款与分期 ====================

## 主动还款：解析输入金额，校验后扣款减债
## 主动还款：先还未分期，再还分期本金（分期本金还清则自动结束分期）
func _on_repay_huabei() -> void:
	var input_text: String = input_repay_amount.text.strip_edges()
	if input_text == "":
		show_message("请输入还款金额！")
		return
	var amount: int = input_text.to_int()
	if amount <= 0:
		show_message("请输入有效的正整数金额！")
		return
	if amount > GameManager.money:
		show_message("活期余额不足！当前余额：%d" % GameManager.money)
		return
	var combined_debt := GameManager.huabei_debt + GameManager.huabei_installment_debt
	if combined_debt <= 0:
		show_message("花呗没有欠款，无需还款！")
		return

	var remaining := mini(amount, combined_debt)
	GameManager.money -= remaining
	var repay_msg := ""

	# 第一步：先还未分期的花呗欠款
	if GameManager.huabei_debt > 0 and remaining > 0:
		var to_huabei := mini(remaining, GameManager.huabei_debt)
		GameManager.huabei_debt -= to_huabei
		GameManager.credit_debt = GameManager.huabei_debt
		remaining -= to_huabei
		repay_msg += "还未分期欠款 %d 元" % to_huabei

	# 第二步：再还分期本金（提前还清则自动结束分期）
	if GameManager.huabei_installment_debt > 0 and remaining > 0:
		var to_installment := mini(remaining, GameManager.huabei_installment_debt)
		GameManager.huabei_installment_debt -= to_installment
		remaining -= to_installment
		if repay_msg != "":
			repay_msg += "
"
		repay_msg += "还分期本金 %d 元" % to_installment
		# 分期本金还清了，自动结束分期
		if GameManager.huabei_installment_debt <= 0:
			GameManager.huabei_installment_months_left = 0
			GameManager.huabei_installment_monthly_pay = 0
			if repay_msg != "":
				repay_msg += "
"
			repay_msg += "分期已提前还清！"

	var actual_repay := mini(amount, combined_debt)
	GameManager.add_finance(-actual_repay, "花呗主动还款", false)
	input_repay_amount.text = ""
	float_stat("还款 -%d" % actual_repay, -actual_repay, get_global_mouse_position())
	var still_owe := GameManager.huabei_debt + GameManager.huabei_installment_debt
	show_message("成功还款 %d 元！
%s
剩余欠款：%d 元" % [actual_repay, repay_msg, still_owe])
	_refresh_alipay_ui()


func _on_installment() -> void:
	if GameManager.huabei_debt < 3000:
		show_message("花呗欠款不足 3000，无法办理分期！")
		return
	if GameManager.huabei_installment_months_left > 0:
		show_message("已有进行中的分期！剩余 %d 期。" % GameManager.huabei_installment_months_left)
		return

	# 计算分期：总手续费15%，分12期
	var principal: int = GameManager.huabei_debt
	var total_with_fee: int = int(float(principal) * 1.15)
	var monthly_pay: int = int(float(total_with_fee) / 12.0)
	GameManager.huabei_installment_debt = principal
	GameManager.huabei_installment_months_left = 12
	GameManager.huabei_installment_monthly_pay = monthly_pay
	GameManager.huabei_debt = 0
	GameManager.credit_debt = 0
	var fee_amount: int = total_with_fee - principal
	GameManager.add_finance(-total_with_fee, "办理12期花呗分期(含15%%手续费)", true)
	GameManager.add_activity("消费", "办理了花呑12期分期，本金 %d + 手续费 %d = 共需还款 %d，每月扣 %d" % [principal, fee_amount, total_with_fee, monthly_pay])
	show_message("分期成功！
分期本金：%d 元
手续费(15%%)：%d 元
总还款：%d 元
每月固定扣款：%d 元，共12期" % [principal, fee_amount, total_with_fee, monthly_pay])
	_refresh_alipay_ui()



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
	float_stat("花呗 +%d" % imp["huabei"], -imp["huabei"], get_global_mouse_position())
	show_message("下单了...短暂的快乐之后是更深的空虚。", true)
	late_night_popup.visible = false
	_proceed_next_week()

## 按钮 B：硬抗！强行闭眼到天亮
func _on_emo_sleep() -> void:
	GameManager.modify_stat("charm", -2)
	GameManager.modify_stat("sanity", -10)
	GameManager.modify_stat("energy", -20)
	GameManager.add_activity("日常", "失眠了一整夜，第二天感觉身体被掏空。")
	float_stat("颜值-2 情绪-10 精力-20", -20, get_global_mouse_position())
	show_message("辗转反侧到天亮，气色极差，整个人像被抽空了...", true)
	late_night_popup.visible = false
	_proceed_next_week()
