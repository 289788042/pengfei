## AlipaySystem.gd - 支服了宝系统管理器
## 负责：支付拦截、支付宝UI、理财操作、花呗还款与分期等全部支付宝逻辑
## 通过 _main 引用 MainGame 节点访问 UI 节点和工具函数
extends RefCounted

# ==================== 成员变量 ====================

var _main: Node

# UI 节点引用
var alipay_popup: ColorRect
var label_alipay_balance: Label
var label_alipay_huabei: Label
var label_al_fin_safe: Label
var label_al_fin_risk: Label
var btn_al_fin_safe_in: Button
var btn_al_fin_risk_in: Button
var btn_al_fin_safe_out: Button
var btn_al_fin_risk_out: Button
var alipay_log_container: VBoxContainer
var btn_close_alipay: Button
var label_al_installment: Label
var btn_repay_huabei: Button
var btn_installment: Button
var label_al_summary: Label
var input_repay_amount: LineEdit
var label_payment_cost: Label
var payment_popup: ColorRect

# 支付状态
var _pending_pay_cost: int = 0
var _pending_pay_desc: String = ""
var _pending_pay_category: String = ""
var _pending_pay_callback: Callable = Callable()

# ==================== 初始化 ====================

func init(main: Node) -> void:
	_main = main
	alipay_popup = main.alipay_popup
	label_alipay_balance = main.label_alipay_balance
	label_alipay_huabei = main.label_alipay_huabei
	label_al_fin_safe = main.label_al_fin_safe
	label_al_fin_risk = main.label_al_fin_risk
	btn_al_fin_safe_in = main.btn_al_fin_safe_in
	btn_al_fin_risk_in = main.btn_al_fin_risk_in
	btn_al_fin_safe_out = main.btn_al_fin_safe_out
	btn_al_fin_risk_out = main.btn_al_fin_risk_out
	alipay_log_container = main.alipay_log_container
	btn_close_alipay = main.btn_close_alipay
	label_al_installment = main.label_al_installment
	btn_repay_huabei = main.btn_repay_huabei
	btn_installment = main.btn_installment
	label_al_summary = main.label_al_summary
	input_repay_amount = main.input_repay_amount
	label_payment_cost = main.label_payment_cost
	payment_popup = main.payment_popup

# ==================== 辅助方法 ====================

func main_node() -> Node:
	return _main


# ==================== 通用支付拦截系统 ====================

func request_payment(cost: int, desc: String, category: String, on_success: Callable) -> void:
	_pending_pay_cost = cost
	_pending_pay_desc = desc
	_pending_pay_category = category
	_pending_pay_callback = on_success
	label_payment_cost.text = "请选择支付方式\n（本次消费：%d 元）" % cost
	# 隐藏可能遮挡支付弹窗的微信菜单
	_main.wechat_menu.visible = false
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
	main_node()._refresh_ui()


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
	label_al_summary.text = "【预计月末资产】：%d\n房租：%d | 餐饮累计：%d | 花呗总欠：%d" % [proj, GameManager.base_rent, GameManager.monthly_food_cost, total_debt]

	if GameManager.huabei_installment_months_left > 0:
		var total_installment := GameManager.huabei_installment_monthly_pay * 12
		var installment_fee := total_installment - GameManager.huabei_installment_debt
		label_al_installment.text = "【分期进行中】剩余 %d / 12 期\n	每月固定扣款：%d 元 | 分期本金：%d 元\n	手续费：%d 元 | 总还款额：%d 元" % [GameManager.huabei_installment_months_left, GameManager.huabei_installment_monthly_pay, GameManager.huabei_installment_debt, installment_fee, total_installment]
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
		main_node().show_message("活期余额不足 500，无法存入！")
		return
	GameManager.money -= 500
	GameManager.invest_safe += 500
	GameManager.add_finance(-500, "存入稳健宝", false)
	main_node().float_stat("-500 存入稳健宝", -500, main_node().get_global_mouse_position())
	main_node().show_message("成功存入 500 到稳健宝！")
	_refresh_alipay_ui()

