extends KinematicBody

export var player_mass := 0.2

var walk_speed := 7.0
var sprint_speed := 10.0
var crouch_speed := 4.0
export var accelleration_weight := 0.5
export var decelleration_weight := 0.5
export var jump_force := 20
export var gravity: Vector3 = Vector3(0, -9.8, 0) * player_mass

export var mouse_sensitivity := 0.03

var velocity := Vector3.ZERO

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
	_handle_horizontal_movement(delta)
	
	if floor_detector.is_on_floor():
		_handle_jumping()
	
	if not is_on_floor():
		velocity = _apply_gravity(velocity)
	
	var rotated_velocity = velocity.rotated(Vector3.UP, camera.global_rotation.y)
	rotated_velocity = move_and_slide(rotated_velocity, Vector3.UP, true)
	velocity = rotated_velocity.rotated(Vector3.UP, -camera.global_rotation.y)


func _handle_horizontal_movement(delta: float) -> void:
	var desired_direction = _get_horizontal_movement()
	var desired_speed = _get_desired_speed()
	
	if floor_detector.is_on_floor():
		_accellerate(desired_direction, desired_speed, delta)
		_decellerate(desired_direction, desired_speed, delta)


func _accellerate(desired_direction: Vector2, desired_speed: float, delta: float) -> void:
	if desired_direction.x > 0:
		velocity.x = lerp(velocity.x, desired_speed, accelleration_weight)
	elif desired_direction.x < 0:
		velocity.x = lerp(velocity.x, -desired_speed, accelleration_weight)
		
	if desired_direction.y > 0:
		velocity.z = lerp(velocity.z, desired_speed, accelleration_weight)
	elif desired_direction.y < 0:
		velocity.z = lerp(velocity.z, -desired_speed, accelleration_weight)


func _decellerate(desired_direction: Vector2, desired_speed: float, delta: float) -> void:
	if desired_direction.x == 0:
		velocity.x = lerp(velocity.x, 0, decelleration_weight)
	if desired_direction.y == 0:
		velocity.z = lerp(velocity.z, 0, decelleration_weight)
	
	velocity = velocity.limit_length(desired_speed)



func _get_horizontal_movement() -> Vector2:
	var desired_direction := Vector2.ZERO
	
	if Input.is_action_pressed("forward"):
		desired_direction.y += -1
	if Input.is_action_pressed("backward"):
		desired_direction.y += 1
	if Input.is_action_pressed("right"):
		desired_direction.x += 1
	if Input.is_action_pressed("left"):
		desired_direction.x += -1
	
	return desired_direction.normalized()


func _get_desired_speed() -> float:
	if Input.is_action_pressed("crouch"):
		return crouch_speed
	elif Input.is_action_pressed("sprint"):
		return sprint_speed
	else:
		return walk_speed


func _handle_jumping() -> void:
	if Input.is_action_just_pressed("jump"):
		velocity.y += jump_force


func _apply_gravity(vec: Vector3) -> Vector3:
	return vec + gravity
