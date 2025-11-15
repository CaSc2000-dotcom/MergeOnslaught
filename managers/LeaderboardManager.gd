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
	"base_table_url": "https://ixgfzxmweunyfyfdtwvi.supabase.co/rest/v1/leaderboard"
}

var api_key: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4Z2Z6eG13ZXVueWZ5ZmR0d3ZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MTUxMTMsImV4cCI6MjA3NzE5MTExM30.5M3zeVhFsMUwDb1SuW4GKuAQY8ihoYqShIvNGbcTSgg"

# Changed to PackedStringArray for strict compatibility with HTTPRequest
var base_headers: PackedStringArray = [
	"apikey: " + api_key,
	"Authorization: Bearer " + api_key,
	"Content-Type: application/json"
]

var http_request: HTTPRequest
var current_request_type: String = ""  # "GET", "POST", "PATCH", or "DELETE"

# Reference to keep the JS callback alive (nullable because it's only used on Web)
var _js_callback_ref: JavaScriptObject = null 

func _ready() -> void:
	# Create HTTPRequest node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	if OS.has_feature("web"):
		_setup_web_fetch()
	else:
		# Add timeout settings for desktop/mobile
		http_request.timeout = 10.0

# Setup JavaScript bridge for Web exports to avoid GZIP double-decompression
func _setup_web_fetch() -> void:
	var js_code: String = """
		window.godot_supa_fetch = function(url, method, headers_json, body, callback) {
			var headers_dict = JSON.parse(headers_json);
			var opts = {
				method: method,
				headers: headers_dict
			};
			if (body) opts.body = body;
			
			fetch(url, opts).then(response => {
				response.text().then(text => {
					// Pass status and text back to Godot
					callback(response.status, text);
				});
			}).catch(error => {
				console.error("Supabase Fetch Error:", error);
				callback(0, "");
			});
		}
	"""
	JavaScriptBridge.eval(js_code)
	_js_callback_ref = JavaScriptBridge.create_callback(_on_web_fetch_completed)

# Callback received from JavaScript
func _on_web_fetch_completed(args: Array) -> void:
	if args.size() < 2:
		return
		
	var status_code: int = int(args[0])
	var response_text: String = str(args[1])
	var body_bytes: PackedByteArray = response_text.to_utf8_buffer()
	
	# Manually trigger the handler with the data from JS
	_on_request_completed(0, status_code, PackedStringArray(), body_bytes)

# Unified request function that handles both Web and Desktop
func _make_request(url: String, headers: PackedStringArray, method: int, body: String = "") -> void:
	if OS.has_feature("web"):
		var window: JavaScriptObject = JavaScriptBridge.get_interface("window")
		# Convert headers array ["Key: Value"] to Dictionary for JS
		var headers_dict: Dictionary = {}
		for h: String in headers:
			var parts: PackedStringArray = h.split(": ", true, 1)
			if parts.size() == 2:
				# Skip Accept-Encoding on web to let browser handle it
				if parts[0].to_lower() == "accept-encoding":
					continue
				headers_dict[parts[0]] = parts[1]
		
		if window:
			# current_request_type is set in the calling functions
			window.godot_supa_fetch(url, current_request_type, JSON.stringify(headers_dict), body, _js_callback_ref)
	else:
		var error: Error = http_request.request(url, headers, method, body)
		if error != OK:
			emit_signal("leaderboard_error", "Failed to start " + current_request_type + " request")

# --- Public Functions ---

# Fetch top 10 scores from leaderboard
func fetch_leaderboard() -> void:
	current_request_type = "GET"
	_make_request(supabase_url["read_top_scores"], base_headers, HTTPClient.METHOD_GET)

# Submit a new score to the leaderboard
func submit_score(username: String, score: int) -> void:
	print("Submitting score...")
	current_request_type = "POST"
	
	var post_headers: PackedStringArray = base_headers.duplicate()
	post_headers.append("Prefer: return=minimal")
	
	var data_to_send: Dictionary = {"username": username, "score": score}
	var json_string: String = JSON.stringify(data_to_send)
	
	_make_request(supabase_url["base_table_url"], post_headers, HTTPClient.METHOD_POST, json_string)

