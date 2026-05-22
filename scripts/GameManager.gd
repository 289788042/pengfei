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
## 春节BOSS战开始（传递当前年龄）
signal spring_festival_boss(age: int)


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
## 是否正在等待结局选择（33岁终局时）
var awaiting_ending_choice: bool = false
## 最近一次结局评估结果
var last_ending: Dictionary = {}
## 是否正在等待月度结算确认
var awaiting_month_settle: bool = false

## 妈妈关爱buff剩余周数（每周精力+20）
var mom_care_buff_weeks: int = 0

## 连续疯狂加班周数（满5触发"福报的代价"）
var consecutive_overtime: int = 0
## 连续吃挂逼套餐周数（满5触发"恩格尔系数 0.01"）
var consecutive_poor_food: int = 0

## 学历等级（0:大专, 1:成人本科）
var degree: int = 0
## 当前职位等级（0:初级行政, 1:新媒体运营, 2:大客户经理）
var job_level: int = 0
## 夜校学分进度（满12获得本科）
var night_school_progress: int = 0
## 王老师上次推送消息的周数（用于隔4周推送逻辑）
var _wang_teacher_last_push_week: int = 0
var _family_chat_used_indices: Array = []
## 职场微事件数据
var workplace_events: Array = []
## 近3周触发的微事件ID（防重复）
var _recent_work_events: Array = []



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
	"wang_teacher": {"name": "尚德夜校-王老师", "affection": 0, "level": 1, "unlocked": true, "warning_msg": "不逼自己一把，你永远只能拿底薪！", "blocked": false, "messages": [], "last_seen_week": 0},
	"xiao_ya": {"name": "小雅", "affection": 30, "level": 1, "unlocked": true, "warning_msg": "", "blocked": false, "messages": [{"sender": "npc", "text": "姐妹你啥时候来深圳呀？来了找我玩！"}], "last_seen_week": 0, "unread": 1},
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
	load_workplace_events()

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

	week_in_month += 1
	# 精力恢复
	energy = max_energy
	# 房屋情绪恢复加成
	if housing_buff_sanity > 0:
		sanity = mini(sanity + housing_buff_sanity, max_sanity)

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

	# 年度结算：12月过完长一岁 + 春节BOSS战
	if month > 12:
		month = 1
		age += 1

		# 33岁终局判定
		if age >= 33:
			game_finished = true
			var ending := evaluate_ending()
			last_ending = ending
			game_ended.emit(ending["type"])
			stats_updated.emit()
			return

		# 发出春节BOSS战信号，等待 finish_spring_festival 回调
		spring_festival_boss.emit(age)
		return

	# 继续推进
	turn_count += 1
	week_advanced.emit(turn_count)
	stats_updated.emit()


