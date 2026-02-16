class_name EvocationModule
extends VBoxContainer

enum Tab { CASE, BONDS }
var current_tab = Tab.CASE

func _init():
	name = "EvocationModule"

func _ready():
	refresh()

func refresh():
	for child in get_children():
		child.queue_free()
	
	# Title
	var title = Label.new()
	title.text = "🔮 EVOCATION - Expand Your Influence"
	title.add_theme_font_size_override("font_size", 16)
	add_child(title)
	
	# Tab buttons
	var tab_container = HBoxContainer.new()
	
	var case_btn = Button.new()
	case_btn.text = "The Case"
	case_btn.pressed.connect(func(): _switch_tab(Tab.CASE))
	tab_container.add_child(case_btn)
	
	var bonds_btn = Button.new()
	bonds_btn.text = "Social Bonds"
	bonds_btn.pressed.connect(func(): _switch_tab(Tab.BONDS))
	tab_container.add_child(bonds_btn)
	
	add_child(tab_container)
	add_child(HSeparator.new())
	
	# Content based on tab
	match current_tab:
		Tab.CASE:
			_show_case_content()
		Tab.BONDS:
			_show_bonds_content()

func _switch_tab(tab: Tab):
	current_tab = tab
	refresh()

func _show_case_content():
	var desc = Label.new()
	desc.text = "Piece together the mystery"
	desc.add_theme_font_size_override("font_size", 12)
	desc.modulate = Color(0.7, 0.7, 0.7)
	add_child(desc)
	
	add_child(HSeparator.new())
	
	# Available clues to discover
	_add_case_option("red_room", "Vision of the Red Room", "A place between worlds...")
	_add_case_option("owls", "The Owls' Secret", "They are not what they seem...")
	_add_case_option("lodge", "The Black Lodge Location", "Where nightmares dwell...")

func _add_case_option(clue_id: String, clue_name: String, hint: String):
	var container = HBoxContainer.new()
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = clue_name
	vbox.add_child(name_label)
	
	var hint_label = Label.new()
	hint_label.text = hint
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.modulate = Color(0.6, 0.6, 0.6)
	vbox.add_child(hint_label)
	
	container.add_child(vbox)
	
	var discover_btn = Button.new()
	discover_btn.text = "Discover"
	discover_btn.disabled = not CharacterProgression.can_upgrade_evocation()
	discover_btn.pressed.connect(func(): _discover_clue(clue_id, clue_name))
	container.add_child(discover_btn)
	
	add_child(container)
	add_child(HSeparator.new())

func _discover_clue(clue_id: String, clue_name: String):
	if CharacterProgression.add_clue(clue_id):
		refresh()

func _show_bonds_content():
	var desc = Label.new()
	desc.text = "Strengthen relationships with characters in your deck"
	desc.add_theme_font_size_override("font_size", 12)
	desc.modulate = Color(0.7, 0.7, 0.7)
	add_child(desc)
	
	add_child(HSeparator.new())
	
	# Show characters from deck
	for card in DeckManager.deck:
		if card.card_type == Card.CardType.CHARACTER:
			_add_bond_option(card)

func _add_bond_option(card: Card):
	var bond_level = CharacterProgression.get_bond_level(card.card_id)
	
	var container = HBoxContainer.new()
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = card.card_name + " [Bond: " + str(bond_level) + "]"
	vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = "Strengthen your connection"
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate = Color(0.6, 0.6, 0.6)
	vbox.add_child(desc_label)
	
	container.add_child(vbox)
	
	var bond_btn = Button.new()
	bond_btn.text = "+"
	bond_btn.custom_minimum_size = Vector2(40, 40)
	bond_btn.disabled = not CharacterProgression.can_upgrade_evocation()
	bond_btn.pressed.connect(func(): _strengthen_bond(card.card_id))
	container.add_child(bond_btn)
	
	add_child(container)
	add_child(HSeparator.new())

func _strengthen_bond(character_id: String):
	if CharacterProgression.strengthen_bond(character_id):
		refresh()
