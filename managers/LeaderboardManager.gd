# LeaderboardManager.gd
# Singleton for managing leaderboard data and Supabase interactions
# Add as autoload: Project Settings -> Autoload -> Add this script as "LeaderboardManager"

extends Node

signal leaderboard_loaded(scores: Array)
signal score_submitted(success: bool)
signal score_modified(success: bool)
signal score_deleted(success: bool)
signal leaderboard_error(error_message: String)

const MAX_LEADERBOARD_SIZE: int = 10

var supabase_url: Dictionary = {
	"read_top_scores": "https://ixgfzxmweunyfyfdtwvi.supabase.co/rest/v1/leaderboard?select=*&order=score.desc&limit=10",
	# Base URL for the 'leaderboard' table. Used for POST, PATCH, and DELETE.
	"base_table_url": "https://ixgfzxmweunyfyfdtwvi.supabase.co/rest/v1/leaderboard"
}

var api_key: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4Z2Z6eG13ZXVueWZ5ZmR0d3ZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MTUxMTMsImV4cCI6MjA3NzE5MTExM30.5M3zeVhFsMUwDb1SuW4GKuAQY8ihoYqShIvNGbcTSgg"

var base_headers: Array = [
	"apikey: " + api_key,
	"Authorization: Bearer " + api_key,
	"Content-Type: application/json"
]

var http_request: HTTPRequest
var current_request_type: String = ""  # "GET", "POST", "PATCH", or "DELETE"


func _ready() -> void:
	# Create HTTPRequest node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)


# Fetch top 10 scores from leaderboard
func fetch_leaderboard() -> void:
	current_request_type = "GET"
	var error: Error = http_request.request(supabase_url["read_top_scores"], base_headers)
	if error != OK:
		emit_signal("leaderboard_error", "Failed to start GET request")


# Submit a new score to the leaderboard
func submit_score(username: String, score: int) -> void:
	print("Submitting score...")
	current_request_type = "POST"
	
	# Public functions use base_headers (anon key)
	var post_headers: Array = base_headers.duplicate()
	post_headers.append("Prefer: return=minimal")
	
	var data_to_send: Dictionary = {"username": username, "score": score}
	var json_string: String = JSON.stringify(data_to_send)
	
	var error: Error = http_request.request(
		supabase_url["base_table_url"],
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


func update_score(id: int, new_username: String, new_score: int) -> void:
	print("Modifying score ID: %d" % id)
	
	if not AdminAuth.is_logged_in():
		emit_signal("score_modified", false)
		emit_signal("leaderboard_error", "Admin not authenticated for PATCH")
		return
	
	current_request_type = "PATCH"
	
	# Add the 'Prefer' header for PATCH
	var patch_headers: Array = AdminAuth.get_admin_headers()
	patch_headers.append("Prefer: return=minimal")
	
	# Construct the URL to target the specific row by its ID
	var patch_url: String = supabase_url["base_table_url"] + "?id=eq." + str(id)
	
	# Create the JSON payload with the new data
	var data_to_send: Dictionary = {"username": new_username, "score": new_score}
	var json_string: String = JSON.stringify(data_to_send)
	
	var error: Error = http_request.request(
		patch_url,
		patch_headers,
		HTTPClient.METHOD_PATCH,
		json_string
	)
	
	if error != OK:
		emit_signal("score_modified", false)
		emit_signal("leaderboard_error", "Failed to start PATCH request")


func delete_score(id: int) -> void:
	print("Deleting score ID: %d" % id)
	
	# Check if admin is logged in
	if not AdminAuth.is_logged_in():
		emit_signal("score_deleted", false)
		emit_signal("leaderboard_error", "Admin not authenticated for DELETE")
		return
	
	current_request_type = "DELETE"
	
	# Add the 'Prefer' header for DELETE
	var delete_headers: Array = AdminAuth.get_admin_headers()
	delete_headers.append("Prefer: return=minimal")
	
	# Construct the URL to target the specific row by its ID
	var delete_url: String = supabase_url["base_table_url"] + "?id=eq." + str(id)
	
	var error: Error = http_request.request(
		delete_url,
		delete_headers,
		HTTPClient.METHOD_DELETE
	)
	
	if error != OK:
		emit_signal("score_deleted", false)
		emit_signal("leaderboard_error", "Failed to start DELETE request")


# Handle HTTP request completion
func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# Route the response to the correct handler based on the request type
	match current_request_type:
		"GET":
			_handle_get_response(response_code, body)
		"POST":
			_handle_post_response(response_code, body)
		"PATCH":
			_handle_patch_response(response_code, body)
		"DELETE":
			_handle_delete_response(response_code, body)
		_:
			print("Unhandled request type: " + current_request_type)
	
	# Reset request type
	current_request_type = ""


func _handle_get_response(response_code: int, body: PackedByteArray) -> void:
	if response_code == 200:
		var json_data: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_data and json_data is Array:
			emit_signal("leaderboard_loaded", json_data)
		else:
			emit_signal("leaderboard_error", "Failed to parse leaderboard data")
	else:
		emit_signal("leaderboard_error", "GET Error: " + str(response_code))


func _handle_post_response(response_code: int, _body: PackedByteArray) -> void:
	if response_code == 201: # 201 means 'Created'
		emit_signal("score_submitted", true)
		# Automatically fetch updated leaderboard
		# Use call_deferred to wait until the HTTPRequest node is no longer busy.
		call_deferred("fetch_leaderboard")
	else:
		emit_signal("score_submitted", false)
		emit_signal("leaderboard_error", "POST Error: " + str(response_code))


# Handle the response from a PATCH request (modify_score)
func _handle_patch_response(response_code: int, _body: PackedByteArray) -> void:
	if response_code == 204: # 204 means 'No Content' (success for minimal return)
		emit_signal("score_modified", true)
		# Automatically fetch updated leaderboard
		# Use call_deferred to wait until the HTTPRequest node is no longer busy.
		call_deferred("fetch_leaderboard")
	else:
		emit_signal("score_modified", false)
		emit_signal("leaderboard_error", "PATCH Error: " + str(response_code))


# Handle the response from a DELETE request (delete_score)
func _handle_delete_response(response_code: int, _body: PackedByteArray) -> void:
	if response_code == 204: # 204 means 'No Content' (success for minimal return)
		emit_signal("score_deleted", true)
		call_deferred("fetch_leaderboard")
	else:
		emit_signal("score_deleted", false)
		emit_signal("leaderboard_error", "Failed to delete score: " + str(response_code))
