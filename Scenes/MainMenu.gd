extends Control

@onready var new_game_button = $VBoxContainer/MenuButtons/NewGameButton
@onready var continue_button = $VBoxContainer/MenuButtons/ContinueButton
@onready var settings_button = $VBoxContainer/MenuButtons/SettingsButton
@onready var quit_button = $VBoxContainer/MenuButtons/QuitButton
@onready var background = $Background

signal start_new_game
signal continue_game
signal open_settings

func _ready():
	# Set background image (you can replace with actual image later)
	# background.texture = load("res://assets/menu_background.png")
	
	new_game_button.pressed.connect(_on_new_game)
	continue_button.pressed.connect(_on_continue)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	
	# Disable continue if no save exists (for now, always disabled)
	continue_button.disabled = true

func _on_new_game():
	start_new_game.emit()

func _on_continue():
	continue_game.emit()

func _on_settings():
	open_settings.emit()

func _on_quit():
	get_tree().quit()
