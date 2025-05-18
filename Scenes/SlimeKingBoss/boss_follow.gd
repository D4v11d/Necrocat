class_name BossFollow
extends Area2D

const FOLLOW_DISTANCE := 40.0

@onready var mob: Boss = $".."
@onready var special_timer = $"../SpecialAttackTimer"
@onready var charge_timer = $"../ChargingTimer"
@onready var jumping: BossJumping = $"../Jumping"

var current_target: Node2D = null

func _ready():
	randomize();

func handle_chasing_target(delta: float) -> void:
	if current_target:
		move_towards_target(current_target, delta)
	else:
		mob.velocity = Vector2.ZERO
		mob.animated_sprite.play("idle")

	mob.move_and_collide(mob.velocity * delta)

func move_towards_target(target: Node2D, delta: float) -> void:
	if mob.is_knocked_back:
		return

	# ── Special charge handling ──────────────────────────
	if mob.special_attack == "dash":
		if mob.position.distance_to(mob.last_target_position) < 5:
			_end_charge()
			return

		var direction := (mob.last_target_position - mob.position).normalized()
		mob.velocity = direction * mob.special_dash_speed

		var collision := mob.move_and_collide(mob.velocity * delta)
		if collision:
			_end_charge()
		return
	
	if mob.special_attack == "jump":
		return
	# ─────────────────────────────────────────────────────

	# Normal chase
	var direction := (target.position - mob.position).normalized()
	mob.velocity = direction * mob.speed

	if mob.hp > 0:
		if abs(direction.x) > abs(direction.y):
			mob.animated_sprite.play("move_side")
			mob.animated_sprite.flip_h = direction.x < 0
		else:
			if direction.y < 0:
				mob.animated_sprite.play("move_back")
			else:
				mob.animated_sprite.play("move_front")

func _on_body_entered(body: Node2D) -> void:
	if body == self:
		return

	if body is Player:
		current_target = body
		special_timer.start()

func _on_special_attack_timer_timeout() -> void:
	charge_timer.start()
	mob.is_charging = true
	mob.animated_sprite.play("charging")

func _on_charging_timer_timeout() -> void:
	mob.is_charging = false
	var options = ["dash", "jump"]
	mob.special_attack = options[randi() % options.size()]
	mob.last_target_position = current_target.position
	
	if mob.special_attack == "jump":
		jumping.start_jump(current_target.position)
		
	mob.animated_sprite.play("idle")

func _end_charge() -> void:
	mob.velocity = Vector2.ZERO
	mob.special_attack = "none"
	special_timer.start()
	if mob.hp > 0:
		mob.animated_sprite.play("idle")


func _on_special_jump_timer_timeout() -> void:
	jumping.start_jump(current_target.position)
