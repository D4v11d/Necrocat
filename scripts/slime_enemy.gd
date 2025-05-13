class_name Mob extends CharacterBody2D

# Mob stats
const MAX_HP := 300

var speed := 40.0
var attack_damage := 20
var hp := MAX_HP

# Chase & attack data
var current_target: Node2D = null # -> could be Player or Mob
var targets_in_chase_area: Array[Node2D] = []

var is_knocked_back := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var chase_player_area: Area2D = $ChaseArea
@onready var attack_area: Area2D = $AttackArea
@onready var knockback_timer: Timer = $KnockbackTimer
@onready var player: Player = $"../Player"
@onready var check_surroundings_timer: Timer = $CheckSurroundingsTimer
@onready var hit_flash_anim_player = $HitflashAnimationPlayer

@export var is_ally := false
@export var mob_type := "" # Enemy or ally for now

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if is_knocked_back:
		move_and_collide(velocity * delta)
		return

	# If ally and current target is dead or gone, look for next
	if is_ally:
		var valid_target = get_first_valid_enemy_in_area()
		if valid_target:
			current_target = valid_target
		else:
			current_target = player

	if current_target:
		move_towards_target(current_target, delta)
	else:
		velocity = Vector2.ZERO

	move_and_collide(velocity * delta)

func move_towards_target(target: Node2D, delta: float) -> void:
	if is_knocked_back:
		return

	var direction = (target.position - position).normalized()
	velocity = speed * direction

	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true

func get_first_valid_enemy_in_area() -> Node2D:
	for entity in targets_in_chase_area:
		if entity is Mob and not entity.is_ally and is_instance_valid(entity):
			return entity
	return null

func attack_received(from_position: Vector2, damage: float) -> void:
	
	var knockback_direction = (position - from_position).normalized()
	velocity = knockback_direction * 200.0
	is_knocked_back = true
	knockback_timer.start()
	hp = hp - damage
	if hp <= 0:
		queue_free()
	hit_flash_anim_player.play("hit_flash")
	

func _on_knockback_timer_timeout() -> void:
	is_knocked_back = false
	velocity = Vector2.ZERO


# Chase target
func _on_chase_area_body_entered(body: Node2D) -> void:
	if body == self:
		return

	if body is Mob or body is Player:
		targets_in_chase_area.append(body)

		# Avoid ally targeting other allies
		if is_ally and current_target == null and not body.is_ally:
			current_target = body

		# Avoid enemy targeting other enemies
		if not is_ally and current_target == null and body.mob_type != "enemy":
			current_target = body


func _on_chase_area_body_exited(body: Node2D) -> void:
	targets_in_chase_area.erase(body)

	if body == current_target:
		current_target = null
