extends Node

var enemies = {}

func _ready():
	setup_enemies()

func setup_enemies():
	enemies["shadow_figure"] = BattleEnemy.new(
		"shadow_figure",
		"Shadow Figure",
		"A dark presence that feeds on fear and doubt.",
		20,
		1,
		"intuition",
		["intimidate", "drain"],
	)
	enemies["possessed_townsperson"] = BattleEnemy.new(
		"possessed_townsperson",
		"Possessed Townsperson",
		"Something has taken control of this innocent person.",
		25,
		2,
		"influence",
		["struggle", "lash_out"]
	)
	enemies["lodge_spirit"] = BattleEnemy.new(
		"lodge_spirit",
		"Lodge Spirit",
		"A malevolent entity from beyond the veil.",
		40,
		3,
		"occult",
		["curse", "drain", "madness"]
	)

func get_enemy(enemy_id: String) -> BattleEnemy:
	if enemies.has(enemy_id):
		return enemies[enemy_id].duplicate(true)
	return null
