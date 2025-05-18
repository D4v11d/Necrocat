class_name BossFollow extends Area2D

const FOLLOW_DISTANCE := 40.0

@onready var mob: Boss = $".."
@onready var special_timer = $"../SpecialAttackTimer"
@onready var charge_timer = $"../ChargingTimer"

var current_target: Node2D = null
#var targets_in_chase_area: Array[Node2D] = []

func handle_chasing_target(delta: float) -> void:
	if current_target:
		move_towards_target(current_target, delta)
	else:
		mob.velocity = Vector2.ZERO

	mob.move_and_collide(mob.velocity * delta)

func move_towards_target(target: Node2D, delta: float) -> void:

	if mob.is_knocked_back:
		return
		
	#perform special attack
	if mob.is_specialing:
		if mob.position.distance_to(mob.last_target_position) < 5:
			mob.is_specialing = false
			special_timer.start()
			return
			
		var direction = (mob.last_target_position - mob.position).normalized()
		mob.velocity = (mob.special_speed) * direction
		return

	var direction = (target.position - mob.position).normalized()	
	mob.velocity = mob.speed * direction

	if direction.x > 0:
		mob.animated_sprite.flip_h = false
	elif direction.x < 0:
		mob.animated_sprite.flip_h = true

func _on_body_entered(body: Node2D) -> void:
	if body == self:
		return

	if body is Player:
		current_target = body
		special_timer.start();

func _on_special_attack_timer_timeout() -> void:
	charge_timer.start()
	mob.is_charging = true
	mob.animated_sprite.play("charging")

func _on_charging_timer_timeout() -> void:
	mob.is_charging = false
	mob.is_specialing = true
	mob.last_target_position = current_target.position
	mob.animated_sprite.play("idle")
