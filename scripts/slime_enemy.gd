class_name Enemy extends CharacterBody2D

const MAX_HP := 300

var speed := 40.0
var entity_type := "enemy"
var attack_damage := 20
var player_inside_chase_area := false
var is_knocked_back := false
var hp := MAX_HP

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var chase_player_area: Area2D = $ChaseArea
@onready var attack_area: Area2D = $AttackArea
@onready var knockback_timer: Timer = $KnockbackTimer
@onready var player: Player = $"../Player"

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not is_knocked_back and player_inside_chase_area:
		move_towards_player(delta)
	elif not is_knocked_back:
		velocity = Vector2.ZERO

	move_and_slide()

func move_towards_player(delta: float) -> void:
	if is_knocked_back:
		return

	var direction = (player.position - position).normalized()
	velocity = speed * direction

	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true

func attack_received(from_position: Vector2, damage: float) -> void:
	
	var knockback_direction = (position - from_position).normalized()
	velocity = knockback_direction * 200.0
	is_knocked_back = true
	knockback_timer.start()
	hp = hp - damage
	if hp <= 0:
		queue_free()
	print("attack_received, Remaining HP: ", hp, "/", MAX_HP)
	

func _on_knockback_timer_timeout() -> void:
	is_knocked_back = false
	velocity = Vector2.ZERO

func _on_chase_area_body_entered(body: Node2D) -> void:
	if body is Player:
		player_inside_chase_area = true


func _on_chase_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player_inside_chase_area = false
