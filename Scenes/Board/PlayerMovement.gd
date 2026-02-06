# ============================================
# PlayerMovement.gd - Movement System Component
# ============================================
class_name PlayerMovement
extends Node

signal movement_finished
signal reached_midnight

const MOVE_DURATION_PER_TILE = 0.4
const RADIUS = 300
const INNER_RADIUS = 220

var player: Node2D
var tiles: Array
var tile_count: int

var current_tile_index: int = 0
var is_moving: bool = false
var landed_event_hour: int = -1

func initialize(p_player: Node2D, p_tiles: Array, p_tile_count: int):
	player = p_player
	tiles = p_tiles
	tile_count = p_tile_count
	
	# Start at hour 6
	for i in range(tiles.size()):
		if tiles[i].hour_value == 6:
			current_tile_index = i
			break
	
	player.position = _get_tile_center_pos(current_tile_index)

func move_by_steps(steps: int):
	var destination = (current_tile_index + steps) % tile_count
	_move_to_tile(destination)

func move_to_event_end():
	if landed_event_hour < 0:
		return
	
	var end_hour = TileEventManager.get_event_end_hour(landed_event_hour)
	var current_hour = get_current_hour()
	
	if end_hour != current_hour:
		var end_tile_idx = _find_tile_by_hour(end_hour)
		if end_tile_idx >= 0:
			_animate_short_path(end_tile_idx)
	
	landed_event_hour = -1

func get_current_hour() -> int:
	return tiles[current_tile_index].hour_value

func set_landed_event_hour(hour: int):
	landed_event_hour = hour

func has_landed_event() -> bool:
	return landed_event_hour >= 0

# ============================================
# PRIVATE MOVEMENT LOGIC
# ============================================

func _move_to_tile(destination: int):
	if is_moving:
		return
	
	is_moving = true
	var path = _calculate_path(current_tile_index, destination)
	
	# Check for midnight crossing
	var midnight_idx = _find_midnight_in_path(path)
	
	if midnight_idx >= 0:
		await _handle_midnight_crossing(path, midnight_idx)
	else:
		await _animate_path(path)
	
	is_moving = false
	movement_finished.emit()

func _handle_midnight_crossing(path: Array, midnight_idx: int):
	var path_to_midnight = path.slice(0, midnight_idx + 1)
	var path_after = path.slice(midnight_idx + 1, path.size())
	
	await _animate_path(path_to_midnight)
	reached_midnight.emit()
	await SignalBus.popup_closed
	
	if path_after.size() > 0:
		await _animate_path(path_after)

func move_to_tile(tile_idx: int):
	_move_to_tile(tile_idx)

func _animate_path(path: Array):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	for tile_idx in path:
		var pos = _get_tile_center_pos(tile_idx)
		tween.tween_property(player, "position", pos, MOVE_DURATION_PER_TILE)
	
	current_tile_index = path[-1]
	await tween.finished

func _animate_short_path(end_tile_idx: int):
	var path = []
	var current = current_tile_index
	
	while current != end_tile_idx:
		current = (current + 1) % tile_count
		path.append(current)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	for tile_idx in path:
		var pos = _get_tile_center_pos(tile_idx)
		tween.tween_property(player, "position", pos, MOVE_DURATION_PER_TILE * 0.5)
	
	current_tile_index = end_tile_idx
	await tween.finished

func _calculate_path(from: int, to: int) -> Array:
	var path = []
	var current = from
	
	while current != to:
		current = (current + 1) % tile_count
		path.append(current)
	
	return path

func _find_midnight_in_path(path: Array) -> int:
	for i in range(path.size()):
		if tiles[path[i]].hour_value == 0:
			return i
	return -1

func _find_tile_by_hour(hour: int) -> int:
	for i in range(tiles.size()):
		if tiles[i].hour_value == hour:
			return i
	return -1

func _get_tile_center_pos(tile_idx: int) -> Vector2:
	var angle = (2 * PI / tile_count) * tile_idx - PI / 2
	var radius = (RADIUS + INNER_RADIUS) / 2.0
	return Vector2(cos(angle) * radius, sin(angle) * radius)
