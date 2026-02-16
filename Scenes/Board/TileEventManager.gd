extends Node

signal event_triggered(event: Event)

var tile_events = {}  # Maps hour to Event resource
var event_pool = []
var multi_tile_event_map = {}  # Maps each hour of a multi-tile event to its starting hour
var locked_tiles = {}

var event_occurrence_count = {}   # event_id -> times triggered total
var event_last_triggered_day = {} # event_id -> last day it was triggered
var events_used_today = {}        # event_id -> true (resets each day)

var standard_event_pool = []
var character_encounter_pool = []
var curse_pool = []
var blessing_pool = []

func _ready():
	setup_event_pools()
	
func setup_events():
	tile_events.clear()
	multi_tile_event_map.clear()
	events_used_today.clear()  # NEW: Reset daily tracker
	
	# First, place all locked tiles back
	for hour in locked_tiles.keys():
		var locked_event = locked_tiles[hour]
		place_event(hour, locked_event)
	
	# Always have lunch (unless hour 12 is locked)
	if not locked_tiles.has(12):
		var lunch_event = Event.new(
			"lunch_break",
			"Lunch Break",
			"The diner is always open at noon.",
			null,
			"standard",
			2
		)
		place_event(12, lunch_event)
	
	add_random_events()
	add_random_resources()

