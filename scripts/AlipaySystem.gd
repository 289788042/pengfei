## AlipaySystem.gd - 支服了宝系统管理器
## 负责：支付拦截、支付宝UI、理财操作、花呗还款与分期等全部支付宝逻辑
## 通过 _main 引用 MainGame 节点访问 UI 节点和工具函数
extends RefCounted

const HeavyAppUI = preload("res://scripts/HeavyAppUI.gd")

# ==================== 成员变量 ====================

var _main: Node

# UI 节点引用
var alipay_popup: ColorRect
var label_alipay_balance: Label
var label_alipay_huabei: Label
var label_alipay_warning: Label
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
var _alipay_pages: Dictionary = {}
var _alipay_tab_buttons: Dictionary = {}
var _current_alipay_tab: String = "overview"
var _label_huabei_detail: Label
var _label_finance_hint: Label
var _label_bill_hint: Label
var _label_about: Label
var _label_overview_risk: Label
var _label_overview_cashflow: Label
var _label_overview_recent: Label
var _label_overview_biggest: Label
var _overview_risk_bar: ProgressBar

# 支付状态
var _pending_pay_cost: int = 0
var _pending_pay_desc: String = ""
var _pending_pay_category: String = ""
var _pending_pay_callback: Callable = Callable()
var _last_payment_changes: Dictionary = {}

# ==================== 初始化 ====================

func init(main: Node) -> void:
	_main = main
	alipay_popup = main.alipay_popup
	label_alipay_balance = main.label_alipay_balance
	label_alipay_huabei = main.label_alipay_huabei
	label_alipay_warning = alipay_popup.find_child("LabelAlipayWarning", true, false) as Label
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
	_setup_phone_alipay_ui()

# ==================== 辅助方法 ====================

func main_node() -> Node:
	return _main


func get_last_payment_changes() -> Dictionary:
	return _last_payment_changes.duplicate()


