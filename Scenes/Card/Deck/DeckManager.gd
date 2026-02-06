extends Node

signal card_added(card: Card)
signal card_removed(card: Card)
signal deck_updated

var deck: Array[Card] = []
var card_pool: Array[Card] = []
var acquired_card_ids: Array[String] = []

func _ready():
	setup_card_pool()
	setup_starting_deck()

func setup_card_pool():
	var you = Card.new(
		"char_you",
		"You",
		Card.CardType.CHARACTER,
		"An occult detective with a knack for uncovering the truth.",
		load("res://assets/portraits/you.png"), # portrait
		-1,   # uses
		[
		"I came to this town looking for answers...",
		"The mysteries here run deeper than anyone knows.",
		"I won't stop until I uncover the truth."
		]
	)
	card_pool.append(you)
	
	var log_lady = Card.new(
		"char_log_lady",
		"The Log Lady",
		Card.CardType.CHARACTER,
		"She speaks for the log, and the log has seen many things.",
		null, # portrait
		-1,   # uses
		[
		"The log saw something that night...",
		"Sometimes the log has things to tell me.",
		"The owls are not what they seem.",
		"Listen to the sounds of the forest."
		]
	)
	card_pool.append(log_lady)
	
	var cooper = Card.new(
		"char_agent_cooper",
		"Agent Cooper",
		Card.CardType.CHARACTER,
		"FBI's finest. Loves coffee, pie, and solving impossible cases.",
		null, # portrait
		-1,   # uses
		[
		"Diane, I've arrived in this strange town.",
		"A damn fine cup of coffee!",
		"Every day, once a day, give yourself a present.",
		"The answers are all around us. We just have to look."
		]
	)
	card_pool.append(cooper)
	
	var sheriff = Card.new(
		"char_sheriff",
		"Sheriff Truman",
		Card.CardType.CHARACTER,
		"The local lawman who knows every secret this town hides.",
		load("res://assets/portraits/truman.png"), # portrait
		-1,   # uses
		[
		"Welcome to our town, stranger.",
		"There are things here that don't make sense.",
		"I've lived here my whole life, and I still don't understand it all."
		]
	)
	card_pool.append(sheriff)
	
	# Items - no dialogue
	card_pool.append(Card.new(
		"item_notebook",
		"Notebook",
		Card.CardType.ITEM,
		"Used to record evidence and draw conclusions."
	))
	
	card_pool.append(Card.new(
		"item_flashlight",
		"Flashlight",
		Card.CardType.ITEM,
		"Illuminates the darkest corners. Batteries not included.",
		null,
		3
	))
	
	card_pool.append(Card.new(
		"item_coffee",
		"Damn Fine Coffee",
		Card.CardType.ITEM,
		"A damn fine cup of coffee. Sharpens the mind.",
		null,
		1
	))
	
	# Actions - no dialogue
	card_pool.append(Card.new(
		"action_talk",
		"Talk",
		Card.CardType.ACTION,
		"The main mode of sharing information between people."
	))
	
	card_pool.append(Card.new(
		"action_investigate",
		"Investigate",
		Card.CardType.ACTION,
		"Search for clues and piece together the mystery."
	))
	
	card_pool.append(Card.new(
		"action_intimidate",
		"Intimidate",
		Card.CardType.ACTION,
		"Sometimes fear loosens tongues better than kindness."
	))
	
	# Rituals - no dialogue
	card_pool.append(Card.new(
		"ritual_summoning",
		"Summoning Circle",
		Card.CardType.RITUAL,
		"Call forth entities from beyond. Requires: Notebook + Character with Insight."
	))
	
	card_pool.append(Card.new(
		"ritual_divination",
		"Divination",
		Card.CardType.RITUAL,
		"Peer into possible futures. Requires: Coffee + Time resource."
	))

func setup_starting_deck():
	# Start with 3 basic cards
	add_card_by_id("char_you")
	add_card_by_id("item_notebook")
	add_card_by_id("action_talk")

func add_card(card: Card):
	# Check if this is a character that's already acquired
	if card.card_type == Card.CardType.CHARACTER:
		if acquired_card_ids.has(card.card_id):
			print("Character already in deck: ", card.card_name)
			return  # Don't add duplicates
	
	deck.append(card)
	acquired_card_ids.append(card.card_id)  # Track it
	card_added.emit(card)
	deck_updated.emit()
	print("Added card to deck: ", card.card_name)

func add_card_by_id(card_id: String):
	for card in card_pool:
		if card.card_id == card_id:
			add_card(card.duplicate(true))
			return
	push_error("Card not found: " + card_id)

func remove_card(card: Card):
	var idx = deck.find(card)
	if idx >= 0:
		deck.remove_at(idx)
		# If it's a character, remove from acquired list
		if card.card_type == Card.CardType.CHARACTER:
			acquired_card_ids.erase(card.card_id)
		card_removed.emit(card)
		deck_updated.emit()
		print("Removed card from deck: ", card.card_name)

func get_random_card() -> Card:
	if card_pool.size() == 0:
		push_error("Card pool is empty!")
		return null
	
	# Try to find a card that isn't already acquired (for characters)
	var available_cards = []
	for card in card_pool:
		if card.card_type == Card.CardType.CHARACTER:
			if not acquired_card_ids.has(card.card_id):
				available_cards.append(card)
		else:
			# Non-characters can repeat
			available_cards.append(card)
	
	print("Available cards: ", available_cards.size(), " / ", card_pool.size())  # DEBUG
	print("Acquired character IDs: ", acquired_card_ids)  # DEBUG
	
	if available_cards.size() > 0:
		var random_card = available_cards[randi() % available_cards.size()]
		print("Selected: ", random_card.card_name, " (", random_card.get_type_name(), ")")  # DEBUG
		return random_card.duplicate(true)
	
	print("No available cards!")  # DEBUG
	return null

func get_cards_by_type(type: Card.CardType) -> Array[Card]:
	var filtered: Array[Card] = []
	for card in deck:
		if card.card_type == type:
			filtered.append(card)
	return filtered

func get_deck_stats() -> Dictionary:
	return {
		"total": deck.size(),
		"characters": get_cards_by_type(Card.CardType.CHARACTER).size(),
		"items": get_cards_by_type(Card.CardType.ITEM).size(),
		"actions": get_cards_by_type(Card.CardType.ACTION).size(),
		"rituals": get_cards_by_type(Card.CardType.RITUAL).size()
	}
