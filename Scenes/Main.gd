extends Node

const MAIN_MENU = preload("res://Scenes/MainMenu.tscn")
const OPENING_CUTSCENE = preload("res://Scenes/OpeningCutscene.tscn")
const BOARD = preload("res://Scenes/Board/Board.tscn")

var current_scene

func _ready():
	_show_main_menu()

func _show_main_menu():
	_clear_scene()
	
	var menu = MAIN_MENU.instantiate()
	menu.start_new_game.connect(_start_new_game)
	menu.continue_game.connect(_continue_game)
	menu.open_settings.connect(_open_settings)
	add_child(menu)
	current_scene = menu

func _start_new_game():
	_show_cutscene()

func _show_cutscene():
	_clear_scene()
	
	var cutscene = OPENING_CUTSCENE.instantiate()
	cutscene.cutscene_finished.connect(_start_board_game)
	add_child(cutscene)
	current_scene = cutscene

func _start_board_game():
	_clear_scene()
	
	var board = BOARD.instantiate()
	add_child(board)
	current_scene = board

func _continue_game():
	print("Continue not implemented yet")
	# TODO: Load save data and go to board

func _open_settings():
	print("Settings not implemented yet")
	# TODO: Show settings menu

func _clear_scene():
	if current_scene:
		current_scene.queue_free()
		current_scene = null
