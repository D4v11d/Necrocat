class_name Mob extends CharacterBody2D

const MAX_HP := 100

var speed := 40.0
var attack_damage := 20
var hp := MAX_HP

var is_knocked_back := false
var is_spirit_slime := false

const JUMP_COOLDOWN := -1.5
#const JUMP_DISTANCE := 30.0  # Distance to target when jump occurs
const JUMP_HEIGHT := 20.0    # How high the jump goes
const JUMP_DURATION := 0.4    # How long the jump takes (seconds)
var jump_progress := 0.0      # Tracks current jump state
var original_y := 0.0         # Stores starting Y position

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var chase_area: Area2D = $ChaseArea
@onready var attack_area: Area2D = $AttackArea
@onready var knockback_timer: Timer = $KnockbackTimer
@onready var player: Player = $"../../Player"
@onready var hit_flash_anim_player = $HitflashAnimationPlayer
@onready var damage_numbers_origin = $DamageNumbersOrigin
@onready var arise_area: Area2D = $AriseArea

@export var is_ally := false
@export var is_recruitable := false

var jump_start_position: Vector2
var jump_target_position: Vector2
var jump_direction: Vector2
var jump_distance: float

func _ready() -> void:
	set_collision_layer_value(1, true)
	set_collision_layer_value(2, true)

func _physics_process(delta: float) -> void:
	if is_knocked_back:
		move_and_collide(velocity * delta)
		return

	if jump_progress < 0:
		jump_progress += delta
		if jump_progress > 0:
			jump_progress = 0

	# Start jump
	if jump_progress == 0:
		original_y = position.y

	# Execute jump logic
	if jump_progress > 0:
		handle_jump(delta)
	else:
		chase_area.handle_chasing_targets(delta)

func start_jump(target_position: Vector2) -> void:	
	jump_progress = 0.001  # Start jump
	jump_start_position = position
	jump_target_position = target_position
	jump_direction = (jump_target_position - jump_start_position).normalized()
	jump_distance = jump_start_position.distance_to(jump_target_position)
	original_y = position.y
	set_collision_layer_value(1, false)

func handle_jump(delta: float) -> void:
	jump_progress += delta
	var jump_completion = min(jump_progress / JUMP_DURATION, 1.0)

	# Compute movement along direction
	var horizontal_move = jump_direction * jump_distance * jump_completion

	# Vertical offset using jump arc
	var jump_offset = sin(jump_completion * PI) * JUMP_HEIGHT

	# Combine movement and vertical arc
	position = jump_start_position + horizontal_move
	position.y -= jump_offset

	# End jump
	if jump_progress >= JUMP_DURATION:
		jump_progress = JUMP_COOLDOWN
		position.y = jump_target_position.y
		set_collision_layer_value(1, true)



func attack_received(from_position: Vector2, damage: float) -> void:
	var knockback_direction = (position - from_position).normalized()
	velocity = knockback_direction * 150.0 # parametrize knockback or change by enemy
	is_knocked_back = true
	knockback_timer.start()
	hit_flash_anim_player.play("hit_flash")
	
	if not is_spirit_slime:
		hp -= damage
		if hp <= 0:
			handle_slime_death()
		DamageNumbers.display_text(str(damage), damage_numbers_origin.global_position)
	

func _on_knockback_timer_timeout() -> void:
	is_knocked_back = false
	velocity = Vector2.ZERO


func _on_attack_area_body_entered(body: Node2D) -> void:
	var target = chase_area.current_target
	if (target and jump_progress == 0 and not is_spirit_slime):
		start_jump(target.position)
		
func handle_slime_death() -> void:
	if is_recruitable:
		is_spirit_slime = true
		player.summon_component.connect("delete_mob", Callable(self, "delete_spirit_mob"))
		animated_sprite.play("spirit")
	else:
		queue_free()

func _on_arise_area_body_entered(body: Node2D) -> void:
	if body is Player and is_spirit_slime:
		player.can_arise_mob = true
		player.e_key_animation.visible = true

func _on_arise_area_body_exited(body: Node2D) -> void:
	if body is Player and is_spirit_slime:
		player.can_arise_mob = false
		player.e_key_animation.visible = false

func delete_spirit_mob() -> void:
	if is_spirit_slime:
		queue_free()

# Fix crashing repeatedly
func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body is Mob:
		if body.is_ally and not is_ally:
			attack_received(body.position, body.attack_damage)
			return
		if not body.is_ally and is_ally:
			attack_received(body.position, body.attack_damage)
			return
