extends CanvasLayer

@onready var close_button = $ColorRect/Panel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var total_label = $ColorRect/Panel/MarginContainer/VBoxContainer/Content/Stats/TotalLabel
@onready var characters_label = $ColorRect/Panel/MarginContainer/VBoxContainer/Content/Stats/CharactersLabel
@onready var items_label = $ColorRect/Panel/MarginContainer/VBoxContainer/Content/Stats/ItemsLabel
@onready var actions_label = $ColorRect/Panel/MarginContainer/VBoxContainer/Content/Stats/ActionsLabel
@onready var rituals_label = $ColorRect/Panel/MarginContainer/VBoxContainer/Content/Stats/RitualsLabel
@onready var card_list_container = $ColorRect/Panel/MarginContainer/VBoxContainer/Content/CardList/CardListContainer
@onready var scroll_container = $ColorRect/Panel/MarginContainer/VBoxContainer/Content/CardList
@onready var content_hbox = $ColorRect/Panel/MarginContainer/VBoxContainer/Content
@onready var main_vbox = $ColorRect/Panel/MarginContainer/VBoxContainer
@onready var panel = $ColorRect/Panel
@onready var margin = $ColorRect/Panel/MarginContainer
@onready var separator = $ColorRect/Panel/MarginContainer/VBoxContainer/HSeparator
@onready var header_hbox = $ColorRect/Panel/MarginContainer/VBoxContainer/Header


func _ready():
	hide()
	close_button.pressed.connect(_on_close_pressed)
	DeckManager.deck_updated.connect(_refresh_display)
	
	await get_tree().process_frame
	

	
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	#	# Calculate available height
	var panel_height = panel.size.y
	var margin_top = 10  # Your margin settings
	var margin_bottom = 10
	var header_height = header_hbox.size.y
	var separator_height = separator.size.y
	
	var available_height = panel_height - margin_top - margin_bottom - header_height - separator_height - 10
	
	# Force content_hbox to use that height
	content_hbox.custom_minimum_size.y = available_height
	content_hbox.size.y = available_height
	
	# Clip everything
	panel.clip_contents = true
	scroll_container.clip_contents = true

func show_deck():
	_refresh_display()
	show()

func _refresh_display():
	_update_stats()
	_update_card_list()

func _update_stats():
	var stats = DeckManager.get_deck_stats()
	total_label.text = "Total Cards: " + str(stats.total)
	characters_label.text = "Characters: " + str(stats.characters)
	items_label.text = "Items: " + str(stats.items)
	actions_label.text = "Actions: " + str(stats.actions)
	rituals_label.text = "Rituals: " + str(stats.rituals)

func _update_card_list():
	# Clear existing cards
	for child in card_list_container.get_children():
		child.queue_free()
	
	# Group cards by type
	var grouped = {
		Card.CardType.CHARACTER: [],
		Card.CardType.ITEM: [],
		Card.CardType.ACTION: [],
		Card.CardType.RITUAL: []
	}
	
	for card in DeckManager.deck:
		grouped[card.card_type].append(card)
	
	# Display cards by type
	for type in [Card.CardType.CHARACTER, Card.CardType.ITEM, Card.CardType.ACTION, Card.CardType.RITUAL]:
		if grouped[type].size() > 0:
			_add_type_header(type)
			for card in grouped[type]:
				_add_card_entry(card)

func _add_type_header(type: Card.CardType):
	var header = Label.new()
	
	match type:
		Card.CardType.CHARACTER:
			header.text = "═══ CHARACTERS ═══"
		Card.CardType.ITEM:
			header.text = "═══ ITEMS ═══"
		Card.CardType.ACTION:
			header.text = "═══ ACTIONS ═══"
		Card.CardType.RITUAL:
			header.text = "═══ RITUALS ═══"
	
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_list_container.add_child(header)
	
	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	card_list_container.add_child(spacer)

func _add_card_entry(card: Card):
	var entry = PanelContainer.new()
	entry.custom_minimum_size = Vector2(0, 60)
	
	var margin = MarginContainer.new()
	entry.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# Card name
	var name_label = Label.new()
	name_label.text = card.card_name
	vbox.add_child(name_label)
	
	# Card type and uses
	var info_label = Label.new()
	var info_text = card.get_type_name()
	if card.card_type == Card.CardType.ITEM and card.uses_remaining > 0:
		info_text += " (" + str(card.uses_remaining) + " uses)"
	info_label.text = info_text
	info_label.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(info_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = card.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	# Hover effects
	entry.mouse_entered.connect(func(): _on_card_hover(entry, true))
	entry.mouse_exited.connect(func(): _on_card_hover(entry, false))
	
	card_list_container.add_child(entry)

func _on_card_hover(entry: PanelContainer, is_hovering: bool):
	if is_hovering:
		var tween = create_tween()
		tween.tween_property(entry, "modulate", Color(1.2, 1.2, 1.0), 0.1)
		entry.z_index = 10
	else:
		var tween = create_tween()
		tween.tween_property(entry, "modulate", Color(1.0, 1.0, 1.0), 0.1)
		entry.z_index = 0

func _on_close_pressed():
	hide()
