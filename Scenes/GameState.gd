extends Node

var current_day: int = 1

func increment_day():
	current_day += 1
	SignalBus.day_changed.emit(current_day)  # Use SignalBus instead of own signal
	print("New day! Day ", current_day)
