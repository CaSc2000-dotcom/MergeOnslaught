# Author: Caleb Schmid
# Name: level.gd
# Handles the main level gameplay takes place on 

extends Node2D

@export var mob_scene: PackedScene

var score: int
var last_milestone: int = 0  # Track the last 1000 milestone we passed

var leaderboard_ui: CanvasLayer
var admin_panel: CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MenuMusic.play()
	$Player/Camera2D/HUD/Background.show()
	$Player/Camera2D/HUD/Subtitle.show()
	
	# Get leaderboard UI manually
	leaderboard_ui = $Player/Camera2D/LeaderboardUI
	print("LeaderboardUI found: ", leaderboard_ui != null)
	
	# Get admin panel
	admin_panel = $Player/Camera2D/AdminPanel
	print("AdminPanel found: ", admin_panel != null)
	
	# Connect leaderboard UI signal
	if leaderboard_ui:
		leaderboard_ui.continue_pressed.connect(_on_leaderboard_continue_pressed)
	else:
		print("ERROR: Could not find LeaderboardUI at path: Player/Camera2D/LeaderboardUI")
	
	# Connect admin panel signal
	if admin_panel:
		admin_panel.closed.connect(_on_admin_panel_closed)


# Handle secret admin key combination (Ctrl + Shift + A)
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_A:
			if admin_panel:
				admin_panel.show_admin_panel()
				$SFX/MenuBlip.play()
				


func _on_admin_panel_closed() -> void:
	# Resume game or return to normal state
	$SFX/MenuBlip.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var current_milestone: int = int(score / 1000)
	if current_milestone > last_milestone:
		last_milestone = current_milestone
		$SFX/ScoreMilestone.play()


# Initiates Game Over sequence
func game_over() -> void:
	$SFX/PlayerDied.play()
	print("=== game_over called, score: ", score)
	$ScoreTimer.stop()
	$MobTimer.stop()
	$GameMusic.stop()
	
	$Player/Camera2D/HUD.show_game_over()
	
	print("Waiting for message timer...")
	await $Player/Camera2D/HUD/MessageTimer.timeout
	print("Message timer finished, showing leaderboard")
	
	# Show leaderboard with current score
	print("leaderboard_ui is: ", leaderboard_ui)
	print("leaderboard_ui null? ", leaderboard_ui == null)
	if leaderboard_ui:
		leaderboard_ui.show_leaderboard(score)
	else:
		print("ERROR: leaderboard_ui is null!")


# Handle leaderboard continue button
func _on_leaderboard_continue_pressed() -> void:
	$SFX/MenuBlip.play()
	$Player/Camera2D/HUD/Background.show()
	$Player/Camera2D/HUD/Subtitle.show()
	$Player/Camera2D/HUD.show_start_button()  # Use new method instead of directly showing button
	$MenuMusic.play()


# Starts a new game
func new_game() -> void:
	$SFX/MenuBlip.play()
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
	# # Connect the mob's died signal to score function
	mob.died.connect(_on_mob_died)


func _on_mob_died() -> void:
	score += 15
	print("Incremented score.")


# Increments the score by 1 every second
func _on_score_timer_timeout() -> void:
	score += 10
	$Player/Camera2D/HUD.update_score(score)


# Starts MobTimer and ScoreTimer when the StartTimer runs out
func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()
