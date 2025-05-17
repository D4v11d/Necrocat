class_name SkeletonMovement extends Node2D

@onready var mob: Mob               = $".."
@onready var chase_area: MobFollow  = $"../ChaseArea"
@onready var emerge_timer: Timer    = $"../EmergeTimer"

var last_direction : Vector2 = Vector2.ZERO
var has_emerged := false

func _ready() -> void:
	emerge_timer.timeout.connect(_on_emerge_timer_timeout)

func _physics_process(delta: float) -> void:

	# 1. Knock‑back overrides everything.
	if mob.is_knocked_back:
		mob.move_and_collide(mob.velocity * delta)
		return

	# 2. If we are still in the emerge phase, show animation once and wait.
	if not has_emerged:
		_play_emerge_once()
		return

	# 3. Past this point the mob is alive, free to move & chase.
	if mob.hp > 0:
		chase_area.handle_chasing_targets(delta)

	_handle_walk_or_idle_animation()

func _play_emerge_once() -> void:
	if not mob.is_emerging:
		mob.is_emerging = true
		mob.animated_sprite.play("emerge")
		emerge_timer.start()          # length = same as “emerge” anim
	# While the timer runs we just keep returning from _physics_process

func _on_emerge_timer_timeout() -> void:
	mob.is_emerging = false
	has_emerged     = true

func _handle_walk_or_idle_animation() -> void:
	if mob.hp <= 0 or mob.is_dying:
		return

	var vel := mob.velocity
	if vel.length() > 0:
		var dir := vel.normalized()

		# side vs up/down
		if abs(dir.x) > abs(dir.y):
			last_direction = Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
			mob.animated_sprite.play("walk_side")
			mob.animated_sprite.flip_h = dir.x < 0
		else:
			if dir.y < 0:
				last_direction = Vector2.UP
				mob.animated_sprite.play("walk_back")
			else:
				last_direction = Vector2.DOWN
				mob.animated_sprite.play("walk_front")
	else:
		# idle
		match last_direction:
			Vector2.UP:    mob.animated_sprite.play("idle_back")
			Vector2.DOWN:  mob.animated_sprite.play("idle_front")
			_:             mob.animated_sprite.play("idle_side"); mob.animated_sprite.flip_h = last_direction == Vector2.LEFT
