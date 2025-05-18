class_name FireballShooting extends Node2D

@export var fireball_scene: PackedScene
@export var shoot_interval := 1.2  # seconds between shots
@export var fireball_speed := 220.0  # px / s
@export var fireball_lifetime := 2.0  # seconds before auto-delete

@onready var mob: Mob = $".."
@onready var player: Player = $"../../../Player"
var shoot_cooldown := 0.0  # counts down each frame

func _physics_process(delta: float) -> void:
	if mob.is_dying or mob.is_knocked_back:
		return  # Don't shoot during death or knockback
	shoot_cooldown -= delta
	if shoot_cooldown <= 0.0 and is_instance_valid(player):
		_shoot_at_player()
		shoot_cooldown = shoot_interval  # reset

func _shoot_at_player() -> void:
	var fireball := fireball_scene.instantiate()
	# Spawn at FireballShooting's global position (includes offset)
	fireball.global_position = global_position
	# Calculate direction from spawn point to player
	var dir = (player.global_position - fireball.global_position).normalized()
	fireball.velocity = dir * fireball_speed
	# Add to parent (Mob's parent, e.g., world)
	get_parent().add_child(fireball)
	# Set up deletion timer
	var delete_timer := Timer.new()
	delete_timer.wait_time = fireball_lifetime
	delete_timer.one_shot = true
	delete_timer.timeout.connect(fireball.queue_free)
	add_child(delete_timer)
	delete_timer.start()