func _on_al_fin_risk_in() -> void:
	if GameManager.money < 500:
		main_node().show_message("活期余额不足 500，无法存入！")
		return
	GameManager.money -= 500
	GameManager.invest_risk += 500
	GameManager.add_finance(-500, "存入高风险基金", false)
	main_node().float_stat("-500 存入高风险", -500, main_node().get_global_mouse_position())
	main_node().show_message("成功存入 500 到高风险基金！祝你好运...")
	_refresh_alipay_ui()

func _on_al_fin_safe_out() -> void:
	if GameManager.invest_safe <= 0:
		main_node().show_message("稳健宝里没有钱可以取出！")
		return
	var amount := GameManager.invest_safe
	GameManager.money += amount
	GameManager.invest_safe = 0
	GameManager.add_finance(amount, "取出稳健宝", false)
	main_node().float_stat("+%d 取出稳健宝" % amount, amount, main_node().get_global_mouse_position())
	main_node().show_message("已从稳健宝取出 %d" % amount)
	_refresh_alipay_ui()

func _on_al_fin_risk_out() -> void:
	if GameManager.invest_risk <= 0:
		main_node().show_message("高风险基金里没有钱可以取出！")
		return
	var amount := GameManager.invest_risk
	GameManager.money += amount
	GameManager.invest_risk = 0
	GameManager.add_finance(amount, "取出高风险基金", false)
	main_node().float_stat("+%d 取出高风险" % amount, amount, main_node().get_global_mouse_position())
	main_node().show_message("已从高风险基金取出 %d" % amount)
	_refresh_alipay_ui()



# ==================== 花呗还款与分期 ====================

## 主动还款：解析输入金额，校验后扣款减债
## 主动还款：先还未分期，再还分期本金（分期本金还清则自动结束分期）
func _on_repay_huabei() -> void:
	var input_text: String = main_node().input_repay_amount.text.strip_edges()
	if input_text == "":
		main_node().show_message("请输入还款金额！")
		return
	var amount: int = input_text.to_int()
	if amount <= 0:
		main_node().show_message("请输入有效的正整数金额！")
		return
	if amount > GameManager.money:
		main_node().show_message("活期余额不足！当前余额：%d" % GameManager.money)
		return
	var combined_debt := GameManager.huabei_debt + GameManager.huabei_installment_debt
	if combined_debt <= 0:
		main_node().show_message("花呗没有欠款，无需还款！")
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
			repay_msg += "\n	"
		repay_msg += "还分期本金 %d 元" % to_installment
		# 分期本金还清了，自动结束分期
		if GameManager.huabei_installment_debt <= 0:
			GameManager.huabei_installment_months_left = 0
			GameManager.huabei_installment_monthly_pay = 0
			if repay_msg != "":
				repay_msg += "\n	"
			repay_msg += "分期已提前还清！"

	var actual_repay := mini(amount, combined_debt)
	GameManager.add_finance(-actual_repay, "花呗主动还款", false)
	main_node().input_repay_amount.text = ""
	main_node().float_stat("还款 -%d" % actual_repay, -actual_repay, main_node().get_global_mouse_position())
	var still_owe := GameManager.huabei_debt + GameManager.huabei_installment_debt
	main_node().show_message("成功还款 %d 元！\n%s\n剩余欠款：%d 元" % [actual_repay, repay_msg, still_owe])
	_refresh_alipay_ui()


func _on_installment() -> void:
	if GameManager.huabei_debt < 3000:
		main_node().show_message("花呗欠款不足 3000，无法办理分期！")
		return
	if GameManager.huabei_installment_months_left > 0:
		main_node().show_message("已有进行中的分期！剩余 %d 期。" % GameManager.huabei_installment_months_left)
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
	main_node().show_message("分期成功！\n分期本金：%d 元\n手续费(15%%)：%d 元\n总还款：%d 元\n每月固定扣款：%d 元，共12期" % [principal, fee_amount, total_with_fee, monthly_pay])
	_refresh_alipay_ui()
