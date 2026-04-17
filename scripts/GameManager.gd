## GameManager.gd - 全局状态与数值管理单例
## 负责：周数、月度、年龄、金钱、精力、情绪等核心数值的存取与边界检查
## 以及 NPC 管理、随机事件、月度结算、结局判定、Buff/Debuff系统
extends Node

# ==================== 自定义信号 ====================

signal stats_updated
signal week_advanced(new_week: int)
## 死亡结局（传递死法标题和描述）
signal game_over(cause_title: String, cause_desc: String)
signal npc_unlocked(npc_id: String, npc_name: String)
## 结局类型："true_love"(真爱), "regret"(遗憾), "elite"(精英)
signal game_ended(ending_type: String)
## 月底到来时发出（暂停推进，等待玩家确认账单）
signal month_ended(pending_salary: int, rent_cost: int, huabei_debt: int, food_cost: int)
## 月度结算完成后发出（用于显示提示）
signal monthly_settled(net_change: int)
## 理财收益结算时发出
signal invest_settled(safe_profit: int, risk_profit: int)
## 岁月衰减时发出
signal aging_decayed
## 春节回家事件（显示扣款和情绪结算提示）
signal spring_festival(msg: String)
## 林凡结局判定（35岁+林凡Lv≥2时发出，等待玩家做出彩礼选择）
signal lin_fan_ending_check()

# ==================== 时间系统 ====================

## 当前年龄
var age: int = 23
## 当前月份（1~12）
var month: int = 1
## 当前月内周数（1~4，每周强制工作一次）
var week_in_month: int = 1
## 每年的周数（12月 × 4周）
var weeks_per_year: int = 48
## 当前总周数（由年龄/月/周推算）
var turn_count: int = 1
## 房租和生活费
var rent_cost: int = 2000
## 固定房租（账本显示用）
var base_rent: int = 1500
## 本月累计餐饮开销
var monthly_food_cost: int = 0

# ==================== 核心数值变量 ====================

## 初始3000，制造"虚假繁荣"错觉
var money: int = 3000
## 待发工资（月末结算时发放）
var pending_salary: int = 0
## 花呗/信用卡欠款（兼容旧引用，新逻辑使用 huabei_debt）
var credit_debt: int = 0
## 花呗欠款（分期还款模式，结算时仅扣最低还款额）
var huabei_debt: int = 0
## 花呗分期负债本金
var huabei_installment_debt: int = 0
## 花呗分期剩余月数
var huabei_installment_months_left: int = 0
## 花呗每月固定分期还款额（含15%手续费）
var huabei_installment_monthly_pay: int = 0
## 活动日志 [{"week":int, "category":String, "desc":String}]
var activity_log: Array = []
## 财务流水日志 [{"week":int, "amount":int, "desc":String, "is_huabei":bool}]
var financial_log: Array = []
var energy: int = 100
var sanity: int = 100
var charm: int = 10
var intellect: int = 10
var eq: int = 10

## 精力上限（默认 100，火象可提升至 120）
var max_energy: int = 100
## 情绪上限（默认 100，水象可提升至 120）
var max_sanity: int = 100

## 租房等级 (0:城中村, 1:精装公寓, 2:豪华大平层)
var housing_level: int = 0
## 房屋带来的额外情绪恢复（每周）
var housing_buff_sanity: int = 0

## 稳健型理财本金（约+2%/月）
var invest_safe: int = 0
## 高风险基金本金（-30%~+40%/月）
var invest_risk: int = 0

## 游戏是否已结束
var game_finished: bool = false
## 是否正在等待月度结算确认
var awaiting_month_settle: bool = false
## 是否正在等待林凡结局彩礼选择
var awaiting_ending_choice: bool = false

## 愧疚debuff剩余周数（每周情绪-10）
var guilt_debuff_weeks: int = 0
## 妈妈关爱buff剩余周数（每周精力+20）
var mom_care_buff_weeks: int = 0

## 连续疯狂加班周数（满5触发“福报的代价”）
var consecutive_overtime: int = 0
## 连续吃挂逼套餐周数（满5触发“恩格尔系数 0.01”）
var consecutive_poor_food: int = 0

## 学历等级（0:大专, 1:成人本科）
var degree: int = 0
## 当前职位等级（0:初级行政, 1:新媒体运营, 2:大客户经理）
var job_level: int = 0
## 夜校学分进度（满12获得本科）
var night_school_progress: int = 0


## 闺蜜小雅蝴蝶效应状态 (0:合租室友, 1:傍上大款的阔太太, 2:被骗的怨妇)
var xiaoya_state: int = 0

