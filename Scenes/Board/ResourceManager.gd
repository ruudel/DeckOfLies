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
	
	resource_pickups["all"] = ResourcePickup.new(
		ResourcePickup.ResourceType.ALL,
		"Everything",
		1,
		"You had a damn fine cup of coffee. Everything is looking better."
	)

func add_resource(pickup: ResourcePickup):
	match pickup.resource_type:
		ResourcePickup.ResourceType.MONEY:
			_update_money(pickup.amount)
			
		ResourcePickup.ResourceType.INSIGHT:
			_update_insight(pickup.amount)
			
		ResourcePickup.ResourceType.TIME:
			_update_time(pickup.amount)
			
		ResourcePickup.ResourceType.ALL:
			time = max(0, time + pickup.amount)
			money = max(0, money + pickup.amount)
			insight = max(0, insight + pickup.amount)
			
			resource_changed.emit(ResourcePickup.ResourceType.TIME, time)
			resource_changed.emit(ResourcePickup.ResourceType.MONEY, money)
			resource_changed.emit(ResourcePickup.ResourceType.INSIGHT, insight)
			
			print("Coffee applied! All resources increased.")

func _update_money(p_amount: int):
	money = max(0, money + p_amount)
	# We force the signal to say 'MONEY' regardless of what the pickup was
	resource_changed.emit(ResourcePickup.ResourceType.MONEY, money)
	print("Money: ", money)

func _update_insight(p_amount: int):
	insight = max(0, insight + p_amount)
	# We force the signal to say 'INSIGHT'
	resource_changed.emit(ResourcePickup.ResourceType.INSIGHT, insight)
	print("Insight: ", insight)

func _update_time(p_amount: int):
	time = max(0, time + p_amount)
	# We force the signal to say 'TIME'
	resource_changed.emit(ResourcePickup.ResourceType.TIME, time)
	print("Time: ", time)

func get_random_resource() -> ResourcePickup:
	var keys = resource_pickups.keys()
	var random_key = keys[randi() % keys.size()]
	return resource_pickups[random_key].duplicate(true)
