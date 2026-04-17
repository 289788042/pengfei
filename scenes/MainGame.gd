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
@onready var btn_loc_library: Button = %Btn_Loc_Library
@onready var btn_loc_gym: Button = %Btn_Loc_Gym
@onready var btn_loc_bar: Button = %Btn_Loc_Bar
@onready var btn_loc_home: Button = %Btn_Loc_Home
@onready var btn_close_loc: Button = %Btn_CloseLoc

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
@onready var label_chat_name: Label = %LabelChatName
@onready var chat_msg_container: VBoxContainer = %ChatMsgContainer
@onready var chat_input_field: Button = %ChatInputField
@onready var btn_chat_back: Button = %Btn_ChatBack
@onready var moments_list: VBoxContainer = %MomentsList

## 微信颜色常量
const WC_GREEN: Color = Color(0.027, 0.757, 0.376, 1)
const WC_BUBBLE_SELF: Color = Color(0.584, 0.925, 0.412, 1)
const WC_BG: Color = Color(0.929, 0.929, 0.929, 1)
const WC_TAB_BG: Color = Color(0.969, 0.969, 0.969, 1)
const WC_RED: Color = Color(0.98, 0.318, 0.318, 1)
const WC_TEXT_PRIMARY: Color = Color(0.1, 0.1, 0.1, 1)
const WC_TEXT_SECONDARY: Color = Color(0.55, 0.55, 0.55, 1)

## 微信当前打开的聊天NPC ID
var _current_chat_npc: String = ""
var _chat_menu_panel: PanelContainer = null
var _current_tab: int = 0

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

var current_phase: Phase = Phase.WEEKDAY
var _pending_event: Dictionary = {}
var _pending_callback: Callable = Callable()
## 存储每个NPC的聊天条目UI节点引用
var _chat_items: Dictionary = {}

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