## 春节BOSS战结算回调
func finish_spring_festival(total_sanity_cost: int, money_cost: int) -> void:
	awaiting_month_settle = false

	# 扣除春节花费
	money -= money_cost

	# 应用情绪总变化
	if total_sanity_cost != 0:
		sanity = clampi(sanity + total_sanity_cost, 0, max_sanity)

	# 存款加成/惩罚
	if money >= 50000:
		sanity = mini(sanity + 30, max_sanity)
	elif money < 10000:
		sanity = maxi(sanity - 20, 0)

	# 春节后破产惩罚
	if money < 0:
		sanity -= 50
		if sanity <= 0:
			sanity = 0
			game_over.emit("【春节破产】", "春节回家花光了所有积蓄，还负了一债。
亲戚们的冷言冷语和父母的叹息压得你喘不过气。
初七那天，你一个人在火车站候车室里，提前买了返程票。")
			stats_updated.emit()
			return

	# 记录活动日志
	GameManager.add_activity("日常", "春节回家过年，花费 %d 元" % money_cost)

	# 继续推进
	turn_count += 1
	week_advanced.emit(turn_count)
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
	# 加载额外NPC数据
	var f2 := FileAccess.open("res://Data/npc_data_new.json", FileAccess.READ)
	if f2:
		var json2 := JSON.new()
		if json2.parse(f2.get_as_text()) == OK:
			for npc in json2.data:
				npc_database.append(npc)
		f2.close()
	# 初始化自动解锁NPC的运行时数据
	for npc in npc_database:
		var enc: Dictionary = npc.get("encounter", {})
		if enc.get("auto_unlock", false):
			var npc_id: String = npc.get("id", "")
			if not unlocked_npcs.has(npc_id):
				unlocked_npcs[npc_id] = {"affection": 0, "flags": []}
	print("GameManager: 已加载 %d 个NPC剧本" % npc_database.size())


## 检查自动解锁NPC（每周开始时调用）
func check_auto_unlock_npcs() -> void:
	for npc in npc_database:
		var enc: Dictionary = npc.get("encounter", {})
		if not enc.get("auto_unlock", false):
			continue
		var npc_id: String = npc.get("id", "")
		if is_npc_unlocked(npc_id):
			continue
		var conds: Dictionary = enc.get("auto_unlock_condition", {})
		if conds.is_empty() or _check_event_conditions(conds):
			unlock_npc(npc_id)
			add_activity("社交", "与%s建立了联系" % npc.get("name", npc_id))
			print("GameManager: 自动解锁NPC %s" % npc.get("name", npc_id))

## 根据 ID 获取静态剧本数据
func get_npc_data(npc_id: String) -> Dictionary:
	for npc in npc_database:
		if npc.get("id", "") == npc_id:
			return npc
	return {}


func get_npc_name(npc_id: String) -> String:
	for npc in npc_database:
		if npc.get("id", "") == npc_id:
			return npc.get("name", "")
	return npc_id


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




## 增加 NPC 未读消息数
func add_unread(npc_id: String, count: int = 1) -> void:
	if not npcs.has(npc_id):
		return
	if not npcs[npc_id].has("unread"):
		npcs[npc_id]["unread"] = 0
	npcs[npc_id]["unread"] += count
	stats_updated.emit()


## 清零 NPC 未读消息数
func clear_unread(npc_id: String) -> void:
	if npcs.has(npc_id):
		npcs[npc_id]["unread"] = 0
		stats_updated.emit()


## 获取所有 NPC 未读总数
func get_total_unread() -> int:
	var total: int = 0
	for npc_id in npcs:
		total += npcs[npc_id].get("unread", 0)
	return total


## 加载职场微事件数据
func load_workplace_events() -> void:
	var f := FileAccess.open("res://Data/workplace_events.json", FileAccess.READ)
	if not f:
		push_warning("GameManager: 无法打开 workplace_events.json")
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		push_warning("GameManager: workplace_events.json 解析失败")
		f.close()
		return
	workplace_events = json.data
	f.close()
	print("GameManager: 已加载 %d 条职场微事件" % workplace_events.size())


## 有效属性名（用于过滤微事件字典）
var _valid_stats: Array = ["energy", "sanity", "charm", "intellect", "eq", "money"]


## 随机抽取一条职场微事件（60%触发率，条件过滤，权重随机，近3周不重复）
func roll_workplace_event() -> Dictionary:
	if randi() % 100 >= 60:
		return {}
	if workplace_events.is_empty():
		return {}
	# 条件过滤
	var candidates: Array = []
	var total_weight: int = 0
	for evt in workplace_events:
		var conds: Dictionary = evt.get("conditions", {})
		if not _check_event_conditions(conds):
			continue
		var eid: String = evt.get("id", "")
		if _recent_work_events.has(eid):
			continue
		var w: int = int(evt.get("weight", 1))
		candidates.append({"event": evt, "weight": w})
		total_weight += w
	if candidates.is_empty():
		return {}
	# 权重随机
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	for c in candidates:
		cumulative += c["weight"]
		if roll < cumulative:
			var picked: Dictionary = c["event"]
			_recent_work_events.append(picked.get("id", ""))
			if _recent_work_events.size() > 9:
				_recent_work_events.pop_front()
			return _clean_event_dict(picked)
	return {}


## 检查微事件条件
func _check_event_conditions(conds: Dictionary) -> bool:
	for key in conds:
		match key:
			"job_level_min":
				if job_level < int(conds[key]):
					return false
			"job_level_max":
				if job_level > int(conds[key]):
					return false
			"age_min":
				if age < int(conds[key]):
					return false
			"age_max":
				if age > int(conds[key]):
					return false
			"money_min":
				if money < int(conds[key]):
					return false
			"money_max":
				if money > int(conds[key]):
					return false
			"sanity_min":
				if sanity < int(conds[key]):
					return false
			"sanity_max":
				if sanity > int(conds[key]):
					return false
			"energy_min":
				if energy < int(conds[key]):
					return false
			"energy_max":
				if energy > int(conds[key]):
					return false
			"charm_min":
				if charm < int(conds[key]):
					return false
			"charm_max":
				if charm > int(conds[key]):
					return false
			"intellect_min":
				if intellect < int(conds[key]):
					return false
			"eq_min":
				if eq < int(conds[key]):
					return false
			"eq_max":
				if eq > int(conds[key]):
					return false
			"overtime_min":
				if consecutive_overtime < int(conds[key]):
					return false
			"huabei_min":
				if huabei_debt < int(conds[key]):
					return false
			"degree_min":
				if degree < int(conds[key]):
					return false
			"turn_count_max":
				if turn_count > int(conds[key]):
					return false
			"turn_count_min":
				if turn_count < int(conds[key]):
					return false
	return true


## 清理微事件字典：只保留 desc + 有效属性名
func _clean_event_dict(raw: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	result["desc"] = raw.get("desc", "")
	for key in _valid_stats:
		if raw.has(key):
			result[key] = int(raw[key])
	return result


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

## 评估33岁终局结局（优先级从高到低，首个匹配生效）
func evaluate_ending() -> Dictionary:
	# 1. 真爱结局：任一非家庭/非老师的NPC等级>=3
	for npc_id in npcs:
		if npc_id == "family_group" or npc_id == "wang_teacher":
			continue
		if npcs[npc_id].get("level", 1) >= 3:
			var npc_name: String = npcs[npc_id].get("name", npc_id)
			return {
				"type": "true_love",
				"title": "【真爱结局】错位的幸福",
				"content": (
					"33岁这年，你终于明白了一件事：
"
					+ "深圳给了你很多，也拿走了很多。
"
					+ "但幸好，有一个始终站在你身边的人。
"
					+ "%s或许不是最完美的那个，却是在你最狼狈的时候，
" % npc_name
					+ "给你递纸巾的那个人。

"
					+ "城中村的出租屋换了又换，但只要有人在等你回家，
"
					+ "那盏灯就是全世界最温暖的光。"
				),
				"npc_name": npc_name,
			}
	# 2. 破产流浪结局：负债
	if money < 0 or (huabei_debt + huabei_installment_debt) > 80000:
		return {
			"type": "bankrupt",
			"title": "【破产结局】消失的她",
			"content": (
				"33岁，你终于还是撑不住了。
"
				+ "花呗的催收电话打到了公司，老板把你叫进了办公室。
"
				+ "第二天你没去上班，第三天也没去。
"
				+ "你把手机关了，背着包坐上了绿皮火车。

"
				+ "深圳很好，只是不属于你。
"
				+ "但谁知道呢？说不定在老家开个小店，
"
				+ "日子也没那么难过。"
			),
		}
	# 3. 社畜结局：高职位低情绪
	if job_level >= 2 and sanity <= 30:
		return {
			"type": "corporate_slave",
			"title": "【社畜结局】福报兑现",
			"content": (
				"你做到了。
"
				+ "大客户经理，月薪两万，南山区的写字楼里有一张你的工位。
"
				+ "代价是发际线后退了两厘米，体检报告上有五个红色箭头。
"
				+ "你妈打电话来问你有对象了没，你说最近在忙。

"
				+ "凌晨两点，你一个人在公司改方案。
"
				+ "外卖小哥送来了炒饭，你说了声谢谢。
"
				+ "这是今天第一个跟你说话的人。"
			),
		}
	# 4. 网红结局：高颜值+有钱
	if charm >= 40 and money >= 50000:
		return {
			"type": "influencer",
			"title": "【网红结局】被关注的代价",
			"content": (
				"你的颜值是你最大的资产，你深谙此道。
"
				+ "小红书十万粉，广告接到手软。
"
				+ "你在后海拍照的样子被路人认出来，
"
				+ "你笑了笑说「谢谢关注」。

"
				+ "但关掉美颜之后的你，只有你自己认识。
"
				+ "你花了三十万在脸上，却没花一分钱治心里的空洞。
"
				+ "直播结束时，你说「爱你哦」，
"
				+ "但你分不清是对谁说的。"
			),
		}
	# 5. 学霸结局：高学识+有学历
	if intellect >= 40 and degree >= 1:
		return {
			"type": "scholar",
			"title": "【学霸结局】知识改变命运",
			"content": (
				"你用夜校的成人本科文凭敲开了另一扇门。
"
				+ "虽然不是985，不是211，但你硬是从城中村走到了写字楼。
"
				+ "书架上的书从鸡汤变成了专业教材，
"
				+ "你的简历从「大专」变成了「本科」。

"
				+ "王老师发了条朋友圈：「今晚加了个鸡腿，
"
				+ "因为我最得意的门生终于出师了。」
"
				+ "你点了个赞，然后继续看书。
"
				+ "知识改变命运，不一定是大富大贵，
"
				+ "但至少给了你选择的权利。"
			),
		}
	# 6. 精英结局：高收入高职位
	if money >= 100000 and job_level >= 2:
		return {
			"type": "elite",
			"title": "【精英结局】孤独的赢家",
			"content": (
				"33岁这年，你如愿成为了别人眼中的精英。
"
				+ "存款六位数，职位体面，住在精装公寓里。
"
				+ "但看着空荡荡的客厅，你想起当年在城中村楼下，
"
				+ "那个淋着雨给你送粥的笨蛋。

"
				+ "你赢得了世界，却唯独弄丢了那个能让你安心哭泣的人。
"
				+ "手机里的联系人越来越多，
"
				+ "但凌晨失眠时，你翻遍了通讯录，却找不到一个能打的电话。"
			),
		}
	# 7. 归园田居：家庭关系好+情绪稳定
	if npcs.get("family_group", {}).get("level", 1) >= 4 and sanity >= 80:
		return {
			"type": "homecoming",
			"title": "【归园田居】此心安处是吾乡",
			"content": (
				"你妈说：「回来了就别走了，隔壁王婶家的儿子开了个奶茶店，
"
				+ "说要找个帮忙的。」
"
				+ "你没说好，也没说不好。
"
				+ "但你发现，你居然在认真考虑这件事。

"
				+ "深圳十年，你学会了点外卖、还花呗、挤早高峰。
"
				+ "但你也学会了，什么叫做「够了」。
"
				+ "老家的空气真好，天也蓝得不像话。
"
				+ "你妈做的菜还是那个味，
"
				+ "你觉得，这辈子值了。"
			),
		}
	# 8. 默认：平庸结局
	return {
		"type": "ordinary",
		"title": "【平庸结局】普通人的生活",
		"content": (
			"33岁，说不上好，说不上坏。
"
			+ "你没有成为精英，也没有一败涂地。
"
			+ "你就是深圳两千万打工人中最普通的那一个。

"
			+ "城中村的房东涨了房租，你换了个更小的房间。
"
			+ "花呗还有欠款，但每个月都在还。
"
			+ "你偶尔想起刚来深圳时的那些雄心壮志，
"
			+ "然后笑了笑，把外卖盒扔进了垃圾桶。

"
			+ "日子嘛，不就是这么过的。
"
			+ "明天又是周一了。"
		),
	}