func _setup_phone_alipay_ui() -> void:
	if not is_instance_valid(alipay_popup):
		return
	HeavyAppUI.setup_layer(
		alipay_popup,
		main_node(),
		80,
		Vector2(960, 760),
		Color(0.015, 0.020, 0.026, 0.66),
		Color(0.945, 0.975, 0.990, 1.0),
		Color(0.12, 0.45, 0.62, 0.35)
	)

	var vbox := label_alipay_balance.get_parent() as VBoxContainer
	if vbox:
		_rebuild_expanded_alipay_layout(vbox)

	_style_label(label_alipay_balance, 18, Color(0.06, 0.13, 0.17, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_style_label(label_alipay_huabei, 14, Color(0.28, 0.09, 0.08, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_style_label(label_alipay_warning, 12, Color(0.78, 0.30, 0.08, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_style_label(label_al_fin_safe, 13, Color(0.10, 0.18, 0.22, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_style_label(label_al_fin_risk, 13, Color(0.10, 0.18, 0.22, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_style_label(label_al_installment, 12, Color(0.55, 0.18, 0.13, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_style_label(label_al_summary, 12, Color(0.16, 0.22, 0.25, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	if is_instance_valid(label_al_summary):
		label_al_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if is_instance_valid(input_repay_amount):
		input_repay_amount.placeholder_text = "还款金额"
		input_repay_amount.custom_minimum_size = Vector2(0, 36)
		input_repay_amount.add_theme_font_size_override("font_size", 13)
		input_repay_amount.add_theme_stylebox_override("normal", _make_style(Color(1, 1, 1, 1), Color(0.65, 0.78, 0.84, 1), 1, 8))
	_style_button(btn_al_fin_safe_in, Color(0.10, 0.62, 0.48, 1), Color(0.08, 0.72, 0.55, 1))
	_style_button(btn_al_fin_safe_out, Color(0.14, 0.30, 0.38, 1), Color(0.17, 0.38, 0.48, 1))
	_style_button(btn_al_fin_risk_in, Color(0.69, 0.37, 0.12, 1), Color(0.80, 0.45, 0.16, 1))
	_style_button(btn_al_fin_risk_out, Color(0.38, 0.30, 0.26, 1), Color(0.46, 0.37, 0.32, 1))
	_style_button(btn_repay_huabei, Color(0.05, 0.50, 0.82, 1), Color(0.07, 0.60, 0.94, 1))
	_style_button(btn_installment, Color(0.80, 0.24, 0.20, 1), Color(0.92, 0.31, 0.24, 1))

	var scroll := alipay_log_container.get_parent() as ScrollContainer
	if scroll:
		scroll.custom_minimum_size = Vector2(0, 120)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_select_alipay_tab("overview")


func _detach_from_parent(node: Node) -> void:
	HeavyAppUI.detach_from_parent(node)


func _rebuild_expanded_alipay_layout(vbox: VBoxContainer) -> void:
	var keep_nodes: Array[Node] = [
		label_alipay_balance,
		label_alipay_huabei,
		label_alipay_warning,
		label_al_fin_safe,
		label_al_fin_risk,
		btn_al_fin_safe_in,
		btn_al_fin_risk_in,
		btn_al_fin_safe_out,
		btn_al_fin_risk_out,
		alipay_log_container,
		btn_close_alipay,
		label_al_installment,
		btn_repay_huabei,
		btn_installment,
		label_al_summary,
		input_repay_amount,
	]
	for node: Node in keep_nodes:
		_detach_from_parent(node)
	for child: Node in vbox.get_children():
		child.queue_free()

	vbox.add_theme_constant_override("separation", 0)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var header := _build_alipay_header()
	vbox.add_child(header)

	var body := HBoxContainer.new()
	body.name = "AlipayExpandedBody"
	body.add_theme_constant_override("separation", 14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(body)

	var nav := VBoxContainer.new()
	nav.name = "AlipayNav"
	nav.custom_minimum_size = Vector2(138, 0)
	nav.add_theme_constant_override("separation", 8)
	body.add_child(nav)

	var content_panel := PanelContainer.new()
	content_panel.name = "AlipayContentPanel"
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_panel.add_theme_stylebox_override("panel", _make_style(Color(1, 1, 1, 1), Color(0.70, 0.82, 0.88, 1), 1, 10))
	body.add_child(content_panel)

	var margin := MarginContainer.new()
	margin.name = "AlipayContentMargin"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	content_panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.name = "AlipayContentScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var page_stack := VBoxContainer.new()
	page_stack.name = "AlipayPageStack"
	page_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(page_stack)

	_alipay_pages.clear()
	_alipay_tab_buttons.clear()
	_add_alipay_tab(nav, "overview", "总览")
	_add_alipay_tab(nav, "huabei", "花呗")
	_add_alipay_tab(nav, "finance", "理财")
	_add_alipay_tab(nav, "bill", "账单")
	_add_alipay_tab(nav, "about", "关于")

	_build_overview_page(page_stack)
	_build_huabei_page(page_stack)
	_build_finance_page(page_stack)
	_build_bill_page(page_stack)
	_build_about_page(page_stack)


func _build_alipay_header() -> Control:
	var header := PanelContainer.new()
	header.name = "AlipayExpandedHeader"
	header.custom_minimum_size = Vector2(0, 70)
	header.add_theme_stylebox_override("panel", _make_style(Color(0.03, 0.23, 0.31, 1), Color(0.10, 0.45, 0.58, 0.45), 1, 12))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	header.add_child(margin)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	hbox.add_child(title_box)
	var title := Label.new()
	title.text = "支服了宝"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	title_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "现金、花呗、分期、理财和账单记录"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.90, 0.94, 1))
	title_box.add_child(subtitle)
	_detach_from_parent(btn_close_alipay)
	btn_close_alipay.text = "×"
	btn_close_alipay.custom_minimum_size = Vector2(46, 40)
	btn_close_alipay.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn_close_alipay.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_close_alipay.tooltip_text = "关闭支付宝"
	_style_button(btn_close_alipay, Color(0.86, 0.92, 0.95, 1), Color(0.76, 0.86, 0.92, 1), Color(0.05, 0.18, 0.24, 1))
	hbox.add_child(btn_close_alipay)
	return header


func _make_page(page_id: String, parent: Node) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = "AlipayPage_" + page_id
	page.add_theme_constant_override("separation", 12)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.visible = false
	parent.add_child(page)
	_alipay_pages[page_id] = page
	return page


func _add_alipay_tab(parent: VBoxContainer, page_id: String, label: String) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 42)
	btn.focus_mode = Control.FOCUS_NONE
	var captured_id := page_id
	btn.pressed.connect(func() -> void:
		_select_alipay_tab(captured_id)
	)
	parent.add_child(btn)
	_alipay_tab_buttons[page_id] = btn


func _select_alipay_tab(page_id: String) -> void:
	if not _alipay_pages.has(page_id):
		return
	_current_alipay_tab = page_id
	for key: String in _alipay_pages.keys():
		var page := _alipay_pages[key] as Control
		if is_instance_valid(page):
			var active := key == page_id
			page.visible = active
			_set_alipay_page_input_mode(page, active)
	for key: String in _alipay_tab_buttons.keys():
		var btn := _alipay_tab_buttons[key] as Button
		_style_tab_button(btn, key == page_id)


func _set_alipay_page_input_mode(root: Node, active: bool) -> void:
	if root is Control:
		var control := root as Control
		control.mouse_filter = Control.MOUSE_FILTER_PASS if active else Control.MOUSE_FILTER_IGNORE
	for child: Node in root.get_children():
		_set_alipay_page_input_mode(child, active)


func _style_tab_button(button: Button, selected: bool) -> void:
	if not is_instance_valid(button):
		return
	button.add_theme_font_size_override("font_size", 15)
	if selected:
		_style_button(button, Color(0.05, 0.48, 0.70, 1), Color(0.06, 0.56, 0.80, 1), Color.WHITE)
	else:
		_style_button(button, Color(0.88, 0.94, 0.96, 1), Color(0.80, 0.90, 0.94, 1), Color(0.05, 0.20, 0.26, 1))


func _build_overview_page(parent: Node) -> void:
	var page := _make_page("overview", parent)
	_add_section_title(page, "财务总览")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(grid)
	_add_card(grid, "现金", [label_alipay_balance])
	_add_card(grid, "花呗", [label_alipay_huabei])
	_add_card(grid, "月底压力", [label_al_summary])
	_add_card(grid, "系统提示", [label_alipay_warning])

	_overview_risk_bar = ProgressBar.new()
	_overview_risk_bar.min_value = 0
	_overview_risk_bar.max_value = 100
	_overview_risk_bar.value = 0
	_overview_risk_bar.show_percentage = false
	_overview_risk_bar.custom_minimum_size = Vector2(0, 16)
	_overview_risk_bar.add_theme_stylebox_override("background", _make_style(Color(0.90, 0.95, 0.96, 1), Color(0.76, 0.86, 0.90, 1), 1, 8))
	_label_overview_risk = _make_body_label("")
	_add_card(page, "月末风险条", [_overview_risk_bar, _label_overview_risk])

	var detail_grid := GridContainer.new()
	detail_grid.columns = 2
	detail_grid.add_theme_constant_override("h_separation", 12)
	detail_grid.add_theme_constant_override("v_separation", 12)
	detail_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(detail_grid)
	_label_overview_recent = _make_body_label("")
	_label_overview_biggest = _make_body_label("")
	_add_card(detail_grid, "近三笔流水", [_label_overview_recent])
	_add_card(detail_grid, "本月最大支出", [_label_overview_biggest])

	_label_overview_cashflow = _make_body_label("")
	_add_card(page, "现金流拆解", [_label_overview_cashflow])


func _build_huabei_page(parent: Node) -> void:
	var page := _make_page("huabei", parent)
	_add_section_title(page, "花呗与分期")
	_label_huabei_detail = _make_body_label("")
	_add_card(page, "当前债务", [_label_huabei_detail])
	_add_card(page, "还款", [input_repay_amount, btn_repay_huabei])
	_add_card(page, "分期", [label_al_installment, btn_installment])
	var tip := _make_body_label("最低还款只解决本月现金流，不会让债务消失。分期会降低短期压力，但总还款会增加。")
	_add_card(page, "说明", [tip])


func _build_finance_page(parent: Node) -> void:
	var page := _make_page("finance", parent)
	_add_section_title(page, "理财")
	_label_finance_hint = _make_body_label("稳健宝收益低但稳定；高风险基金可能翻身，也可能把月底现金流打穿。这里不是福利按钮，是风险选择。")
	_add_card(page, "规则", [_label_finance_hint])
	_add_card(page, "稳健宝", [label_al_fin_safe, btn_al_fin_safe_in, btn_al_fin_safe_out])
	_add_card(page, "高风险基金", [label_al_fin_risk, btn_al_fin_risk_in, btn_al_fin_risk_out])


func _build_bill_page(parent: Node) -> void:
	var page := _make_page("bill", parent)
	_add_section_title(page, "流水账单")
	_label_bill_hint = _make_body_label("")
	_add_card(page, "本月判断", [_label_bill_hint])
	_add_card(page, "最近流水", [alipay_log_container])


func _build_about_page(parent: Node) -> void:
	var page := _make_page("about", parent)
	_add_section_title(page, "关于支服了宝")
	_label_about = _make_body_label(
		"这里是你的财务中枢。\n\n" +
		"1. 总览看现金、花呗和月底预计现金。\n" +
		"2. 花呗页可以主动还款，也可以在欠款较高时办理分期。\n" +
		"3. 理财不是稳定变富按钮，高风险基金会在月末结算波动。\n" +
		"4. 账单页记录收入、消费和花呗透支，方便复盘为什么钱没了。\n\n" +
		"游戏建议：每次大额消费后都回来看一眼月底预计现金。你不是输在买了一件东西，而是输在每一笔都以为下个月再说。"
	)
	_add_card(page, "使用说明", [_label_about])


func _add_section_title(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.05, 0.18, 0.24, 1))
	parent.add_child(label)


func _make_body_label(text: String) -> Label:
	return HeavyAppUI.make_body_label(text, 14, Color(0.12, 0.20, 0.24, 1))


func _add_card(parent: Node, title: String, controls: Array) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_style(Color(0.965, 0.985, 0.992, 1), Color(0.78, 0.88, 0.92, 1), 1, 9))
	parent.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(box)
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color(0.04, 0.28, 0.36, 1))
	box.add_child(title_label)
	for control_variant in controls:
		var control := control_variant as Control
		if not is_instance_valid(control):
			continue
		_detach_from_parent(control)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(control)


func _ensure_alipay_header(vbox: VBoxContainer) -> void:
	var header := vbox.get_node_or_null("AlipayHeader") as HBoxContainer
	if not header:
		header = HBoxContainer.new()
		header.name = "AlipayHeader"
		header.custom_minimum_size = Vector2(0, 42)
		header.add_theme_constant_override("separation", 8)
		var title := Label.new()
		title.name = "AlipayTitle"
		title.text = "支服了宝"
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 20)
		title.add_theme_color_override("font_color", Color(0.02, 0.20, 0.28, 1))
		header.add_child(title)
		vbox.add_child(header)
		vbox.move_child(header, 0)
	if is_instance_valid(btn_close_alipay) and btn_close_alipay.get_parent() != header:
		var old_parent := btn_close_alipay.get_parent()
		if old_parent:
			old_parent.remove_child(btn_close_alipay)
		header.add_child(btn_close_alipay)
	btn_close_alipay.text = "×"
	btn_close_alipay.custom_minimum_size = Vector2(42, 36)
	btn_close_alipay.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn_close_alipay.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_close_alipay.tooltip_text = "关闭支付宝"
	_style_button(btn_close_alipay, Color(0.86, 0.92, 0.95, 1), Color(0.76, 0.86, 0.92, 1), Color(0.05, 0.18, 0.24, 1))


func _make_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	return HeavyAppUI.make_flat_style(bg, border, border_width, radius)


func _style_button(button: Button, normal: Color, hover: Color, font_color: Color = Color.WHITE) -> void:
	HeavyAppUI.style_text_button(button, normal, hover, font_color)


func _style_label(label: Label, font_size: int, color: Color, align = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	if not is_instance_valid(label):
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align


# ==================== 通用支付拦截系统 ====================

func request_payment(cost: int, desc: String, category: String, on_success: Callable) -> void:
	_pending_pay_cost = cost
	_pending_pay_desc = desc
	_pending_pay_category = category
	_pending_pay_callback = on_success
	_last_payment_changes = {}
	label_payment_cost.text = "请选择支付方式\n（本次消费：%d 元）" % cost
	if main_node().has_method("set_ui_layer_visible"):
		main_node().set_ui_layer_visible(payment_popup, true, false)
	else:
		payment_popup.visible = true

func _on_pay_mix() -> void:
	if GameManager.money < _pending_pay_cost:
		main_node().show_message("现金余额不足！当前余额：%d 元" % GameManager.money)
		return
	var cost := _pending_pay_cost
	GameManager.modify_stat("money", -cost)
	_last_payment_changes = {"money": -cost}
	GameManager.add_finance(-cost, _pending_pay_desc, false)
	GameManager.add_activity(_pending_pay_category, _pending_pay_desc + "现金支付")
	_finish_payment()
func _on_pay_huabei() -> void:
	GameManager.huabei_debt += _pending_pay_cost
	GameManager.credit_debt = GameManager.huabei_debt
	_last_payment_changes = {"credit_debt": _pending_pay_cost}
	GameManager.add_finance(-_pending_pay_cost, _pending_pay_desc, true)
	GameManager.add_activity(_pending_pay_category, _pending_pay_desc + "（花呗透支）")
	_finish_payment()

func _on_pay_cancel() -> void:
	if main_node().has_method("set_ui_layer_visible"):
		main_node().set_ui_layer_visible(payment_popup, false)
	else:
		payment_popup.visible = false
	_pending_pay_callback = Callable()

func _finish_payment() -> void:
	if main_node().has_method("set_ui_layer_visible"):
		main_node().set_ui_layer_visible(payment_popup, false)
	else:
		payment_popup.visible = false
	var cb := _pending_pay_callback
	_pending_pay_callback = Callable()
	if cb.is_valid():
		cb.call()
	main_node()._refresh_ui()


# ==================== 支服了宝 UI ====================

func _refresh_alipay_ui() -> void:
	_style_label(label_alipay_balance, 22, Color(0.06, 0.13, 0.17, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	label_alipay_balance.text = "现金余额  %d" % GameManager.money

	var combined_debt := GameManager.huabei_debt + GameManager.huabei_installment_debt
	if combined_debt > 0:
		label_alipay_huabei.add_theme_color_override("font_color", Color(0.76, 0.12, 0.10, 1))
		var huabei_min := mini(int(GameManager.huabei_debt * 0.1 + 200), GameManager.huabei_debt)
		var debt_detail := "花呗总欠款  %d" % combined_debt
		if GameManager.huabei_debt > 0:
			debt_detail += "\n未分期 %d  |  本月最低还款 %d" % [GameManager.huabei_debt, huabei_min]
		if GameManager.huabei_installment_debt > 0:
			debt_detail += "\n分期剩余本金 %d  |  本月月供 %d" % [GameManager.huabei_installment_debt, GameManager.huabei_installment_monthly_pay]
		label_alipay_huabei.text = debt_detail
	else:
		label_alipay_huabei.add_theme_color_override("font_color", Color(0.027, 0.757, 0.376, 1))
		label_alipay_huabei.text = "花呗欠款  0\n信用良好，别主动给自己挖坑。"
	var month_preview := _get_month_end_preview_safe()
	var month_cash_after := int(month_preview.get("cash_after_all", GameManager.get_projected_balance()))
	var full_clear_balance := GameManager.get_projected_balance()
	if is_instance_valid(_label_huabei_detail):
		_label_huabei_detail.text = label_alipay_huabei.text + "\n\n当前现金：%d\n月底结算后现金：%d\n全额还清后现金：%d" % [GameManager.money, month_cash_after, full_clear_balance]

	label_al_fin_safe.add_theme_color_override("font_color", Color(0.10, 0.18, 0.22, 1))
	label_al_fin_safe.text = "稳健宝  %d  |  约 +5%% / 月" % GameManager.invest_safe
	label_al_fin_risk.add_theme_color_override("font_color", Color(0.10, 0.18, 0.22, 1))
	label_al_fin_risk.text = "高风险基金  %d  |  -30%% ~ +40%% / 月" % GameManager.invest_risk
	btn_al_fin_safe_in.text = "存入 500 到稳健宝"
	btn_al_fin_safe_out.text = "全部取出稳健宝"
	btn_al_fin_risk_in.text = "存入 500 到高风险"
	btn_al_fin_risk_out.text = "全部取出高风险"

	var total_debt := GameManager.huabei_debt + GameManager.huabei_installment_debt
	label_al_summary.add_theme_color_override("font_color", Color(0.16, 0.22, 0.25, 1))
	label_al_summary.text = "月底结算后现金  %d\n全额还清后现金  %d\n待扣：房租 %d / 餐饮 %d / 花呗债务 %d" % [month_cash_after, full_clear_balance, GameManager.base_rent, GameManager.monthly_food_cost, total_debt]
	if is_instance_valid(label_alipay_warning):
		if month_cash_after < 0:
			label_alipay_warning.text = "预警：按当前账单，月底现金会变负。先停消费，优先打工或还款。"
		elif total_debt > 0:
			label_alipay_warning.text = "提示：最低还款只能缓一口气，剩余债务仍会留到后面。"
		else:
			label_alipay_warning.text = "提示：当前没有花呗压力，别把安全感花掉。"
		label_alipay_warning.visible = true

	if GameManager.huabei_installment_months_left > 0:
		var left_pay_total := GameManager.huabei_installment_monthly_pay * GameManager.huabei_installment_months_left
		var left_fee_est := maxi(left_pay_total - GameManager.huabei_installment_debt, 0)
		label_al_installment.text = "分期进行中：剩余 %d / 12 期\n每月固定扣款 %d  |  剩余本金 %d  |  预计手续费 %d" % [GameManager.huabei_installment_months_left, GameManager.huabei_installment_monthly_pay, GameManager.huabei_installment_debt, left_fee_est]
		label_al_installment.visible = true
		btn_installment.disabled = true
		btn_installment.text = "分期进行中：剩余 %d 期" % GameManager.huabei_installment_months_left
	else:
		if GameManager.huabei_debt >= 3000:
			btn_installment.disabled = false
			btn_installment.text = "办理 12 期分期（总手续费 15%）"
		else:
			btn_installment.disabled = true
			btn_installment.text = "欠款不足 3000，暂不能分期"
		label_al_installment.text = "分期信息：无"

	btn_repay_huabei.text = "确认还款"
	if is_instance_valid(_label_bill_hint):
		var log_count := GameManager.financial_log.size()
		var huabei_count := 0
		for entry: Dictionary in GameManager.financial_log:
			if bool(entry.get("is_huabei", false)):
				huabei_count += 1
		_label_bill_hint.text = "已记录 %d 条流水，其中 %d 条使用花呗。负数是支出，带 [花呗] 的支出会变成未来压力。" % [log_count, huabei_count]
	_refresh_overview_summary()
	_refresh_alipay_log()


func _refresh_overview_summary() -> void:
	var month_start_week := GameManager.turn_count - GameManager.week_in_month + 1
	var income_total := 0
	var cash_spend_total := 0
	var huabei_spend_total := 0
	var biggest_spend_amount := 0
	var biggest_spend_entry: Dictionary = {}
	var recent_lines: Array = []
	var recent_count := 0
	for i: int in range(GameManager.financial_log.size() - 1, -1, -1):
		var entry: Dictionary = GameManager.financial_log[i]
		var week := int(entry.get("week", 0))
		if week < month_start_week:
			continue
		var amount := int(entry.get("amount", 0))
		var is_huabei := bool(entry.get("is_huabei", false))
		if recent_count < 3:
			recent_lines.append(_format_finance_line(entry))
			recent_count += 1
		if amount >= 0:
			income_total += amount
		elif is_huabei:
			huabei_spend_total += -amount
		else:
			cash_spend_total += -amount
		if amount < 0 and -amount > biggest_spend_amount:
			biggest_spend_amount = -amount
			biggest_spend_entry = entry

	var month_preview := _get_month_end_preview_safe()
	var total_debt := GameManager.huabei_debt + GameManager.huabei_installment_debt
	var available := GameManager.money + GameManager.pending_salary + GameManager.invest_safe + GameManager.invest_risk
	var fixed_due := int(month_preview.get("mandatory_cost", GameManager.base_rent + GameManager.monthly_food_cost + total_debt))
	var month_cash_after := int(month_preview.get("cash_after_all", GameManager.get_projected_balance()))
	var full_clear_balance := GameManager.get_projected_balance()
	var risk_score := _calc_overview_risk_score(available, fixed_due, total_debt, month_cash_after)
	var risk_color := _overview_risk_color(risk_score)
	if is_instance_valid(_overview_risk_bar):
		_overview_risk_bar.value = risk_score
		_overview_risk_bar.add_theme_stylebox_override("fill", _make_style(risk_color, risk_color, 0, 8))

	if is_instance_valid(_label_overview_risk):
		_label_overview_risk.add_theme_color_override("font_color", _overview_risk_text_color(risk_score))
		_label_overview_risk.text = "风险 %d/100｜%s\n%s" % [risk_score, _overview_risk_level(risk_score), _overview_risk_advice(month_cash_after, total_debt, GameManager.money)]

	if is_instance_valid(_label_overview_cashflow):
		_label_overview_cashflow.text = (
			"本月入账：+%d\n现金支出：-%d｜花呗支出：-%d\n可用资金：%d｜月底固定待扣：%d\n月底结算后：%d｜全额还清后：%d"
			% [income_total, cash_spend_total, huabei_spend_total, available, fixed_due, month_cash_after, full_clear_balance]
		)

	if is_instance_valid(_label_overview_recent):
		if recent_lines.is_empty():
			_label_overview_recent.text = "本月暂无流水。消费、工资、还款和理财操作会出现在这里。"
		else:
			_label_overview_recent.text = "\n".join(recent_lines)

	if is_instance_valid(_label_overview_biggest):
		if biggest_spend_entry.is_empty():
			_label_overview_biggest.text = "本月暂无支出。现在的安全感来自你还没开始花钱。"
		else:
			var tag := "花呗透支" if bool(biggest_spend_entry.get("is_huabei", false)) else "现金支付"
			_label_overview_biggest.text = "%s\n金额：-%d｜方式：%s\n这笔最扎眼，月底压力基本就是这样一点点堆起来的。" % [
				str(biggest_spend_entry.get("desc", "未知支出")),
				biggest_spend_amount,
				tag
			]


func _calc_overview_risk_score(available: int, fixed_due: int, total_debt: int, projected: int) -> int:
	if projected < 0:
		return 100
	var pressure := float(fixed_due) / maxf(float(available), 1.0)
	var debt_pressure := float(total_debt) / maxf(float(GameManager.money + GameManager.pending_salary), 1.0)
	return int(clampf(pressure * 72.0 + debt_pressure * 28.0, 0.0, 100.0))


func _overview_risk_level(score: int) -> String:
	if score >= 85:
		return "危险"
	if score >= 60:
		return "紧张"
	if score >= 35:
		return "可控"
	return "安全"


func _overview_risk_color(score: int) -> Color:
	if score >= 85:
		return Color(0.82, 0.16, 0.12, 1)
	if score >= 60:
		return Color(0.88, 0.48, 0.12, 1)
	if score >= 35:
		return Color(0.08, 0.50, 0.70, 1)
	return Color(0.08, 0.62, 0.42, 1)


func _overview_risk_text_color(score: int) -> Color:
	if score >= 85:
		return Color(0.72, 0.08, 0.06, 1)
	if score >= 60:
		return Color(0.64, 0.28, 0.04, 1)
	return Color(0.12, 0.20, 0.24, 1)


func _overview_risk_advice(projected: int, total_debt: int, cash: int) -> String:
	if projected < 0:
		return "马上处理：暂停消费，优先打工或还款。当前节奏会让月底现金变负。"
	if total_debt > cash:
		return "注意：花呗压力已经高过现金安全垫。继续透支会把下个月也拖下水。"
	if projected < GameManager.base_rent:
		return "提醒：月底剩余现金接近一间房租，别再把风险藏到花呗里。"
	return "当前还算稳，但每一笔大额消费后都应该回来看一次。"


func _format_finance_line(entry: Dictionary) -> String:
	var amount := int(entry.get("amount", 0))
	var sign_str := "+" if amount >= 0 else ""
	var hb_tag := " [花呗]" if bool(entry.get("is_huabei", false)) else ""
	return "[第%d周] %s%s：%s%d" % [int(entry.get("week", 0)), str(entry.get("desc", "")), hb_tag, sign_str, amount]


func _get_month_end_preview_safe() -> Dictionary:
	if is_instance_valid(main_node()) and main_node().has_method("_get_month_end_preview"):
		var preview = main_node().call("_get_month_end_preview")
		if preview is Dictionary:
			return preview
	return {}


func _refresh_alipay_ui_legacy_unused() -> void:
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
	for child: Node in alipay_log_container.get_children():
		child.queue_free()
	var logs: Array = GameManager.financial_log
	if logs.is_empty():
		var empty_label := Label.new()
		empty_label.text = "暂无流水。消费、工资、还款和理财操作会记录在这里。"
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.add_theme_color_override("font_color", Color(0.40, 0.50, 0.55, 1))
		alipay_log_container.add_child(empty_label)
		return
	var start_idx := maxi(0, logs.size() - 30)
	for i: int in range(start_idx, logs.size()):
		var entry: Dictionary = logs[i]
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 12)
		var sign_str := "+" if entry["amount"] >= 0 else ""
		var hb_tag := " [花呗]" if entry.get("is_huabei", false) else ""
		lbl.text = "[第%d周] %s%s：%s%d" % [entry["week"], entry["desc"], hb_tag, sign_str, entry["amount"]]
		if entry["amount"] >= 0:
			lbl.add_theme_color_override("font_color", Color(0.09, 0.55, 0.27, 1))
		else:
			lbl.add_theme_color_override("font_color", Color(0.76, 0.12, 0.10, 1))
		alipay_log_container.add_child(lbl)


func _refresh_alipay_log_legacy_unused() -> void:
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
	if main_node().has_method("set_ui_layer_visible"):
		main_node().set_ui_layer_visible(alipay_popup, false)
	else:
		alipay_popup.visible = false

# 支服了宝 - 理财操作
func _on_al_fin_safe_in() -> void:
	if GameManager.money < 500:
		main_node().show_message("活期余额不足 500，无法存入！")
		return
	GameManager.modify_stat("money", -500)
	GameManager.invest_safe += 500
	GameManager.add_finance(-500, "存入稳健宝", false)
	main_node().float_stat("-500 存入稳健宝", -500, main_node().get_global_mouse_position())
	main_node().show_message("成功存入 500 到稳健宝！")
	_refresh_alipay_ui()

func _on_al_fin_risk_in() -> void:
	if GameManager.money < 500:
		main_node().show_message("活期余额不足 500，无法存入！")
		return
	GameManager.modify_stat("money", -500)
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
	GameManager.modify_stat("money", amount)
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
	GameManager.modify_stat("money", amount)
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
	GameManager.modify_stat("money", -remaining)
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
