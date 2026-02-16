class_name InvocationModule
extends VBoxContainer

func _init():
	name = "InvocationModule"

func _ready():
	refresh()

func refresh():
	# Clear existing
	for child in get_children():
		child.queue_free()
	
	# Title
	var title = Label.new()
	title.text = "⚡ INVOCATION - Strengthen Yourself"
	title.add_theme_font_size_override("font_size", 16)
	add_child(title)
	
	# Description
	var desc = Label.new()
	desc.text = "Improve your personal abilities"
	desc.add_theme_font_size_override("font_size", 12)
	desc.modulate = Color(0.7, 0.7, 0.7)
	add_child(desc)
	
	add_child(HSeparator.new())
	
	# Stats
	_add_stat_upgrade("investigation", "Investigation", "Find clues and examine evidence", CharacterProgression.investigation)
	_add_stat_upgrade("intuition", "Intuition", "Understand the occult and hidden meanings", CharacterProgression.intuition)
	_add_stat_upgrade("influence", "Influence", "Persuade and manipulate others", CharacterProgression.influence)
	_add_stat_upgrade("occult", "Occult", "Perform rituals and invoke powers", CharacterProgression.occult)

func _add_stat_upgrade(stat_id: String, stat_name: String, description: String, current_value: int):
	var container = HBoxContainer.new()
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = stat_name + " [" + str(current_value) + "]"
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate = Color(0.6, 0.6, 0.6)
	vbox.add_child(desc_label)
	
	container.add_child(vbox)
	
	var upgrade_btn = Button.new()
	upgrade_btn.text = "+"
	upgrade_btn.custom_minimum_size = Vector2(40, 40)
	upgrade_btn.disabled = not CharacterProgression.can_upgrade_stat()
	upgrade_btn.pressed.connect(func(): _upgrade_stat(stat_id, upgrade_btn))
	container.add_child(upgrade_btn)
	
	add_child(container)
	add_child(HSeparator.new())

func _upgrade_stat(stat_id: String, button: Button):
	if CharacterProgression.upgrade_stat(stat_id):
		refresh()  # Refresh to show new values