# Check if a score qualifies for top 10
func is_top_score(score: int, leaderboard_data: Array) -> bool:
	if leaderboard_data.size() < MAX_LEADERBOARD_SIZE:
		return true
	
	# Check if score is higher than the lowest score
	var lowest_entry: Dictionary = leaderboard_data[leaderboard_data.size() - 1]
	var lowest_score: int = int(lowest_entry.get("score", 0))
	return score > lowest_score

func update_score(id: int, new_username: String, new_score: int) -> void:
	print("Modifying score ID: %d" % id)
	
	if not AdminAuth.is_logged_in():
		emit_signal("score_modified", false)
		emit_signal("leaderboard_error", "Admin not authenticated for PATCH")
		return
	
	current_request_type = "PATCH"
	
	# Add the 'Prefer' header for PATCH
	# We assume AdminAuth.get_admin_headers() returns Array or PackedStringArray
	var patch_headers: PackedStringArray = PackedStringArray(AdminAuth.get_admin_headers())
	patch_headers.append("Prefer: return=minimal")
	
	# Construct the URL to target the specific row by its ID
	var patch_url: String = supabase_url["base_table_url"] + "?id=eq." + str(id)
	
	# Create the JSON payload with the new data
	var data_to_send: Dictionary = {"username": new_username, "score": new_score}
	var json_string: String = JSON.stringify(data_to_send)
	
	_make_request(patch_url, patch_headers, HTTPClient.METHOD_PATCH, json_string)

func delete_score(id: int) -> void:
	print("Deleting score ID: %d" % id)
	
	# Check if admin is logged in
	if not AdminAuth.is_logged_in():
		emit_signal("score_deleted", false)
		emit_signal("leaderboard_error", "Admin not authenticated for DELETE")
		return
	
	current_request_type = "DELETE"
	
	# Add the 'Prefer' header for DELETE
	var delete_headers: PackedStringArray = PackedStringArray(AdminAuth.get_admin_headers())
	delete_headers.append("Prefer: return=minimal")
	
	# Construct the URL to target the specific row by its ID
	var delete_url: String = supabase_url["base_table_url"] + "?id=eq." + str(id)
	
	_make_request(delete_url, delete_headers, HTTPClient.METHOD_DELETE)


# --- Response Handlers ---

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
	print("=== GET Response Debug ===")
	print("Response code: ", response_code)
	print("Body length: ", body.size())
	# print("Body as string: ", body.get_string_from_utf8()) # Uncomment for debug
	print("========================")
	
	if response_code == 200:
		var body_string: String = body.get_string_from_utf8()
		
		# Check if body is empty
		if body_string.is_empty():
			print("ERROR: Response body is empty!")
			emit_signal("leaderboard_error", "Empty response from server")
			return
		
		var json_data: Variant = JSON.parse_string(body_string)
		
		if json_data == null:
			print("ERROR: Failed to parse JSON")
			emit_signal("leaderboard_error", "Failed to parse leaderboard data")
			return
		
		if json_data is Array:
			print("SUCCESS: Parsed ", json_data.size(), " entries")
			emit_signal("leaderboard_loaded", json_data)
		else:
			print("ERROR: JSON is not an array, it's: ", typeof(json_data))
			emit_signal("leaderboard_error", "Invalid data format")
	else:
		emit_signal("leaderboard_error", "GET Error: " + str(response_code))

func _handle_post_response(response_code: int, _body: PackedByteArray) -> void:
	if response_code == 201: # 201 means 'Created'
		emit_signal("score_submitted", true)
		# Automatically fetch updated leaderboard
		call_deferred("fetch_leaderboard")
	else:
		emit_signal("score_submitted", false)
		emit_signal("leaderboard_error", "POST Error: " + str(response_code))

func _handle_patch_response(response_code: int, _body: PackedByteArray) -> void:
	if response_code == 204: # 204 means 'No Content' (success for minimal return)
		emit_signal("score_modified", true)
		call_deferred("fetch_leaderboard")
	else:
		emit_signal("score_modified", false)
		emit_signal("leaderboard_error", "PATCH Error: " + str(response_code))

func _handle_delete_response(response_code: int, _body: PackedByteArray) -> void:
	if response_code == 204: # 204 means 'No Content' (success for minimal return)
		emit_signal("score_deleted", true)
		call_deferred("fetch_leaderboard")
	else:
		emit_signal("score_deleted", false)
		emit_signal("leaderboard_error", "Failed to delete score: " + str(response_code))
