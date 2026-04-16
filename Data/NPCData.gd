## NPCData.gd - NPC 数据资源
## 用于定义每个可交互角色的基础信息、解锁条件与好感度
class_name NPCData
extends Resource

## NPC 唯一标识符（如 "npc_01"）
@export var npc_id: String = ""

## NPC 显示名称
@export var npc_name: String = ""

## 解锁该 NPC 所需的属性条件
## 例如：{"charm": 50} 表示颜值达到 50 才能解锁
@export var required_stats: Dictionary = {}

## 当前好感度（初始为 0）
@export var affection: int = 0
