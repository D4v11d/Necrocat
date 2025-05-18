class_name Summon extends Node2D

@onready var summon_cooldown: Timer = $"../Timers/SummonCooldown"
@onready var player: Player = $".."
@onready var casting_timer: Timer = $"../Timers/CastingTimer"

var can_summon := true # reset after cooldown
var summoned_allies_list: Array[Mob] = []

const SUMMONS := {
	"summon_Q": {"enabled_flag": "Q_summon_enabled", "scene": "slime_summon"},
	"summon_R": {"enabled_flag": "R_summon_enabled", "scene": "skeleton_summon"},
	"summon_F": {"enabled_flag": "F_summon_enabled", "scene": "ghost_summon"},
}

signal delete_mob # called after arising

func _physics_process(_delta: float) -> void:
	summon_ally()
	
	clear_all_summons()

func summon_ally() -> void:
	if not can_summon:
		return

	for action in SUMMONS.keys():
		if Input.is_action_just_pressed(action):
			var data = SUMMONS[action]

			# Is that particular summon enabled on the player?
			if not player.get(data.enabled_flag):
				return

			var packed: PackedScene = player.get(data.scene)
			if packed == null:
				return

			var ally: Mob = packed.instantiate()
			_process_new_ally(ally)       # shared follow‑up
			break                         # stop after we handled one tap


const MAX_SUMMONS := 10

func _process_new_ally(ally: Node2D) -> void:
	# ‑‑‑ enforce the limit ‑‑‑
	if summoned_allies_list.size() >= MAX_SUMMONS:
		var summon = summoned_allies_list.pop_front()
		if is_instance_valid(summon):
			summon.is_dying = true
			summon.handle_death()

	# ‑‑‑ normal spawn flow ‑‑‑
	summoned_allies_list.append(ally)
	can_summon = false
	summon_cooldown.start()

	ally.is_ally = true
	ally.position = player.position + calculate_summon_position()

	var summons_node := get_tree().current_scene.get_node("Summons")
	if summons_node:
		summons_node.add_child(ally)
	else:
		push_warning("Summons node not found!")

func calculate_summon_position() -> Vector2:
	var spawn_offset = get_spawn_position_offset()
	for summon in summoned_allies_list:
		if summon.position == player.position + spawn_offset:
			spawn_offset.x += 2
			
	return spawn_offset

func get_spawn_position_offset() -> Vector2:
	
	if player.last_direction == Vector2.UP:
		return Vector2(0, -15)
		
	if player.last_direction == Vector2.DOWN:
		return Vector2(0, 25)
		
	if player.last_direction == Vector2.LEFT:
		return Vector2(-20, 0)
		
	if player.last_direction == Vector2.RIGHT:
		return Vector2(20, 0)
	
	return Vector2(0,0)


func _on_summon_cooldown_timeout() -> void:
	can_summon = true
	
func clear_all_summons() -> void:
	if Input.is_action_pressed("delete_summons"):
		for summon in summoned_allies_list:
			summon.is_dying = true
			summoned_allies_list.erase(summon)
			summon.handle_death()

# Which summon to unlock next, in order
const ARISE_ORDER := [
	{ "flag": "Q_summon_enabled", "sprite": "slime_summon_sprite" },
	{ "flag": "R_summon_enabled", "sprite": "skeleton_summon_sprite" },
	{ "flag": "F_summon_enabled", "sprite": "ghost_summon_sprite" },
]

func handle_arise_mob() -> void:
	if not Input.is_action_just_pressed("arise"):
		return

	_unlock_next_summon()
	_after_arise()  # shared follow‑up


func _unlock_next_summon() -> void:
	for data in ARISE_ORDER:
		if not player.get(data.flag):
			# enable this summon and reveal its sprite
			player.set(data.flag, true)
			player.get(data.sprite).visible = true
			return             # stop after the first disabled one


func _after_arise() -> void:
	play_cast_animation()
	casting_timer.start()
	player.is_casting_spell = true
	emit_signal("delete_mob")
	player.e_key_animation.visible = false

func play_cast_animation() -> void:
	if player.last_direction == Vector2.UP:
		player.animated_sprite_2d.play("cast_back")
	elif player.last_direction == Vector2.DOWN:
		player.animated_sprite_2d.play("cast_front")
	else:
		player.animated_sprite_2d.play("cast_side")
		player.animated_sprite_2d.flip_h = player.last_direction == Vector2.LEFT

func show_arise_message() -> void:
	var label = player.new_summon_label
	DamageNumbers.animate_label(label, "New Summon Arised")

func summon_killed(summon: Mob) -> void:
	summoned_allies_list.erase(summon)


func _on_casting_timer_timeout() -> void:
	player.is_casting_spell = false
	show_arise_message()
	player.play_idle_animation()
