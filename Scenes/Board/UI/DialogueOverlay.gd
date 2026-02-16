extends CanvasLayer

@onready var portrait = $ColorRect/Panel/MarginContainer/HBoxContainer/Portrait
@onready var name_label = $ColorRect/Panel/MarginContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var dialogue_label = $ColorRect/Panel/MarginContainer/HBoxContainer/VBoxContainer/DialogueLabel
@onready var next_button = $ColorRect/Panel/MarginContainer/HBoxContainer/VBoxContainer/NextButton

signal dialogue_finished(card: Card)

var current_card: Card
var dialogue_lines: Array[String] = []
var current_line_index: int = 0

func _ready():
	hide()
	next_button.pressed.connect(_on_next_pressed)

func show_dialogue(card: Card):
	if card.card_type != Card.CardType.CHARACTER:
		push_error("Only characters have dialogue!")
		return
	
	if card.dialogue_lines.size() == 0:
		push_error("Character has no dialogue lines!")
		dialogue_finished.emit(card)
		return
	
	current_card = card
	dialogue_lines = card.dialogue_lines.duplicate()
	current_line_index = 0
	
	name_label.text = card.card_name
	
	# Display portrait
	if card.portrait:
		portrait.texture = card.portrait
		portrait.show()
	else:
		portrait.hide()  # Hide if no portrait
	
	_display_current_line()
	show()

func _display_current_line():
	if current_line_index < dialogue_lines.size():
		dialogue_label.text = dialogue_lines[current_line_index]
		print("Displaying dialogue: ", dialogue_lines[current_line_index])  # DEBUG
		
		if current_line_index == dialogue_lines.size() - 1:
			next_button.text = "✓ Add to Deck"
		else:
			next_button.text = "▶"
	else:
		_finish_dialogue()

func _on_next_pressed():
	current_line_index += 1
	
	if current_line_index >= dialogue_lines.size():
		_finish_dialogue()
	else:
		_display_current_line()

func _finish_dialogue():
	hide()
	dialogue_finished.emit(current_card)
