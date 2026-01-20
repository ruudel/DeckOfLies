extends Node

signal event_triggered(event: Event)

var tile_events = {}  # Maps hour to Event resource
var event_pool = []  # Pool of Event resources

func _ready():
	setup_event_pool()

func setup_events():
	tile_events.clear()
	
	# Always have lunch
	var lunch_event = Event.new(
		"lunch_break",
		"Lunch Break",
		"The diner is always open at noon. Coffee and pie await.",
		null,
		"standard"
	)
	tile_events[12] = lunch_event
	
	add_random_events()

func setup_event_pool():
	event_pool = [
		Event.new(
			"black_lodge",
			"The Black Lodge Beckons",
			"You feel a strange pull towards the woods. Red curtains dance in your peripheral vision.",
			null,
			"standard"
		),
		Event.new(
			"radio_broadcast",
			"Strange Radio Broadcast",
			"Your radio crackles with a backwards message. Is someone trying to tell you something?",
			null,
			"standard"
		),
		Event.new(
			"log_lady_warning",
			"The Log Lady's Warning",
			"An elderly woman with a log whispers cryptically: 'The owls are gathering.'",
			null,
			"character_encounter"
		),
		Event.new(
			"doppelganger",
			"Doppelganger Sighting",
			"You swear you just saw yourself walking down the street. They didn't seem to notice you.",
			null,
			"standard"
		),
		Event.new(
			"coopers_coffee",
			"Cooper's Coffee",
			"A damn fine cup of coffee. You feel energized and ready to investigate.",
			null,
			"character_encounter"
		),
		Event.new(
			"owls",
			"The Owls Are Not What They Seem",
			"An owl watches you from a nearby tree. Its eyes are too knowing, too human.",
			null,
			"standard"
		),
		Event.new(
			"red_room",
			"Red Room Dream",
			"You dozed off and dreamed of a room with red curtains. A dwarf spoke backwards to you.",
			null,
			"standard"
		),
		Event.new(
			"missing_person",
			"Missing Person Poster",
			"A new face on the bulletin board. How many people have disappeared from this town?",
			null,
			"standard"
		),
		Event.new(
			"giant_riddle",
			"The Giant's Riddle",
			"A impossibly tall figure appears briefly. 'Listen to the sounds,' he says before vanishing.",
			null,
			"character_encounter"
		),
		Event.new(
			"bob_laughter",
			"BOB's Laughter",
			"Maniacal laughter echoes through the trees. You feel watched by something malevolent.",
			null,
			"standard"
		),
		Event.new(
			"package",
			"Mysterious Package",
			"A package with no return address sits on your doorstep. Do you open it?",
			null,
			"standard"
		),
		Event.new(
			"sheriff",
			"The Sheriff Needs Help",
			"The local sheriff waves you down. There's been another incident at the mill.",
			null,
			"character_encounter"
		)
	]

func add_random_events():
	var num_events = randi_range(3, 5)
	var available_hours = range(24)
	available_hours.erase(12)
	available_hours.shuffle()
	
	for i in range(num_events):
		if i < available_hours.size():
			var hour = available_hours[i]
			var random_event = event_pool[randi() % event_pool.size()]
			tile_events[hour] = random_event

func get_event_hours() -> Array:
	return tile_events.keys()

func has_event(hour: int) -> bool:
	return tile_events.has(hour)

func get_event(hour: int) -> Event:
	return tile_events.get(hour, null)

func trigger_event(hour: int):
	if tile_events.has(hour):
		event_triggered.emit(tile_events[hour])

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
		"day_change"
	)
