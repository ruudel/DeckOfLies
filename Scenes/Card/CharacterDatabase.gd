extends Node

var characters = {}

func _ready():
	setup_characters()

func setup_characters():
	# Create some Twin Peaks-inspired characters
	characters["log_lady"] = Character.new(
		"Margaret Lanterman",
		"The Log Lady",
		"She carries a log and speaks in cryptic wisdom. The log knows things.",
		null,  # We'll add portraits later
		"rare"
	)
	
	characters["agent_cooper"] = Character.new(
		"Dale Cooper",
		"FBI Special Agent",
		"A damn fine investigator with a love for coffee and cherry pie.",
		null,
		"legendary"
	)
	
	characters["sheriff_truman"] = Character.new(
		"Harry Truman",
		"Town Sheriff",
		"The lawman who knows every secret this town holds.",
		null,
		"common"
	)
	
	characters["laura_palmer"] = Character.new(
		"Laura Palmer",
		"Homecoming Queen",
		"Her death started it all. But is she really gone?",
		null,
		"legendary"
	)
	
	characters["the_giant"] = Character.new(
		"The Fireman",
		"Mysterious Guide",
		"An impossibly tall being who speaks in riddles and warnings.",
		null,
		"rare"
	)
	
	characters["bob"] = Character.new(
		"BOB",
		"Malevolent Spirit",
		"A demon who feeds on fear and garmonbozia. Pure evil incarnate.",
		null,
		"legendary"
	)

func get_character(id: String) -> Character:
	return characters.get(id, null)

func get_random_character() -> Character:
	var keys = characters.keys()
	var random_key = keys[randi() % keys.size()]
	return characters[random_key]
