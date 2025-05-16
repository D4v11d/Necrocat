class_name Summon extends Node2D

@onready var summon_cooldown: Timer = $"../SummonCooldown"
@onready var player: Player = $".."
@onready var casting_timer: Timer = $"../CastingTimer"

var can_summon := true # reset after cooldown
var summoned_allies_list: Array[Mob] = []

signal delete_mob # called after arising

func _physics_process(_delta: float) -> void:
	summon_ally()
	
	clear_all_summons()


func summon_ally() -> void:
	if Input.is_key_pressed(KEY_Q) and can_summon and player.Q_summon_enabled:
		if player.slime_summon != null:
			var new_ally = player.slime_summon.instantiate()
			summoned_allies_list.append(new_ally)
			
			can_summon = false
			summon_cooldown.start()
			if new_ally:
				new_ally.is_ally = true
				
				
				
				new_ally.position = player.position + calculate_summon_position()
				
				# Spawn inside Summons node
				var summons_node = get_tree().current_scene.get_node("Summons")
				if summons_node:
					summons_node.add_child(new_ally)
				else:
					push_warning("Summons node not found!")

func calculate_summon_position() -> Vector2:
	var spawn_offset = get_spawn_position_offset()
	for summon in summoned_allies_list:
		if summon.position == player.position + spawn_offset:
			spawn_offset.x += 2
			
	return spawn_offset

func get_spawn_position_offset() -> Vector2:
	
	if player.last_direction == Vector2.UP:
		return Vector2(0, -15)
		
	if player.last_direction == Vector2.DOWN:
		return Vector2(0, 25)
		
	if player.last_direction == Vector2.LEFT:
		return Vector2(-20, 0)
		
	if player.last_direction == Vector2.RIGHT:
		return Vector2(20, 0)
	
	return Vector2(0,0)


func _on_summon_cooldown_timeout() -> void:
	can_summon = true
	
func clear_all_summons() -> void:
	if Input.is_action_pressed("delete_summons"):
		for summon in summoned_allies_list:
			summoned_allies_list.erase(summon)
			summon.queue_free()

func handle_arise_mob() -> void:
	if Input.is_action_just_pressed("arise"):
		play_cast_animation()
		casting_timer.start()
		player.is_casting_spell = true
		player.Q_summon_enabled = true
		player.slime_summon_sprite.visible = true
		emit_signal("delete_mob")
		player.e_key_animation.visible = false

func play_cast_animation() -> void:
	if player.last_direction == Vector2.UP:
		player.animated_sprite_2d.play("cast_back")
	elif player.last_direction == Vector2.DOWN:
		player.animated_sprite_2d.play("cast_front")
	else:
		player.animated_sprite_2d.play("cast_side")
		player.animated_sprite_2d.flip_h = player.last_direction == Vector2.LEFT

func show_arise_message() -> void:
	var label = player.new_summon_label
	DamageNumbers.animate_label(label, "New Summon Arised")

func summon_killed(summon: Mob) -> void:
	summoned_allies_list.erase(summon)


func _on_casting_timer_timeout() -> void:
	player.is_casting_spell = false
	show_arise_message()
	player.play_idle_animation()
