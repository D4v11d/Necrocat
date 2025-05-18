class_name Fireball extends CharacterBody2D

var attack_damage := 20
var is_ally       := false

func _physics_process(delta: float) -> void:
	# Move straight along the velocity set by the shooter
	if velocity != Vector2.ZERO:
		move_and_collide(velocity * delta)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Player:
		if not is_ally:
			body._on_hurt_box_damage_taken(attack_damage, self)
			queue_free()
