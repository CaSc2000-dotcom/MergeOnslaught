extends RigidBody2D


# In your mob's script
@export var speed: float = 60.0
var player: Node = null


func _ready() -> void:
	# Find the player node as soon as the mob is ready
	player = get_tree().get_first_node_in_group("player")
	$AnimatedSprite2D.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if player: # Make sure the player exists before trying to move
		# Calculate the direction from the mob to the player
		var direction: Vector2 = (player.global_position - self.global_position).normalized()
		
		# Set the body's linear velocity directly
		linear_velocity = direction * speed
		
		_update_animation()


func _update_animation() -> void:
	if linear_velocity.length() == 0.0: # When the mob isn't moving
		$AnimatedSprite2D.animation = "idle"
		return
	if linear_velocity.x > 0.0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_h = true
