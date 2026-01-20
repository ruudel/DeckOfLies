extends Resource
class_name Character

@export var character_name: String = ""
@export var title: String = ""  # e.g. "The Log Lady", "FBI Agent"
@export_multiline var description: String = ""
@export var portrait: Texture2D  # We'll use placeholders for now
@export var rarity: String = "common"  # common, rare, legendary

# Optional stats for later
@export var insight: int = 0  # How much they help with investigations
@export var connection: int = 0  # How well they know the town

func _init(
	p_name: String = "",
	p_title: String = "",
	p_description: String = "",
	p_portrait: Texture2D = null,
	p_rarity: String = "common"
):
	character_name = p_name
	title = p_title
	description = p_description
	portrait = p_portrait
	rarity = p_rarity
