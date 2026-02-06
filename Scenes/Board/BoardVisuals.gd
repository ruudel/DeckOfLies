# ============================================
# BoardVisuals.gd - Visual Rendering Component
# ============================================
class_name BoardVisuals
extends Node

const RADIUS = 300
const INNER_RADIUS = 220
const FIRST_TILE_HOUR = 0

# Colors
const EVENT_HIGHLIGHT_COLOR = Color(0.243, 0.804, 0.627, 1.0)
const RESOURCE_HIGHLIGHT_COLOR = Color(0.91, 0.541, 0.427, 1.0)
const CURSE_TILE_COLOR = Color(0.769, 0.302, 0.482, 1.0)
const BLESSING_TILE_COLOR = Color(0.29, 0.553, 0.745, 1.0)
const TILE_HOVER_COLOR = Color(0.91, 0.878, 0.831, 1.0)
const TILE_BASE_COLOR = Color(0.769, 0.729, 0.69, 1.0)

const EVENT_DIVIDER_COLOR = Color(0.29, 0.553, 0.745, 1.0)
const RESOURCE_DIVIDER_COLOR = Color(0.831, 0.353, 0.227, 1.0)
const CURSE_DIVIDER_COLOR = Color(1.0, 0.0, 0.0, 1.0)
const BLESSING_DIVIDER_COLOR = Color(0.243, 0.804, 0.627, 1.0)

var event_tile_hours = {}
var divider_lines = []

func create_tiles(tile_scene: PackedScene) -> Array:
	var tiles = []
	var tile_count = 24
	
	for i in range(tile_count):
		var angle = (2 * PI / tile_count) * i - PI / 2
		var hour = (i + FIRST_TILE_HOUR) % tile_count
		
		var tile = tile_scene.instantiate()
		tile.rotation = angle
		tile.set_hour(hour)
		
		_setup_tile_visuals(tile, hour, i)
		_add_hour_label(tile, hour, angle, tile_count)
		
		get_parent().add_child(tile)
		tiles.append(tile)
	
	return tiles

func highlight_event_tiles(tiles: Array):
	_clear_dividers()
	
	var event_starts = TileEventManager.get_event_hours()
	for start_hour in event_starts:
		var event = TileEventManager.get_event(start_hour)
		if event:
			_color_event_tiles(tiles, start_hour, event)
			_add_event_dividers(tiles, start_hour, event)

func clear_highlights(tiles: Array):
	event_tile_hours.clear()
	_clear_dividers()
	
	for tile in tiles:
		var polygon = tile.get_node("Polygon2D")
		polygon.color = _get_time_color(tile.hour_value)

func refresh_highlights(tiles: Array = []):
	if tiles.size() == 0:
		tiles = get_parent().tiles
	clear_highlights(tiles)
	highlight_event_tiles(tiles)

# ============================================
# PRIVATE HELPERS
# ============================================

func _setup_tile_visuals(tile: Area2D, hour: int, tile_index: int):
	var polygon = tile.get_node("Polygon2D")
	var collision = tile.get_node("CollisionPolygon2D")
	
	var points = _create_wedge_points()
	polygon.polygon = points
	collision.polygon = points
	polygon.color = _get_time_color(hour)
	
	_add_border(tile, points)
	
	# Connect hover signals
	tile.mouse_entered.connect(func(): _on_tile_hover(tile))
	tile.mouse_exited.connect(func(): _on_tile_unhover(tile))
	tile.input_event.connect(func(viewport, event, shape_idx): _on_tile_clicked(event, tile_index))

func _create_wedge_points() -> PackedVector2Array:
	var tile_count = 24
	var angle_size = 2 * PI / tile_count
	var half_angle = angle_size / 2.0
	var points = PackedVector2Array()
	
	for j in range(5):
		var t = float(j) / 4.0
		var a = lerp(-half_angle, half_angle, t)
		points.append(Vector2(cos(a), sin(a)) * INNER_RADIUS)
	
	for j in range(5):
		var t = float(j) / 4.0
		var a = lerp(half_angle, -half_angle, t)
		points.append(Vector2(cos(a), sin(a)) * RADIUS)
	
	return points

