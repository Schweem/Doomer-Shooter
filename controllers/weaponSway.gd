extends Node3D

var mouse_movement 
var sway_max = 5
var sway_lerp = 5

@export var sway_left : Vector3
@export var sway_right : Vector3
@export var sway_normal : Vector3


var rotate_max = 4
var rotate_lerp = 4
@export var rotate_left : Vector3
@export var rotate_right : Vector3
@export var rotate_normal : Vector3


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if mouse_movement != null:
		if mouse_movement > sway_max:
			rotation = rotation.lerp(sway_left, sway_lerp * delta)
		elif mouse_movement < -sway_max:
			rotation = rotation.lerp(sway_right, sway_lerp * delta)
		else:
			rotation = rotation.lerp(sway_normal, sway_lerp * delta)
	
	if Input.is_action_pressed("move_left"):
		if rotation.z < rotate_max:
			rotation = rotation.lerp(rotate_left, rotate_lerp * delta)
	elif Input.is_action_pressed("move_right"):
		if rotation.z > -rotate_max:
			rotation = rotation.lerp(rotate_right, rotate_lerp * delta)
	else:
		rotation = rotation.lerp(rotate_normal, rotate_lerp * delta)
	
func _input(event):
	if event is InputEventMouseMotion:
		mouse_movement = -event.relative.x
