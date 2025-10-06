# Author: Caleb Schmid
# Name: mob.gd
# Mob logic and physics

extends RigidBody2D


signal died


@export var speed: float = 60.0
var health: float
var is_dead: bool
var is_hurting: bool
var player: Node = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = 50.0
	# Find the player node as soon as the mob is ready
	player = get_tree().get_first_node_in_group("player")
	$AnimatedSprite2D.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Called once on each physics tick. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if is_dead or is_hurting: # to prevent mobs from accidentally not dying/taking damage
		return
	if player.visible:
		# Calculate the direction from the mob to the player
		var direction: Vector2 = (player.global_position - self.global_position).normalized()
		# Set the body's linear velocity directly
		linear_velocity = direction * speed
		_update_animation()


# Changes the animation based on what direction the mob is going
func _update_animation() -> void:
	if linear_velocity.length() == 0.0: # When the mob isn't moving
		$AnimatedSprite2D.animation = "idle"
		return
	if linear_velocity.x > 0.0: # When moving right
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_h = false
	else: # When moving left
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_h = true
	$AnimatedSprite2D.play() # Plays in case it was paused after take_damage()


# Decrements health by damage and calls die() if health reaches zero
func take_damage(damage: float) -> void:
	if is_dead: # to prevent multiple calls when dying
		return
		
	health -= damage
	if health <= 0.0: # died
		is_dead = true
		die()
	else: # didn't die
		is_hurting = true
		$AnimatedSprite2D.play("hurt")
		await $AnimatedSprite2D.animation_finished
		is_hurting = false


# Mob death sequence
func die() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	linear_velocity = Vector2.ZERO
	emit_signal("died")
	$AnimatedSprite2D.modulate = Color.RED
	$AnimatedSprite2D.play("death")
	await $AnimatedSprite2D.animation_finished
	await get_tree().create_timer(2.0).timeout
	queue_free()
