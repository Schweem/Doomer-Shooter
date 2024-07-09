extends Sprite3D

func _process(delta):
	# Get the main camera
	var camera = get_viewport().get_camera_3d()
	
	# Check if the camera exists
	if camera:
		# Get the direction to the camera
		var dir = camera.global_position - global_position
		
		# Project the direction onto the XZ plane
		dir.y = 0
		
		# If the direction is not zero, look at it
		if dir.length_squared() > 0.001:
			# Make the sprite look at the camera's position on the XZ plane
			look_at(global_position + dir, Vector3.UP)
			
			# Rotate the sprite 180 degrees around its Y-axis
			rotate_object_local(Vector3.UP, PI)
