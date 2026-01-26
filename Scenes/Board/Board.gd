extends Node2D

# ============================================
# CONSTANTS
# ============================================
const TILE_COUNT = 24
const RADIUS = 300
const INNER_RADIUS = 220
const TILE_SCENE = preload("res://Scenes/Board/Board_tile.tscn")
const PLAYER_SCENE = preload("res://Scenes/Board/Player.tscn")
const MOVE_DURATION_PER_TILE = 0.4
const EVENT_POPUP = preload("res://Scenes/Board/UI/EventPopup.tscn")
const CHARACTER_CARD = preload("res://Scenes/Card/CharacterCard.tscn")
const FIRST_TILE_HOUR = 0

# Visual constants
const EVENT_HIGHLIGHT_COLOR = Color(0.295, 0.963, 0.808, 1.0)  # Multiplier for event tiles
const TILE_HOVER_COLOR = Color(1.0, 1.0, 1.0, 1.0)  # White on hover
const TILE_BASE_COLOR = Color(0.474, 0.474, 0.474, 1.0)
const RESOURCE_HIGHLIGHT_COLOR = Color(1.5, 1.2, 0.8)
const PLAYER_STATS_UI = preload("res://Scenes/Board/UI/PlayerStatsUI.tscn")

# ============================================
# STATE VARIABLES
# ============================================
var tiles = []
var player
var player_tile_index: int = 0
var is_moving: bool = false
var last_tile_index: int = 0
var event_popup
var event_tile_effects = {}  # Store references to highlight effects
var current_tween: Tween = null
var landed_event_hour: int = -1
var event_border_lines = []
var event_tile_hours = {}
var player_stats_ui

# ============================================
# UI REFERENCES
# ============================================
@onready var day_label = Label.new()
@onready var roll_button = $CanvasLayer/Button

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	TileEventManager.setup_events()
	
	# Use SignalBus for global events
	SignalBus.day_changed.connect(_on_day_changed)
	SignalBus.popup_closed.connect(_on_popup_closed)
	
	create_circular_board()
	spawn_player()
	setup_ui()
	setup_event_popup()
	setup_player_stats_ui()
	highlight_event_tiles()

func setup_ui():
	roll_button.pressed.connect(_on_roll_button_pressed)
	
	#day_label.text = "Day: " + str(GameState.current_day)
	#day_label.position = Vector2(10, 10)
	#$CanvasLayer.add_child(day_label)
	
func setup_player_stats_ui():
	player_stats_ui = PLAYER_STATS_UI.instantiate()
	player_stats_ui.position = Vector2(10, 50)  # Top-left, below day counter
	$CanvasLayer.add_child(player_stats_ui)

# ============================================
# BOARD CREATION
# ============================================

func create_circular_board():
	for i in range(TILE_COUNT):
		var angle = (2 * PI / TILE_COUNT) * i - PI / 2
		
		# Calculate what hour this tile represents
		var hour = (i + FIRST_TILE_HOUR) % TILE_COUNT
		
		var tile = TILE_SCENE.instantiate()
		tile.rotation = angle
		tile.set_hour(hour)  # Tell the tile what hour it is
		
		setup_tile_shape(tile, hour)
		setup_tile_signals(tile, i)
		add_hour_label(tile, hour, angle)
		
		add_child(tile)
		tiles.append(tile)

func setup_tile_shape(tile: Area2D, hour: int):  # Parameter is 'hour' not 'tile_index'
	var polygon = tile.get_node("Polygon2D")
	var collision = tile.get_node("CollisionPolygon2D")
	
	var points = _create_wedge_points()
	
	polygon.polygon = points
	collision.polygon = points
	polygon.color = _get_time_of_day_color(hour)  # Use hour, not tile_index
	
	_add_tile_border(tile, points)

func setup_tile_signals(tile: Area2D, tile_index: int):
	tile.input_event.connect(_on_tile_clicked.bind(tile_index))
	tile.mouse_entered.connect(_on_tile_hover.bind(tile_index, tile))
	tile.mouse_exited.connect(_on_tile_unhover.bind(tile_index, tile))

# ============================================
# EVENTS
# ============================================

func setup_event_popup():
	event_popup = EVENT_POPUP.instantiate()
	add_child(event_popup)

func highlight_event_tiles():
	var event_starts = TileEventManager.get_event_hours()
	
	for start_hour in event_starts:
		var event = TileEventManager.get_event(start_hour)
		if event:
			_color_multi_tile_event(start_hour, event)

func _color_multi_tile_event(start_hour: int, event: Event):
	var duration = event.duration_hours
	
	# Choose color based on event type
	var highlight_color = EVENT_HIGHLIGHT_COLOR
	if event.event_type == "resource":
		highlight_color = RESOURCE_HIGHLIGHT_COLOR
	
	for i in range(duration):
		var hour = (start_hour + i) % 24
		event_tile_hours[hour] = true
		
		for tile_idx in range(tiles.size()):
			if tiles[tile_idx].hour_value == hour:
				var polygon = tiles[tile_idx].get_node("Polygon2D")
				var base_color = _get_time_of_day_color(hour)
				polygon.color = base_color * highlight_color
				break