# ==================== NPC 剧本数据 ====================

## 静态剧本数据库（从 npc_data.json 加载）
var npc_database: Array = []
## 玩家运行时动态数据（如 {"shen_yi": {"affection": 0, "flags": [], "used_daily_chats": []}}）
var unlocked_npcs: Dictionary = {}
var encounter_failed_ids: Array = []

# ==================== 玩家信息 ====================

var player_name: String = ""
var player_zodiac: String = ""

# ==================== NPC 数据 ====================

var npcs: Dictionary = {
	"family_group": {"name": "相亲相爱一家人 (爸妈)", "affection": 50, "level": 1, "unlocked": true, "warning_msg": "你妈昨天又在朋友圈转发了《女孩过了25岁还不结婚有多可怕》", "blocked": false, "messages": [], "last_seen_week": 0},
	"lin_fan": {"name": "林凡", "affection": 0, "level": 1, "unlocked": true, "warning_msg": "", "blocked": false, "messages": [], "last_seen_week": 0},
	"chen_yu": {"name": "陈宇", "affection": 0, "level": 1, "unlocked": false, "warning_msg": "朋友圈三天可见，且都是深夜emo文案，疑似海王", "blocked": false, "messages": [], "last_seen_week": 0},
	"gu_lin": {"name": "顾凛", "affection": 0, "level": 1, "unlocked": false, "warning_msg": "只发高端商务局，从不回复你的评论，高阶玩家", "blocked": false, "messages": [], "last_seen_week": 0},
	"zhang_minghao": {"name": "张明浩", "affection": 0, "level": 1, "unlocked": false, "warning_msg": "经常在工作群画大饼，爹味极重", "blocked": false, "messages": [], "last_seen_week": 0},
	"wang_teacher": {"name": "尚德夜校-王老师", "affection": 0, "level": 1, "unlocked": true, "warning_msg": "不逼自己一把，你永远只能拿底薪！", "blocked": false, "messages": [], "last_seen_week": 0},
	"xiao_ya": {"name": "小雅 (大专闺蜜)", "affection": 50, "level": 1, "unlocked": true, "warning_msg": "", "blocked": false, "messages": [], "last_seen_week": 0},
}

# ==================== 属性名中文映射 ====================

var stat_names: Dictionary = {
	"money": "金钱", "energy": "精力", "sanity": "情绪",
	"charm": "颜值", "intellect": "学识", "eq": "情商",
	"credit_debt": "花呗欠款",
}

# ==================== 核心函数 ====================

func _ready() -> void:
	load_npc_data()

## 修改指定属性的值
func modify_stat(stat_name: String, amount: int) -> void:
	match stat_name:
		"money":
			money = maxi(money + amount, 0)
		"energy":
			energy = clampi(energy + amount, 0, max_energy)
		"sanity":
			sanity = clampi(sanity + amount, 0, max_sanity)
			if sanity <= 0:
				game_over.emit("【情绪崩溃】", "你的情绪已经跌到了谷底，连续的打击让你再也撑不住了。\n你把自己锁在出租屋里，不吃不喝，手机关机。\n三天后，同事发现你时，你已经瘦了一圈，被送进了医院。")
		"charm":
			charm = maxi(charm + amount, 0)
		"intellect":
			intellect = maxi(intellect + amount, 0)
		"eq":
			eq = maxi(eq + amount, 0)
		"turn_count":
			turn_count = maxi(turn_count + amount, 1)
		_:
			push_warning("GameManager: 未知的属性名 '%s'" % stat_name)
			return

	check_npc_unlocks()
	stats_updated.emit()


## 记录活动日志（category: "日常"/"提升"/"社交"/"消费"）
func add_activity(category: String, desc: String) -> void:
	activity_log.append({"week": turn_count, "category": category, "desc": desc})

## 记录财务流水（is_huabei: 是否花呗支付）
func add_finance(amount: int, desc: String, is_huabei: bool) -> void:
	financial_log.append({"week": turn_count, "amount": amount, "desc": desc, "is_huabei": is_huabei})

## 增加NPC好感度（含自动升级逻辑：每50好感升一级）
func add_npc_affection(npc_id: String, amount: int) -> void:
	if not npcs.has(npc_id):
		return
	npcs[npc_id]["affection"] += amount
	while npcs[npc_id]["affection"] >= 50:
		npcs[npc_id]["affection"] -= 50
		npcs[npc_id]["level"] += 1
	stats_updated.emit()


