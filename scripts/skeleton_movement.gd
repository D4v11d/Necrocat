class_name SkeletonMovement extends Node2D

@onready var mob: Mob = $".."
@onready var chase_area: MobFollow = $"../ChaseArea"

func _physics_process(delta: float) -> void:
	if mob.is_knocked_back:
		mob.move_and_collide(mob.velocity * delta)
		return
	
	chase_area.handle_chasing_targets(delta)
