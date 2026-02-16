extends CanvasLayer

@onready var invocation_points = $ColorRect/Panel/MarginContainer/VBoxContainer/HBoxContainer/InvocationPoints
@onready var evocation_points = $ColorRect/Panel/MarginContainer/VBoxContainer/HBoxContainer/EvocationPoints
@onready var invocation_button = $ColorRect/Panel/MarginContainer/VBoxContainer/HBoxContainer2/InvocationButton
@onready var evocation_button = $ColorRect/Panel/MarginContainer/VBoxContainer/HBoxContainer2/EvocationButton
@onready var content_panel = $ColorRect/Panel/MarginContainer/VBoxContainer/ContentPanel
@onready var continue_button = $ColorRect/Panel/MarginContainer/VBoxContainer/ContinueButton

var invocation_module
var evocation_module
var current_module = null

func _ready():
	hide()
	invocation_button.pressed.connect(_show_invocation)
	evocation_button.pressed.connect(_show_evocation)
	continue_button.pressed.connect(_on_continue)
	
	invocation_module = InvocationModule.new()
	evocation_module = EvocationModule.new()

func show_level_up():
	_update_points()
	_show_invocation()
	show()
	
func _update_points():
	print("invocation_points node: ", invocation_points)
	print("evocation_points node: ", evocation_points)
	
	if invocation_points == null or evocation_points == null:
		push_error("Node paths are wrong! Check your scene structure.")
		return
	
	invocation_points.text = "Invocation Points: " + str(CharacterProgression.available_invocation_points)
	evocation_points.text = "Evocation Points: " + str(CharacterProgression.available_evocation_points)

func _show_invocation():
	_clear_content()
	current_module = invocation_module
	content_panel.add_child(invocation_module)
	invocation_module.refresh()

func _show_evocation():
	_clear_content()
	current_module = evocation_module
	content_panel.add_child(evocation_module)
	evocation_module.refresh()

func _clear_content():
	for child in content_panel.get_children():
		content_panel.remove_child(child)

func _on_continue():
	hide()
	SignalBus.popup_closed.emit()
