extends Resource
class_name Event

@export var event_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var image: Texture2D
@export var event_type: String = "standard"
@export var duration_hours: int = 1
@export var awards_character_id: String = ""
@export var resource_pickup: ResourcePickup  # NEW: Store resource data

func _init(
	p_id: String = "",
	p_title: String = "",
	p_description: String = "",
	p_image: Texture2D = null,
	p_type: String = "standard",
	p_duration: int = 1
):
	event_id = p_id
	title = p_title
	description = p_description
	image = p_image
	event_type = p_type
	duration_hours = p_duration
