class_name GameManager
extends Node2D

@export var next_room: String

@onready var move_to_next_room: Area2D   = $"../MoveToNextRoom"
@onready var block:          StaticBody2D = $"../Block"
@onready var enemies:        Node2D       = $"../Enemies"

func _ready() -> void:
	move_to_next_room.body_entered.connect(_on_move_to_next_room_body_entered)

func _physics_process(_delta: float) -> void:
	# If the Enemies node has no children, remove the blocker once
	if enemies.get_child_count() == 0 and is_instance_valid(block):
		block.queue_free()

func _on_move_to_next_room_body_entered(body: Node2D) -> void:
	# Let only the player trigger the transition (optional)
	if not body is Player:
		return

	get_tree().change_scene_to_file(next_room)
