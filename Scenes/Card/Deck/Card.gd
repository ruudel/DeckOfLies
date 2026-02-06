extends Resource
class_name Card

enum CardType {
	CHARACTER,
	ITEM,
	ACTION,
	RITUAL
}

@export var card_id: String = ""
@export var card_name: String = ""
@export var card_type: CardType = CardType.CHARACTER
@export_multiline var description: String = ""
@export var portrait: Texture2D
@export var uses_remaining: int = -1  # -1 = infinite, >0 = limited uses (for items)
@export var dialogue_lines: Array[String] = []

func _init(
	p_id: String = "",
	p_name: String = "",
	p_type: CardType = CardType.CHARACTER,
	p_description: String = "",
	p_portrait: Texture2D = null,
	p_uses: int = -1,
	p_dialogue: Array[String] = []
):
	card_id = p_id
	card_name = p_name
	card_type = p_type
	description = p_description
	portrait = p_portrait
	uses_remaining = p_uses
	dialogue_lines = p_dialogue


func get_type_name() -> String:
	match card_type:
		CardType.CHARACTER:
			return "Character"
		CardType.ITEM:
			return "Item"
		CardType.ACTION:
			return "Action"
		CardType.RITUAL:
			return "Ritual"
	return "Unknown"

func is_permanent() -> bool:
	return uses_remaining == -1

func use_item() -> bool:
	if uses_remaining > 0:
		uses_remaining -= 1
		return true
	elif uses_remaining == -1:
		return true  # Infinite uses
	return false  # No uses left
