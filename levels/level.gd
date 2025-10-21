# Author: Caleb Schmid
# Name: level.gd
# Handles the main level gameplay takes place on 

extends Node2D


@export var mob_scene: PackedScene
var score: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MenuMusic.play()
	$Player/Camera2D/HUD/Background.show()
	$Player/Camera2D/HUD/Subtitle.show()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Initiates Game Over sequence
func game_over() -> void:
	$ScoreTimer.stop()
	$MobTimer.stop()
	$GameMusic.stop()
	
	$Player/Camera2D/HUD.show_game_over()
	
	await $Player/Camera2D/HUD/MessageTimer.timeout
	$Player/Camera2D/HUD/Background.show()
	$Player/Camera2D/HUD/Subtitle.show()
	$MenuMusic.play()


# Starts a new game
func new_game() -> void:
	score = 0
	$Player/Camera2D/HUD/Background.hide()
	$Player/Camera2D/HUD/Subtitle.hide()
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$MenuMusic.stop()
	$GameMusic.play()
	
	get_tree().call_group("mobs", "queue_free")
	
	$Player/Camera2D/HUD.update_score(score)
	$Player/Camera2D/HUD.show_message("Get Ready")


# Spawns a new Mob every time the MobTimer runs out
func _on_mob_timer_timeout() -> void:
	# Create a mob instance and add it to the scene
	var mob: Node = mob_scene.instantiate()
	# Choose a random location on the path
	var mob_spawn_location: Node = $Player/Camera2D/SpawnPath/SpawnLocation
	mob_spawn_location.progress_ratio = randf() # randf() gives a random float between 0 and 1
	# Set position to the random location
	mob.global_position = mob_spawn_location.global_position
	# Spawn the mob
	add_child(mob)


# Increments the score by 1 every second
func _on_score_timer_timeout() -> void:
	score += 1
	$Player/Camera2D/HUD.update_score(score)


# Starts MobTimer and ScoreTimer when the StartTimer runs out
func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()