## 推进到下一周
func advance_week() -> void:
	if game_finished:
		return

	# 闺蜜蝴蝶效应：半年后（第24周）触发小雅命运分歧
	if turn_count == 24 and xiaoya_state == 0:
		xiaoya_state = randi() % 2 + 1
		match xiaoya_state:
			1:
				npcs["xiao_ya"]["name"] = "小雅 (阔太太)"
				npcs["xiao_ya"]["warning_msg"] = "最近朋友圈全是马尔代夫和爱马仕..."
			2:
				npcs["xiao_ya"]["name"] = "小雅 (被骗的怨妇)"
				npcs["xiao_ya"]["warning_msg"] = "她上周哭着说被那个男的骗了十几万..."
		npc_unlocked.emit("xiao_ya", npcs["xiao_ya"]["name"])

	week_in_month += 1
	# 精力恢复
	energy = max_energy
	# 房屋情绪恢复加成
	if housing_buff_sanity > 0:
		sanity = mini(sanity + housing_buff_sanity, max_sanity)

	# 愧疚debuff：每周情绪-10
	if guilt_debuff_weeks > 0:
		sanity = maxi(sanity - 10, 0)
		guilt_debuff_weeks -= 1
		if sanity <= 0:
			game_over.emit("【内欺煎熬】", "每周的愧究感像钍刀割肉一样折磨着你。\n你想起上次挂掉妈妈的电话，想起她说'行吧，你自己的事自己决定'时的沉默。\n你终于没忍住，在被子里哭了一整夜，第二天没能爬起来上班。")
			stats_updated.emit()
			return

	# 妈妈关爱buff：每周精力+20
	if mom_care_buff_weeks > 0:
		energy = mini(energy + 20, max_energy)
		mom_care_buff_weeks -= 1

	# 月底结算：不立刻处理，发出信号等待玩家确认
	if week_in_month > 4:
		awaiting_month_settle = true
		month_ended.emit(pending_salary, rent_cost, huabei_debt, monthly_food_cost)
		return

	# 正常推进
	turn_count += 1
	week_advanced.emit(turn_count)
	stats_updated.emit()


