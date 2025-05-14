extends Node

func display_number(value: int, position: Vector2, color: String = "#FFF"):
	var number = Label.new()
	number.global_position = position
	number.text = str(value)
	number.z_index = 5
	number.label_settings = LabelSettings.new()
	
	number.label_settings.font_color = color
	number.label_settings.font_size = 11
	number.label_settings.outline_color = "#000"
	number.label_settings.outline_size = 1
	
	call_deferred("add_child", number)
	
	await number.resized
	number.pivot_offset = Vector2(number.size / 2)
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		number, "position:y", number.position.y - 24, 0.4
	).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	number.queue_free()