## 家庭群随机事件池
var _family_events: Array = [
	{
		"title": "坏掉的冰箱",
		"desc": "妈：家里的冰箱又坏了，你爸说修修还能用，但我觉得也该换了...\n\n你看着视频里妈妈笑嘻嘻的脸，突然注意到她身后那个用了十年的老冰箱，门关不严，用胶带缠着。",
		"choices": [
			{"label": "转5000块换个新的", "effects": {"money": -5000, "sanity": 30}, "affection_gain": 30, "msg": "妈妈发了个哭泣的表情包，说：'闺女长大了！'\n（金钱 -5000, 亲情 +30, 情绪 +30, 获得【妈妈的关爱】3周）", "set_mom_care": 3},
			{"label": "让他们自己想办法", "effects": {"sanity": -10}, "affection_gain": -10, "msg": "你挂了电话，心里堵得慌。\n（亲情 -10, 情绪 -10, 触发【愧疚】3周）", "set_guilt": 3},
		],
	},
	{
		"title": "无效的相亲局",
		"desc": "妈：隔壁王阿姨的儿子在深圳当程序员，年薪50万，人很老实的！\n\n你妈兴冲冲地推来了一个微信名片。你点开朋友圈一看——全是'奋斗逼语录'和健身自拍。再一看共同好友：你的高中同学、你前男友、还有你老板。",
		"choices": [
			{"label": "加微信聊聊看吧", "effects": {"eq": 5, "sanity": -20}, "affection_gain": 0, "msg": "加了微信，对方第一句话就是：'你月薪多少？能接受异地吗？'\n（情商 +5, 情绪 -20）"},
			{"label": "明确拒绝，别烦我", "effects": {"sanity": -10}, "affection_gain": -5, "msg": "你妈沉默了五秒：'行吧，你自己的事自己决定。'\n（亲情 -5, 情绪 -10, 触发【愧疚】2周）", "set_guilt": 2},
		],
	},
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
	GameManager.lin_fan_ending_check.connect(_on_lin_fan_ending_check)

	btn_work_normal.pressed.connect(_on_work_normal)
	btn_work_slack.pressed.connect(_on_work_slack)
	btn_work_overtime.pressed.connect(_on_work_overtime)
	btn_event_confirm.pressed.connect(_on_event_confirmed)
	btn_next_week.pressed.connect(_on_btn_next_week)
	btn_loc_library.pressed.connect(_on_loc_library)
	btn_loc_gym.pressed.connect(_on_loc_gym)
	btn_loc_bar.pressed.connect(_on_loc_bar)
	btn_loc_home.pressed.connect(_on_loc_home)
	btn_close_loc.pressed.connect(_on_close_loc)
	btn_close_wechat.pressed.connect(_on_close_wechat)
	_build_chat_items()
	btn_wc_back.pressed.connect(_on_close_wechat)
		# btn_wc_search removed
	tab_contacts.pressed.connect(_on_wc_tab.bind(0))
	tab_moments.pressed.connect(_on_wc_tab.bind(1))
	btn_chat_back.pressed.connect(_on_chat_back)
	chat_input_field.pressed.connect(_on_chat_send)
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
				if dialog_box.get_global_rect().has_point(get_global_mouse_position()):
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
	if wechat_menu.visible:
		if wc_chat_view.visible:
			_on_chat_back()
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
	label.position = start_pos
	label.z_index = 100
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", start_pos.y - 60, 1.0)
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
	wechat_menu.visible = false
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
	_refresh_wechat_ui()


func _refresh_wechat_ui() -> void:
	for npc_id in _chat_items:
		var item: Dictionary = _chat_items[npc_id]
		var npc_data: Dictionary = GameManager.npcs[npc_id]
		var is_unlocked: bool = npc_data["unlocked"] and not npc_data.get("blocked", false)
		item["root"].visible = is_unlocked
		if not is_unlocked:
			continue
		## 更新聊天列表项的预览文字
		var preview_text: String = ""
		if npc_id == "family_group":
			preview_text = "亲情: %d" % npc_data["affection"]
			if GameManager.guilt_debuff_weeks > 0:
				preview_text = "你总觉得对不住爸妈... (愧疚 %d周)" % GameManager.guilt_debuff_weeks
			elif GameManager.mom_care_buff_weeks > 0:
				preview_text = "妈妈寄来了家乡特产和一箱牛奶~"
		elif npc_id == "wang_teacher":
			if GameManager.night_school_progress >= 12:
				preview_text = "已毕业 ✅ 恭喜！"
			else:
				preview_text = "学分: %d/12" % GameManager.night_school_progress
		elif npc_id == "xiao_ya":
			preview_text = "闺蜜好感: %d" % npc_data["affection"]
		else:
			preview_text = "进度: %d/50" % npc_data["affection"]
			if npc_data["warning_msg"] != "" and GameManager.eq >= 30:
				preview_text = "[⚠] " + npc_data["warning_msg"]
		## 如果有消息记录，显示最后一条
		var msgs: Array = npc_data.get("messages", [])
		if msgs.size() > 0:
			preview_text = msgs[-1]["text"]
		item["label_preview"].text = preview_text
	var unlocked_count: int = 0
	for npc_id in GameManager.npcs:
		if GameManager.npcs[npc_id]["unlocked"] and not GameManager.npcs[npc_id].get("blocked", false):
			unlocked_count += 1
	label_wc_title.text = "微信 (%d)" % unlocked_count



func _refresh_debt_display() -> void:
	var debt_text := "当前花呗欠款：%d" % GameManager.huabei_debt
	label_bt_debt.text = debt_text
	label_tm_debt.text = debt_text


# ==================== 信号回调 ====================

func _on_stats_updated() -> void:
	_refresh_ui()

func _on_week_advanced(_new_week: int) -> void:
	_refresh_ui()

func _on_npc_unlocked(_id: String, npc_name: String) -> void:
	show_message("[%s] 通过群聊添加了你的微信！" % npc_name, true)
	_build_chat_items()

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


func _on_lin_fan_ending_check() -> void:
	# 全屏遮罩
	var overlay := ColorRect.new()
	overlay.name = "EndingChoiceOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.z_index = 50
	add_child(overlay)

	# 居中容器
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	# 弹窗面板
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.98, 0.97, 0.95, 1)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# 标题
	var title_label := Label.new()
	title_label.text = "【彩礼大考】"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color.BLACK)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# 描述
	var desc_label := Label.new()
	desc_label.text = (
		"你拨通了家里的电话，说自己想结婚了。\n\n"
		+ "你妈在电话那头沉默了很久，最后说：\n"
		+ "'闺女，你想清楚了？那小子...行吧，只要你高兴就好。'\n"
		+ "'不过，咱家这边的规矩你也知道...'\n\n"
		+ "【当前存款：%d】" % GameManager.money
	)
	desc_label.add_theme_font_size_override("font_size", 15)
	desc_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# 选项1：风风光光结婚
	var btn_marry := Button.new()
	btn_marry.text = "拿出50万存款，风风光光办婚礼"
	btn_marry.custom_minimum_size = Vector2(0, 44)
	var marry_style := StyleBoxFlat.new()
	marry_style.bg_color = Color(1.0, 0.4, 0.4, 1)
	marry_style.set_corner_radius_all(8)
	btn_marry.add_theme_stylebox_override("normal", marry_style)
	btn_marry.add_theme_color_override("font_color", Color.WHITE)
	btn_marry.add_theme_font_size_override("font_size", 15)
	btn_marry.pressed.connect(_on_ending_choice.bind(true))
	vbox.add_child(btn_marry)

	# 选项2：算了
	var btn_giveup := Button.new()
	btn_giveup.text = "算了，别为难父母了"
	btn_giveup.custom_minimum_size = Vector2(0, 44)
	var giveup_style := StyleBoxFlat.new()
	giveup_style.bg_color = Color(0.5, 0.5, 0.5, 1)
	giveup_style.set_corner_radius_all(8)
	btn_giveup.add_theme_stylebox_override("normal", giveup_style)
	btn_giveup.add_theme_color_override("font_color", Color.WHITE)
	btn_giveup.add_theme_font_size_override("font_size", 15)
	btn_giveup.pressed.connect(_on_ending_choice.bind(false))
	vbox.add_child(btn_giveup)


