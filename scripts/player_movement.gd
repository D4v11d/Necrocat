class_name Player extends CharacterBody2D

# Set from inspector
@export var slime_summon: PackedScene 

# Components
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var vertical_hitbox: Area2D = $VerticalAttackHitbox
@onready var horizontal_hitbox: Area2D = $HorizontalAttackHitbox
@onready var attack_timer: Timer = $AttackTimer
@onready var damage_numbers_origin := $DamageNumbersOrigin
@onready var e_key_animation: AnimatedSprite2D = $EKeyAnimation

# Funcionality:
@onready var summon_component: Summon = $Summon

# Canvas Layer objects
@onready var slime_summon_sprite: Sprite2D = $"../CanvasLayer/BoxContainer/Q-summon/Slime-blue"
@onready var new_summon_label: Label = $"../CanvasLayer/NewSummonLabel"

const SPEED = 100.0
const ATTACK_POWER = 20.0

var last_direction := Vector2.DOWN
var is_moving := false
var is_attacking := false

var can_arise_mob := false
var Q_summon_enabled := false # should be an array for Q, E and R

func _ready() -> void:
	animated_sprite_2d.play("idle_front")
	vertical_hitbox.set_deferred("monitoring", false)
	horizontal_hitbox.set_deferred("monitoring", false)

func _physics_process(delta: float) -> void:
	if is_attacking:
		return
	
	if can_arise_mob:
		summon_component.handle_arise_mob()

	handle_attack()
	handle_move(delta)

func handle_move(delta: float) -> void:
	var direction := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()

	if direction != Vector2.ZERO:
		velocity = direction * SPEED * delta
		update_move_animation(direction)
		is_moving = true
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
		if is_moving and velocity == Vector2.ZERO:
			play_idle_animation()
			is_moving = false

	move_and_collide(velocity)
	

func handle_attack() -> void:
	if Input.is_action_just_pressed("attack"):
		is_attacking = true

		if last_direction == Vector2.UP:
			animated_sprite_2d.play("attack_back")
			activate_hitbox(vertical_hitbox, Vector2(-2, -15))
		elif last_direction == Vector2.DOWN:
			animated_sprite_2d.play("attack_front")
			activate_hitbox(vertical_hitbox, Vector2(0, 0))
		else:
			animated_sprite_2d.play("attack_side")
			animated_sprite_2d.flip_h = last_direction == Vector2.LEFT
			activate_hitbox(horizontal_hitbox, Vector2(-14 if last_direction == Vector2.LEFT else 0, 0))

		attack_timer.start()

func activate_hitbox(hitbox: Area2D, offset: Vector2) -> void:
	hitbox.global_position = global_position + offset
	hitbox.set_deferred("monitoring", true)

func update_move_animation(direction: Vector2) -> void:
	if not is_attacking:
		if abs(direction.y) > abs(direction.x):
			if direction.y < 0:
				animated_sprite_2d.play("walk_back")
				last_direction = Vector2.UP
			else:
				animated_sprite_2d.play("walk_front")
				last_direction = Vector2.DOWN
		else:
			if direction.x != 0:
				animated_sprite_2d.play("walk_side")
				animated_sprite_2d.flip_h = direction.x < 0
				last_direction = Vector2.RIGHT if direction.x > 0 else Vector2.LEFT

func play_idle_animation() -> void:
	if last_direction == Vector2.UP:
		animated_sprite_2d.play("idle_back")
	elif last_direction == Vector2.DOWN:
		animated_sprite_2d.play("idle_front")
	else:
		animated_sprite_2d.play("idle_side")
		animated_sprite_2d.flip_h = last_direction == Vector2.LEFT

# there's no friendly fire to or from summons
func _on_vertical_attack_hitbox_body_entered(body: Node2D) -> void:
	if body is Mob and not body.is_ally and vertical_hitbox.visible:
		body.attack_received(global_position, ATTACK_POWER)

func _on_horizontal_attack_hitbox_body_entered(body: Node2D) -> void:
	if body is Mob and not body.is_ally and horizontal_hitbox.visible:
		body.attack_received(global_position, ATTACK_POWER)

func _on_attack_timer_timeout() -> void:
	vertical_hitbox.set_deferred("monitoring", false)
	horizontal_hitbox.set_deferred("monitoring", false)
	is_attacking = false
	play_idle_animation()
	
func _on_hurt_box_damage_taken(amount: Variant) -> void:
	DamageNumbers.display_text(str(amount), damage_numbers_origin.global_position, "#F00")
