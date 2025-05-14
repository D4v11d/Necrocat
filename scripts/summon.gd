class_name Summon extends Node2D

@onready var summon_cooldown: Timer = $"../SummonCooldown"
@onready var player: Player = $".."

var can_summon := true
var summoned_allies_list: Array[Mob] = []

func _physics_process(_delta: float) -> void:
	summon_ally()
	
	clear_all_summons()


func summon_ally() -> void:
	if Input.is_key_pressed(KEY_Q) and can_summon:
		if player.slime_summon != null:
			var new_ally = player.slime_summon.instantiate()
			summoned_allies_list.append(new_ally)
			
			can_summon = false
			summon_cooldown.start()
			if new_ally:
				new_ally.is_ally = true
				
				new_ally.position = player.position + get_spawn_position_offset()
				
				# Spawn inside Summons node
				var summons_node = get_tree().current_scene.get_node("Summons")
				if summons_node:
					summons_node.add_child(new_ally)
				else:
					push_warning("Summons node not found!")


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
	if Input.is_key_pressed(KEY_BACKSPACE):
		for summon in summoned_allies_list:
			summoned_allies_list.erase(summon)
			summon.queue_free()
