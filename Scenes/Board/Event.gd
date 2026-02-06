extends Resource
class_name Event

@export var event_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var image: Texture2D
@export var event_type: String = "standard"
@export var duration_hours: int = 1
@export var awards_character_id: String = ""
@export var resource_pickup: ResourcePickup

enum RecurrenceType {
	UNIQUE,
	LIMITED,
	UNLIMITED
}

@export var recurrence: RecurrenceType = RecurrenceType.UNLIMITED
@export var max_occurrences: int = 1
@export var cooldown_days: int = 0

# NEW: Support multiple time windows
@export var time_windows: Array[Dictionary] = []  # [{start: int, end: int}, ...]

# Keep old single-window support for backward compatibility
@export var available_start_hour: int = -1
@export var available_end_hour: int = -1

func _init(
	p_id: String = "",
	p_title: String = "",
	p_description: String = "",
	p_image: Texture2D = null,
	p_type: String = "standard",
	p_duration: int = 1,
	p_recurrence: RecurrenceType = RecurrenceType.UNLIMITED,
	p_max_occurrences: int = 1,
	p_cooldown: int = 0,
	p_start_hour: int = -1,
	p_end_hour: int = -1
):
	event_id = p_id
	title = p_title
	description = p_description
	image = p_image
	event_type = p_type
	duration_hours = p_duration
	recurrence = p_recurrence
	max_occurrences = p_max_occurrences
	cooldown_days = p_cooldown
	available_start_hour = p_start_hour
	available_end_hour = p_end_hour

func is_curse() -> bool:
	return event_type == "curse"

func is_blessing() -> bool:
	return event_type == "blessing"

func is_permanent() -> bool:
	return is_curse() or is_blessing()

func can_occur_at_hour(hour: int) -> bool:
	# Check multiple time windows first
	if time_windows.size() > 0:
		for window in time_windows:
			if _hour_in_range(hour, window.start, window.end):
				return true
		return false
	
	# Fall back to single window (backward compatibility)
	if available_start_hour == -1 or available_end_hour == -1:
		return true
	
	return _hour_in_range(hour, available_start_hour, available_end_hour)

func _hour_in_range(hour: int, start: int, end: int) -> bool:
	if start <= end:
		# Normal range (e.g., 08:00 to 17:00)
		return hour >= start and hour <= end
	else:
		# Wraparound range (e.g., 21:00 to 02:00) - but we avoid 00
		return hour >= start or hour <= end

func add_time_window(start_hour: int, end_hour: int):
	time_windows.append({"start": start_hour, "end": end_hour})