# ============================================
# TILE VISUAL HELPERS
# ============================================

func _create_wedge_points() -> PackedVector2Array:
	var angle_size = 2 * PI / TILE_COUNT
	var half_angle = angle_size / 2.0
	var points = PackedVector2Array()
	
	# Inner arc
	for j in range(5):
		var t = float(j) / 4.0
		var a = lerp(-half_angle, half_angle, t)
		points.append(Vector2(cos(a), sin(a)) * INNER_RADIUS)
	
	# Outer arc
	for j in range(5):
		var t = float(j) / 4.0
		var a = lerp(half_angle, -half_angle, t)
		points.append(Vector2(cos(a), sin(a)) * RADIUS)
	
	return points

func add_hour_label(_tile: Area2D, hour: int, angle: float):
	var label = Label.new()
	label.text = "%02d" % hour  # Format as 02, 06, 12, etc.
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	
	# Position at inner radius (inside border)
	var label_radius = INNER_RADIUS - label.size.x - 10  # Slightly inside the inner border
	var x = cos(angle) * label_radius
	var y = sin(angle) * label_radius
	
	label.position = Vector2(x - 8, y - 10)  # Adjust offset for centering
	label.z_index = 10
	
	add_child(label)

func _add_tile_border(tile: Area2D, points: PackedVector2Array):
	var line = Line2D.new()
	line.points = points
	line.add_point(points[0])
	line.width = 2
	line.default_color = Color(0.2, 0.2, 0.3, 0.5)
	line.closed = true
	line.z_index = 2
	tile.add_child(line)

func _get_time_of_day_color(hour: int) -> Color:
	#var dawn = Color(0.8, 0.4, 0.3)          # Orange/pink
	#var noon = Color(0.9, 0.9, 0.6)          # Bright yellow
	#var dusk = Color(0.6, 0.3, 0.5)          # Purple/orange
	#var night = Color(0.1, 0.1, 0.3)         # Deep blue
	
	var dawn = TILE_BASE_COLOR
	var noon = TILE_BASE_COLOR
	var dusk = TILE_BASE_COLOR
	var night = TILE_BASE_COLOR
	
	# Hour-based gradient
	if hour >= 21 or hour < 5:  # Night (21-4)
		return night
	elif hour >= 5 and hour < 8:  # Dawn (5-7)
		var t = (hour - 5) / 3.0
		return night.lerp(dawn, t)
	elif hour >= 8 and hour < 12:  # Morning to noon (8-11)
		var t = (hour - 8) / 4.0
		return dawn.lerp(noon, t)
	elif hour >= 12 and hour < 17:  # Afternoon (12-16)
		var t = (hour - 12) / 5.0
		return noon.lerp(dusk, t)
	else:  # Evening to night (17-20)
		var t = (hour - 17) / 4.0
		return dusk.lerp(night, t)

# ============================================
# PLAYER MANAGEMENT
# ============================================

func spawn_player():
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	
	# Find the tile with hour 6
	for i in range(tiles.size()):
		if tiles[i].hour_value == 6:
			player_tile_index = i
			break
	
	var pos = _get_tile_center_position(player_tile_index)
	player.position = pos
	player.z_index = 10

func _get_tile_center_position(tile_index: int) -> Vector2:
	var angle = (2 * PI / TILE_COUNT) * tile_index - PI / 2
	var tile_center_radius = (RADIUS + INNER_RADIUS) / 2.0
	return Vector2(cos(angle) * tile_center_radius, sin(angle) * tile_center_radius)

# ============================================
# PLAYER MOVEMENT
# ============================================

func move_player_to(tile_index: int):
	if is_moving:
		return
	is_moving = true
	
	# Use your existing path calculation 
	var path = _calculate_path(player_tile_index, tile_index)
	
	# Instead of animating the whole path at once, we move step-by-step
	# This allows us to catch the "Midnight" moment safely
	for next_tile in path:
		# Check if this specific step crosses from hour 23 (Index 11/12 depending on start) to 0
		# Based on your logic: crossing from index 23 to 0 [cite: 199]
		if player_tile_index == 23 and next_tile == 0:
			# 1. Animate to the last tile of the day
			await animate_along_path([next_tile]) 
			player_tile_index = next_tile
			
			# 2. Trigger the midnight logic [cite: 92, 201]
			_on_reached_midnight()
			
			# 3. Wait for the user to close the popup before continuing the rest of the move
			await SignalBus.popup_closed
		else:
			# Normal step movement
			await animate_along_path([next_tile])
			player_tile_index = next_tile

	# Once the entire path is finished
	is_moving = false
	_on_move_finished()

