extends CharacterBody3D

#navigation variables
var speed : float = 3.0
var jump_velocity : float = 4.5
var gravity : float = 9.8
var mouse_sensitivity : float = 0.015

#bob variables
var bob_frequency : float = 2.0
var bob_amplitude : float = 0.08
var bob_def : float = 0.0

#fov variables
var base_fov : float = 75.0
var change_in_fov : float = 1.5

#extended nodes as variables
@onready var head : Node3D = $head
@onready var player_camera : Camera3D = $head/player_camera

func _ready():
	#Mouse captured at the centre of the screen.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	#Player intertial navigation, head movement, looking around.
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		player_camera.rotate_x(-event.relative.y * mouse_sensitivity)
		player_camera.rotation.x = clamp(player_camera.rotation.x, deg_to_rad(-45), deg_to_rad(70))

func _physics_process(delta):

	#FPS Counter 
	var fps_counter : float = Engine.get_frames_per_second()
	print(str(fps_counter))

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	#sprint or walk
	if Input.is_action_pressed("sprint"):
		speed = 7.0
	else:
		speed = 3.0

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():	
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x, delta * 4.0)
			velocity.z = lerp(velocity.z, direction.z, delta * 4.0)
	else:
		velocity.x = lerp(velocity.x, direction.x, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z, delta * 2.0)

	#player head bob
	bob_def += delta * velocity.length() * float(is_on_floor())
	player_camera.transform.origin = _player_head_bob(bob_def)

	#fov change with player motion
	var velocity_clamped = clamp(velocity.length(), 0.5, 15.0)
	var target_fov = base_fov + change_in_fov * velocity_clamped
	player_camera.fov = lerp(player_camera.fov, target_fov, delta * 8.0)

	move_and_slide()

func _player_head_bob(bob_time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(bob_time * bob_frequency) * bob_amplitude
	pos.x = cos(bob_time * bob_frequency) * bob_amplitude
	return pos