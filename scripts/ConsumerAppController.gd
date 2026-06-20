## ConsumerAppController.gd
## Owns consumer-pressure apps: 宝淘, 团美医美, 贝壳找房, and late-night impulse spending.
extends RefCounted

var _main: Node
var _app: RefCounted
var _pending_impulse: Dictionary = {}
var _impulse_pool: Array = [
	{"text": "被直播间洗脑，分期拿下轻奢包包 (花呗+5000, 情绪+40)", "huabei": 5000, "sanity": 40, "charm": 0, "desc": "深夜失眠，被直播间洗脑分期买了轻奢包"},
	{"text": "深夜emo，疯狂网购一堆无用盲盒 (花呗+800, 情绪+15)", "huabei": 800, "sanity": 15, "charm": 0, "desc": "深夜emo，疯狂网购了一堆无用盲盒"},
	{"text": "刷到前任秀恩爱，怒点昂贵医美套餐 (花呗+10000, 颜值+10, 情绪+30)", "huabei": 10000, "sanity": 30, "charm": 10, "desc": "深夜刷到前任秀恩爱，怒点昂贵医美套餐"},
]


func init(main: Node, app_system: RefCounted) -> void:
	_main = main
	_app = app_system


func open_baotao() -> void:
	if not _app._can_open_phone_app():
		return
	if not _app._ensure_app_unlocked("baotao"):
		return
	_app._close_all_menus()
	var menu := _app.baotao_menu as ColorRect
	_clear_menu(menu)
	var debt_info := "花呗欠款：%d 元" % (GameManager.huabei_debt + GameManager.huabei_installment_debt)
	var items := [
		{"name": "大牌护肤套装", "icon_color": Color(0.95, 0.45, 0.6), "cost": "800 元 | +5颜值 +5情绪", "action": on_bt_skincare, "close_on_action": false},
		{"name": "快时尚穿搭", "icon_color": Color(0.3, 0.7, 0.9), "cost": "1500 元 | +8颜值 +10情绪", "action": on_bt_fashion, "close_on_action": false},
	]
	_app._build_app_overlay(menu, "宝淘", Color(0.95, 0.35, 0.35, 1), debt_info, items)
	_app._set_layer_visible(menu, true)


func open_tuanmei() -> void:
	if not _app._can_open_phone_app():
		return
	if not _app._ensure_app_unlocked("tuanmei"):
		return
	_app._close_all_menus()
	var menu := _app.tuanmei_menu as ColorRect
	_clear_menu(menu)
	var debt_info := "花呗欠款：%d 元" % (GameManager.huabei_debt + GameManager.huabei_installment_debt)
	var items := [
		{"name": "水光针+热玛吉", "icon_color": Color(0.8, 0.4, 0.8), "cost": "6000 元 | +15颜值 | 需颜值<30", "action": on_tm_injection, "close_on_action": false},
		{"name": "全脸微调手术", "icon_color": Color(0.6, 0.2, 0.8), "cost": "20000 元 | +30颜值 | 需颜值<20", "action": on_tm_surgery, "close_on_action": false},
	]
	_app._build_app_overlay(menu, "团美医美", Color(0.6, 0.3, 0.8, 1), debt_info, items)
	_app._set_layer_visible(menu, true)


func open_house() -> void:
	if not _app._can_open_phone_app():
		return
	if not _app._ensure_app_unlocked("house"):
		return
	_app._close_all_menus()
	var menu := _app.house_menu as ColorRect
	_clear_menu(menu)
	var housing_names: Array = ["城中村单间", "精装一居室", "CBD大平层"]
	var house_name: String = housing_names[GameManager.housing_level]
	var status := "当前住房：%s (月租 %d) | 押金=2个月房租" % [house_name, GameManager.base_rent]
	var deposits: Array = [3000, 8000, 24000]
	var rents: Array = [1500, 4000, 12000]
	var actions := [on_house_village, on_house_apartment, on_house_luxury]
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
			item["action"] = actions[i]
		items.append(item)
	_app._build_app_overlay(menu, "贝壳找房", Color(0.15, 0.6, 0.7, 1), status, items)
	_app._set_layer_visible(menu, true)


func on_bt_skincare() -> void:
	_main.alipay.request_payment(800, "大牌护肤套装", "消费", func() -> void:
		var payment_changes: Dictionary = _main.alipay.get_last_payment_changes()
		_app._show_story_then_apply_changes("大牌护肤套装到货。你对着镜子认真涂完一整套流程，皮肤状态确实亮了一点。", {"charm": 5, "sanity": 5}, payment_changes)
	)


