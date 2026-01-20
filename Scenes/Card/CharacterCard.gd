extends PanelContainer

@onready var name_label = $MarginContainer/VBoxContainer/NameLabel
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var portrait_rect = $MarginContainer/VBoxContainer/PortraitRect
@onready var description_label = $MarginContainer/VBoxContainer/DescriptionLabel

var character_data: Character

func setup(character: Character):
	character_data = character
	
	name_label.text = character.character_name
	title_label.text = character.title
	description_label.text = character.description
	
	# Set portrait if available
	if character.portrait:
		# We'll handle this properly later
		pass
	
	# Color based on rarity
	match character.rarity:
		"common":
			modulate = Color(0.9, 0.9, 0.9)
		"rare":
			modulate = Color(0.7, 0.8, 1.0)  # Slight blue tint
		"legendary":
			modulate = Color(1.0, 0.9, 0.5)  # Golden tint
