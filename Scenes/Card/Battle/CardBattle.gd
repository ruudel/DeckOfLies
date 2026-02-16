extends Control

signal battle_won
signal battle_fled
signal battle_lost

# UI References
@onready var enemy_portrait = $ColorRect/VBoxContainer/EnemyArea/EnemyPortrait
@onready var enemy_name = $ColorRect/VBoxContainer/EnemyArea/EnemyInfo/EnemyName
@onready var enemy_health = $ColorRect/VBoxContainer/EnemyArea/EnemyInfo/EnemyHealth
@onready var enemy_description = $ColorRect/VBoxContainer/EnemyArea/EnemyInfo/EnemyDescription
@onready var deck_count = $ColorRect/VBoxContainer/BattleFooter/MarginContainer/HBoxContainer/VBoxContainer/DeckCount
@onready var draw_button = $ColorRect/VBoxContainer/BattleFooter/MarginContainer/HBoxContainer/VBoxContainer/DrawButton
@onready var hand_container = $ColorRect/VBoxContainer/BattleFooter/MarginContainer/HBoxContainer/ScrollContainer/HandContainer
@onready var end_turn_button = $ColorRect/VBoxContainer/BattleFooter/MarginContainer/HBoxContainer/VBoxContainer2/EndTurnButton
@onready var turn_info = $ColorRect/VBoxContainer/BattleFooter/MarginContainer/HBoxContainer/VBoxContainer2/TurnInfo

# Battle state
var current_enemy: BattleEnemy
var battle_deck: Array[Card] = []
var hand: Array[Card] = []
var discard_pile: Array[Card] = []

const MAX_HAND_SIZE = 7
const CARDS_PER_TURN = 3

var player_turn: bool = true
var cards_played_this_turn: int = 0

