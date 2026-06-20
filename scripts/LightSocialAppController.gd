## LightSocialAppController.gd
## Owns lightweight social apps: zodiac and swipe dating.
extends RefCounted

var _main: Node
var _app: RefCounted

var _dating_names: Array = [
	"王大壮", "李富贵", "张天宇", "赵子龙", "刘星",
	"陈浩南", "周杰", "吴彦组", "孙小宝", "马赛克",
	"钱多多", "郑经", "冯提莫", "何老师", "罗永亮",
]

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
	"佛系男，随缘哈",
	"创业合伙人，带你飞",
	"摄影师，只拍女朋友",
	"摩托车爱好者，带你兜风",
]


func init(main: Node, app_system: RefCounted) -> void:
	_main = main
	_app = app_system


func open_zodiac() -> void:
	if not _app._can_open_phone_app():
		return
	if not _app._ensure_app_unlocked("zodiac"):
		return
	_app._close_all_menus()
	_app.label_zodiac_content.text = "亲爱的%s宝宝，本周运势：\n请注意控制消费，警惕烂桃花哦！" % GameManager.player_zodiac
	_app._set_layer_visible(_app.zodiac_popup, true)


func close_zodiac() -> void:
	_app._set_layer_visible(_app.zodiac_popup, false)


func open_dating() -> void:
	if not _app._can_open_phone_app():
		return
	if not _app._ensure_app_unlocked("dating"):
		return
	_app._close_all_menus()
	if GameManager.charm < 10:
		_main.show_message("颜值太低（需>=10），没有匹配对象！先提升自己吧～")
		return
	refresh_dating_card()
	_app._set_layer_visible(_app.dating_popup, true)


func refresh_dating_card() -> void:
	var name_idx: int = randi() % _dating_names.size()
	var bio_idx: int = randi() % _dating_bios.size()
	var age_val: int = 25 + (randi() % 11)
	_app.label_date_name.text = _dating_names[name_idx]
	_app.label_date_age.text = "年龄：%d岁 | 身高：%dcm" % [age_val, 170 + (randi() % 16)]
	_app.label_date_bio.text = "「%s」" % _dating_bios[bio_idx]


func on_pass() -> void:
	if GameManager.energy < 5:
		_main.show_message("精力不足，没力气滑了！")
		return
	GameManager.modify_stat("energy", -5)
	refresh_dating_card()


func on_like() -> void:
	if GameManager.energy < 5:
		_main.show_message("精力不足，没力气滑了！")
		return
	var score: int = GameManager.charm + GameManager.eq
	var roll: int = randi() % 100
	var scam_chance: int = 70 - score
	if scam_chance < 20:
		scam_chance = 20
	var changes := {"energy": -5}
	var story := ""
	if roll < scam_chance:
		changes["money"] = -500
		changes["sanity"] = -15
		story = "你以为对面是真心聊天，结果对方绕了几句就开始要红包。反应过来的时候，钱已经转出去了。"
	elif roll < scam_chance + 50:
		story = "聊了两句，你们都意识到不是一路人。对方沉默，你也顺手划掉了聊天框。"
	else:
		changes["eq"] = 2
		story = "这次遇到的人有点奇怪，但你没有被带着走。聊完以后，你反而更懂怎么识别套路。"
	_app._show_story_then_apply_changes(story, changes, {}, func() -> void:
		refresh_dating_card()
	)


func close_dating() -> void:
	_app._set_layer_visible(_app.dating_popup, false)
