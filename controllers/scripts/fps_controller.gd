extends CharacterBody3D

@export var SPEED : float = 5.0
@onready var MAXSPEED : float = SPEED * 4
@onready var BASESPEED : float = SPEED
@export var SPRINT_SPEED : float = 7.2
@onready var SPEED_LABEL : Label3D = $CameraController/Camera3D/handAnchor/popupHUD/SPEEDLABEL

@export var JUMP_VELOCITY : float = 4.5
@onready var max_jump_velocity : float = JUMP_VELOCITY * 4
@onready var BASE_JUMP_VELOCITY : float = JUMP_VELOCITY
@onready var jump_sound : AudioStreamPlayer = $takeOff

@export var MOUSE_SENSITIVITY : float = 0.5
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var PLAYER_CONTROLLER : CharacterBody3D
@onready var CROSSHAIR : Sprite3D = $CameraController/Camera3D/handAnchor/cursor

@onready var ROCKET_BOOTS : OmniLight3D = $rocketBoots
var _has_boots : bool = true

var _mouse_input : bool = false
var _rotation_input : float
var _tilt_input : float
var _mouse_rotation : Vector3
var _player_rotation : Vector3
var _camera_rotation : Vector3


var _max_jumps : int = 2
@onready var _current_jumps : int = _max_jumps

var _max_coyote_time : float = 0.3
@onready var _coyote_time : float = _max_coyote_time

var _sprint_toggle : bool = false
var _crouch_toggle : bool = false

@onready var _standing_position = CAMERA_CONTROLLER.position.y
@onready var _main_camera = $CameraController/Camera3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _unhandled_input(event: InputEvent) -> void:
	
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY
		
func _input(event):
	
	if event.is_action_pressed("exit"):
		get_tree().quit()
	
	if event.is_action_pressed("sprint"):
		_sprint_toggle = true
	if event.is_action_released("sprint"):
		_sprint_toggle = false
		
	if event.is_action_pressed("crouch"):
		_crouch_toggle = true
	if event.is_action_released("crouch"):
		_crouch_toggle = false
		
	if event.is_action_pressed("aim"):
		_main_camera.fov = 95
	if event.is_action_released("aim"):
		_main_camera.fov = lerpf(_main_camera.fov, _main_camera.fov + 15, 1)
		
func _update_camera(delta):
	
	if _crouch_toggle:
		PLAYER_CONTROLLER.scale.y = 0.6
		CAMERA_CONTROLLER.position.y = _standing_position - 0.6
	if !_crouch_toggle:
		PLAYER_CONTROLLER.scale.y = 1.0
		CAMERA_CONTROLLER.position.y = _standing_position
	
	# Rotates camera using euler rotation
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)

	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	CAMERA_CONTROLLER.rotation.z = 0.0

	_rotation_input = 0.0
	_tilt_input = 0.0
	
func _ready():

	# Get mouse input
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	
	# Update camera movement based on mouse movement
	_update_camera(delta)
	CROSSHAIR.rotate(Vector3(0,0,1), 0.03)
	SPEED_LABEL.text = "SPEED: " + str(round(SPEED))
	
	if _sprint_toggle:
		SPEED = SPRINT_SPEED
	else:
		SPEED = SPEED
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		_coyote_time -= delta
		if _crouch_toggle:
			if direction: 
				while SPEED < MAXSPEED:
					SPEED += 0.2
					break
		else:
			if direction:
				while SPEED < MAXSPEED:
					SPEED += 0.07
					break
					
			if JUMP_VELOCITY == BASE_JUMP_VELOCITY:
				ROCKET_BOOTS.light_energy = 0
			
	else:
		_current_jumps = _max_jumps
		_coyote_time = _max_coyote_time
		while SPEED > BASESPEED:
			SPEED -= 0.1
			break

	while Input.is_action_pressed("jump") and is_on_floor():
		if _has_boots:
			print("BIG STOMP")
			if JUMP_VELOCITY <= max_jump_velocity:
				if JUMP_VELOCITY > BASE_JUMP_VELOCITY * 2.0:
					ROCKET_BOOTS.light_energy += 0.5
					CAMERA_CONTROLLER.add_shake(0.06, 0.2)
				JUMP_VELOCITY += 0.5
			if JUMP_VELOCITY == max_jump_velocity:
				jump()
				CAMERA_CONTROLLER.add_shake(0.5, 0.2)
			break
		else:
			jump()
			
	
	# Handle Jump.
	if Input.is_action_just_released("jump"):
		if _has_boots:
			jump()
		else:
			pass
		
	if direction:
		if !_crouch_toggle:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		if _crouch_toggle:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
func jump():
	if JUMP_VELOCITY > BASE_JUMP_VELOCITY * 2.5:
		jump_sound.play()
	if _current_jumps == _max_jumps:
		if _coyote_time > 0:
			_current_jumps -= 1
			velocity.y = JUMP_VELOCITY
			JUMP_VELOCITY = BASE_JUMP_VELOCITY
	elif _current_jumps < _max_jumps and _current_jumps > 0:
		_current_jumps -= 1
		velocity.y = JUMP_VELOCITY * (SPEED * 0.1)
		JUMP_VELOCITY = BASE_JUMP_VELOCITY
