extends AnimatedSprite2D

@onready var mob: Mob = $".."

var last_direction = Vector2()

func _physics_process(delta: float) -> void:
	if mob.hp <= 0 or mob.is_emerging or mob.is_dying:
		return
		
	if mob.velocity.length() > 0:
		var direction = mob.velocity.normalized()
		# Update last_direction
		if abs(direction.x) > abs(direction.y):
			last_direction = Vector2.RIGHT if direction.x > 0 else Vector2.LEFT
			play("walk_side")
			flip_h = direction.x < 0
		else:
			if direction.y < 0:
				last_direction = Vector2.UP
				play("walk_back")
			else:
				last_direction = Vector2.DOWN
				play("walk_front")
	else:
		if last_direction == Vector2.UP:
			play("idle_back")
		elif last_direction == Vector2.DOWN:
			play("idle_front")
		else:
			play("idle_side")
			flip_h = last_direction == Vector2.LEFT