# Ensure your animation function uses 'await' so the loop knows when a tile move is done
func animate_along_path(path: Array):
	var tween = create_tween()
	for tile_idx in path:
		var target_pos = _get_tile_center_position(tile_idx) 
		tween.tween_property(player, "position", target_pos, MOVE_DURATION_PER_TILE)
	
	await tween.finished # This is crucial for the loop above to work

func _continue_movement_after_day_change(remaining_path: Array):
	_animate_along_path(remaining_path, false)

func _check_day_transition(destination: int): 
	# If we're moving past tile 0, increment day 
	if player_tile_index > destination or (player_tile_index == TILE_COUNT - 1 and destination == 0): 
		GameState.increment_day()

func _calculate_path(from_index: int, to_index: int) -> Array:
	var path = []
	var current = from_index
	
	while current != to_index:
		current = (current + 1) % TILE_COUNT
		path.append(current)
	
	return path

func _animate_along_path(path: Array, stop_at_end: bool = false):
	is_moving = true
	roll_button.disabled = true
	
	current_tween = create_tween()
	current_tween.set_ease(Tween.EASE_IN_OUT)
	current_tween.set_trans(Tween.TRANS_CUBIC)
	
	for tile_index in path:
		var pos = _get_tile_center_position(tile_index)
		current_tween.tween_property(player, "position", pos, MOVE_DURATION_PER_TILE)
	
	player_tile_index = path[-1]
	
	if stop_at_end:
		# Stopped at midnight for day change
		current_tween.finished.connect(_on_reached_midnight)
	else:
		# Normal movement end
		current_tween.finished.connect(_on_move_finished)

func clear_event_highlights():
	event_tile_hours.clear()
	
	for i in range(tiles.size()):
		var tile = tiles[i]
		var hour = tile.hour_value
		var polygon = tile.get_node("Polygon2D")
		polygon.color = _get_time_of_day_color(hour)


# ============================================
# SIGNAL HANDLERS
# ============================================

func _on_roll_button_pressed():
	if is_moving:
		return
	
	var die_roll = randi_range(1, 6)
	print("Rolled: ", die_roll)
	
	var destination = (player_tile_index + die_roll) % TILE_COUNT
	move_player_to(destination)

func _on_move_finished():
	is_moving = false
	roll_button.disabled = false
	
	var current_hour = tiles[player_tile_index].hour_value
	SignalBus.player_landed_on_tile.emit(player_tile_index, current_hour)
	
	if TileEventManager.has_event(current_hour):
		landed_event_hour = current_hour  # Remember where we landed
		var event = TileEventManager.get_event(current_hour)
		SignalBus.popup_requested.emit(event)
		roll_button.disabled = true

func _on_day_changed(new_day: int):
	#day_label.text = "Day: " + str(new_day)
	pass

func _on_tile_clicked(_viewport, event, _shape_idx, tile_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_moving:
			print("Clicked tile: ", tile_index)
			move_player_to(tile_index)

func _on_tile_hover(_tile_index: int, tile: Area2D):
	var polygon = tile.get_node("Polygon2D")
	polygon.color = TILE_HOVER_COLOR

func _on_tile_unhover(_tile_index: int, tile: Area2D):
	var polygon = tile.get_node("Polygon2D")
	var hour = tile.hour_value
	var base_color = _get_time_of_day_color(hour)
	
	if event_tile_hours.has(hour):
		# Check what type of event to restore correct color
		var event = TileEventManager.get_event(hour)
		if event and event.event_type == "resource":
			polygon.color = base_color * RESOURCE_HIGHLIGHT_COLOR
		else:
			polygon.color = base_color * EVENT_HIGHLIGHT_COLOR
	else:
		polygon.color = base_color

func _on_event_triggered(event_data: Dictionary):
	print("Event triggered: ", event_data.get("title", ""))

func _on_popup_closed():
	if landed_event_hour >= 0:
		# Move player to the end of the event
		var end_hour = TileEventManager.get_event_end_hour(landed_event_hour)
		
		# Find the tile with that end hour
		for i in range(tiles.size()):
			if tiles[i].hour_value == end_hour:
				# Animate player to end of event
				var tween = create_tween()
				var target_pos = _get_tile_center_position(i)
				tween.tween_property(player, "position", target_pos, 0.3)
				player_tile_index = i
				break
		
		landed_event_hour = -1  # Reset
	
	if not is_moving:
		roll_button.disabled = false

func _on_reached_midnight():
	is_moving = false
	
	SignalBus.midnight_crossed.emit()
	GameState.increment_day()
	
	TileEventManager.setup_events()
	clear_event_highlights()
	highlight_event_tiles()
	
	var day_event = TileEventManager.get_day_change_event(GameState.current_day)
	SignalBus.popup_requested.emit(day_event)
