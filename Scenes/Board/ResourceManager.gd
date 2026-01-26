extends Node

# Player resources
var money: int = 0
var insight: int = 0
var time: int = 0

# Signals for UI updates
signal resource_changed(resource_type: ResourcePickup.ResourceType, new_amount: int)

# Resource pickup database
var resource_pickups = {}

func _ready():
	setup_resource_pickups()

func setup_resource_pickups():
	resource_pickups["money"] = ResourcePickup.new(
		ResourcePickup.ResourceType.MONEY,
		"Money",
		2,
		"You found some cash. Not much, but every dollar counts."
	)
	
	resource_pickups["insight"] = ResourcePickup.new(
		ResourcePickup.ResourceType.INSIGHT,
		"Insight",
		1,
		"A flash of understanding. The pieces are coming together."
	)
	
	resource_pickups["time"] = ResourcePickup.new(
		ResourcePickup.ResourceType.TIME,
		"Extra Time",
		1,
		"You find a way to extend your investigation. Time is on your side."
	)

func add_resource(pickup: ResourcePickup):
	match pickup.resource_type:
		ResourcePickup.ResourceType.MONEY:
			money += pickup.amount
			resource_changed.emit(pickup.resource_type, money)
			print("Gained ", pickup.amount, " money. Total: ", money)
		ResourcePickup.ResourceType.INSIGHT:
			insight += pickup.amount
			resource_changed.emit(pickup.resource_type, insight)
			print("Gained ", pickup.amount, " insight. Total: ", insight)
		ResourcePickup.ResourceType.TIME:
			time += pickup.amount
			resource_changed.emit(pickup.resource_type, time)
			print("Gained ", pickup.amount, " time. Total: ", time)

func get_random_resource() -> ResourcePickup:
	var keys = resource_pickups.keys()
	var random_key = keys[randi() % keys.size()]
	return resource_pickups[random_key].duplicate(true)
