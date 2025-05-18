class_name FireballShooting
extends Node2D

# ── Tunables ───────────────────────────────────────────────
@export var fireball_scene        : PackedScene
@export var shoot_interval        : float   = 1.2   # seconds
@export var fireball_speed        : float   = 220.0 # px/s
@export var fireball_lifetime     : float   = 2.0   # seconds
@export var shoot_range           : float   = 250.0
@onready var fire_spawn: Marker2D = $"../AnimatedSprite2D/Marker2D"

# ───────────────────────────────────────────────────────────

@onready var mob      : Mob     = $".."
@onready var player   : Player  = $"../../../Player"

var shoot_cooldown : float = 0.0
var current_target : Node2D = null

# ───────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if mob.is_dying or mob.is_knocked_back:
		return                                        # don't shoot in these states

	shoot_cooldown -= delta
	if shoot_cooldown > 0.0:
		return

	# Decide whom to shoot at
	if not mob.is_emerging:
		var target: Node2D = _get_enemy_target() if mob.is_ally else player
		if target and _within_range(target):
			_fire_fireball(target)

	shoot_cooldown = shoot_interval

# ───────────────────────────────────────────────────────────
# Ally‑specific helper: pick (or refresh) an enemy target.
func _get_enemy_target() -> Node2D:
	# 1. If we already have a living target, keep it
	if is_instance_valid(current_target):
		return current_target

	# 2. Otherwise search the Enemies container for the first valid hostile
	var enemies_root = $"/root/Main/Enemies"
	for child in enemies_root.get_children():
		if child is Mob and not child.is_ally and not child.is_dying:
			current_target = child
			return current_target

	# 3. No enemies available
	current_target = null
	return null

# ───────────────────────────────────────────────────────────
func _within_range(target: Node2D) -> bool:
	return global_position.distance_to(target.global_position) <= shoot_range

# ───────────────────────────────────────────────────────────
func _fire_fireball(target: Node2D) -> void:
	# Instance & configure
	
	var fireball: Fireball = fireball_scene.instantiate()
	if mob.is_ally:
		fireball.is_ally = true
	fireball.global_position = fire_spawn.global_position          # ← exact pixel
	fireball.velocity       = (target.global_position - fireball.global_position).normalized() * fireball_speed
	get_tree().current_scene.add_child(fireball)               # or other parent


	var dir = (target.global_position - fireball.global_position).normalized()
	fireball.velocity = dir * fireball_speed

	# Add to scene
	get_parent().add_child(fireball)

	# Auto‑delete timer
	var del_timer := Timer.new()
	del_timer.wait_time = fireball_lifetime
	del_timer.one_shot = true
	del_timer.timeout.connect(fireball.queue_free)
	add_child(del_timer)
	del_timer.start()