func setup_event_pools():
	standard_event_pool = [
		Event.new(
			"party",
			"Town Party",
			"The whole town gathers for a celebration. Music, dancing, and strange undercurrents.",
			null,
			"standard",
			4,
			Event.RecurrenceType.LIMITED,
			3,
			2,
			18,
			23
		),
		Event.new(
			"black_lodge",
			"The Black Lodge Beckons",
			"You feel a strange pull towards the woods. Red curtains dance in your peripheral vision.",
			null,
			"standard",
			1,
			Event.RecurrenceType.UNIQUE
		),
		Event.new(
			"investigation",
			"Deep Investigation",
			"You spend hours piecing together clues. The conspiracy runs deeper than you thought.",
			null,
			"standard",
			3,
			Event.RecurrenceType.UNLIMITED,
			-1,
			1,
			8,
			20
		),
		Event.new(
			"radio_broadcast",
			"Strange Radio Broadcast",
			"Your radio crackles with a backwards message.",
			null,
			"standard",
			1,
			Event.RecurrenceType.UNLIMITED
		),
		Event.new(
			"doppelganger",
			"Doppelganger Sighting",
			"You swear you just saw yourself walking down the street.",
			null,
			"standard",
			1,
			Event.RecurrenceType.LIMITED,
			2,
			0
		)
	]
	
	# Night Stakeout with split time windows
	var stakeout = Event.new(
		"stakeout",
		"All Night Stakeout",
		"You watch a suspicious location through the night. Nothing happens... or does it?",
		null,
		"standard",
		5,
		Event.RecurrenceType.UNLIMITED,
		-1,
		2
	)
	stakeout.add_time_window(19, 23)  # Evening window
	stakeout.add_time_window(1, 5)    # Early morning window (skips midnight)
	standard_event_pool.append(stakeout)
	
	# Character encounters
	character_encounter_pool = [
		Event.new(
			"log_lady_warning",
			"The Log Lady's Warning",
			"An elderly woman with a log whispers cryptically: 'The owls are gathering.'",
			null,
			"character_encounter",
			1,
			Event.RecurrenceType.UNIQUE  # Special encounters only once
		),
		Event.new(
			"meet_cooper",
			"FBI Agent",
			"A well-dressed man in a suit introduces himself.",
			null,
			"character_encounter",
			1,
			Event.RecurrenceType.UNIQUE
		),
		Event.new(
			"meet_sheriff",
			"The Sheriff",
			"The local lawman greets you with a handshake.",
			null,
			"character_encounter",
			1,
			Event.RecurrenceType.UNIQUE
		)
	]
	
	# Curses (negative permanent effects)
	curse_pool = [
		Event.new(
			"cursed_ground",
			"Cursed Ground",
			"This place is tainted by ancient evil. You lose 1 Insight whenever you pass through here.",
			null,
			"curse",
			1
		),
		Event.new(
			"time_drain",
			"Temporal Anomaly",
			"Time moves strangely here. Lose 1 Time resource when landing on this tile.",
			null,
			"curse",
			1
		),
		Event.new(
			"money_pit",
			"Money Pit",
			"Your wallet feels lighter every time you're near this place. Lose 2 Money.",
			null,
			"curse",
			1
		)
	]
	
	# Add resource effects to curses
	curse_pool[0].resource_pickup = ResourcePickup.new(
		ResourcePickup.ResourceType.INSIGHT,
		"Insight",
		-1,  # Negative amount!
		"The curse drains your mental clarity."
	)
	curse_pool[1].resource_pickup = ResourcePickup.new(
		ResourcePickup.ResourceType.TIME,
		"Time",
		-1,
		"Time slips away from you."
	)
	curse_pool[2].resource_pickup = ResourcePickup.new(
		ResourcePickup.ResourceType.MONEY,
		"Money",
		-2,
		"Your money vanishes into the void."
	)
	
	# Blessings (positive permanent effects)
	blessing_pool = [
		Event.new(
			"sacred_grove",
			"Sacred Grove",
			"A peaceful sanctuary blessed by ancient spirits. Gain 2 Insight.",
			null,
			"blessing",
			1
		),
		Event.new(
			"lucky_spot",
			"Lucky Spot",
			"Fortune smiles upon this location. Gain 3 Money.",
			null,
			"blessing",
			1
		),
		Event.new(
			"time_well",
			"Time Well",
			"Time flows more generously here. Gain 1 Time.",
			null,
			"blessing",
			1
		),
		Event.new(
			"golden_hour",
			"Golden hour",
			"The Sun rises. The birds sing. Mystic powers are growing. Gain a bit of everything.",
			null,
			"blessing",
			1
		)
	]
	
	# Add resource effects to blessings
	blessing_pool[0].resource_pickup = ResourcePickup.new(
		ResourcePickup.ResourceType.INSIGHT,
		"Insight",
		2,
		"The grove shares its wisdom with you."
	)
	blessing_pool[1].resource_pickup = ResourcePickup.new(
		ResourcePickup.ResourceType.MONEY,
		"Money",
		3,
		"Fortune favors you here."
	)
	blessing_pool[2].resource_pickup = ResourcePickup.new(
		ResourcePickup.ResourceType.TIME,
		"Time",
		1,
		"Time extends in your favor."
	)
	blessing_pool[3].resource_pickup = ResourcePickup.new(
		ResourcePickup.ResourceType.ALL,
		"Mystic",
		1,
		"The source of all life."
	)
	
	# Add a card reward event
	standard_event_pool.append(
		Event.new(
			"mysterious_stranger",
			"Mysterious Stranger",
			"You meet someone who seems to know more than they should. They join your investigation.",
			null,
			"character_encounter",
			1,
			Event.RecurrenceType.UNLIMITED
		)
	)
	
	var shadow_encounter = Event.new(
		"shadow_battle",
		"Shadow in the Dark",
		"A menacing presence blocks your path.",
		null,
		"battle",  # NEW TYPE
		1,
		Event.RecurrenceType.UNLIMITED,
		-1,
		2  # 2 day cooldown
	)
	shadow_encounter.add_time_window(20, 4)  # Night encounters
	standard_event_pool.append(shadow_encounter)
	
	# Combine for backward compatibility
	event_pool = standard_event_pool + character_encounter_pool
	
	

func can_event_occur(event: Event) -> bool:
	var current_day = GameState.current_day
	
	# Check if already used today
	if events_used_today.has(event.event_id):
		return false
	
	# Check recurrence type
	match event.recurrence:
		Event.RecurrenceType.UNIQUE:
			# Can only happen once ever
			if event_occurrence_count.get(event.event_id, 0) >= 1:
				return false
		
		Event.RecurrenceType.LIMITED:
			# Can happen max_occurrences times
			if event_occurrence_count.get(event.event_id, 0) >= event.max_occurrences:
				return false
	
	# Check cooldown
	if event.cooldown_days > 0:
		var last_day = event_last_triggered_day.get(event.event_id, -999)
		if current_day - last_day < event.cooldown_days:
			return false
	
	return true