## 月度结算确认后调用（严格按5步执行 + 春节 + 关系人审视 + 结局判定）
func start_new_month() -> void:
	awaiting_month_settle = false

	# 步骤1：理财结算
	var invest_profit_safe: int = 0
	var invest_profit_risk: int = 0
	if invest_safe > 0:
		invest_profit_safe = int(invest_safe * 0.05)
		invest_safe += invest_profit_safe
	if invest_risk > 0:
		var risk_rate := randf_range(-0.30, 0.40)
		invest_profit_risk = int(invest_risk * risk_rate)
		invest_risk += invest_profit_risk
		invest_risk = maxi(invest_risk, 0)
	invest_settled.emit(invest_profit_safe, invest_profit_risk)

	# 步骤2：账单扣除（严格按四步顺序执行）
	var salary_paid: int = pending_salary

	# 第1步：扣除刚性支出（房租+餐饮）
	money += pending_salary
	money -= base_rent
	money -= monthly_food_cost

	# 第2步：处理分期账单
	if huabei_installment_months_left > 0:
		money -= huabei_installment_monthly_pay
		huabei_installment_months_left -= 1
		var principal_this_month: int = int(float(huabei_installment_monthly_pay) / 1.15)
		huabei_installment_debt = maxi(huabei_installment_debt - principal_this_month, 0)
		if huabei_installment_months_left <= 0:
			huabei_installment_debt = 0
			huabei_installment_monthly_pay = 0

	# 第3步：处理未分期的花呗最低还款
	if huabei_debt > 0:
		var min_payment: int = mini(int(huabei_debt * 0.1 + 200), huabei_debt)
		if money >= min_payment:
			money -= min_payment
			huabei_debt -= min_payment
		else:
			huabei_debt -= money
			money = 0
			sanity -= 50
			if sanity <= 0:
				sanity = 0
				game_over.emit("【负债累累】", "花呗最低还款都付不起了。\n催收电话打到公司前台，同事看你的眼神都变了。\n你把手机关机，蜷缩在出租屋的角落，感觉自己被整个世界抛弃了。")
				stats_updated.emit()
				return
		if huabei_debt > 0:
			huabei_debt = int(float(huabei_debt) * 1.05)
	credit_debt = huabei_debt

	# 第4步：破产惩罚（入不敷出）
	var total_cost: int = base_rent + monthly_food_cost
	if money < 0:
		sanity -= 50
		if sanity <= 0:
			sanity = 0
			# 死法判定：优先检查特殊死法
			var death_title: String = "【破产绝路】"
			var death_desc: String = "入不敷出，弹尽粮绝。你坐在空荡荡的出租屋里，连泡面都买不起了。\n手机上全是催收短信，窗外的霓虹灯照不进你的生活。"
			if invest_risk > 0 and invest_profit_risk < 0:
				death_title = "【A股明灯】"
				death_desc = "你重仓的比特币/高风险基金本月暴跌，加上日常开销入不敷出，资金链彻底断裂。\n你在天台上看着万家灯火，想起自己曾经也是其中一盏。\n据说你割肉离场的那支币，第二个月涨了300%。"
			elif (huabei_debt + huabei_installment_debt) > 50000:
				death_title = "【人造的名媛】"
				death_desc = "花呗欠款超过5万，催收把你通讯录打了个遍。\n你妈在电话那头哭着问：'闺女，你是不是在外面欠了高利贷？'\n你看着满屋子的名牌包和医美账单，第一次觉得这些东西真他妈丑。"
			game_over.emit(death_title, death_desc)
			stats_updated.emit()
			return

	# 月度结算提示
	var net_change: int = salary_paid - total_cost
	monthly_settled.emit(net_change)

	# 岁月催人老
	if charm > 0:
		charm = maxi(charm - 1, 0)
		aging_decayed.emit()

	# 清理账单
	pending_salary = 0
	monthly_food_cost = 0

	# 月份推进
	week_in_month = 1
	month += 1

	# 年度结算：12月过完长一岁 + 春节回家 + 关系人审视 + 结局判定
	if month > 12:
		month = 1
		age += 1

		# 春节回家：固定扣除 5000（红包/压岁钱/机票刚性支出）
		var pre_sf_money: int = money
		money -= 5000
		var sf_msg: String = "春节回老家过年，人情往来与车马费共计花费 5000 元！\n"
		if pre_sf_money >= 50000:
			sanity = mini(sanity + 50, max_sanity)
			sf_msg += "存款丰厚，父母倍儿有面子！(情绪 +50)\n"
		elif pre_sf_money < 10000:
			sanity = maxi(sanity - 30, 0)
			sf_msg += "亲戚冷嘲热讽，父母唉声叹气。(情绪 -30)\n"
		else:
			sf_msg += "平平淡淡又是一年。\n"

		# 春节关系人审视：找最高等级的可约会NPC
		var highest_npc_id: String = ""
		var highest_level: int = 0
		for check_id in ["lin_fan", "chen_yu", "gu_lin", "zhang_minghao"]:
			if npcs[check_id]["unlocked"] and npcs[check_id]["level"] > highest_level:
				highest_level = npcs[check_id]["level"]
				highest_npc_id = check_id
		if highest_npc_id == "gu_lin":
			eq = maxi(eq - 10, 0)
			sanity = maxi(sanity - 20, 0)
			sf_msg += "\n过年聚会上，顾凛的助理发来一条消息：'顾总说新年快乐。'你把手机翻了过去。(情商 -10, 情绪 -20)"
		elif highest_npc_id == "lin_fan":
			sanity = mini(sanity + 80, max_sanity)
			sf_msg += "\n林凡提着两袋橘子出现在你家楼下，被你妈拉进屋吃了顿饺子。你看着他在厨房帮忙的背影，突然觉得这样也挺好。(情绪 +80)"

		spring_festival.emit(sf_msg)

		# 春节后破产惩罚
		if money < 0:
			sanity -= 50
			if sanity <= 0:
				sanity = 0
				game_over.emit("【春节破产】", "春节回家花光了所有积蓄，还负了一债。\n亲戚们的冷言冷语和父母的叹息压得你喘不过气。\n初七那天，你一个人在火车站候车室里，提前买了返程票。")
				stats_updated.emit()
				return

		# 35岁结局判定
		if age >= 35:
			if npcs["lin_fan"]["level"] >= 2:
				# 林凡路线：等待玩家做出彩礼选择
				awaiting_ending_choice = true
				lin_fan_ending_check.emit()
				stats_updated.emit()
				return
			else:
				# 精英结局：没有林凡
				game_finished = true
				game_ended.emit("elite")
				stats_updated.emit()
				return

	# 继续推进
	turn_count += 1
	week_advanced.emit(turn_count)
	stats_updated.emit()


