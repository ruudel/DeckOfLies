extends CanvasLayer

@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var image_rect = $Panel/VBoxContainer/ImageRect
@onready var description_label = $Panel/VBoxContainer/DescriptionLabel
@onready var close_button = $Panel/VBoxContainer/CloseButton

func _ready():
	hide()
	close_button.pressed.connect(_on_close_pressed)
	
	# Listen to SignalBus for popup requests
	SignalBus.popup_requested.connect(show_event)

func show_event(event: Event):
	title_label.text = event.title
	description_label.text = event.description
	
	if event.image:
		image_rect.texture = event.image
		image_rect.show()
	else:
		image_rect.hide()
	
	# If this is a resource event, collect it
	if event.event_type == "resource" and event.resource_pickup:
		ResourceManager.add_resource(event.resource_pickup)
	
	show()

func _on_close_pressed():
	hide()
	SignalBus.popup_closed.emit()
