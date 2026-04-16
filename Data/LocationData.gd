## LocationData.gd - 地点数据资源
## 用于定义每个可前往地点的消耗与属性变化
class_name LocationData
extends Resource

## 地点名称（如"咖啡馆"、"图书馆"）
@export var location_name: String = ""

## 前往该地点消耗的精力
@export var energy_cost: int = 0

## 前往该地点消耗的金钱
@export var money_cost: int = 0

## 前往后触发的属性变化，键为属性名，值为变化量
## 例如：{"sanity": 10, "charm": 2} 表示情绪+10、颜值+2
@export var stat_changes: Dictionary = {}
