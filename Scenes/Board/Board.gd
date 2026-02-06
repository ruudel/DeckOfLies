# ============================================
# Board.gd - Main Game Coordinator
# ============================================
extends Node2D

const TILE_COUNT = 24

# Scene references
const TILE_SCENE = preload("res://Scenes/Board/Board_tile.tscn")
const PLAYER_SCENE = preload("res://Scenes/Board/Player.tscn")
const EVENT_POPUP = preload("res://Scenes/Board/UI/EventPopup.tscn")
const PLAYER_STATS_UI = preload("res://Scenes/Board/UI/PlayerStatsUI.tscn")
const DECK_VIEW = preload("res://Scenes/Card/Deck/DeckView.tscn")
const ROLL_OVERLAY = preload("res://Scenes/Board/UI/RollOverlay.tscn")
const DIALOGUE_OVERLAY = preload("res://Scenes/Board/UI/DialogueOverlay.tscn")

# Component scripts
var visuals: BoardVisuals
var movement: PlayerMovement
var event_display: EventDisplay

# UI references
@onready var roll_button = $CanvasLayer/Button

var tiles = []
var player
var deck_view

func _ready():
	_initialize_components()
	_setup_signals()
	_create_board()
	_setup_ui()
	_setup_starting_tiles()

func _initialize_components():
	# Create component instances
	visuals = BoardVisuals.new()
	movement = PlayerMovement.new()
	event_display = EventDisplay.new()
	
	add_child(visuals)
	add_child(movement)
	add_child(event_display)
	
	# Initialize systems
	TileEventManager.setup_events()
	
func _setup_signals():
	SignalBus.day_changed.connect(_on_day_changed)
	SignalBus.popup_closed.connect(_on_popup_closed)
	SignalBus.board_refresh_requested.connect(visuals.refresh_highlights)
	SignalBus.dialogue_requested.connect(event_display.show_dialogue)
	
	movement.movement_finished.connect(_on_movement_finished)
	movement.reached_midnight.connect(_on_reached_midnight)
	event_display.dialogue_finished.connect(_on_dialogue_finished)

func _create_board():
	# Create tiles
	tiles = visuals.create_tiles(TILE_SCENE)
	
	# Create and position player
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.z_index = 10
	movement.initialize(player, tiles, TILE_COUNT)
	
	# Highlight event tiles
	visuals.highlight_event_tiles(tiles)

func _setup_ui():
	# Roll button
	roll_button.pressed.connect(_on_roll_pressed)
	
	# Deck button
	var deck_button = Button.new()
	deck_button.text = "View Deck"
	deck_button.position = Vector2(10, 200)
	deck_button.pressed.connect(_on_deck_pressed)
	$CanvasLayer.add_child(deck_button)
	
	# Stats UI
	var stats_ui = PLAYER_STATS_UI.instantiate()
	stats_ui.position = Vector2(10, 50)
	$CanvasLayer.add_child(stats_ui)
	
	# Deck view
	deck_view = DECK_VIEW.instantiate()
	add_child(deck_view)
	
	# Event display (popups, dialogue, roll overlay)
	event_display.setup_ui(self)

func _setup_starting_tiles():
	# Lock starting curse and blessing
	var curse = TileEventManager.get_random_curse()
	if curse:
		TileEventManager.lock_tile(15, curse)
	
	var blessing = TileEventManager.get_blessing_by_id("golden_hour")
	if blessing:
		TileEventManager.lock_tile(6, blessing)
	
	SignalBus.board_refresh_requested.emit()

# ============================================
# BUTTON HANDLERS
# ============================================

func _on_roll_pressed():
	if movement.is_moving:
		return
	
	roll_button.disabled = true
	var roll = randi_range(1, 6)
	event_display.show_roll(roll, func(): movement.move_by_steps(roll))

func _on_deck_pressed():
	deck_view.show_deck()

# ============================================
# SIGNAL HANDLERS
# ============================================

func _on_movement_finished():
	roll_button.disabled = false
	
	var current_hour = movement.get_current_hour()
	SignalBus.player_landed_on_tile.emit(movement.current_tile_index, current_hour)
	
	if TileEventManager.has_event(current_hour):
		var event = TileEventManager.get_event(current_hour)
		if event:
			movement.set_landed_event_hour(current_hour)
			SignalBus.popup_requested.emit(event)
			roll_button.disabled = true

func _on_reached_midnight():
	SignalBus.midnight_crossed.emit()
	GameState.increment_day()
	
	TileEventManager.setup_events()
	visuals.clear_highlights(tiles)
	visuals.highlight_event_tiles(tiles)
	
	var day_event = TileEventManager.get_day_change_event(GameState.current_day)
	SignalBus.popup_requested.emit(day_event)

func _on_popup_closed():
	# Handle multi-tile event end movement
	if movement.has_landed_event():
		movement.move_to_event_end()
		roll_button.disabled = false
	elif not movement.is_moving:
		roll_button.disabled = false

func _on_dialogue_finished(card: Card):
	DeckManager.add_card(card)
	SignalBus.popup_closed.emit()

func _on_day_changed(_new_day: int):
	pass  # Stats UI handles this
