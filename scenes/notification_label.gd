class_name Notification
extends Control

@onready var label: Label = $Label

var _tween: Tween


func show_message(text: String) -> void:
	label.text = text
	
	if _tween != null:
		_tween.kill()
		
	modulate.a = 0.0
	show()
	
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.15)
	_tween.tween_interval(1.5)
	_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	_tween.tween_callback(hide)