func on_bt_fashion() -> void:
	_main.alipay.request_payment(1500, "快时尚穿搭", "消费", func() -> void:
		var payment_changes: Dictionary = _main.alipay.get_last_payment_changes()
		_app._show_story_then_apply_changes("新衣服很快到了。你换上之后拍了几张照，虽然知道它不便宜，但心情确实轻了一点。", {"charm": 8, "sanity": 10}, payment_changes)
	)


func on_tm_injection() -> void:
	if GameManager.charm >= 30:
		_main.show_message("你颜值已经>=30了，医生说不需要做这个项目~")
		return
	_main.alipay.request_payment(6000, "水光针热玛吉", "消费", func() -> void:
		var payment_changes: Dictionary = _main.alipay.get_last_payment_changes()
		_app._show_story_then_apply_changes("项目做完后，你盯着镜子看了很久。变化很明显，账单也很明显。", {"charm": 15, "sanity": 20}, payment_changes)
	)


func on_tm_surgery() -> void:
	if GameManager.charm >= 20:
		_main.show_message("你颜值已经>=20了，做全脸微调太浪费钱了！")
		return
	_main.alipay.request_payment(20000, "全脸微调手术", "消费", func() -> void:
		var payment_changes: Dictionary = _main.alipay.get_last_payment_changes()
		_app._show_story_then_apply_changes("恢复期比你想象中难熬。拆线那天，你看着镜子里的自己，熟悉又陌生。", {"charm": 30, "eq": -10, "sanity": 30}, payment_changes)
	)


func on_house_village() -> void:
	if GameManager.money < 3000:
		_main.show_message("余额不足，城中村押金需要 3000 元。")
		return
	_app._show_story_then_apply_changes("你重新签了城中村的小房间。空间不大，但至少账单还算能喘气。下月起房租 1500。", {"money": -3000}, {}, func() -> void:
		GameManager.base_rent = 1500
		GameManager.housing_level = 0
		GameManager.housing_buff_sanity = 0
	)


func on_house_apartment() -> void:
	if GameManager.money < 8000:
		_main.show_message("余额不足，精装公寓押金需要 8000 元。")
		return
	_app._show_story_then_apply_changes("精装公寓的灯光很柔和，电梯也不再有怪味。你换上拖鞋，第一次觉得回家像回家。下月起房租 4000。", {"money": -8000, "charm": 5}, {}, func() -> void:
		GameManager.base_rent = 4000
		GameManager.housing_level = 1
		GameManager.housing_buff_sanity = 10
	)


func on_house_luxury() -> void:
	if GameManager.money < 24000:
		_main.show_message("余额不足，CBD大平层押金需要 24000 元。")
		return
	_app._show_story_then_apply_changes("CBD 大平层的落地窗外就是夜景。你站在窗边看了很久，知道自己正在买一种很贵的体面。下月起房租 12000。", {"money": -24000, "charm": 10}, {}, func() -> void:
		GameManager.base_rent = 12000
		GameManager.housing_level = 2
		GameManager.housing_buff_sanity = 25
	)


func enter_late_night() -> void:
	_pending_impulse = _impulse_pool[randi() % _impulse_pool.size()]
	_app.btn_emo_bag.text = _pending_impulse["text"]
	_app.btn_emo_sleep.text = "忍住诱惑，强迫自己睡觉 (颜值-2 情绪-10 精力-20)"
	_app._set_layer_visible(_app.late_night_popup, true)


func on_emo_bag() -> void:
	var imp: Dictionary = _pending_impulse
	var changes := {"credit_debt": int(imp["huabei"])}
	if int(imp["sanity"]) > 0:
		changes["sanity"] = int(imp["sanity"])
	if int(imp["charm"]) > 0:
		changes["charm"] = int(imp["charm"])
	GameManager.add_activity("消费", "深夜失眠，冲动消费换取了短暂的安慰。")
	_app._set_layer_visible(_app.late_night_popup, false)
	_app._show_story_then_apply_changes("下单了。屏幕上弹出支付成功的提示，短暂的快乐之后，是更深的空虚。", changes, {}, func() -> void:
		GameManager.add_finance(-imp["huabei"], imp["desc"], true, "消费")
		_main._proceed_next_week()
	)


func on_emo_sleep() -> void:
	var changes := {"charm": -2, "sanity": -10, "energy": -20}
	GameManager.add_activity("日常", "失眠了一整夜，第二天感觉身体被掏空。")
	_app._set_layer_visible(_app.late_night_popup, false)
	if not GameManager.game_finished:
		_app._show_story_then_apply_changes("你辗转反侧到天亮。窗外开始发白的时候，整个人像被抽空了一样。", changes, {}, func() -> void:
			_main._proceed_next_week()
		)


func _clear_menu(menu: Control) -> void:
	if not is_instance_valid(menu):
		return
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()
