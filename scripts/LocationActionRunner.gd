## LocationActionRunner.gd
## Owns location event lifetime, background switching, and return-to-weekend cleanup.
extends RefCounted

var _main: Node
var _app: RefCounted
var _event_hold_count: int = 0
var _loc_visit_count: Dictionary = {}


func init(main: Node, app_system: RefCounted) -> void:
	_main = main
	_app = app_system


func begin_location_event() -> void:
	_event_hold_count += 1
	var gal = _main.get("galgame")
	if gal and gal.has_method("hold_location_bg"):
		gal.hold_location_bg()


func end_location_event() -> void:
	if _event_hold_count <= 0:
		return
	_event_hold_count -= 1
	var gal = _main.get("galgame")
	if gal and gal.has_method("release_location_bg"):
		gal.release_location_bg()
	elif _main.has_method("return_to_home_environment"):
		_main.return_to_home_environment("location_event_end")


func hold_count() -> int:
	return _event_hold_count


func finish_after(after: Callable = Callable()) -> Callable:
	return func() -> void:
		if after.is_valid():
			after.call()
		end_location_event()
		if is_instance_valid(_main) and _main.get("current_phase") == _main.Phase.EVENT:
			_main.set("current_phase", _main.Phase.WEEKEND)
			if _main.has_method("sync_ui_state"):
				_main.sync_ui_state()
			if _main.has_method("_refresh_ui"):
				_main._refresh_ui()


func show_location_background(location: String) -> void:
	var bg_path := _get_background_path(location)
	if bg_path != "":
		_main.galgame.show_location_bg(bg_path)
		return
	var env = _main.get("environment")
	if env and env.has_method("show_location_color"):
		env.show_location_color(location)
	elif _main.has_method("return_to_home_environment"):
		_main.return_to_home_environment("location_without_bg")
	var gal = _main.get("galgame")
	if gal and gal.has_method("play_ambient_for_location"):
		gal.play_ambient_for_location(location)


func _get_background_path(location: String) -> String:
	if location == "gym":
		_loc_visit_count["gym"] = int(_loc_visit_count.get("gym", 0)) + 1
		if int(_loc_visit_count["gym"]) == 1:
			return "res://Assets/Backgrounds/gym/Gym_bg_rain_morning.jpg"
		var gym_bgs: Array[String] = [
			"res://Assets/Backgrounds/gym/Gym_bg_rain_morning.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_rain_night.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_sunny_morning.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_sunny_noon.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_sunny_evening.jpg",
			"res://Assets/Backgrounds/gym/Gym_bg_hazy_afternoon.jpg",
		]
		return gym_bgs[randi() % gym_bgs.size()]
	var bg_map: Dictionary = {
		"library": "res://Assets/Backgrounds/library/Bookshop_bg_day1.png",
		"park": "res://Assets/Backgrounds/park/beach.jpg",
	}
	return bg_map.get(location, "")
