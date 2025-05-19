class_name BossJumping extends Node2D

const JUMP_COOLDOWN := -1.5
#const JUMP_DISTANCE := 30.0  # Distance to target when jump occurs
const JUMP_HEIGHT := 40.0    # How high the jump goes
const JUMP_DURATION := 0.4    # How long the jump takes (seconds)

var jump_progress := 0.0      # Tracks current jump state
var original_y := 0.0         # Stores starting Y position

var jump_start_position: Vector2
var jump_target_position: Vector2
var jump_direction: Vector2
var jump_distance: float

const SPECIAL_JUMP_MAX := 3
var special_jump_count := SPECIAL_JUMP_MAX

@onready var chase_area: BossFollow = $"../ChaseArea"
@onready var mob: Boss = $".."
@onready var special_attack_timer: Timer = $"../SpecialAttackTimer"
@onready var special_jump_timer: Timer = $"../SpecialJumpTimer"
@onready var drop_stream_player: AudioStreamPlayer2D = $"../SoundEffects/DropStreamPlayer"

func _physics_process(delta: float) -> void:
	if mob.is_charging:
		return
	
	if mob.is_knocked_back:
		mob.move_and_collide(mob.velocity * delta)
		return
		
	if jump_progress < 0:
		jump_progress += delta
		if jump_progress > 0:
			jump_progress = 0

	# Start jump
	if jump_progress == 0:
		original_y = mob.position.y

	# Execute jump logic
	if jump_progress > 0:
		handle_jump(delta)
	else:
		if mob.hp > 0:
			chase_area.handle_chasing_target(delta)

func start_jump(target_position: Vector2) -> void:	
	jump_progress = 0.001  # Start jump
	jump_start_position = mob.position
	jump_target_position = target_position
	jump_direction = (jump_target_position - jump_start_position).normalized()
	jump_distance = jump_start_position.distance_to(jump_target_position)
	original_y = mob.position.y
	mob.set_collision_layer_value(1, false)

func handle_jump(delta: float) -> void:
	print("called handle_jump")
	jump_progress += delta
	var jump_completion = min(jump_progress / JUMP_DURATION, 1.0)

	# Compute movement along direction
	var horizontal_move = jump_direction * jump_distance * jump_completion

	# Vertical offset using jump arc
	var jump_offset = sin(jump_completion * PI) * JUMP_HEIGHT

	# Combine movement and vertical arc
	mob.position = jump_start_position + horizontal_move
	mob.position.y -= jump_offset

	# End jump
	if jump_progress >= JUMP_DURATION:
		drop_stream_player.play()
		jump_progress = JUMP_COOLDOWN
		mob.position.y = jump_target_position.y
		mob.set_collision_layer_value(1, true)
		
		special_jump_count -= 1
		if special_jump_count == 0:
			mob.special_attack = "none"
			special_attack_timer.start()
			special_jump_count = SPECIAL_JUMP_MAX
		else:
			special_jump_timer.start()
		

func _on_attack_area_body_entered(body: Node2D) -> void:
	var target = chase_area.current_target
	if (target and jump_progress == 0 and mob.hp > 0):
		start_jump(target.position)
