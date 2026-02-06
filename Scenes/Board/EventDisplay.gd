# ============================================
# EventDisplay.gd - Event UI Coordination
# ============================================
class_name EventDisplay
extends Node

signal dialogue_finished(card: Card)

const EVENT_POPUP = preload("res://Scenes/Board/UI/EventPopup.tscn")
const ROLL_OVERLAY = preload("res://Scenes/Board/UI/RollOverlay.tscn")
const DIALOGUE_OVERLAY = preload("res://Scenes/Board/UI/DialogueOverlay.tscn")

var event_popup
var roll_overlay
var dialogue_overlay

func setup_ui(parent: Node):
	event_popup = EVENT_POPUP.instantiate()
	parent.add_child(event_popup)
	
	roll_overlay = ROLL_OVERLAY.instantiate()
	parent.add_child(roll_overlay)
	
	dialogue_overlay = DIALOGUE_OVERLAY.instantiate()
	parent.add_child(dialogue_overlay)
	
	dialogue_overlay.dialogue_finished.connect(func(card): dialogue_finished.emit(card))

func show_roll(number: int, on_complete: Callable):
	roll_overlay.show_roll(number)
	roll_overlay.roll_display_finished.connect(on_complete, CONNECT_ONE_SHOT)

func show_dialogue(card: Card):
	dialogue_overlay.show_dialogue(card)
