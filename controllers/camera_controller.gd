extends Camera3D

var shake_amount = 0.0
var shake_duration = 0.0
var shake_timer = 0.0

func _process(delta):
	if shake_timer > 0:
		shake_timer -= delta
		
		# Generate random offset
		var offset = Vector3(
			randf_range(-1.0, 1.0) * shake_amount,
			randf_range(-1.0, 1.0) * shake_amount,
			0
		)
		
		# Apply offset to camera
		h_offset = offset.x
		v_offset = offset.y
		
		# Reset camera when shake is done
		if shake_timer <= 0:
			h_offset = 0
			v_offset = 0
			shake_amount = 0

func add_shake(amount: float, duration: float):
	shake_amount = amount
	shake_duration = duration
	shake_timer = duration
