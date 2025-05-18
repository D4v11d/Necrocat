class_name MobFollow extends Area2D

const FOLLOW_DISTANCE := 40.0

@onready var mob: Mob = $".."

var current_target: Node2D = null
var targets_in_chase_area: Array[Node2D] = []

func handle_chasing_targets(delta: float) -> void:
	if mob.is_ally:
		if current_target and current_target in targets_in_chase_area:
			move_towards_target(current_target, delta)
		else:
			var enemy = find_enemy_in_area()
			if enemy:
				current_target = enemy
				move_towards_target(current_target, delta)
			else:
				var distance_to_player = mob.position.distance_to(mob.player.position)
				if distance_to_player > FOLLOW_DISTANCE:
					move_towards_target(mob.player, delta)
				else:
					mob.animated_sprite.play("idle")
					mob.velocity = Vector2.ZERO
	else:
		if current_target and current_target in targets_in_chase_area:
			move_towards_target(current_target, delta)
		else:
			current_target = find_valid_enemy_target()
			if current_target:
				move_towards_target(current_target, delta)
			else:
				mob.velocity = Vector2.ZERO

	mob.move_and_collide(mob.velocity * delta)

func find_enemy_in_area() -> Node2D:
			
	for target in targets_in_chase_area:
		if _is_enemy(target):
			return target
	return null

func find_valid_enemy_target() -> Node2D:
	for target in targets_in_chase_area:
		if target is Player or (target is Mob and target.is_ally):
			return target
	return null

func move_towards_target(target: Node2D, delta: float) -> void:
	# ── 1. Early‑out cases ─────────────────────────────────────────
	if mob.is_spirit_slime or mob.is_knocked_back:
		return

	# ── 2. Compute velocity ───────────────────────────────────────
	var direction: Vector2 = (target.position - mob.position).normalized()
	mob.velocity = direction * mob.speed

	# ── 3. Pick the animation & handle sprite flipping ────────────
	if abs(direction.x) > abs(direction.y):
		# Horizontal movement
		mob.animated_sprite.play("move_side")
		mob.animated_sprite.flip_h = direction.x < 0
	else:
		# Vertical movement
		if direction.y < 0:
			mob.animated_sprite.play("move_back")   # moving up
		else:
			mob.animated_sprite.play("move_front")  # moving down

func _on_body_entered(body: Node2D) -> void:
	if body == self:
		return

	if body is Player or body is Mob:
		targets_in_chase_area.append(body)
		if mob.is_ally:
			if _is_enemy(body):
				current_target = body
		elif not mob.is_ally:
			if current_target == null and (body is Player or (body is Mob and body.is_ally)):
				current_target = body

func _on_body_exited(body: Node2D) -> void:
	targets_in_chase_area.erase(body)

	if body == current_target:
		current_target = null


func _is_enemy(body: Node2D) -> bool:
	return body is Mob and not body.is_ally
