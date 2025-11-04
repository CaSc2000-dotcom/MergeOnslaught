# LeaderboardManager.gd
# Singleton for managing leaderboard data and Supabase interactions
# Add as autoload: Project Settings -> Autoload -> Add this script as "LeaderboardManager"

extends Node

signal leaderboard_loaded(scores: Array)
signal score_submitted(success: bool)
signal leaderboard_error(error_message: String)

const MAX_LEADERBOARD_SIZE: int = 10

var supabase_url: Dictionary = {
	"read_top_scores": "https://ixgfzxmweunyfyfdtwvi.supabase.co/rest/v1/leaderboard?select=*&order=score.desc&limit=10",
	"insert_score": "https://ixgfzxmweunyfyfdtwvi.supabase.co/rest/v1/leaderboard"
}

var api_key: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4Z2Z6eG13ZXVueWZ5ZmR0d3ZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MTUxMTMsImV4cCI6MjA3NzE5MTExM30.5M3zeVhFsMUwDb1SuW4GKuAQY8ihoYqShIvNGbcTSgg"

var headers: Array = [
	"apikey: " + api_key,
	"Authorization: Bearer " + api_key,
	"Content-Type: application/json"
]

var http_request: HTTPRequest
var current_request_type: String = ""  # "GET" or "POST"


func _ready() -> void:
	# Create HTTPRequest node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)


# Fetch top 10 scores from leaderboard
func fetch_leaderboard() -> void:
	current_request_type = "GET"
	var error: Error = http_request.request(supabase_url["read_top_scores"], headers)
	if error != OK:
		emit_signal("leaderboard_error", "Failed to start GET request")


# Submit a new score to the leaderboard
func submit_score(username: String, score: int) -> void:
	current_request_type = "POST"
	
	var post_headers: Array = [
		headers[0],
		headers[1],
		headers[2],
		"Prefer: return=minimal"
	]
	
	var data_to_send: Dictionary = {"username": username, "score": score}
	var json_string: String = JSON.stringify(data_to_send)
	
	var error: Error = http_request.request(
		supabase_url["insert_score"],
		post_headers,
		HTTPClient.METHOD_POST,
		json_string
	)
	
	if error != OK:
		emit_signal("score_submitted", false)
		emit_signal("leaderboard_error", "Failed to start POST request")


# Check if a score qualifies for top 10
func is_top_score(score: int, leaderboard_data: Array) -> bool:
	if leaderboard_data.size() < MAX_LEADERBOARD_SIZE:
		return true
	
	# Check if score is higher than the lowest score
	var lowest_score: int = leaderboard_data[leaderboard_data.size() - 1]["score"]
	return score > lowest_score


# Handle HTTP request completion
func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if current_request_type == "GET":
		_handle_get_response(response_code, body)
	elif current_request_type == "POST":
		_handle_post_response(response_code, body)


func _handle_get_response(response_code: int, body: PackedByteArray) -> void:
	if response_code == 200:
		var json_data: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_data and json_data is Array:
			emit_signal("leaderboard_loaded", json_data)
		else:
			emit_signal("leaderboard_error", "Failed to parse leaderboard data")
	else:
		emit_signal("leaderboard_error", "Server error: " + str(response_code))


func _handle_post_response(response_code: int, _body: PackedByteArray) -> void:
	if response_code == 201:
		emit_signal("score_submitted", true)
		# Automatically fetch updated leaderboard
		fetch_leaderboard()
	else:
		emit_signal("score_submitted", false)
		emit_signal("leaderboard_error", "Failed to submit score: " + str(response_code))
