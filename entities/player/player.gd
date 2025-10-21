extends Area2D


signal hit


@export var map: TileMapLayer
@export var camera: Camera2D
var clamp_min: Vector2
var clamp_max: Vector2

@export var speed: float = 100.0 # How fast the player will move (pixels/sec).
var velocity: Vector2  # The player's movement vector.


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	# Get map boundary in pixels
	var used_rect_tiles: Rect2i = map.get_used_rect()
	var map_min_pixel: Vector2 = map.map_to_local(used_rect_tiles.position)
	var map_max_pixel: Vector2 = map.map_to_local(used_rect_tiles.end)
	# Set camera limits
	camera.limit_left = int(map_min_pixel.x)
	camera.limit_top = int(map_min_pixel.y)
	camera.limit_right = int(map_max_pixel.x) - 10
	camera.limit_bottom = int(map_max_pixel.y) - 10
	# Calculate player clamping
	var capsule_shape: CapsuleShape2D = $CollisionShape2D.shape
	var half_width: float = capsule_shape.radius
	var half_height: float = (capsule_shape.height / 2.0) + capsule_shape.radius
	# Convert the tile coordinates to pixel coordinates
	clamp_min = map_min_pixel + Vector2(half_width, half_height)
	clamp_max = map_max_pixel - Vector2(half_width, half_height)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_doMovementInput(delta)
	_switchAnimation()


func _doMovementInput(delta: float) -> void:
	velocity = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		velocity.x += 1.0
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1.0
	if Input.is_action_pressed("move_down"):
		velocity.y += 1.0
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1.0

	if velocity.length() > 0.0:
		velocity = velocity.normalized() * speed	
		
	position += velocity * delta
	position = position.clamp(clamp_min, clamp_max)


func _switchAnimation() -> void:
	if velocity.length() == 0.0: # When the player isn't moving
		$AnimatedSprite2D.animation = "idle"
		return
	# Only show walk_down/up if no horizontal movement
	if velocity.y != 0.0 and velocity.x == 0.0:
		$AnimatedSprite2D.animation = "walk_down" if velocity.y > 0.0 else "walk_up"
		return
	$AnimatedSprite2D.animation = "walk_right" if velocity.x > 0.0 else "walk_left"


func _on_body_entered(_body: Node2D) -> void:
	hide() # Player disappears after being hit.
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)


func start(pos: Vector2) -> void:
	position = pos
	show()
	$CollisionShape2D.disabled = false
	$AnimatedSprite2D.play()