## 结局选择回调
func _on_ending_choice(is_true_love: bool) -> void:
	var overlay_node := get_node_or_null("EndingChoiceOverlay")
	if overlay_node:
		overlay_node.queue_free()
	GameManager.finalize_lin_fan_ending(is_true_love)


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
	restart_style.set_corner_radius_all(10)
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
	match ending_type:
		"true_love":
			label_ending_title.text = "【真爱结局】平凡的幸福"
			label_ending_content.text = (
				"35岁这年，你没有成为亿万富翁，也没有住进大别墅。\n"
				+ "但当你下班推开家门，看到林凡在厨房忙碌的背影，闻到饭菜的香味。\n"
				+ "你突然觉得，在这个诺大的城市里，有一盏灯为你而亮，其实就已经足够了。\n\n"
				+ "婚礼那天，你爸偷偷抹了一把眼泪，嘴上还在说：'这小子，配不上我闺女。'\n"
				+ "你妈塞给你一张银行卡，说：'密码是你生日。'\n"
				+ "林凡在一旁手足无措地笑，阳光正好打在他脸上。"
			)
		"regret":
			label_ending_title.text = "【遗憾结局】差一点的幸福"
			label_ending_content.text = (
				"35岁这年，你终于攒够了勇气，却没有攒够存款。\n"
				+ "你看着银行卡上的余额，拨通了林凡的电话。\n"
				+ "他沉默了很久，说：'没关系，我等你。'\n"
				+ "但你心里清楚，有些话现在说不出，以后就更说不出了。\n\n"
				+ "你们没有分手，但也没有结婚。\n"
				+ "后来你在朋友圈看到他晒了婚纱照，新娘笑得很好看。\n"
				+ "你点了个赞，然后把手机翻了过去。"
			)
		"elite":
			label_ending_title.text = "【精英结局】孤独的赢家"
			label_ending_content.text = (
				"35岁这年，你如愿成为了别人眼中的精英。\n"
				+ "但看着空荡荡的高级公寓，你想起当年在城中村楼下，那个淋着雨给你送粥的笨蛋。\n"
				+ "你赢得了世界，却唯独弄丢了那个能让你安心哭泣的人。"
			)
	var family_lv: int = GameManager.npcs["family_group"]["level"]
	label_ending_age.text = "终局统计 | 年龄：%d岁 | 金钱：%d | 林凡 Lv.%d | 顾凛 Lv.%d | 家庭 Lv.%d" % [
		GameManager.age, GameManager.money,
		GameManager.npcs["lin_fan"]["level"],
		GameManager.npcs["gu_lin"]["level"],
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
	wechat_menu.visible = false
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
	panel_style.set_corner_radius_all(12)
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
	location_menu.visible = true

func _on_app_wechat() -> void:
	_refresh_wechat_ui()
	_on_wc_tab(0)
	wechat_menu.mouse_filter = Control.MOUSE_FILTER_PASS
	if not wechat_menu.gui_input.is_connected(_on_wechat_gui_input):
		wechat_menu.gui_input.connect(_on_wechat_gui_input)
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
	GameManager.modify_stat("energy", -20)
	GameManager.modify_stat("intellect", 3)
	GameManager.modify_stat("sanity", 5)
	float_stat("+3 学识 +5 情绪", 5, get_global_mouse_position())
	GameManager.add_activity("提升", "在图书馆读书，学识+3，情绪+5")
	_visit_location("library", "在图书馆度过了一个充实的下午。")

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


# ==================== 微信 ====================
func _build_chat_items() -> void:
	for child in chat_list_container.get_children():
		child.queue_free()
	_chat_items.clear()
	var sorted_ids: Array = GameManager.npcs.keys()
	sorted_ids.erase("family_group")
	sorted_ids.push_front("family_group")
	for npc_id in sorted_ids:
		var npc_data: Dictionary = GameManager.npcs[npc_id]
		var item := _create_chat_item(npc_id, npc_data)
		chat_list_container.add_child(item)
		var info_vbox: VBoxContainer = item.get_child(1).get_child(2)
		_chat_items[npc_id] = {
			"root": item,
			"label_name": info_vbox.get_child(0).get_child(0) as Label,
			"label_preview": info_vbox.get_child(1) as Label,
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
	if npc_id == "family_group":
		avatar.color = Color(1.0, 0.6, 0.2, 1)
	elif npc_id == "xiao_ya":
		avatar.color = Color(0.85, 0.35, 0.55, 1)
	elif npc_id == "wang_teacher":
		avatar.color = Color(0.12, 0.35, 0.75, 1)
	elif npc_id == "chen_yu":
		avatar.color = Color(0.2, 0.5, 0.8, 1)
	elif npc_id == "gu_lin":
		avatar.color = Color(0.4, 0.4, 0.4, 1)
	else:
		avatar.color = Color(0.3, 0.3, 0.3, 1)
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


func _on_wechat_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if wc_chat_view.visible:
			_on_chat_back()
			return
		_on_close_wechat()

func _on_close_wechat() -> void:
	if wc_chat_view.visible:
		_on_chat_back()
		return
	wechat_menu.visible = false


	# ==================== 微信新版 UI 函数 ====================

func _on_wc_tab(tab_idx: int) -> void:
	_current_tab = tab_idx
	wc_chat_list_view.visible = (tab_idx == 0)
	wc_moments_content.visible = (tab_idx == 1)
	## 更新tab栏高亮颜色
	for i in [tab_contacts, tab_moments]:
		i.add_theme_color_override("font_color", WC_TEXT_SECONDARY)
	match tab_idx:
		0: tab_contacts.add_theme_color_override("font_color", WC_GREEN)
		1:
			tab_moments.add_theme_color_override("font_color", WC_GREEN)
			_build_moments()
	## 隐藏子视图
	wc_chat_view.visible = false


func _open_chat_view(npc_id: String) -> void:
	_current_chat_npc = npc_id
	var npc_data: Dictionary = GameManager.npcs[npc_id]
	label_chat_name.text = npc_data["name"]
	## 渲染消息气泡
	while chat_msg_container.get_child_count() > 0:
		var _c := chat_msg_container.get_child(0)
		chat_msg_container.remove_child(_c)
		_c.free()
	var msgs: Array = npc_data.get("messages", [])
	for msg in msgs:
		_add_chat_bubble(msg["sender"], msg["text"])
	## 设置操作按钮
	## 显示聊天视图
	wc_chat_view.mouse_filter = Control.MOUSE_FILTER_STOP
	wc_chat_view.visible = true

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

	chat_msg_container.add_child(wrapper)


func _get_npc_avatar_color(npc_id: String) -> Color:
	match npc_id:
		"family_group": return Color(1.0, 0.6, 0.2, 1)
		"xiao_ya": return Color(0.85, 0.35, 0.55, 1)
		"wang_teacher": return Color(0.12, 0.35, 0.75, 1)
		"chen_yu": return Color(0.2, 0.5, 0.8, 1)
		"gu_lin": return Color(0.4, 0.4, 0.4, 1)
		_: return Color(0.3, 0.3, 0.3, 1)

func _on_chat_back() -> void:
	wc_chat_view.visible = false
	_current_chat_npc = ""

func _on_chat_send() -> void:
	if _current_chat_npc == "":
		return
	_show_chat_action_menu()


func _show_chat_action_menu() -> void:
	## 清除旧菜单
	if is_instance_valid(_chat_menu_panel):
		_chat_menu_panel.queue_free()
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
	## 根据 NPC 添加选项
	match _current_chat_npc:
		"family_group":
			_add_menu_btn(vbox, "查看家庭消息", func() -> void: _on_family_interact())
		"wang_teacher":
			if GameManager.night_school_progress >= 12:
				_add_menu_btn(vbox, "已毕业 ✅", func() -> void: pass)
			else:
				_add_menu_btn(vbox, "报名冲刺班 (-50精力, -1000金)", func() -> void: _on_chat_wang_teacher())
		"xiao_ya":
			match GameManager.xiaoya_state:
				0: _add_menu_btn(vbox, "跟她吐槽工作 (-10精力)", func() -> void: _on_chat_xiao_ya())
				1: _add_menu_btn(vbox, "赴约高级下午茶 (-20精力, -800金)", func() -> void: _on_chat_xiao_ya())
				2: _add_menu_btn(vbox, "听她哭诉渣男 (-20精力)", func() -> void: _on_chat_xiao_ya())
		_:
			_add_menu_btn(vbox, "吐槽 (-10精力)", func() -> void: _on_chat_npc(_current_chat_npc))
			if npc_data["level"] >= 2:
				_add_menu_btn(vbox, "约会", func() -> void: _on_date_npc(_current_chat_npc))
	## 删除好友
	_add_menu_btn(vbox, "删除好友", Color(1, 0.2, 0.2, 1), func() -> void: _do_delete_friend())
	## 取消
	_add_menu_btn(vbox, "取消", func() -> void:
		if is_instance_valid(_chat_menu_panel):
			_chat_menu_panel.queue_free()
			_chat_menu_panel = null)
	## 显示菜单
	wc_chat_view.add_child(_chat_menu_panel)
	var input_pos := chat_input_field.get_global_position()
	_chat_menu_panel.global_position = Vector2(input_pos.x, input_pos.y - _chat_menu_panel.size.y - 4)


func _send_text_message(text: String) -> void:
	chat_input_field.text = ""
	_add_chat_bubble("self", text)
	var npc_data: Dictionary = GameManager.npcs[_current_chat_npc]
	npc_data["messages"].append({"sender": "self", "text": text})
	var reply := _get_npc_auto_reply(_current_chat_npc)
	await get_tree().create_timer(0.5).timeout
	_add_chat_bubble("npc", reply)
	npc_data["messages"].append({"sender": "npc", "text": reply})
	_refresh_wechat_ui()


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
	var replies: Dictionary = {
		"family_group": ["你妈：吃饭了没？", "你爸：注意身体。", "妈：今天降温了，多穿点！", "爸：工作顺利吗？"],
		"lin_fan": ["哈哈", "嗯嗯", "你今天上班累不累？", "发了个表情包", "刚下班"],
		"chen_yu": ["👌", "在忙", "嗯", "你也早点休息", "看到你朋友圈了"],
		"gu_lin": ["好的", "最近行业变化很大", "有空聊聊", "嗯"],
		"zhang_minghao": ["兄弟！明天吃啥", "最近项目不错", "加油干！", "发了个搞笑图片"],
		"wang_teacher": ["好好学习！", "下周记得来上课", "加油！毕业指日可待"],
		"xiao_ya": ["天哪！！！", "哈哈哈哈哈", "姐妹我跟你讲", "又是想躺平的一天", "你猜怎么着"],
	}
	var pool: Array = replies.get(npc_id, ["嗯", "好的"])
	return pool[randi() % pool.size()]









func _build_contacts_list() -> void:
	for child in wc_contact_list.get_children():
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
		if npc_id == "family_group":
			avatar.color = Color(1.0, 0.6, 0.2, 1)
		elif npc_id == "xiao_ya":
			avatar.color = Color(0.85, 0.35, 0.55, 1)
		elif npc_id == "wang_teacher":
			avatar.color = Color(0.12, 0.35, 0.75, 1)
		elif npc_id == "chen_yu":
			avatar.color = Color(0.2, 0.5, 0.8, 1)
		elif npc_id == "gu_lin":
			avatar.color = Color(0.4, 0.4, 0.4, 1)
		else:
			avatar.color = Color(0.3, 0.3, 0.3, 1)
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
		wc_contact_list.add_child(row)

func _build_moments() -> void:
	for child in moments_list.get_children():
		child.queue_free()
	## 为每个解锁的NPC生成朋友圈动态
	var moments_data: Dictionary = {
		"family_group": {"text": "妈：今天包了饺子，等你回来吃！🏠", "likes": 12},
		"lin_fan": {"text": "城中村又停水了... 什么时候是个头", "likes": 3},
		"chen_yu": {"text": "", "likes": 88},
		"gu_lin": {"text": "今天在陆家嘴参加了行业峰会。认真思考下一个十年。", "likes": 256},
		"zhang_minghao": {"text": "兄弟们！年底冲业绩！冲冲冲！🔥", "likes": 15},
		"wang_teacher": {"text": "教育改变命运！尚德夜校春季班火热招生中！", "likes": 42},
		"xiao_ya": {"text": "", "likes": 67},
	}
	for npc_id in GameManager.npcs:
		var npc_data: Dictionary = GameManager.npcs[npc_id]
		if not npc_data["unlocked"] or npc_data.get("blocked", false):
			continue
		var data: Dictionary = moments_data.get(npc_id, {"text": "...", "likes": 0})
		## 特殊：陈宇和小雅的朋友圈根据状态变化
		if npc_id == "chen_yu":
			data["text"] = "[图片]"
		elif npc_id == "xiao_ya":
			match GameManager.xiaoya_state:
				0: data["text"] = "和室友一起看综艺笑到肚子疼😂"
				1: data["text"] = "下午茶时光☕ 今天的心情和拿铁一样甜"
				2: data["text"] = "有些人不值得... 再也不相信爱情了💔"
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
		if npc_id == "family_group":
			avatar.color = Color(1.0, 0.6, 0.2, 1)
		elif npc_id == "xiao_ya":
			avatar.color = Color(0.85, 0.35, 0.55, 1)
		elif npc_id == "wang_teacher":
			avatar.color = Color(0.12, 0.35, 0.75, 1)
		elif npc_id == "chen_yu":
			avatar.color = Color(0.2, 0.5, 0.8, 1)
		elif npc_id == "gu_lin":
			avatar.color = Color(0.4, 0.4, 0.4, 1)
		else:
			avatar.color = Color(0.3, 0.3, 0.3, 1)
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
		content_label.text = data["text"]
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
		like_label.text = "❤ %d" % data["likes"]
		like_label.add_theme_color_override("font_color", WC_TEXT_SECONDARY)
		like_label.add_theme_font_size_override("font_size", 12)
		like_hbox.add_child(like_label)
		## 底部间距
		var bottom_space := Control.new()
		bottom_space.custom_minimum_size = Vector2(0, 10)
		post_vbox.add_child(bottom_space)
		moments_list.add_child(post)
	## 分隔线
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 1)
	moments_list.add_child(sep)


# ==================== 家庭群专属互动 ====================

## 查看家庭消息（触发随机家庭事件）
func _on_family_interact() -> void:
	var event_idx: int = randi() % _family_events.size()
	_show_family_event(event_idx)


## 显示家庭事件弹窗
func _show_family_event(event_idx: int) -> void:
	var event: Dictionary = _family_events[event_idx]

	# 全屏遮罩
	var overlay := ColorRect.new()
	overlay.name = "FamilyEventOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.z_index = 50
	add_child(overlay)

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

	# 选项按钮
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
			show_message("金钱不足，无法这么做！")
			return

	# 应用属性效果
	for stat in effects:
		GameManager.modify_stat(stat, effects[stat])

	# 好感度变化
	var affection_gain: int = choice.get("affection_gain", 0)
	if affection_gain != 0:
		GameManager.add_npc_affection("family_group", affection_gain)

	# Buff/Debuff设置
	if choice.get("set_mom_care", 0) > 0:
		GameManager.mom_care_buff_weeks = choice["set_mom_care"]
	if choice.get("set_guilt", 0) > 0:
		GameManager.guilt_debuff_weeks = choice["set_guilt"]

	# 显示结果消息
	show_message(choice["msg"], true)

	# 移除弹窗
	var overlay_node := get_node_or_null("FamilyEventOverlay")
	if overlay_node:
		overlay_node.queue_free()

	_refresh_wechat_ui()


# ==================== NPC 聊天（NPC差异化逻辑 + 门槛校验）====================

func _on_chat_npc(npc_id: String) -> void:
	if GameManager.energy < 10:
		show_message("精力不足，没力气聊天了！")
		return

	var affection_gain: int = 5
	var sanity_change: int = 0
	var msg: String = ""

	match npc_id:
		"lin_fan":
			# 林凡聊天：50%温馨 / 50%踩雷
			var lin_fan_roll: int = randi() % 100
			if lin_fan_roll < 50:
				sanity_change = 15
				msg = "林凡给你发了个搞笑表情包，心情变好了！"
			elif lin_fan_roll < 80:
				sanity_change = -10
				msg = "你随口说起加班累，林凡却说：'那你辞职呗，我养你啊。'你不确定他是不是在开玩笑。"
			else:
				sanity_change = -15
				msg = "林凡又聊到城中村那个讨厌的邻居，你劝他搬他说没钱。两个人都沉默了。"
		"chen_yu":
			if GameManager.charm < 30:
				show_message("颜值不够(需30)，陈宇根本不回你消息...")
				return
			sanity_change = 25
			msg = "陈宇夸你今天照片好看，聊得挺开心。"
		"gu_lin":
			if GameManager.charm < 70 or GameManager.intellect < 60:
				show_message("谈吐或外貌未达顾凛的社交门槛(需颜值70+学识60)...")
				return
			sanity_change = -5
			GameManager.modify_stat("intellect", 5)
			msg = "和顾凛聊了行业趋势，压力山大但学到不少。"
		"zhang_minghao":
			sanity_change = 5
			affection_gain = 3
			msg = "张明浩又在画大饼，你情商在线没上当。"
		_:
			sanity_change = 5
			msg = "聊天结束。"

	GameManager.modify_stat("energy", -10)
	GameManager.modify_stat("sanity", sanity_change)
	if affection_gain > 0:
		GameManager.add_npc_affection(npc_id, affection_gain)
	float_stat("+%d 好感 %s%d 情绪" % [affection_gain, "+" if sanity_change >= 0 else "", sanity_change], affection_gain, get_global_mouse_position())
	## 添加聊天消息记录
	var npc_data: Dictionary = GameManager.npcs[npc_id]
	npc_data["messages"].append({"sender": "npc", "text": msg})
	## 在聊天界面显示气泡
	if _current_chat_npc == npc_id and wc_chat_view.visible:
		_add_chat_bubble("npc", msg)
	show_message(msg, true)
	_refresh_wechat_ui()


## 约会（NPC差异化：金钱花费/收益各不同）
func _on_date_npc(npc_id: String) -> void:
	if GameManager.energy < 50:
		show_message("精力不足，无法约会！(需要50精力)")
		return

	var npc_data: Dictionary = GameManager.npcs[npc_id]
	var npc_name: String = npc_data["name"]
	var money_cost: int = 0
	var sanity_change: int = 0
	var affection_gain: int = 0
	var msg: String = ""

	match npc_id:
		"lin_fan":
			money_cost = 0
			sanity_change = 30
			affection_gain = 30
			msg = "和林凡在城中村楼下散步聊天，简单却温馨。"
		"chen_yu":
			money_cost = 800
			sanity_change = 50
			affection_gain = 20
			msg = "和陈宇去了网红餐厅，你抢着买了单..."
		"gu_lin":
			money_cost = 0
			sanity_change = -20
			affection_gain = 10
			msg = "顾凛带你去了米其林餐厅，送了个名牌包，但你格格不入..."
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
		if the_npc == "gu_lin":
			GameManager.modify_stat("charm", 10)
			float_stat("+10 颜值 +%d 好感", the_aff, get_global_mouse_position())
		else:
			float_stat("+%d 好感 %s%d 情绪" % [the_aff, "+" if the_sanity >= 0 else "", the_sanity], the_aff, get_global_mouse_position())
		show_message(the_msg, true)
		GameManager.add_activity("社交", the_msg)
		_refresh_wechat_ui()

	if the_cost > 0:
		request_payment(the_cost, "%s约会" % npc_name, "社交", do_date)
	else:
		do_date.call()


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


# ==================== 旧购物系统 ====================










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


# ==================== 钱多多理财App ====================














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


# ==================== 夜校王老师 ====================

func _on_chat_wang_teacher() -> void:
	if GameManager.night_school_progress >= 12:
		show_message("你已经毕业了！快去 BOSS弯聘 看看新机会吧！")
		return
	if GameManager.energy < 50:
		show_message("精力不足（需50），没法上课了！")
		return
	request_payment(1000, "夜校报名冲刺班", "提升", func() -> void:
		GameManager.modify_stat("energy", -50)
		GameManager.modify_stat("sanity", -10)
		GameManager.night_school_progress += 1
		if GameManager.night_school_progress >= 12:
			GameManager.degree = 1
			_show_graduation_popup()
		else:
			show_message("王老师：恭喜完成本周课程！当前学分进度：%d/12。" % GameManager.night_school_progress)
			float_stat("+1 学分 | 进度 %d/12" % GameManager.night_school_progress, 1, get_global_mouse_position())
		_refresh_wechat_ui()
	)


## 夜校毕业弹窗
func _show_graduation_popup() -> void:
	var overlay := ColorRect.new()
	overlay.name = "GraduationOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.z_index = 50
	add_child(overlay)

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
		var node := get_node_or_null("GraduationOverlay")
		if node:
			node.queue_free()
	)
	vbox.add_child(btn)


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
	var cash_part := mini(GameManager.money, cost)
	var huabei_part := cost - cash_part
	GameManager.money -= cash_part
	if cash_part > 0:
		GameManager.add_finance(-cash_part, _pending_pay_desc, false)
	if huabei_part > 0:
		GameManager.huabei_debt += huabei_part
		GameManager.credit_debt = GameManager.huabei_debt
		GameManager.add_finance(-huabei_part, _pending_pay_desc, true)
	GameManager.add_activity(_pending_pay_category, _pending_pay_desc + "（混合支付）")
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


