extends Node

signal event_triggered(event: Event)

var tile_events = {}  # Maps hour to Event resource
var event_pool = []
var multi_tile_event_map = {}  # Maps each hour of a multi-tile event to its starting hour

func _ready():
	setup_event_pool()

func setup_events():
	tile_events.clear()
	multi_tile_event_map.clear()
	
	# Always have lunch
	var lunch_event = Event.new(
		"lunch_break",
		"Lunch Break",
		"The diner is always open at noon. A long, leisurely meal with the locals.",
		null,
		"standard",
		2
	)
	place_event(12, lunch_event)
	
	add_random_events()
	add_random_resources()

func setup_event_pool():
	event_pool = [
		Event.new(
			"party",
			"Town Party",
			"The whole town gathers for a celebration. Music, dancing, and strange undercurrents. This takes most of the evening.",
			null,
			"standard",
			4  # 4 hours long!
		),
		Event.new(
			"black_lodge",
			"The Black Lodge Beckons",
			"You feel a strange pull towards the woods. Red curtains dance in your peripheral vision.",
			null,
			"standard",
			1
		),
		Event.new(
			"investigation",
			"Deep Investigation",
			"You spend hours piecing together clues. The conspiracy runs deeper than you thought.",
			null,
			"standard",
			3  # 3 hours
		),
		Event.new(
			"radio_broadcast",
			"Strange Radio Broadcast",
			"Your radio crackles with a backwards message. Is someone trying to tell you something?",
			null,
			"standard",
			1
		),
		Event.new(
			"log_lady_warning",
			"The Log Lady's Warning",
			"An elderly woman with a log whispers cryptically: 'The owls are gathering.'",
			null,
			"character_encounter",
			1
		),
		Event.new(
			"doppelganger",
			"Doppelganger Sighting",
			"You swear you just saw yourself walking down the street. They didn't seem to notice you.",
			null,
			"standard",
			1
		),
		Event.new(
			"stakeout",
			"All Night Stakeout",
			"You watch a suspicious location through the night. Nothing happens... or does it?",
			null,
			"standard",
			5  # 5 hours
		)
	]

func place_event(start_hour: int, event: Event):
	# Check if event would wrap past midnight
	if start_hour + event.duration_hours > 24:
		return
	
	# Check if there's space for this event
	for i in range(event.duration_hours):
		var hour = start_hour + i  # No modulo
		if tile_events.has(hour):
			return
	
	# Place the event at starting hour
	tile_events[start_hour] = event
	
	# Map all hours in the event to the starting hour
	for i in range(event.duration_hours):
		var hour = start_hour + i  # No modulo
		multi_tile_event_map[hour] = start_hour

func add_random_events():
	var num_events = randi_range(2, 4)
	
	for i in range(num_events):
		var random_event = event_pool[randi() % event_pool.size()].duplicate(true)
		
		# Get all available starting positions for this event
		var available_starts = _get_available_start_hours(random_event.duration_hours)
		
		if available_starts.size() > 0:
			# Pick a random available slot
			var start_hour = available_starts[randi() % available_starts.size()]
			place_event(start_hour, random_event)

func add_random_resources():
	var num_resources = randi_range(3, 5)
	
	for i in range(num_resources):
		var resource_pickup = ResourceManager.get_random_resource()
		
		var resource_event = Event.new(
			"resource_" + str(i),
			"Found: " + resource_pickup.display_name,
			resource_pickup.description + "\n\n+%d %s" % [resource_pickup.amount, resource_pickup.display_name],
			null,
			"resource",
			1
		)
		resource_event.resource_pickup = resource_pickup  # Store the actual resource
		
		var available_starts = _get_available_start_hours(1)
		
		if available_starts.size() > 0:
			var start_hour = available_starts[randi() % available_starts.size()]
			place_event(start_hour, resource_event)

func _get_available_start_hours(duration: int) -> Array:
	var available = []
	
	# Check each possible starting hour
	for start_hour in range(24):
		# Don't allow events to wrap past midnight
		if start_hour + duration > 24:
			continue
		
		var can_fit = true
		
		# Check if all hours needed are free
		for i in range(duration):
			var check_hour = start_hour + i  # No modulo - we don't wrap
			if multi_tile_event_map.has(check_hour):
				can_fit = false
				break
		
		if can_fit:
			available.append(start_hour)
	
	return available


# Helper function to check lunch conflict
func _conflicts_with_lunch(start_hour: int) -> bool:
	# Lunch is at 12-13 (2 hours)
	for i in range(2):
		var lunch_hour = (12 + i) % 24
		if start_hour == lunch_hour:
			return true
	return false

# Helper function to check if an event can be placed
func _can_place_event(start_hour: int, duration: int) -> bool:
	# Check each hour this event would occupy
	for i in range(duration):
		var check_hour = (start_hour + i) % 24
		
		# If this hour is already occupied by ANY event, can't place
		if multi_tile_event_map.has(check_hour):
			return false
	
	return true

func get_event_hours() -> Array:
	return tile_events.keys()

func get_all_event_tile_hours() -> Array:
	# Returns ALL hours that are part of any event (including continuation hours)
	return multi_tile_event_map.keys()

func has_event(hour: int) -> bool:
	return multi_tile_event_map.has(hour)

func get_event(hour: int) -> Event:
	# Get the starting hour, then return the event
	var start_hour = multi_tile_event_map.get(hour, -1)
	if start_hour >= 0:
		return tile_events.get(start_hour, null)
	return null

func get_event_start_hour(hour: int) -> int:
	return multi_tile_event_map.get(hour, hour)


func get_event_end_hour(hour: int) -> int:
	var event = get_event(hour)
	if event:
		var start = get_event_start_hour(hour)
		return (start + event.duration_hours - 1) % 24
	return hour

func trigger_event(hour: int):
	var event = get_event(hour)
	if event:
		event_triggered.emit(event)

func get_day_change_event(day_number: int) -> Event:
	var descriptions = [
		"Another day in this peculiar town. The coffee is hot and the mysteries are cold.",
		"The morning mist clings to the pines. Something feels different today.",
		"You wake with fragments of a strange dream. Red curtains. Backwards speech.",
		"The town seems quieter than usual. Too quiet.",
		"Day %d. How many more until you solve this mystery?" % day_number
	]
	
	return Event.new(
		"day_change",
		"Day %d" % day_number,
		descriptions[randi() % descriptions.size()],
		null,
		"day_change",
		1
	)
