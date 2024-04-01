extends CharacterBody3D

#mouse navigation variables.
var mouse_sensitivity : float = 0.015

#speed variables.
var current_speed : float 
var walking_speed : float = 4.0
var sprint_speed : float = 8.0
var crouch_speed : float = 2.0

#head position variables for position on the y axis.
var primary_head_pos : float = 1.8
var crouch_head_pos : float = 0.9

#jump and gravity values.
var jump_velocity : float = 5
var gravity : float = 9.8

#bob variables.
var bob_frequency : float = 2.0
var bob_amplitude : float = 0.08
var bob_def : float = 0.0

#fov variables.
var base_fov : float = 75.0
var change_in_fov : float = 1.5
var is_zoomed : bool = false

#player states.
var walking : bool = false
var sprinting : bool = false
var crouching : bool = false
var sliding : bool = false

#extended nodes as variables.
@onready var head : Node3D = $head
@onready var player_camera : Camera3D = $head/player_camera
@onready var standing_collision = $standing_collision
@onready var crouching_collision = $crouching_collision
@onready var raycast_stand_checker = $raycast_stand_checker

func _ready():

	#Mouse captured at the centre of the screen.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	#Player intertial navigation, head movement, looking around.
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		player_camera.rotate_x(-event.relative.y * mouse_sensitivity)
		player_camera.rotation.x = clamp(player_camera.rotation.x, deg_to_rad(-75), deg_to_rad(89))

func _physics_process(delta):

	#state machine as follows.
	#crouching.
	if Input.is_action_pressed("crouch"):
		current_speed = crouch_speed
		head.position.y = lerp(head.position.y, crouch_head_pos, delta * 7.5)
		standing_collision.disabled = true
		crouching_collision.disabled = false

		walking = false
		sprinting = false
		crouching = true

	#standing
	elif !raycast_stand_checker.is_colliding():
		head.position.y = lerp(head.position.y, primary_head_pos, delta * 7.5)
		standing_collision.disabled = false
		crouching_collision.disabled = true

		#sprinting
		if Input.is_action_pressed("sprint"):
			current_speed = sprint_speed

			walking = false
			sprinting = true
			crouching = false

		#walking
		else:
			current_speed = walking_speed

			walking = true
			sprinting = false
			crouching = false

	#debug FPS count to print.
	var fps_counter : float = Engine.get_frames_per_second()
	print(str(fps_counter))

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():	
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = lerp(velocity.x, direction.x, delta * 4.0)
			velocity.z = lerp(velocity.z, direction.z, delta * 4.0)
	else:
		velocity.x = lerp(velocity.x, direction.x, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z, delta * 2.0)

	#player head bob values.
	bob_def += delta * velocity.length() * float(is_on_floor()) 
	player_camera.transform.origin = _player_head_bob(bob_def)

	#sight zoom, controlled.
	var zoomed_fov : float = 100.00
	var zoom_fov_step : float = 50.00
	if Input.is_action_pressed("sight_zoom"):
		zoomed_fov = zoomed_fov - zoom_fov_step
	player_camera.set_fov(lerp(player_camera.fov, zoomed_fov, delta * 8.0))

	#fov change with player motion.
	var velocity_clamped = clamp(velocity.length(), 0.5, 15.0)
	var target_fov = base_fov + change_in_fov * velocity_clamped
	if is_zoomed == false:
		player_camera.fov = lerp(player_camera.fov, target_fov, delta * 5.0)

	move_and_slide()

#head bob implementation.
func _player_head_bob(bob_time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(bob_time * bob_frequency) * bob_amplitude
	pos.x = cos(bob_time * bob_frequency) * bob_amplitude
	return pos