# ==================== 闺蜜小雅专属交互 ====================

## 小雅聊天逻辑（根据蝴蝶效应状态差异化）
func _on_chat_xiao_ya() -> void:
	if GameManager.energy < 10:
		show_message("精力不足，没力气聊天了！")
		return

	match GameManager.xiaoya_state:
		0:
			# 合租室友：互相取暖，但偶尔也会踩雷
			GameManager.modify_stat("energy", -10)
			var xiaoya_roll: int = randi() % 100
			if xiaoya_roll < 60:
				GameManager.modify_stat("sanity", 15)
				float_stat("+15 情绪", 15, get_global_mouse_position())
				show_message("和小雅窝在沙发上看综艺吐槽老板，心情好多了~", true)
				GameManager.add_activity("社交", "和小雅吐槽工作 (情绪+15)")
			else:
				GameManager.modify_stat("sanity", -10)
				float_stat("-10 情绪", -10, get_global_mouse_position())
				show_message("小雅突然说：'你那个相亲对象后来怎么样了？'你不想回答这个问题。", true)
				GameManager.add_activity("社交", "和小雅聊天被戳到痛点 (情绪-10)")
		1:
			# 阔太太：赴约高级下午茶（强烈的同辈压力）
			if GameManager.energy < 20:
				show_message("精力不足（需20），不想出门赴约！")
				return
			request_payment(800, "和小雅的高级下午茶", "社交", func() -> void:
				GameManager.modify_stat("energy", -20)
				GameManager.modify_stat("charm", 5)
				GameManager.modify_stat("intellect", 5)
				GameManager.modify_stat("sanity", -20)
				float_stat("+5 颜值 +5 学识 -20 情绪", -20, get_global_mouse_position())
				show_message("小雅全身名牌，谈起生活轻描淡写。你看着菜单上 298 元的甜点，笑着说好划算。", true)
				GameManager.add_activity("社交", "赴约小雅的高级下午茶 (颜值+5, 学识+5, 情绪-20)")
				_refresh_wechat_ui()
			)
		2:
			# 怨妇：听她哭诉渣男（情绪垃圾桶，有概率获得防骗经验）
			GameManager.modify_stat("energy", -20)
			GameManager.modify_stat("sanity", -15)
			var roll: int = randi() % 100
			if roll < 40:
				GameManager.modify_stat("eq", 2)
				float_stat("-15 情绪 +2 情商", 2, get_global_mouse_position())
				show_message("听了小雅一晚上哭诉，你决定以后一定擦亮眼睛。(情商+2)", true)
				GameManager.add_activity("社交", "听小雅哭诉渣男经历 (情绪-15, 情商+2)")
			else:
				float_stat("-15 情绪", -15, get_global_mouse_position())
				show_message("小雅的负能量让你也跟着低落...", true)
				GameManager.add_activity("社交", "听小雅哭诉渣男经历 (情绪-15)")
			_refresh_wechat_ui()
