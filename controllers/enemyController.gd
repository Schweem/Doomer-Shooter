extends CharacterBody3D

const SPEED = 0.03
const JUMP_VELOCITY = 4.5
const MIN_FOLLOW_DISTANCE = 12.0
const FIRE_RANGE = 25

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var _health : int = 5
var player : CharacterBody3D = null

var _can_shoot : bool = true 

@export var head : CollisionShape3D
@export var body : CollisionShape3D
@onready var detectionRad : Area3D = $detectionRadius
@onready var sprite : Sprite3D = get_parent()

func _ready():
	# Ensure the detectionRadius is an Area3D node
	if not detectionRad is Area3D:
		push_error("detectionRadius must be an Area3D node")
	else:
		# Connect the body entered and exited signals
		detectionRad.body_entered.connect(_on_detection_body_entered)
		detectionRad.body_exited.connect(_on_detection_body_exited)

func _physics_process(delta):
	if _health <= 0:
		get_parent().queue_free()
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	patrol()
	
	move_and_slide()
	
	sprite.global_position = global_position

func bodyShot():
	_health -= 1
	print(_health)

func headShot():
	_health -= 3
	print(_health)

func patrol():
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		var direction = (player.global_position - global_position).normalized()
		
		if distance_to_player > MIN_FOLLOW_DISTANCE:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = 0
			velocity.z = 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func _on_detection_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_body_exited(body):
	if body == player:
		player = null