## 林凡结局最终确认（由MainGame调用）
func finalize_lin_fan_ending(is_true_love: bool) -> void:
	awaiting_ending_choice = false
	game_finished = true
	if is_true_love:
		if money >= 50000:
			money -= 50000
			game_ended.emit("true_love")
		else:
			game_ended.emit("regret")
	else:
		game_ended.emit("elite")
	stats_updated.emit()


## 随机事件系统：30%概率触发
func roll_random_event(context: String) -> Dictionary:
	if randi() % 100 >= 30:
		return {}

	match context:
		"work":
			return {"desc": "老板今天心情不好，你成了出气筒。", "sanity": -15}
		"library":
			return {"desc": "读到一本好书，心灵得到净化。", "sanity": 20, "intellect": 5}
		"bar":
			return {"desc": "在吧台被一个奇怪的人搭讪，感觉很差。", "sanity": -10}
		_:
			return {}


## 检查是否有新 NPC 解锁
## 加载 NPC 静态剧本数据
func load_npc_data() -> void:
	var f := FileAccess.open("res://Data/npc_data.json", FileAccess.READ)
	if not f:
		push_warning("GameManager: 无法打开 npc_data.json")
		return
	var json_text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(json_text) != OK:
		push_warning("GameManager: npc_data.json 解析失败 - " + json.get_error_message())
		return
	npc_database = json.data
	print("GameManager: 已加载 %d 个NPC剧本" % npc_database.size())


## 根据 ID 获取静态剧本数据
func get_npc_data(npc_id: String) -> Dictionary:
	for npc in npc_database:
		if npc.get("id", "") == npc_id:
			return npc
	return {}


## 获取/创建运行时动态数据
func get_npc_runtime(npc_id: String) -> Dictionary:
	if not unlocked_npcs.has(npc_id):
		unlocked_npcs[npc_id] = {
			"affection": 0,
			"flags": [],
			"used_daily_chats": [],
			"chat_cooldown": 0
		}
	return unlocked_npcs[npc_id]


## 检查 NPC 是否已解锁
func is_npc_unlocked(npc_id: String) -> bool:
	return unlocked_npcs.has(npc_id)


## 解锁一个 NPC
func unlock_npc(npc_id: String) -> void:
	if unlocked_npcs.has(npc_id):
		return
	var static_data := get_npc_data(npc_id)
	var display_name: String = static_data.get("name", npc_id)
	unlocked_npcs[npc_id] = {
		"affection": 0,
		"flags": [],
		"used_daily_chats": [],
		"chat_cooldown": 0
	}
	# 同步加入微信联系人列表（npcs 字典）
	if not npcs.has(npc_id):
		npcs[npc_id] = {
			"name": display_name,
			"affection": 0,
			"level": 1,
			"unlocked": true,
			"warning_msg": "",
			"blocked": false,
			"messages": [],
			"last_seen_week": 0,
		}
	else:
		npcs[npc_id]["unlocked"] = true
	npc_unlocked.emit(npc_id, display_name)


func check_npc_unlocks() -> void:
	if not npcs["chen_yu"]["unlocked"] and eq >= 20:
		npcs["chen_yu"]["unlocked"] = true
		npc_unlocked.emit("chen_yu", npcs["chen_yu"]["name"])
	if charm >= 20 and not npcs["gu_lin"]["unlocked"]:
		npcs["gu_lin"]["unlocked"] = true
		npc_unlocked.emit("gu_lin", npcs["gu_lin"]["name"])
	if not npcs["zhang_minghao"]["unlocked"] and month >= 3:
		npcs["zhang_minghao"]["unlocked"] = true
		npc_unlocked.emit("zhang_minghao", npcs["zhang_minghao"]["name"])



## 检查连续行为死法（加班/吃土），返回死法信息字典或空字典
func check_behavior_death() -> Dictionary:
	if consecutive_overtime >= 5:
		return {
			"title": "【福报的代价】",
			"desc": "周二凌晨3点，你刚发完最后一版PPT，心脏突然猛烈地跳动了一下，然后归于平静。
老板在葬礼上流下了鳄鱼的眼泪，并连夜招了个底薪比你低1000块的应届生。"
		}
	if consecutive_poor_food >= 5:
		return {
			"title": "【恩格尔系数 0.01】",
			"desc": "为了省钱，你硬生生啃了一个多月的泡面。今天挤早高峰地铁时，你眼前一黑晕了过去。
重度营养不良伴随低血糖，医药费刚好是你省下来的钱。"
		}
	return {}

## 预计月末资产（账本显示用，含理财资产总额）
func get_projected_balance() -> int:
	return money + pending_salary + invest_safe + invest_risk - base_rent - huabei_debt - monthly_food_cost
