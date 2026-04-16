## StartMenu.gd - 开场界面控制器
## 负责：输入玩家姓名、选择星象、初始化属性并跳转到主游戏界面
extends Control

# ==================== 节点路径引用 ====================

## 姓名输入框
@onready var input_name: LineEdit = %Input_Name

## 四个星象选择按钮（toggle_mode，同一时间只能选中一个）
@onready var btn_earth: Button = %Btn_Earth
@onready var btn_fire: Button = %Btn_Fire
@onready var btn_water: Button = %Btn_Water
@onready var btn_wind: Button = %Btn_Wind

## 开始游戏按钮（选择星象后才能点击）
@onready var btn_start_game: Button = %Btn_StartGame

## 加成信息已移到每个星座图标下方，无需单独引用

## 当前选中的星象名称，空字符串表示未选择
var selected_zodiac: String = ""



# ==================== 生命周期 ====================

func _ready() -> void:

	# 连接四个星象按钮的点击事件
	btn_earth.pressed.connect(_on_zodiac_selected.bind("土象"))
	btn_fire.pressed.connect(_on_zodiac_selected.bind("火象"))
	btn_water.pressed.connect(_on_zodiac_selected.bind("水象"))
	btn_wind.pressed.connect(_on_zodiac_selected.bind("风象"))

	# 连接开始游戏按钮
	btn_start_game.pressed.connect(_on_start_game_pressed)

	# 连接锁屏解锁信号
	var lock = get_node_or_null("Phone/ScreenContent/LockScreen")
	if lock:
		lock.unlock_success.connect(_on_unlocked)


# ==================== 星象选择逻辑 ====================

## 选择某个星象时调用
func _on_zodiac_selected(zodiac_name: String) -> void:
	selected_zodiac = zodiac_name

	# 更新按钮状态：选中的按钮保持按下，其他按钮弹起
	btn_earth.button_pressed = (zodiac_name == "土象")
	btn_fire.button_pressed = (zodiac_name == "火象")
	btn_water.button_pressed = (zodiac_name == "水象")
	btn_wind.button_pressed = (zodiac_name == "风象")

	# 选择星象后解锁开始按钮
	btn_start_game.disabled = false


# ==================== 开始游戏 ====================

## 滑动解锁成功后显示主UI
func _on_unlocked() -> void:
	var phone = get_node_or_null("Phone")
	if phone and phone.has_method("show_main_ui"):
		phone.show_main_ui()


## 点击"开始深漂生活"按钮时调用
func _on_start_game_pressed() -> void:
	# 读取玩家姓名，为空则使用默认名"林小满"
	var name_text: String = input_name.text.strip_edges()
	if name_text == "":
		name_text = "林小满"

	# 将玩家信息写入全局单例
	GameManager.player_name = name_text
	GameManager.player_zodiac = selected_zodiac

	# 根据选择的星象，在基础属性上累加对应的初始加成
	match selected_zodiac:
		"土象":
			# 金钱+500，学识+5
			GameManager.modify_stat("money", 500)
			GameManager.modify_stat("intellect", 5)
		"火象":
			# 精力上限提升至 120，颜值+5
			GameManager.max_energy = 120
			GameManager.energy = 120
			GameManager.modify_stat("charm", 5)
		"水象":
			# 情绪上限提升至 120，情商+5
			GameManager.max_sanity = 120
			GameManager.sanity = 120
			GameManager.modify_stat("eq", 5)
		"风象":
			# 颜值+2，情商+2，学识+2（均衡型）
			GameManager.modify_stat("charm", 2)
			GameManager.modify_stat("eq", 2)
			GameManager.modify_stat("intellect", 2)

	# 跳转到主游戏场景
	get_tree().change_scene_to_file("res://scenes/MainGame.tscn")
