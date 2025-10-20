extends Area2D

signal hit

@export var speed: float = 100.0 # How fast the player will move (pixels/sec).
var velocity: Vector2  # The player's movement vector.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()

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

func _switchAnimation() -> void:
	if velocity.length() == 0.0: # When the player isn't moving
		$AnimatedSprite2D.animation = "idle"
		return
	# Only show walk_down/up if no horizontal movement
	if velocity.y != 0.0 and velocity.x == 0.0:
		$AnimatedSprite2D.animation = "walk_down" if velocity.y > 0.0 else "walk_up"
		return
	$AnimatedSprite2D.animation = "walk_right" if velocity.x > 0.0 else "walk_left"
	
func _on_body_entered(body: Node2D) -> void:
	hide() # Player disappears after being hit.
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)

func start(pos: Vector2) -> void:
	position = pos
	show()
	$CollisionShape2D.disabled = false
	$AnimatedSprite2D.play()
