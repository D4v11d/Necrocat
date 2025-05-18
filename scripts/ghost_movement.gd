class_name GhostMovement extends Node2D

@onready var emerge_timer: Timer = $"../EmergeTimer"
@onready var mob: Mob = $".."
@onready var player = $"../../../Player"
@export var avoid_distance: float = 50.0  # Minimum distance to maintain from player
@export var max_follow_distance: float = 100.0  # Maximum distance to start following
var has_emerged: bool = false

func _physics_process(delta: float) -> void:
	if mob.is_knocked_back:
		mob.move_and_collide(mob.velocity * delta)
		return
	
	if mob.is_ally and not has_emerged:
		_play_emerge()
		return
	
	# Calculate distance to player
	var distance_to_player = mob.global_position.distance_to(player.global_position)
	
	if not mob.is_ally and mob.hp > 0:
		mob.animated_sprite.play("idle_front")
		if distance_to_player < avoid_distance:
			# Move away from player
			var direction = (mob.global_position - player.global_position).normalized()
			mob.velocity = direction * mob.speed
			mob.move_and_collide(mob.velocity * delta)
		else:
			# Stop moving if far enough
			mob.velocity = Vector2.ZERO
	
	if mob.is_ally and has_emerged and not mob.is_dying and mob.hp > 0:
		mob.animated_sprite.play("idle_front")
		if distance_to_player > max_follow_distance:
			# Move toward player
			var direction = (player.global_position - mob.global_position).normalized()
			mob.velocity = direction * mob.speed
			mob.move_and_collide(mob.velocity * delta)
		elif distance_to_player < avoid_distance:
			# Move away from player to maintain minimum distance
			var direction = (mob.global_position - player.global_position).normalized()
			mob.velocity = direction * mob.speed
			mob.move_and_collide(mob.velocity * delta)
		else:
			# Stop moving if within desired range
			mob.velocity = Vector2.ZERO

func _play_emerge() -> void:
	if not mob.is_emerging:
		mob.is_emerging = true
		mob.animated_sprite.play("emerge")
		emerge_timer.start()          # length = same as “emerge” anim
	# While the timer runs we just keep returning from _physics_process

func _on_emerge_timer_timeout() -> void:
	mob.is_emerging = false
	has_emerged     = true
