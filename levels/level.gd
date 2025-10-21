extends Node2D


@export var mob_scene: PackedScene # Drag your mob scene here in the Inspector
var score: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func game_over() -> void:
	$ScoreTimer.stop()
	$MobTimer.stop()
	
	$Player/Camera2D/HUD.show_game_over()


func new_game() -> void:
	score = 0
	$Player.start($StartPosition.position)
	$StartTimer.start()
	
	get_tree().call_group("mobs", "queue_free")
	
	$Player/Camera2D/HUD.update_score(score)
	$Player/Camera2D/HUD.show_message("Get Ready")


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


func _on_score_timer_timeout() -> void:
	score += 1
	$Player/Camera2D/HUD.update_score(score)


func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()
