class_name HealthBar extends TextureProgressBar

@onready var timer: Timer = $Timer

var health: float = 0 : set = _set_health

func _set_health(new_health: float) -> void:
	var previous_health = health
	health = min(max_value, new_health)
	value = health

func init_health(_health: float) -> void:
	health = _health
	max_value = _health
	value = _health
