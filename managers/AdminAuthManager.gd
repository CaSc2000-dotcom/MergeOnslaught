# AdminAuthManager.gd
# Singleton for handling admin authentication
# Add as autoload: Project Settings -> Autoload -> Add this script as "AdminAuth"

extends Node

signal login_successful
signal login_failed(error_message: String)
signal logout_successful

var supabase_url: String = "https://ixgfzxmweunyfyfdtwvi.supabase.co"
var api_key: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4Z2Z6eG13ZXVueWZ5ZmR0d3ZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MTUxMTMsImV4cCI6MjA3NzE5MTExM30.5M3zeVhFsMUwDb1SuW4GKuAQY8ihoYqShIvNGbcTSgg"

var http_request: HTTPRequest
var is_admin_logged_in: bool = false
var admin_access_token: String = ""
var current_request_type: String = ""


func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)


# Login with email and password
func login_admin(email: String, password: String) -> void:
	current_request_type = "LOGIN"
	
	var headers: Array = [
		"apikey: " + api_key,
		"Content-Type: application/json"
	]
	
	var auth_url: String = supabase_url + "/auth/v1/token?grant_type=password"
	var body: Dictionary = {
		"email": email,
		"password": password
	}
	
	var error: Error = http_request.request(
		auth_url,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	
	if error != OK:
		emit_signal("login_failed", "Failed to start login request")


# Logout admin
func logout_admin() -> void:
	is_admin_logged_in = false
	admin_access_token = ""
	emit_signal("logout_successful")


# Get headers with admin authentication
func get_admin_headers() -> Array:
	if not is_admin_logged_in:
		push_error("Attempting to use admin headers without being logged in!")
		return []
	
	return [
		"apikey: " + api_key,
		"Authorization: Bearer " + admin_access_token,
		"Content-Type: application/json"
	]


# Check if currently logged in as admin
func is_logged_in() -> bool:
	return is_admin_logged_in


# Handle HTTP responses
func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if current_request_type == "LOGIN":
		_handle_login_response(response_code, body)


func _handle_login_response(response_code: int, body: PackedByteArray) -> void:
	if response_code == 200:
		var json_data: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_data and json_data.has("access_token"):
			admin_access_token = json_data["access_token"]
			is_admin_logged_in = true
			print("Admin logged in successfully")
			emit_signal("login_successful")
		else:
			is_admin_logged_in = false
			emit_signal("login_failed", "Invalid response format")
	else:
		is_admin_logged_in = false
		var error_msg: String = "Login failed with code: " + str(response_code)
		print(error_msg)
		emit_signal("login_failed", error_msg)
