extends KinematicBody

export var player_mass := 0.1

var walk_speed := 7.0
var sprint_speed := 10.0
var crouch_speed := 4.0
export var accelleration_weight := 0.5
export var decelleration_weight := 0.5
export var jump_force := 10
export var gravity: Vector3 = Vector3(0, -9.8, 0) * player_mass

export var mouse_sensitivity := 0.03

var velocity := Vector3.ZERO
var external_force := Vector3.ZERO

onready var camera = $Camera
onready var floor_detector: OnFloorDetector = $OnFloorDetector


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(_delta):
	_handle_input()
	DebugDraw.set_text("Velocity", velocity)


func _physics_process(delta):
	_handle_movement(delta)


func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_object_local(Vector3.UP, -(mouse_sensitivity * event.relative.x/10))
		camera.rotate(Vector3.RIGHT, -(mouse_sensitivity * event.relative.y/10))
		camera.rotation.x = clamp(camera.rotation.x, deg2rad(-90), deg2rad(90))


func _handle_input() -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _handle_movement(delta: float) -> void:
	var desired_velocity := velocity.rotated(Vector3.UP, -camera.global_rotation.y)
	desired_velocity = _handle_horizontal_movement(desired_velocity, delta)
	
	if not is_on_floor():
		desired_velocity = _apply_gravity(desired_velocity)
	
	if floor_detector.is_on_floor():
		desired_velocity = _handle_jumping(desired_velocity)
	
	velocity = desired_velocity.rotated(Vector3.UP, camera.global_rotation.y)
	velocity += external_force
	var external_force_applied := external_force.length_squared() > 0
	velocity = move_and_slide(velocity, Vector3.UP, true)
	
	if external_force_applied:
		external_force = Vector3.ZERO


func _handle_horizontal_movement(desired_velocity: Vector3, delta: float) -> Vector3:
	var desired_direction := _get_horizontal_movement()
	var desired_speed = _get_desired_speed()
	
	if floor_detector.is_on_floor():
		desired_velocity = _accellerate(desired_velocity, desired_direction, desired_speed, delta)
		desired_velocity = _decellerate(desired_velocity, desired_direction, desired_speed, delta)
	
	return desired_velocity


func _accellerate(
	desired_velocity: Vector3,
	desired_direction: Vector3, 
	desired_speed: float,
	delta: float
) -> Vector3:
	if desired_direction.x > 0:
		desired_velocity.x = lerp(desired_velocity.x, desired_speed, accelleration_weight)
	elif desired_direction.x < 0:
		desired_velocity.x = lerp(desired_velocity.x, -desired_speed, accelleration_weight)
		
	if desired_direction.z > 0:
		desired_velocity.z = lerp(desired_velocity.z, desired_speed, accelleration_weight)
	elif desired_direction.z < 0:
		desired_velocity.z = lerp(desired_velocity.z, -desired_speed, accelleration_weight)
	
	return desired_velocity


func _decellerate(
	desired_velocity: Vector3,
	desired_direction: Vector3,
	desired_speed: float,
	delta: float
) -> Vector3:
	if desired_direction.x == 0:
		desired_velocity.x = lerp(desired_velocity.x, 0, decelleration_weight)
	if desired_direction.z == 0:
		desired_velocity.z = lerp(desired_velocity.z, 0, decelleration_weight)
	
	return desired_velocity.limit_length(desired_speed)



func _get_horizontal_movement() -> Vector3:
	var desired_direction := Vector3.ZERO
	
	if Input.is_action_pressed("forward"):
		desired_direction.z += -1
	if Input.is_action_pressed("backward"):
		desired_direction.z += 1
	if Input.is_action_pressed("right"):
		desired_direction.x += 1
	if Input.is_action_pressed("left"):
		desired_direction.x += -1
	
	return desired_direction


func _get_desired_speed() -> float:
	if Input.is_action_pressed("crouch"):
		return crouch_speed
	elif Input.is_action_pressed("sprint"):
		return sprint_speed
	else:
		return walk_speed


func _handle_jumping(desired_velocity: Vector3) -> Vector3:
	if Input.is_action_just_pressed("jump"):
		desired_velocity.y += jump_force
	
	return desired_velocity


func _apply_gravity(vec: Vector3) -> Vector3:
	return vec + gravity
