# Author: Caleb Schmid
# Name: level.gd
# Handles the main level gameplay takes place on 

extends Node2D


@onready var http_request: Node = $Leaderboard
# different urls correspond to different PostGres commands
var supabase_url: Dictionary = {
	"read_all_rows": "https://ixgfzxmweunyfyfdtwvi.supabase.co/rest/v1/leaderboard?select=*",
	"insert_a_row":  "https://ixgfzxmweunyfyfdtwvi.supabase.co/rest/v1/leaderboard"
}
# safe public api key
var api_key: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4Z2Z6eG13ZXVueWZ5ZmR0d3ZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MTUxMTMsImV4cCI6MjA3NzE5MTExM30.5M3zeVhFsMUwDb1SuW4GKuAQY8ihoYqShIvNGbcTSgg"
# idk what headers do yet
var headers: Array = [
	"apikey: " + api_key,
	"Authorization: Bearer " + api_key,
	"Content-Type: application/json" # (Needed for insert/modify)
]

@export var mob_scene: PackedScene
var score: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MenuMusic.play()
	$Player/Camera2D/HUD/Background.show()
	$Player/Camera2D/HUD/Subtitle.show()
	
	get_scores() # TODO: implement within a UI element


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Initiates Game Over sequence
func game_over() -> void:
	$ScoreTimer.stop()
	$MobTimer.stop()
	$GameMusic.stop()
	
	$Player/Camera2D/HUD.show_game_over()
	
	# submit_new_score("reto", score) # TODO: implement within a UI element
	
	await $Player/Camera2D/HUD/MessageTimer.timeout
	$Player/Camera2D/HUD/Background.show()
	$Player/Camera2D/HUD/Subtitle.show()
	$MenuMusic.play()
	
	get_scores() # remove this eventually


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


# Fetches the scores
func get_scores() -> void:
	var error: Error = http_request.request(supabase_url["read_all_rows"], headers)
	if error != OK:
		print("Error starting the GET request")

# Submits a new score that didn't exist before
func submit_new_score(username: String, user_score: int) -> void:
	# Headers for POST
	var post_headers: Array = [
		headers[0],
		headers[1],
		headers[2],
		"Prefer: return=minimal" # Good practice: tells Supabase we don't need data back
	]
	
	# Prepares data in a format it can send to DB
	var data_to_send: Dictionary = { "username": username, "score": user_score }
	var json_string_body: String = JSON.stringify(data_to_send)
	# Sent request with METHOD_POST
	var error: Error = http_request.request(
		supabase_url["insert_a_row"], 
		post_headers, 
		HTTPClient.METHOD_POST,
		json_string_body
	)
	if error != OK:
		print("Error starting the POST request")

# What to do based on what request was completed
func _on_leaderboard_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	
	# METHOD_GET
	if response_code == 200:
		var json_data: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_data:
			print("Scores: ", json_data)
			# code to display it
		else:
			print("Error parsing JSON, or no data returned")
	
	# METHOD_POST
	elif response_code == 201:
		print("Scores submitted successfully!")
	
	# ERROR
	else:
		print("An error occurred. Response code: ", response_code)
		print("Response body: ", body.get_string_from_utf8())
