extends CanvasLayer

@onready var roll_label = $Panel/VBoxContainer/RollLabel
@onready var sub_label = $Panel/VBoxContainer/SubLabel
@onready var panel = $Panel

signal roll_display_finished

func _ready():
	hide()

func show_roll(number: int):
	roll_label.text = str(number)
	sub_label.text = "You rolled!"
	show()
	
	# Reset panel state
	panel.scale = Vector2(0.5, 0.5)
	panel.modulate.a = 1.0  # Make sure it's visible
	
	# Entrance animation - scale pop
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2(1.2, 1.2), 0.12)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Hold, then fade out
	tween.tween_interval(0.6)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.finished.connect(_on_animation_finished)

func _on_animation_finished():
	hide()
	panel.modulate.a = 1.0  # Reset for next time
	roll_display_finished.emit()
