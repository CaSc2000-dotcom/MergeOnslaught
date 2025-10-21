extends Area2D


signal hit

# POSITION AND CAMERA CLAMPING VARIABLES
@export var map: TileMapLayer
@export var camera: Camera2D
var clamp_min: Vector2
var clamp_max: Vector2

# MOVEMENT VARIABLES
@export var speed: float = 100.0 # How fast the player will move (pixels/sec).
var velocity: Vector2  # The player's movement vector.
var can_move: bool = false

# DAMAGE VARIABLES
var hit_list: Array[Node2D] = [] # Stores all mobs hit during a single swing
@onready var attack_timer: Node = $AttackTimer
@onready var hitbox_shape: Node = $WeaponHitbox/CollisionShape2D
var facing_right: bool


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	$WeaponHitbox.hide()
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
	if can_move:
		_doMovementInput(delta)
	_switchAnimation()


# Controls player movement
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
	position = position.clamp(clamp_min, clamp_max) # clamped to TileMapLayer Rect2D


# Swtiches animations based on what direction the player is moving
# Left/Right animation prioritized over Up/Down
func _switchAnimation() -> void:
	if velocity.length() == 0.0: # When the player isn't moving
		$AnimatedSprite2D.animation = "idle"
		return
	# Only show walk_down/up if no horizontal movement
	if velocity.y != 0.0 and velocity.x == 0.0:
		$AnimatedSprite2D.animation = "walk_down" if velocity.y > 0.0 else "walk_up"
		return
	if velocity.x > 0.0:
		facing_right = true
		$AnimatedSprite2D.animation = "walk_right" 
	else:
		facing_right = false
		$AnimatedSprite2D.animation = "walk_left" 


# Dies when mob enters body
func _on_body_entered(_body: Node2D) -> void:
	can_move = false
	hide() # Player disappears after being hit.
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)


# Starting sequence
func start(pos: Vector2) -> void:
	position = pos
	can_move = true
	show()
	$CollisionShape2D.disabled = false
	$AnimatedSprite2D.play()


# Handles non-movement input (attacking)
func _unhandled_input(event: InputEvent) -> void:
	if not can_move:
		return
	# Start attack
	if event.is_action_pressed("attack"):
		# Check if the attack is already in progress
		if attack_timer.is_stopped():
			hit_list.clear() # Clear the list for a new swing
			hitbox_shape.disabled = false # Enable the hitbox
			attack_timer.start() # Start the swing duration
			
			# Flip x position of WeaponHitbox if not oriented correctly
			var weapon_pos: Vector2 = $WeaponHitbox.position
			if (not facing_right and weapon_pos.x > 0.0) or (facing_right and weapon_pos.x < 0.0):
				weapon_pos.x *= -1
				$WeaponHitbox.position = weapon_pos
			$WeaponHitbox/CollisionShape2D/AnimatedSprite2D.flip_h = false if facing_right else true
			
			# Play attack animation
			$WeaponHitbox.show()
			$WeaponHitbox/CollisionShape2D/AnimatedSprite2D.play("attack")
			await get_tree().create_timer(0.2).timeout
			$WeaponHitbox.hide()


# Called once on each physics tick.
func _physics_process(_delta: float) -> void:
	# Check for hits while the attack is active
	if not hitbox_shape.disabled:
		# Get a list of all bodies currently inside the hitbox
		var bodies: Array = $WeaponHitbox.get_overlapping_bodies()
		
		for body: Node2D in bodies:
			# Check if it's a mob AND we haven't hit it yet
			if body.is_in_group("mobs") and not body in hit_list:
				# Add it to the list so we don't hit it again
				hit_list.append(body)

				body.take_damage(10)


# Hitbox disabled when on cooldown
func _on_attack_timer_timeout() -> void:
	hitbox_shape.disabled = true # Disable the hitbox
