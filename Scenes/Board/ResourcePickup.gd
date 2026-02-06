extends Resource
class_name ResourcePickup

enum ResourceType {
	MONEY,
	INSIGHT,
	TIME,
	ALL  # NEW: Add this
}

@export var resource_type: ResourceType = ResourceType.MONEY
@export var display_name: String = ""
@export var amount: int = 0
@export var description: String = ""
@export var icon: Texture2D

func _init(
	p_type: ResourceType = ResourceType.MONEY,
	p_name: String = "",
	p_amount: int = 0,
	p_description: String = ""
):
	resource_type = p_type
	display_name = p_name
	amount = p_amount
	description = p_description
