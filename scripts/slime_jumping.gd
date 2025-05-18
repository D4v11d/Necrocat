class_name SlimeJumping extends Node2D

const JUMP_COOLDOWN := -1.5
#const JUMP_DISTANCE := 30.0  # Distance to target when jump occurs
const JUMP_HEIGHT := 20.0    # How high the jump goes
const JUMP_DURATION := 0.4    # How long the jump takes (seconds)

var jump_progress := 0.0      # Tracks current jump state
var original_y := 0.0         # Stores starting Y position

var jump_start_position: Vector2
var jump_target_position: Vector2
var jump_direction: Vector2
var jump_distance: float

@onready var chase_area: MobFollow = $"../ChaseArea"
@onready var mob: Mob = $".."

func _physics_process(delta: float) -> void:
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
			chase_area.handle_chasing_targets(delta)

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
	end_jump()

func end_jump():
	if jump_progress >= JUMP_DURATION:
		jump_progress = JUMP_COOLDOWN
		mob.position.y = jump_target_position.y

		# Avoids getting stuck in collision after jumping
		var params := PhysicsPointQueryParameters2D.new()
		params.position        = mob.position
		params.collision_mask  = mob.collision_mask
		params.exclude         = [mob]

		var space_state := get_world_2d().direct_space_state
		var collisions  := space_state.intersect_point(params, 4)   # up to 4 hits

		for hit in collisions:
			if hit.collider is Mob and hit.collider != mob:
				mob.position += Vector2(4, 0)   # shift 4 px on X
				break
				
		mob.set_collision_layer_value(1, true)

func _on_attack_area_body_entered(body: Node2D) -> void:
	var target = chase_area.current_target
	if (target and jump_progress == 0 and mob.hp > 0):
		start_jump(target.position)
