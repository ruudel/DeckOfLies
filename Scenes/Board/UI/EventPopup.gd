extends CanvasLayer

@onready var panel = $ColorRect/Panel
@onready var title_label = $ColorRect/Panel/VBoxContainer/TitleLabel
@onready var image_rect = $ColorRect/Panel/VBoxContainer/ImageRect
@onready var description_label = $ColorRect/Panel/VBoxContainer/DescriptionLabel
@onready var close_button = $ColorRect/Panel/VBoxContainer/CloseButton

var pending_character: Card = null

func _ready():
	hide()
	close_button.pressed.connect(_on_close_pressed)
	
	# Listen to SignalBus for popup requests
	SignalBus.popup_requested.connect(show_event)

func show_event(event: Event):
	if event == null:
		push_error("Attempted to show null event")
		visible = false
		SignalBus.popup_closed.emit()
		return

	title_label.text = event.title
	description_label.text = event.description
	
	if event.image:
		image_rect.texture = event.image
		image_rect.show()
	else:
		image_rect.hide()
	
	# Handle resource collection
	if event.event_type == "resource" and event.resource_pickup:
		ResourceManager.add_resource(event.resource_pickup)
	
	# Handle character encounters - DON'T add card yet, show dialogue first
	if event.event_type == "character_encounter":
		# Get a random CHARACTER specifically
		var available_characters = []
		for card in DeckManager.card_pool:
			if card.card_type == Card.CardType.CHARACTER:
				if not DeckManager.acquired_card_ids.has(card.card_id):
					available_characters.append(card)
		
		if available_characters.size() > 0:
			pending_character = available_characters[randi() % available_characters.size()].duplicate(true)
			print("Character encounter! Got: ", pending_character.card_name)
			description_label.text = "You encounter someone..."
		else:
			print("No available characters to meet!")
			description_label.text += "\n\n(You've already met everyone in town.)"
			pending_character = null
	
	if event.is_curse() or event.is_blessing():
		if event.resource_pickup:
			ResourceManager.add_resource(event.resource_pickup)
		
	# Handle battle encounters
	if event.event_type == "battle":
		description_label.text += "\n\n[Prepare for battle!]"
		close_button.text = "Fight!"
	else:
		close_button.text = "Close"
	
	show()

func _on_close_pressed():
	print("EventPopup: Close button pressed")  # DEBUG
	hide()
	
	if pending_character:
		print("EventPopup: Requesting dialogue for ", pending_character.card_name)  # DEBUG
		SignalBus.dialogue_requested.emit(pending_character)
		pending_character = null
	else:
		print("EventPopup: No pending character, emitting popup_closed")  # DEBUG
		SignalBus.popup_closed.emit()
