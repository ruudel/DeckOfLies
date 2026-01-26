extends PanelContainer

@onready var money_value = $MarginContainer/VBoxContainer/MoneyContainer/MoneyValue
@onready var insight_value = $MarginContainer/VBoxContainer/InsightContainer/InsightValue
@onready var time_value = $MarginContainer/VBoxContainer/TimeContainer/TimeValue
@onready var day_label = $MarginContainer/VBoxContainer/DayLabel

func _ready():
	# Connect to resource changes
	ResourceManager.resource_changed.connect(_on_resource_changed)
	SignalBus.day_changed.connect(_on_day_changed)
	
	# Initial update
	update_all_values()

func update_all_values():
	money_value.text = str(ResourceManager.money)
	insight_value.text = str(ResourceManager.insight)
	time_value.text = str(ResourceManager.time)
	day_label.text = "Day: " + str(GameState.current_day)

func _on_resource_changed(resource_type: ResourcePickup.ResourceType, new_amount: int):
	# Animate the value change for feedback
	match resource_type:
		ResourcePickup.ResourceType.MONEY:
			money_value.text = str(new_amount)
			_animate_value_change(money_value)
		ResourcePickup.ResourceType.INSIGHT:
			insight_value.text = str(new_amount)
			_animate_value_change(insight_value)
		ResourcePickup.ResourceType.TIME:
			time_value.text = str(new_amount)
			_animate_value_change(time_value)

func _on_day_changed(new_day: int):
	day_label.text = "Day: " + str(new_day)

func _animate_value_change(label: Label):
	# Quick scale pulse to show the value changed
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Color flash
	var original_color = label.modulate
	label.modulate = Color(1.5, 1.5, 0.5)  # Yellow flash
	tween.tween_property(label, "modulate", original_color, 0.3)
