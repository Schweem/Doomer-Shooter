extends AnimatedSprite3D

@export var slide_distance: float = 300.0  # Distance to slide off-screen
@export var slide_duration: float = 0.5  # Duration of the slide animation

var is_visible: bool = true
var initial_position: Vector3

func _ready():
	initial_position = position
	
func _physics_process(delta):
	if Input.is_action_just_pressed("toggleHUD"):
		toggle_hud()

func toggle_hud():
	print("toggle")
	is_visible = !is_visible
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	if is_visible:
		# Slide back to initial position
		tween.tween_property(self, "position", initial_position, slide_duration)
	else:
		# Slide off-screen to the right
		var off_screen_position = initial_position + Vector3(slide_distance, 0, 0)
		tween.tween_property(self, "position", off_screen_position, slide_duration)
