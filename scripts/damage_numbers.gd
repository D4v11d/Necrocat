extends Node

func display_text(value: String, position: Vector2, color: String = "#FFF"):
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
	await play_tween_animation(number)
	number.queue_free()

func play_tween_animation(label: Label, y_offset := 24, duration := 0.4) -> void:
	await get_tree().process_frame  # Wait a frame to ensure layout is correct
	label.pivot_offset = label.size / 2
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		label, "position:y", label.position.y - y_offset, duration
	).set_ease(Tween.EASE_OUT)
	
	await tween.finished

func animate_label(label: Label, text: String, color: String = "#FFF"):
	label.visible = true
	label.text = text
	label.z_index = 5
	await play_tween_animation(label, 20, 2)
	label.visible = false
