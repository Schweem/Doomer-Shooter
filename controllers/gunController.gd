extends MeshInstance3D

@export var CAMERA_CONTROLLER : CharacterBody3D

var _start_position : Vector3
var _aiming : bool = false
@onready var _sights : Sprite3D = $SIGHTS
@onready var _sight_color = _sights.modulate

var _can_shoot : bool = true 

var _base_fire_rate : float
var _fire_rate : float = 5.0
var _fire_mode : int = 0

@export var _muzzle_flash : Sprite3D
@export var _muzzle_light : OmniLight3D
@export var _gun_sound : AudioStreamPlayer
@export var _reload_sound : AudioStreamPlayer
var _reloading : bool = false
@onready var _rounds : GPUParticles3D = $ROUNDS


@export var camera : Camera3D 
@onready var _hit_scan : RayCast3D = $RayCast3D
@onready var _hit_mark_scene : PackedScene = preload("res://scenes/hit_mark.tscn")
@onready var _shot_mark_scene : PackedScene = preload("res://scenes/shot_mark.tscn")

@export var _ammo_counter : Label3D
var _ammo_count : int = 10
var _base_ammo : int 

# Target position and rotation values for ads()
var target_position = Vector3(0, -0.2, -0.4)
var target_rotation = Vector3(0, 90, 0)
var _start_rotation : Vector3
var shot_angle = Vector3(0, 90, 12)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get mouse input
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_start_position = position
	_start_rotation = rotation
	_base_fire_rate = _fire_rate
	_muzzle_flash.visible = false
	_muzzle_light.visible = false
	_base_ammo = _ammo_count
	update_ammo_count()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_raycast()
	
	if Input.is_action_just_pressed("reload"):
		if _ammo_count < _base_ammo:
			reload()
	
	if Input.is_action_pressed("aim"):
		ads()
		_sights.modulate.a = lerpf(0, 220.0 / 255.0, 0.5)
		_ammo_counter.modulate.a = lerpf(0, 220.0 / 255.0, 0.5)
		_ammo_counter.outline_modulate.a = lerpf(0, 220.0 / 255.0, 0.5)
	else:
		_sights.modulate.a = lerpf(_sights.modulate.a / 255.0, 0, 0.3)
		_ammo_counter.modulate.a = lerpf(_ammo_counter.modulate.a / 255.0, 0, 0.3)
		_ammo_counter.outline_modulate.a = lerpf(_ammo_counter.outline_modulate.a / 255.0, 0, 0.3)
		
		
	if Input.is_action_just_pressed("toggle"):
		#if _fire_mode == 1:
		#	_fire_mode = 0
		#	update_sights()
		#else:
		#	_fire_mode = 1
		#	update_sights()
			
		if _fire_mode < 2:
			_fire_mode += 1
			update_sights()
		else:
			_fire_mode = 0
			update_sights()
			
	if Input.is_action_just_pressed("fire"):
		if _can_shoot and !_reloading:
			if _fire_mode == 0:
				shoot(delta)
				_can_shoot = false
				await get_tree().create_timer(0.3).timeout
				if _ammo_count > 0:
					_can_shoot = true
				else:
					reload()
			elif _fire_mode == 1:
				shoot(delta)
				await get_tree().create_timer(0.2).timeout
				shoot(delta)
				_can_shoot = false
				await get_tree().create_timer(0.3).timeout
				if _ammo_count > 0:
					_can_shoot = true
				else:
					reload()
			elif _fire_mode == 2:
				for round in _ammo_count:
					shoot(delta)
					await get_tree().create_timer(0.07).timeout
		
		
	handle_crouch()

func update_raycast():
	if camera:
		# Get the global transform of the camera
		var camera_transform = camera.global_transform
		
		# Set the raycast's global transform to match the camera
		_hit_scan.global_transform = camera_transform
		
		# The raycast should point forward from the camera
		_hit_scan.target_position = Vector3(0, 0, -100)  # 100 units forward

# Function to rotate the object 360 degrees and return to the original rotation
func reload():
	_reloading = true
	print(_reloading)
	var original_rotation = rotation
	var tween = create_tween()
	_can_shoot = false
	_reload_sound.playing = true
	
	tween.tween_property(self, "rotation_degrees", rotation_degrees + Vector3(0, 0, -360), 0.3)
	tween.tween_property(self, "rotation", _start_rotation, 0.2)
	tween.tween_property(self, "position", _start_position, 0.2)
	
	_ammo_count = _base_ammo
	update_sights()
	_sights.modulate = _sight_color
	_can_shoot = true
	await tween.finished
	_reloading = false
	print(_reloading)
	
	
