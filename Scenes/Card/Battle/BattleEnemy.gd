extends Resource
class_name BattleEnemy

@export var enemy_id: String = ""
@export var enemy_name: String = ""
@export_multiline var description: String = ""
@export var portrait: Texture2D

# Combat stats
@export var max_health: int = 30
@export var current_health: int = 30
@export var threat_level: int = 1  # Difficulty

# AI behavior
@export var attack_pattern: Array[String] = []  # List of attack IDs
@export var weakness: String = ""  # Card type or stat it's weak to

func _init(
	p_id: String = "",
	p_name: String = "",
	p_desc: String = "",
	p_health: int = 30,
	p_threat: int = 1,
	p_weakness: String = "",
	p_pattern: Array[String] = []
):
	enemy_id = p_id
	enemy_name = p_name
	description = p_desc
	max_health = p_health
	current_health = p_health
	threat_level = p_threat
	weakness = p_weakness             
	attack_pattern = p_pattern

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	
func is_defeated() -> bool:
	return current_health <= 0

func get_health_percent() -> float:
	return float(current_health) / float(max_health)
