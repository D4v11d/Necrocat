class_name Mob extends CharacterBody2D

const MAX_HP := 100
const FOLLOW_DISTANCE := 40.0

var speed := 40.0
var attack_damage := 20
var hp := MAX_HP

var current_target: Node2D = null
var targets_in_chase_area: Array[Node2D] = []

var is_knocked_back := false
var is_spirit_slime := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var chase_player_area: Area2D = $ChaseArea
@onready var attack_area: Area2D = $AttackArea
@onready var knockback_timer: Timer = $KnockbackTimer
@onready var player: Player = $"../../Player"
@onready var hit_flash_anim_player = $HitflashAnimationPlayer
@onready var damage_numbers_origin = $DamageNumbersOrigin
@onready var arise_area: Area2D = $AriseArea

@export var is_ally := false
@export var mob_type := ""
@export var is_recruitable := false

func _ready() -> void:
	player.connect("delete_mob", Callable(self, "delete_spirit_mob"))

func _physics_process(delta: float) -> void:
	if is_knocked_back:
		move_and_collide(velocity * delta)
		return

	handle_chasing_targets(delta)

func handle_chasing_targets(delta: float) -> void:
	if is_ally:
		if current_target and current_target in targets_in_chase_area:
			move_towards_target(current_target, delta)
		else:
			var enemy = find_enemy_in_area()
			if enemy:
				current_target = enemy
				move_towards_target(current_target, delta)
			else:
				var distance_to_player = position.distance_to(player.position)
				if distance_to_player > FOLLOW_DISTANCE:
					move_towards_target(player, delta)
				else:
					velocity = Vector2.ZERO
	else:
		if current_target and current_target in targets_in_chase_area:
			move_towards_target(current_target, delta)
		else:
			current_target = find_valid_enemy_target()
			if current_target:
				move_towards_target(current_target, delta)
			else:
				velocity = Vector2.ZERO

	move_and_collide(velocity * delta)

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
	if is_spirit_slime:
		return

	if is_knocked_back:
		return

	var direction = (target.position - position).normalized()
	velocity = speed * direction

	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true

func attack_received(from_position: Vector2, damage: float) -> void:
	var knockback_direction = (position - from_position).normalized()
	velocity = knockback_direction * 200.0
	is_knocked_back = true
	knockback_timer.start()
	hp -= damage
	if hp <= 0:
		handle_slime_death()
	DamageNumbers.display_number(damage, damage_numbers_origin.global_position)
	hit_flash_anim_player.play("hit_flash")

func _on_knockback_timer_timeout() -> void:
	is_knocked_back = false
	velocity = Vector2.ZERO

func _on_chase_area_body_entered(body: Node2D) -> void:
	if body == self:
		return

	if body is Player or body is Mob:
		targets_in_chase_area.append(body)
		if is_ally:
			if _is_enemy(body):
				current_target = body
		elif not is_ally:
			if current_target == null and (body is Player or (body is Mob and body.is_ally)):
				current_target = body

func _on_chase_area_body_exited(body: Node2D) -> void:
	targets_in_chase_area.erase(body)

	if body == current_target:
		current_target = null

func _is_enemy(body: Node2D) -> bool:
	return body is Mob and not body.is_ally


func handle_slime_death() -> void:
	if is_recruitable:
		is_spirit_slime = true
		animated_sprite.play("spirit")
	else:
		queue_free()

func _on_arise_area_body_entered(body: Node2D) -> void:
	if body is Player and is_spirit_slime:
		player.can_arise_mob = true

func delete_spirit_mob() -> void:
	if is_spirit_slime:
		queue_free()