func _ready():
	hide()
	draw_button.pressed.connect(_on_draw_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

func start_battle(enemy: BattleEnemy):
	current_enemy = enemy
	_setup_ui()
	_setup_battle_deck()
	_draw_starting_hand()
	show()

func _setup_ui():
	enemy_name.text = current_enemy.enemy_name
	enemy_description.text = current_enemy.description
	enemy_health.max_value = current_enemy.max_health
	enemy_health.value = current_enemy.current_health
	
	if current_enemy.portrait:
		enemy_portrait.texture = current_enemy.portrait
	
	_update_deck_count()
	_update_turn_info()

func _setup_battle_deck():
	# Create battle deck from player's collection
	battle_deck.clear()
	
	for card in DeckManager.deck:
		# Only use CHARACTER and ACTION cards in battle
		if card.card_type == Card.CardType.CHARACTER or card.card_type == Card.CardType.ACTION:
			battle_deck.append(card.duplicate(true))
	
	battle_deck.shuffle()
	discard_pile.clear()

func _draw_starting_hand():
	for i in range(CARDS_PER_TURN):
		_draw_card()

func _draw_card():
	if hand.size() >= MAX_HAND_SIZE:
		print("Hand is full!")
		return
	
	if battle_deck.size() == 0:
		_reshuffle_discard()
	
	if battle_deck.size() > 0:
		var card = battle_deck.pop_back()
		hand.append(card)
		_add_card_to_hand_ui(card)
	
	_update_deck_count()

func _reshuffle_discard():
	battle_deck = discard_pile.duplicate()
	battle_deck.shuffle()
	discard_pile.clear()
	print("Reshuffled discard pile into deck")

func _add_card_to_hand_ui(card: Card):
	var card_button = Button.new()
	card_button.text = card.card_name
	card_button.custom_minimum_size = Vector2(120, 160)
	card_button.pressed.connect(func(): _play_card(card, card_button))
	
	# Add tooltip with description
	card_button.tooltip_text = card.description
	
	hand_container.add_child(card_button)

func _play_card(card: Card, button: Button):
	if not player_turn:
		print("Not your turn!")
		return
	
	print("Playing card: ", card.card_name)
	
	# Calculate damage based on card type and stats
	var damage = _calculate_card_damage(card)
	_deal_damage_to_enemy(damage)
	
	# Remove from hand
	hand.erase(card)
	discard_pile.append(card)
	button.queue_free()
	
	cards_played_this_turn += 1
	
	_check_battle_end()

func _calculate_card_damage(card: Card) -> int:
	var base_damage = 5
	
	# Characters use their associated stat
	if card.card_type == Card.CardType.CHARACTER:
		# Use a stat based on character (simplified for now)
		base_damage += CharacterProgression.investigation
	
	# Actions have fixed damage
	elif card.card_type == Card.CardType.ACTION:
		if card.card_id == "action_investigate":
			base_damage = 8
		elif card.card_id == "action_intimidate":
			base_damage = 10
		else:
			base_damage = 6
	
	# Bonus damage if exploiting weakness
	var stat_match = _get_card_stat_type(card)
	if stat_match == current_enemy.weakness:
		base_damage = int(base_damage * 1.5)
		print("WEAKNESS EXPLOITED! +50% damage")
	
	return base_damage

func _get_card_stat_type(card: Card) -> String:
	# Map cards to stat types for weakness system
	match card.card_id:
		"char_agent_cooper", "action_investigate":
			return "investigation"
		"char_log_lady":
			return "intuition"
		"char_sheriff", "action_intimidate":
			return "influence"
		_:
			return "investigation"

func _deal_damage_to_enemy(damage: int):
	current_enemy.take_damage(damage)
	enemy_health.value = current_enemy.current_health
	
	print("Dealt ", damage, " damage! Enemy HP: ", current_enemy.current_health, "/", current_enemy.max_health)
	
	# Visual feedback
	_flash_enemy_damage()

func _flash_enemy_damage():
	var tween = create_tween()
	tween.tween_property(enemy_portrait, "modulate", Color(1.5, 0.5, 0.5), 0.1)
	tween.tween_property(enemy_portrait, "modulate", Color.WHITE, 0.2)

func _check_battle_end():
	if current_enemy.is_defeated():
		_on_battle_won()

func _on_draw_pressed():
	if hand.size() >= MAX_HAND_SIZE:
		print("Hand is full!")
		return
	
	_draw_card()

func _on_end_turn_pressed():
	if not player_turn:
		return
	
	_end_player_turn()
	_enemy_turn()
	_start_player_turn()

func _end_player_turn():
	player_turn = false
	cards_played_this_turn = 0
	_update_turn_info()

func _enemy_turn():
	print("=== ENEMY TURN ===")
	
	# Simple AI: enemy attacks
	var damage = 5 + current_enemy.threat_level * 2
	
	# Player takes damage (reduce Insight for now)
	ResourceManager.add_resource(ResourcePickup.new(
		ResourcePickup.ResourceType.INSIGHT,
		"Insight",
		-damage,
		"The enemy strikes at your sanity!"
	))
	
	print("Enemy dealt ", damage, " damage!")
	
	await get_tree().create_timer(1.0).timeout

func _start_player_turn():
	player_turn = true
	
	# Draw cards at start of turn
	for i in range(CARDS_PER_TURN):
		_draw_card()
	
	_update_turn_info()
	print("=== YOUR TURN ===")

func _update_deck_count():
	deck_count.text = "Cards: " + str(battle_deck.size())

func _update_turn_info():
	if player_turn:
		turn_info.text = "Your Turn"
	else:
		turn_info.text = "Enemy Turn"

func _on_battle_won():
	print("VICTORY!")
	
	# Rewards
	ResourceManager.add_resource(ResourcePickup.new(
		ResourcePickup.ResourceType.INSIGHT,
		"Insight",
		2,
		"You learned from this encounter."
	))
	
	await get_tree().create_timer(1.0).timeout
	battle_won.emit()
	hide()

func _on_battle_lost():
	print("DEFEAT...")
	battle_lost.emit()
	hide()