func _get_available_start_hours_for_event(event: Event) -> Array:
	var available = []
	var duration = event.duration_hours
	
	for start_hour in range(1, 24 - duration + 1):
		# Check if event can occur at this time
		if not event.can_occur_at_hour(start_hour):
			continue
		
		var can_fit = true
		
		# Check if all hours needed are free
		for i in range(duration):
			var check_hour = start_hour + i
			if multi_tile_event_map.has(check_hour) or locked_tiles.has(check_hour):
				can_fit = false
				break
		
		if can_fit:
			available.append(start_hour)
	
	# DEBUG
	if event.event_id == "stakeout" and available.size() > 0:
		print("Stakeout available hours: ", available)
	
	return available

func get_random_curse() -> Event:
	if curse_pool.size() > 0:
		return curse_pool[randi() % curse_pool.size()].duplicate(true)
	return null

func get_random_blessing() -> Event:
	if blessing_pool.size() > 0:
		return blessing_pool[randi() % blessing_pool.size()].duplicate(true)
	return null

func get_random_character_encounter() -> Event:
	if character_encounter_pool.size() > 0:
		return character_encounter_pool[randi() % character_encounter_pool.size()].duplicate(true)
	return null

func get_curse_by_id(curse_id: String) -> Event:
	for curse in curse_pool:
		if curse.event_id == curse_id:
			return curse.duplicate(true)
	return null

func get_blessing_by_id(blessing_id: String) -> Event:
	for blessing in blessing_pool:
		if blessing.event_id == blessing_id:
			return blessing.duplicate(true)
	return null

func place_event(start_hour: int, event: Event):
	# Check if event would wrap past midnight
	if start_hour + event.duration_hours > 24:
		return
	
	# Check if there's space for this event (fix: use multi_tile_event_map)
	for i in range(event.duration_hours):
		var hour = start_hour + i  # No modulo
		if multi_tile_event_map.has(hour):  # Changed from tile_events.has(hour)
			return
	
	# Place the event at starting hour
	tile_events[start_hour] = event
	
	# Map all hours in the event to the starting hour
	for i in range(event.duration_hours):
		var hour = start_hour + i  # No modulo
		multi_tile_event_map[hour] = start_hour

func lock_tile(hour: int, event: Event):
	locked_tiles[hour] = event
	
	# Immediately place it on the board
	# First clear that hour if it has something
	if multi_tile_event_map.has(hour):
		var old_start = multi_tile_event_map[hour]
		# Remove the old event from that position
		tile_events.erase(old_start)
		multi_tile_event_map.erase(hour)
	
	place_event(hour, event)
	print("Locked tile at hour ", hour, " with event: ", event.title)

func unlock_tile(hour: int):
	if locked_tiles.has(hour):
		locked_tiles.erase(hour)
		print("Unlocked tile at hour ", hour)
		
		# Remove from current board
		if multi_tile_event_map.has(hour):
			var event_start = multi_tile_event_map[hour]
			tile_events.erase(event_start)
			multi_tile_event_map.erase(hour)

func is_tile_locked(hour: int) -> bool:
	return locked_tiles.has(hour)

func add_random_events():
	var num_events = randi_range(2, 4)
	print("=== Placing ", num_events, " random events ===")
	var attempts = 0
	var max_attempts = 50
	
	for i in range(num_events):
		var placed = false
		
		while not placed and attempts < max_attempts:
			attempts += 1
			
			var random_event = event_pool[randi() % event_pool.size()]
			
			if not can_event_occur(random_event):
				continue
			
			var available_starts = _get_available_start_hours_for_event(random_event)
			
			if available_starts.size() > 0:
				var start_hour = available_starts[randi() % available_starts.size()]
				var event_copy = random_event.duplicate(true)
				
				print("  ✓ Placed '", event_copy.title, "' at hour ", start_hour)  # DEBUG
				
				place_event(start_hour, event_copy)
				events_used_today[event_copy.event_id] = true
				placed = true
		
		if not placed:
			print("  ✗ Failed to place event ", i)  # DEBUG

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
	
	for start_hour in range(1, 24 - duration + 1):
		var can_fit = true
		
		# Check if all hours needed are free AND not locked
		for i in range(duration):
			var check_hour = start_hour + i
			if multi_tile_event_map.has(check_hour) or locked_tiles.has(check_hour):
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
		# Track occurrence
		var count = event_occurrence_count.get(event.event_id, 0)
		event_occurrence_count[event.event_id] = count + 1
		event_last_triggered_day[event.event_id] = GameState.current_day
		
		print("Event '", event.title, "' triggered. Total occurrences: ", event_occurrence_count[event.event_id])
		
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
