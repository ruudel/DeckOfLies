extends Resource
class_name Event

@export var event_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var image: Texture2D
@export var event_type: String = "standard"  # standard, character_encounter, etc.

# Optional: character to award
@export var awards_character_id: String = ""

func _init(
	p_id: String = "",
	p_title: String = "",
	p_description: String = "",
	p_image: Texture2D = null,
	p_type: String = "standard"
):
	event_id = p_id
	title = p_title
	description = p_description
	image = p_image
	event_type = p_type
