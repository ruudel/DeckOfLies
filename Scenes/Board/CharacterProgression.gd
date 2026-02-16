extends Node

signal stat_increased(stat_name: String, new_value: int)
signal case_progress_updated(clue: String)
signal bond_strengthened(character_id: String, new_level: int)

# Character Stats (Invocation)
var investigation: int = 1  # Ability to find clues
var intuition: int = 1      # Insight into mysteries
var influence: int = 1      # Social manipulation
var occult: int = 1         # Ritual knowledge

# Case Progress (Evocation - Case)
var clues_discovered: Array[String] = []
var case_breakthrough_level: int = 0

# Social Bonds (Evocation - Bonds)
var character_bonds = {}  # character_id -> bond_level

# Upgrade Points
var available_invocation_points: int = 0
var available_evocation_points: int = 0

func _ready():
	SignalBus.day_changed.connect(_on_day_changed)

func _on_day_changed(new_day: int):
	# Gain points each new day
	available_invocation_points += 1
	available_evocation_points += 1

# === INVOCATION (Character Stats) ===
func can_upgrade_stat() -> bool:
	return available_invocation_points > 0

func upgrade_stat(stat_name: String) -> bool:
	if not can_upgrade_stat():
		return false
	
	match stat_name:
		"investigation":
			investigation += 1
			stat_increased.emit("investigation", investigation)
		"intuition":
			intuition += 1
			stat_increased.emit("intuition", intuition)
		"influence":
			influence += 1
			stat_increased.emit("influence", influence)
		"occult":
			occult += 1
			stat_increased.emit("occult", occult)
		_:
			return false
	
	available_invocation_points -= 1
	print("Upgraded ", stat_name, " - Points remaining: ", available_invocation_points)
	return true

# === EVOCATION (External Progress) ===
func can_upgrade_evocation() -> bool:
	return available_evocation_points > 0

func add_clue(clue: String) -> bool:
	if not can_upgrade_evocation():
		return false
	
	clues_discovered.append(clue)
	available_evocation_points -= 1
	case_progress_updated.emit(clue)
	return true

func strengthen_bond(character_id: String) -> bool:
	if not can_upgrade_evocation():
		return false
	
	var current_level = character_bonds.get(character_id, 0)
	character_bonds[character_id] = current_level + 1
	available_evocation_points -= 1
	bond_strengthened.emit(character_id, current_level + 1)
	return true

func get_bond_level(character_id: String) -> int:
	return character_bonds.get(character_id, 0)
