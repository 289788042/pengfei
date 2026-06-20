## TutorialDirector.gd
## Owns early tutorial state and step transitions. MainGame keeps only UI effects.
extends RefCounted

var _main: Node

var _app_gate: String = ""
var _app_tutorial_done: bool = false
var _alipay_tutorial_shown: bool = false
var _overtime_done: bool = false
var _wechat_done: bool = false
var _beach_unlocked: bool = false
var _beach_end_hint_done: bool = false
var _stats_page_flash_started: bool = false
var _second_week_map_hint_shown: bool = false
var _second_week_map_hint_active: bool = false


func init(main: Node) -> void:
	_main = main


func current_gate() -> String:
	return _app_gate


func is_gate(gate: String) -> bool:
	return _app_gate == gate


func is_first_week_context() -> bool:
	return GameManager.month == 1 and GameManager.week_in_month == 1 and GameManager.turn_count == 1


func maybe_start_first_week_app_tutorial() -> void:
	if _app_tutorial_done or _app_gate != "":
		return
	if not is_first_week_context():
		return
	_app_gate = "alipay"
	_main.call("_hide_phone_dim_overlay")
	refresh_first_week_app_focus()


func allow_app_open(app_id: String) -> bool:
	if _app_gate == "":
		return true
	if not is_first_week_context():
		return true
	if _app_gate == "map_beach" and app_id == "map":
		return true
	if app_id == _app_gate:
		return true
	match _app_gate:
		"alipay":
			_main.call("_show_tutorial_dialog", ["先打开支服了宝，看看账单吧"])
		"map":
			_main.call("_show_tutorial_dialog", ["现在打开高德地图，再决定出门去哪。"])
		"wechat":
			_main.call("_show_tutorial_dialog", ["先看看微信吧？别漏掉家人和朋友的信息。"])
		"map_beach":
			_main.call("_show_tutorial_dialog", ["先打开高德地图，去海边散散心。"])
	return false


func refresh_first_week_app_focus() -> void:
	if _app_gate == "":
		_main.call("_stop_phone_focus_pulse")
		return
	var target: Button = null
	match _app_gate:
		"alipay":
			target = _main.get("btn_app_alipay") as Button
			_main.call("_keep_tutorial_app_button_normal", _main.get("btn_app_map"))
			_main.call("_keep_tutorial_app_button_normal", _main.get("btn_app_wechat"))
		"map":
			target = _main.get("btn_app_map") as Button
			_main.call("_keep_tutorial_app_button_normal", _main.get("btn_app_alipay"))
			_main.call("_keep_tutorial_app_button_normal", _main.get("btn_app_wechat"))
		"wechat":
			target = _main.get("btn_app_wechat") as Button
			_main.call("_keep_tutorial_app_button_normal", _main.get("btn_app_alipay"))
			_main.call("_keep_tutorial_app_button_normal", _main.get("btn_app_map"))
		"map_beach":
			target = _main.get("btn_app_map") as Button
			_main.call("_keep_tutorial_app_button_normal", _main.get("btn_app_alipay"))
			_main.call("_keep_tutorial_app_button_normal", _main.get("btn_app_wechat"))
	if is_instance_valid(target):
		target.disabled = false
		target.mouse_filter = Control.MOUSE_FILTER_STOP
		_main.call("_start_phone_focus_pulse", target)


func consume_alipay_tutorial_request() -> bool:
	if _alipay_tutorial_shown:
		return false
	_alipay_tutorial_shown = true
	return true


func on_alipay_closed() -> void:
	if _app_gate != "alipay":
		return
	_app_gate = "map"
	_main.call("_sync_phone_home_apps", true)
	refresh_first_week_app_focus()


func finish_first_week_app_tutorial() -> void:
	_app_gate = ""
	_app_tutorial_done = true
	_main.call("_clear_alipay_tutorial_callouts")
	_main.call("_stop_phone_focus_pulse")
	_main.call("_stop_stats_panel_focus_flash")
	_main.call("_sync_phone_home_apps", true)


func on_map_beach_opened() -> void:
	_app_gate = ""
	_main.call("_stop_phone_focus_pulse")
	_main.call("_sync_phone_home_apps", true)


