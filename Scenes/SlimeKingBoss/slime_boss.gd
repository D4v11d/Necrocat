class_name Boss extends CharacterBody2D

@export var MAX_HP := 2000
@export var attack_damage := 50
@export var speed := 40
@export var special_dash_speed := 800
@export var knockback := 150.0
@export var mp_hit_gain := 2
@export var mp_death_gain := 50

var hp := MAX_HP

var is_knocked_back := false
var is_dying := false
var is_dead := false
var is_charging := false
var special_attack := "none"
var last_target_position: Vector2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var chase_area: Area2D = $ChaseArea
@onready var attack_area: Area2D = $AttackArea
@onready var knockback_timer: Timer = $KnockbackTimer
@onready var player: Player = $"../../Player"
@onready var hit_flash_anim_player = $HitflashAnimationPlayer
@onready var damage_numbers_origin = $DamageNumbersOrigin
@onready var arise_area: Area2D = $AriseArea
@onready var healthbar: HealthBar = $CanvasLayer/Healthbar
@onready var hit_stream_player: AudioStreamPlayer2D = $SoundEffects/HitStreamPlayer
@onready var audio_stream_player: AudioStreamPlayer2D = $"../../AudioStreamPlayer2D"

@export var is_ally := false
@export var is_recruitable := false

func _ready() -> void:
	set_collision_layer_value(1, true)
	set_collision_layer_value(2, true)
	
	# Connect signals automatically
	knockback_timer.timeout.connect(_on_knockback_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func attack_received(source: Variant, damage: float) -> void:
		
	if hp > 0:
		var knockback_direction = (position - source.position).normalized()
		velocity = knockback_direction * knockback
		is_knocked_back = true
		knockback_timer.start()
		hit_flash_anim_player.play("hit_flash")
	
		hp -= damage
		healthbar._set_health(hp)
		if source is Player:
			hit_stream_player.play()
	
	if hp <= 0:
		handle_death()
		if source is Player:
			source.increase_mp(mp_death_gain)
			
	DamageNumbers.display_text(str(damage), damage_numbers_origin.global_position)
	

func _on_knockback_timer_timeout() -> void:
	is_knocked_back = false
	velocity = Vector2.ZERO


func handle_death() -> void:
	is_dead = true
	animated_sprite.play("death")

func _on_hurtbox_damage_taken(amount: Variant, source: Variant) -> void:
	attack_received(source, amount)

func _on_animation_finished():
	if animated_sprite.animation == "death":
		queue_free()
		if healthbar:
			healthbar.queue_free()
		_fade_out_music()

func _fade_out_music():
	if audio_stream_player:
		var tween = get_tree().create_tween()
		tween.tween_property(audio_stream_player, "volume_db", -80, 2.0) # Baja el volumen a -80 dB en 2 segundos
		tween.tween_callback(Callable(audio_stream_player, "stop"))
