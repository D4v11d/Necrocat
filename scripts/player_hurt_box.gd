class_name PlayerHurtbox extends Area2D

signal damage_taken(amount, source)  # Define your custom signal

const MAX_HP:= 350
const DAMAGE_COOLDOWN:= 0.5
var hp:= MAX_HP

var damage_cooldown := DAMAGE_COOLDOWN  # seconds between damage ticks
var enemies_in_hurtbox := []
var can_take_damage := true

@onready var healthbar: HealthBar = $"../CanvasLayer/Healthbar"
@onready var cat_hurt_stream_player_1: AudioStreamPlayer2D = $"../SoundEffects/CatHurtStreamPlayer1"
@onready var cat_hurt_stream_player_2: AudioStreamPlayer2D = $"../SoundEffects/CatHurtStreamPlayer2"
@onready var cat_hurt_stream_player_3: AudioStreamPlayer2D = $"../SoundEffects/CatHurtStreamPlayer3"
@onready var boring_hurt_stream_player: AudioStreamPlayer2D = $"../SoundEffects/BoringHurtStreamPlayer"

func _ready() -> void:
	set_collision_mask_value(2, false)
	healthbar.max_value = MAX_HP
	healthbar.call_deferred("init_health", hp)
	randomize()

func add_attacker(body: Node2D):
	if can_take_damage:
		take_damage(body)
		can_take_damage = false
	enemies_in_hurtbox.append(body)
	if enemies_in_hurtbox.size() == 1:
		$DamageCooldown.start(damage_cooldown)

func remove_attacker(body: Node2D):
	enemies_in_hurtbox.erase(body)

func _on_DamageCooldown_timeout():
	can_take_damage = true
	
	if enemies_in_hurtbox.is_empty():
		return
	
	for enemy in enemies_in_hurtbox:
		take_damage(enemy)
	
	can_take_damage = false
	# Restart timer
	$DamageCooldown.start(damage_cooldown)
	
func play_hurt_sound():
	var options = [
		cat_hurt_stream_player_1, 
		cat_hurt_stream_player_2,
		cat_hurt_stream_player_3
	]
	var stream_player = options[randi() % options.size()]
	stream_player.play()
	#if not boring_hurt_stream_player.playing:
		#boring_hurt_stream_player.play()
	
func take_damage(enemy):
	emit_signal("damage_taken", enemy.attack_damage, enemy)

func _on_body_entered(body: Node2D) -> void:
	if body is Mob:
		if not body.is_ally and body.hp > 0:
			add_attacker(body)
	
	if body is Boss:
		add_attacker(body)

func _on_body_exited(body: Node2D) -> void:
	if body in enemies_in_hurtbox:
		remove_attacker(body)