func on_first_week_location_finished(location: String) -> void:
	if not is_first_week_context():
		return
	if location == "overtime":
		if _overtime_done:
			return
		_overtime_done = true
		_app_gate = "wechat"
		_main.call("_sync_phone_home_apps", true)
		refresh_first_week_app_focus()
		_main.call("_show_tutorial_dialog", [
			"加班回来了，钱是多了一点，情绪也是真的掉了。",
			"先打开[color=6BB7FF]微信[/color]看看吧。家人和朋友的信息，也别完全错过。",
		])
		return
	if location == "park":
		if not _beach_unlocked or _beach_end_hint_done:
			return
		_beach_end_hint_done = true
		_app_gate = ""
		_main.call("_stop_phone_focus_pulse")
		_main.call("_sync_phone_home_apps", true)
		var next_btn := _main.get("btn_next_week") as Button
		if is_instance_valid(next_btn):
			next_btn.disabled = false
			_main.call("_start_phone_focus_pulse", next_btn)
		_main.call("_show_tutorial_dialog", [
			"海边回来，脑子终于松了一点。",
			"这一周你已经学会了看账单、看地图、看微信，也知道了情绪不能一直硬扛。",
			"现在点击右下角的[color=FFD700]结束本周[/color]，进入下一周。以后周末想继续行动就继续，不想逛了也可以直接结束本周。",
		])


func on_wechat_closed() -> void:
	if _app_gate != "wechat":
		return
	if not is_first_week_context():
		return
	if _wechat_done:
		return
	_wechat_done = true
	_beach_unlocked = true
	_app_gate = ""
	_main.call("_stop_phone_focus_pulse")
	_main.call("_sync_phone_home_apps", true)
	show_first_week_stats_tutorial()


func should_finish_first_week_wechat_on_back() -> bool:
	return _app_gate == "wechat" and is_first_week_context()


func is_first_week_beach_route_unlocked() -> bool:
	return is_first_week_context() and _beach_unlocked


func should_pulse_first_week_park_card() -> bool:
	return is_first_week_beach_route_unlocked() and _app_gate == "map_beach"


func show_first_week_stats_tutorial() -> void:
	_stats_page_flash_started = false
	var dialog_box := _main.get("left_dialog_box") as Control
	if is_instance_valid(dialog_box):
		dialog_box.z_index = 220
	_main.call("_hide_phone_dim_overlay")
	_main.galgame.show_galgame_dialog([
		"加班回来，精神紧绷，很疲惫，也有点 emo。",
		"[color=6BB7FF]（加班会减少情绪值，请注意自己的情绪，数值过低会导致严重的后果。）[/color]",
		"[color=6BB7FF]（在这个快节奏的城市里，记得好好照顾自己的心理健康。）[/color]",
		"[color=6BB7FF]（关于自己的所有属性数值，可以在右侧手机的数值面板中看到。手机里正在发光的那个框框就是。）[/color]",
		"别继续硬扛了。打开高德地图，去海边散散心吧。",
	], func() -> void:
		_main.call("_stop_stats_panel_focus_flash")
		_stats_page_flash_started = false
		_app_gate = "map_beach"
		_main.call("_sync_phone_home_apps", true)
		refresh_first_week_app_focus()
	)


func on_galgame_page_started(text: String) -> void:
	if _stats_page_flash_started:
		return
	if not _wechat_done or not _beach_unlocked:
		return
	var mentions_glow := text.find("发光") >= 0 or text.find("鍙戝厜") >= 0
	var mentions_stats_panel := text.find("数值面板") >= 0 or text.find("手机") >= 0 or text.find("鏁板€奸潰鏉?") >= 0 or text.find("鎵嬫満") >= 0
	if not mentions_glow or not mentions_stats_panel:
		return
	_stats_page_flash_started = true
	_main.call("_start_stats_panel_focus_flash")


func maybe_show_second_week_map_hint() -> void:
	if _second_week_map_hint_shown:
		return
	if _main.get("current_phase") != _main.Phase.WEEKEND:
		return
	if GameManager.month != 1 or GameManager.week_in_month != 2:
		return
	if _main.call("has_blocking_dialog") or _main.call("_has_active_blocking_layer"):
		_main.call_deferred("_maybe_show_second_week_map_hint")
		return
	_second_week_map_hint_shown = true
	_second_week_map_hint_active = true
	_main.call("_sync_phone_home_apps", true)
	var map_btn := _main.get("btn_app_map") as Button
	if is_instance_valid(map_btn):
		_main.call("_start_phone_focus_pulse", map_btn)
	_main.call("_show_tutorial_dialog", [
		"新的周末到了。",
		"高德地图里有新地点解锁了，可以打开看看。这个周末不一定只剩加班，也可以去更日常的地方喘口气。",
	])


func is_second_week_map_hint_active() -> bool:
	return _second_week_map_hint_active


func clear_second_week_map_hint() -> void:
	if not _second_week_map_hint_active:
		return
	_second_week_map_hint_active = false
	_main.call("_stop_phone_focus_pulse")
