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
	highlight_event_tiles()

func setup_ui():
	roll_button.pressed.connect(_on_roll_button_pressed)
	
	day_label.text = "Day: " + str(GameState.current_day)
	day_label.position = Vector2(10, 10)
	$CanvasLayer.add_child(day_label)

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

func setup_tile_shape(tile: Area2D, tile_index: int):
	var polygon = tile.get_node("Polygon2D")
	var collision = tile.get_node("CollisionPolygon2D")
	
	var points = _create_wedge_points()
	
	polygon.polygon = points
	collision.polygon = points
	polygon.color = _get_time_of_day_color(tile_index)
	
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
	var event_hours = TileEventManager.get_event_hours()
	
	for hour in event_hours:
		# Find the tile with this hour
		for i in range(tiles.size()):
			if tiles[i].hour_value == hour:
				highlight_tile_border(tiles[i], i)
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
	tile.add_child(line)

func highlight_tile_border(tile: Area2D, _tile_index: int):
	# Find the Line2D border that was added to this tile
	for child in tile.get_children():
		if child is Line2D:
			child.default_color = Color(0.0, 1.0, 0.5, 1.0)
			child.width = 3  # Make it thicker
			child.z_index = 100
			break

func _get_time_of_day_color(hour: int) -> Color:
	var dawn = Color(0.8, 0.4, 0.3)          # Orange/pink
	var noon = Color(0.9, 0.9, 0.6)          # Bright yellow
	var dusk = Color(0.6, 0.3, 0.5)          # Purple/orange
	var night = Color(0.1, 0.1, 0.3)         # Deep blue
	
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

func _get_tile_center_position(tile_index: int) -> Vector2:
	var angle = (2 * PI / TILE_COUNT) * tile_index - PI / 2
	var tile_center_radius = (RADIUS + INNER_RADIUS) / 2.0
	return Vector2(cos(angle) * tile_center_radius, sin(angle) * tile_center_radius)

# ============================================
# PLAYER MOVEMENT
# ============================================

func move_player_to(tile_index: int):
	if tile_index == player_tile_index:
		return
	
	var path = _calculate_path(player_tile_index, tile_index)
	
	# Check if path crosses midnight (hour 0)
	var midnight_position = -1
	
	for i in range(path.size()):
		var tile_hour = tiles[path[i]].hour_value
		if tile_hour == 0:
			midnight_position = i
			break
	
	# If we cross midnight, split the movement
	if midnight_position >= 0:
		var path_to_midnight = path.slice(0, midnight_position + 1)
		_animate_along_path(path_to_midnight, true)
		
		if midnight_position < path.size() - 1:
			var remaining_path = path.slice(midnight_position + 1, path.size())
			event_popup.popup_closed.connect(_continue_movement_after_day_change.bind(remaining_path), CONNECT_ONE_SHOT)
	else:
		_animate_along_path(path, false)

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
	# Reset all tile borders to default
	for tile in tiles:
		for child in tile.get_children():
			if child is Line2D:
				child.default_color = Color(0.2, 0.2, 0.3, 0.5)
				child.width = 2
				break

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
		var event = TileEventManager.get_event(current_hour)
		SignalBus.popup_requested.emit(event)
		roll_button.disabled = true

func _on_day_changed(new_day: int):
	day_label.text = "Day: " + str(new_day)

func _on_tile_clicked(_viewport, event, _shape_idx, tile_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_moving:
			print("Clicked tile: ", tile_index)
			move_player_to(tile_index)

func _on_tile_hover(_tile_index: int, tile: Area2D):
	var polygon = tile.get_node("Polygon2D")
	polygon.color = Color(1.0, 1.0, 1.0, 1.0)
 
func _on_tile_unhover(tile_index: int, tile: Area2D):
	var polygon = tile.get_node("Polygon2D")
	var hour = tile.hour_value  # Just ask the tile!
	polygon.color = _get_time_of_day_color(hour)

func _on_event_triggered(event_data: Dictionary):
	print("Event triggered: ", event_data.get("title", ""))

func _on_popup_closed():
	# Just re-enable button if movement is done
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