func _add_border(tile: Area2D, points: PackedVector2Array):
	var line = Line2D.new()
	line.points = points
	line.add_point(points[0])
	line.width = 2
	line.default_color = Color(0.374, 0.374, 0.374, 0.5)
	line.closed = true
	line.z_index = 2
	tile.add_child(line)

func _add_hour_label(tile: Area2D, hour: int, angle: float, tile_count: int):
	var label = Label.new()
	label.text = "%02d" % hour
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	
	var label_radius = INNER_RADIUS - 20
	var x = cos(angle) * label_radius
	var y = sin(angle) * label_radius
	
	label.position = Vector2(x - 8, y - 10)
	label.z_index = 10
	
	get_parent().add_child(label)

func _get_time_color(hour: int) -> Color:
	var midnight = Color(0.42, 0.302, 0.671, 1.0)
	
	if hour == 0:
		return midnight
	else:
		return TILE_BASE_COLOR

func _color_event_tiles(tiles: Array, start_hour: int, event: Event):
	var highlight_color = EVENT_HIGHLIGHT_COLOR
	
	match event.event_type:
		"curse": highlight_color = CURSE_TILE_COLOR
		"blessing": highlight_color = BLESSING_TILE_COLOR
		"resource": highlight_color = RESOURCE_HIGHLIGHT_COLOR
	
	for i in range(event.duration_hours):
		var hour = start_hour + i
		event_tile_hours[hour] = true
		
		for tile in tiles:
			if tile.hour_value == hour:
				var polygon = tile.get_node("Polygon2D")
				var base_color = _get_time_color(hour)
				polygon.color = base_color * highlight_color
				break

func _add_event_dividers(tiles: Array, start_hour: int, event: Event):
	var divider_color = EVENT_DIVIDER_COLOR
	
	match event.event_type:
		"curse": divider_color = CURSE_DIVIDER_COLOR
		"blessing": divider_color = BLESSING_DIVIDER_COLOR
		"resource": divider_color = RESOURCE_DIVIDER_COLOR
	
	var start_tile = _find_tile_by_hour(tiles, start_hour)
	var end_tile = _find_tile_by_hour(tiles, start_hour + event.duration_hours - 1)
	
	if start_tile:
		_draw_divider(start_tile, true, divider_color)
	if end_tile:
		_draw_divider(end_tile, false, divider_color)

func _draw_divider(tile: Area2D, is_left: bool, color: Color):
	var polygon = tile.get_node("Polygon2D")
	var points = polygon.polygon
	
	if points.size() < 10:
		return
	
	var inner = points[0] if is_left else points[4]
	var outer = points[9] if is_left else points[5]
	
	var transform = tile.global_transform
	var world_inner = transform * inner
	var world_outer = transform * outer
	
	var line = Line2D.new()
	line.width = 3
	line.default_color = color
	line.z_index = 15
	line.add_point(world_inner)
	line.add_point(world_outer)
	
	get_parent().add_child(line)
	divider_lines.append(line)

func _clear_dividers():
	for line in divider_lines:
		line.queue_free()
	divider_lines.clear()

func _find_tile_by_hour(tiles: Array, hour: int):
	for tile in tiles:
		if tile.hour_value == hour:
			return tile
	return null

func _on_tile_clicked(event: InputEvent, tile_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var movement = get_parent().movement
		if not movement.is_moving:
			movement.move_to_tile(tile_index)

func _on_tile_hover(tile: Area2D):
	var polygon = tile.get_node("Polygon2D")
	polygon.color = TILE_HOVER_COLOR

func _on_tile_unhover(tile: Area2D):
	var polygon = tile.get_node("Polygon2D")
	var hour = tile.hour_value
	var base_color = _get_time_color(hour)
	
	if event_tile_hours.has(hour):
		var event = TileEventManager.get_event(hour)
		if event:
			var highlight = EVENT_HIGHLIGHT_COLOR
			match event.event_type:
				"curse": highlight = CURSE_TILE_COLOR
				"blessing": highlight = BLESSING_TILE_COLOR
				"resource": highlight = RESOURCE_HIGHLIGHT_COLOR
			polygon.color = base_color * highlight
		else:
			polygon.color = base_color
	else:
		polygon.color = base_color
