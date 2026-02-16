extends Control

@onready var text_display = $VBoxContainer/TextDisplay
@onready var skip_button = $SkipButton

signal cutscene_finished

var lines = [
	"You've arrived in a small town shrouded in mystery...",
	"",
	"Strange occurrences plague the residents.",
	"Shadows move where there should be none.",
	"The owls watch from the trees.",
	"",
	"As an occult detective, you've been called to investigate.",
	"But the deeper you dig, the more questions arise...",
	"",
	"What secrets hide in this forgotten place?",
	"And what price will you pay to uncover them?"
]

var current_line = 0
var char_index = 0
var typing_speed = 0.05

func _ready():
	skip_button.pressed.connect(_on_skip)
	text_display.bbcode_enabled = true
	text_display.text = ""
	_start_typing()

func _start_typing():
	_type_next_char()

func _type_next_char():
	if current_line >= lines.size():
		await get_tree().create_timer(2.0).timeout
		_finish_cutscene()
		return
	
	var current_text = lines[current_line]
	
	if char_index < current_text.length():
		text_display.text += current_text[char_index]
		char_index += 1
		await get_tree().create_timer(typing_speed).timeout
		_type_next_char()
	else:
		# Line finished, move to next
		text_display.text += "\n"
		current_line += 1
		char_index = 0
		await get_tree().create_timer(0.5).timeout  # Pause between lines
		_type_next_char()

func _on_skip():
	_finish_cutscene()

func _finish_cutscene():
	cutscene_finished.emit()