# Helper function to set the rotation back to the original
func _reset_rotation(original_rotation):
	rotation = original_rotation
	
func _reset_position(original_position):
	position = _start_position
	
func handle_crouch():
	if CAMERA_CONTROLLER._crouch_toggle == true:
		position.y = _start_position.y - 0.2
	if CAMERA_CONTROLLER._crouch_toggle == false:
		position.y = _start_position.y
		
func ads():
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, 0.2)
	tween.tween_property(self, "rotation_degrees", target_rotation, 0.2)
	tween.tween_property(self, "rotation", _start_rotation, 0.2)
	tween.tween_property(self, "position", _start_position, 0.2)
	
func shoot(delta):
	if _ammo_count > 0:
		_muzzle_light.visible = true
		_muzzle_flash.rotation.z = randi_range(-360, 360)
		_muzzle_flash.visible = true
		_gun_sound.playing = true
		camera.add_shake(0.08, 0.2)
		_rounds.emitting = true
		var target_rotation = rotation
		if target_rotation.z < 11:
			target_rotation.z += deg_to_rad(12)
		
		var tween = create_tween()
		tween.tween_property(self, "rotation", target_rotation, 0.2)
		
		update_ammo_count()
		_hit_scan.force_raycast_update()
		
		if _hit_scan.is_colliding():
			var collision_point = _hit_scan.get_collision_point()
			var collision_normal = _hit_scan.get_collision_normal()
			spawn_hit_mark(collision_point, collision_normal)
			
		target_rotation.z -= rotation.z + target_rotation.z
		
		if target_rotation.z < 0 or target_rotation.z > 0:
			target_rotation.z = 0
		
		tween.tween_property(self, "rotation", target_rotation, 0.2)
		await get_tree().create_timer(0.3).timeout
		_muzzle_light.visible = false
		_muzzle_flash.visible = false
	else:
		reload()
	
func update_ammo_count():
	if _ammo_counter:
		var alpha_value = 100.0 / 255.0
		
		if _ammo_count <= 6: #green almost full 
			_sights.modulate = Color(1, 1, 0, alpha_value)
		if _ammo_count <= 4: #yellow we cutting it close
			_sights.modulate = Color(1, 0, 0, alpha_value)
		if _ammo_count >= 0: #reload or it'll do it for you (red)
			_ammo_count -= 1
			update_sights()
	else:
		print("fuck") #we have no ammo counter 

func spawn_hit_mark(position: Vector3, normal: Vector3):
	if _hit_mark_scene:
		print(_hit_scan.get_collider())
		if _hit_scan.get_collider().is_in_group("body"):
			var enemy = _hit_scan.get_collider()
			var bodyPart = _hit_scan.get_collider_shape()
			
			var shot_mark_instance = _shot_mark_scene.instantiate()
			get_tree().root.add_child(shot_mark_instance)
			shot_mark_instance.global_position = position
			shot_mark_instance.emitting = true
			
			if bodyPart == 0:
				enemy.headShot()
			if bodyPart == 1:
				enemy.bodyShot()
		
		var hit_mark_instance = _hit_mark_scene.instantiate()
		get_tree().root.add_child(hit_mark_instance)
		hit_mark_instance.global_position = position
		
		# Orient the hit mark to face outward from the surface
		if normal != Vector3.ZERO:
			hit_mark_instance.look_at(position + normal, Vector3.UP)
		
		var timer = Timer.new()
		hit_mark_instance.add_child(timer)
		timer.connect("timeout", Callable(hit_mark_instance, "queue_free"))
		timer.set_wait_time(5.0)  # 5 seconds
		timer.set_one_shot(true)
		timer.start()
	else:
		print("Error: hit_mark_scene not loaded correctly.")
		
func update_sights():
	var toggle : String
	if _fire_mode == 0:
		toggle = "-"
	if _fire_mode == 1:
		toggle = "--"
	if _fire_mode == 2:
		toggle = "^_^"
	_ammo_counter.text = str(_ammo_count) + " | " + toggle # for JIMIN
