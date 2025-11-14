# admin_panel.gd
# Admin interface for managing leaderboard entries

extends CanvasLayer

signal closed

var is_clicking_outside: bool = false

@onready var login_panel: Control = $LoginPanel
@onready var management_panel: Control = $ManagementPanel
@onready var email_input: LineEdit = $LoginPanel/VBoxContainer/EmailInput
@onready var password_input: LineEdit = $LoginPanel/VBoxContainer/PasswordInput
@onready var login_button: Button = $LoginPanel/VBoxContainer/LoginButton
@onready var status_label: Label = $LoginPanel/VBoxContainer/StatusLabel

@onready var leaderboard_list: VBoxContainer = $ManagementPanel/VBoxContainer/ScrollContainer/LeaderboardList
@onready var logout_button: Button = $ManagementPanel/VBoxContainer/TopBar/LogoutButton
@onready var refresh_button: Button = $ManagementPanel/VBoxContainer/TopBar/RefreshButton
@onready var close_button: Button = $ManagementPanel/VBoxContainer/TopBar/CloseButton

var current_leaderboard_data: Array = []


func _ready() -> void:
	visible = false
	
	# Connect auth signals
	AdminAuth.login_successful.connect(_on_login_successful)
	AdminAuth.login_failed.connect(_on_login_failed)
	
	# Connect leaderboard signals
	LeaderboardManager.leaderboard_loaded.connect(_on_leaderboard_loaded)
	LeaderboardManager.score_modified.connect(_on_score_updated)
	LeaderboardManager.score_deleted.connect(_on_score_deleted)
	LeaderboardManager.leaderboard_error.connect(_on_leaderboard_error)
	
	# Connect button signals
	login_button.pressed.connect(_on_login_pressed)
	logout_button.pressed.connect(_on_logout_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Start with login panel visible
	_show_login_panel()


# Add this new function to handle input
func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Only handle mouse clicks
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if click is outside the login panel
		if login_panel.visible:
			var panel_rect: Rect2 = login_panel.get_global_rect()
			var mouse_pos: Vector2 = event.position
			
			if not panel_rect.has_point(mouse_pos):
				visible = false
				emit_signal("closed")


# Show the admin panel
func show_admin_panel() -> void:
	visible = true
	if AdminAuth.is_logged_in():
		_show_management_panel()
	else:
		_show_login_panel()


# Show login panel
func _show_login_panel() -> void:
	login_panel.visible = true
	management_panel.visible = false
	status_label.text = ""
	password_input.text = ""


# Show management panel
func _show_management_panel() -> void:
	login_panel.visible = false
	management_panel.visible = true
	LeaderboardManager.fetch_leaderboard()


# Handle login button
func _on_login_pressed() -> void:
	var email: String = email_input.text.strip_edges()
	var password: String = password_input.text
	
	if email.is_empty() or password.is_empty():
		status_label.text = "Please enter email and password"
		status_label.modulate = Color.RED
		return
	
	status_label.text = "Logging in..."
	status_label.modulate = Color.WHITE
	login_button.disabled = true
	
	AdminAuth.login_admin(email, password)


# Handle successful login
func _on_login_successful() -> void:
	login_button.disabled = false
	_show_management_panel()


# Handle failed login
func _on_login_failed(error_message: String) -> void:
	login_button.disabled = false
	status_label.text = "Login failed: " + error_message
	status_label.modulate = Color.RED


# Handle logout
func _on_logout_pressed() -> void:
	AdminAuth.logout_admin()
	_show_login_panel()


# Handle refresh
func _on_refresh_pressed() -> void:
	LeaderboardManager.fetch_leaderboard()


# Handle close
func _on_close_pressed() -> void:
	visible = false
	emit_signal("closed")


# Populate leaderboard entries
func _on_leaderboard_loaded(scores: Array) -> void:
	current_leaderboard_data = scores
	
	# Clear existing entries
	for child in leaderboard_list.get_children():
		child.queue_free()
	
	if scores.is_empty():
		var label: Label = Label.new()
		label.text = "No entries in leaderboard"
		leaderboard_list.add_child(label)
		return
	
	# Add each entry with edit/delete buttons
	for entry: Dictionary in scores:
		_create_leaderboard_entry(entry)


# Create a single editable leaderboard entry
func _create_leaderboard_entry(entry: Dictionary) -> void:
	var container: HBoxContainer = HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 40)
	
	# ID (hidden but stored)
	var id_label: Label = Label.new()
	id_label.text = "ID: " + str(entry["id"])
	id_label.custom_minimum_size = Vector2(60, 0)
	
	# Username
	var username_input: LineEdit = LineEdit.new()
	username_input.text = entry["username"]
	username_input.custom_minimum_size = Vector2(150, 0)
	username_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Score
	var score_input: SpinBox = SpinBox.new()
	score_input.min_value = 0
	score_input.max_value = 999999
	score_input.value = entry["score"]  # Set value AFTER max_value
	score_input.custom_minimum_size = Vector2(100, 0)
	
	# Update button
	var update_btn: Button = Button.new()
	update_btn.text = "Update"
	update_btn.custom_minimum_size = Vector2(80, 0)
	update_btn.pressed.connect(func() -> void: _on_update_entry(entry["id"], username_input.text, int(score_input.value)))
	
	# Delete button
	var delete_btn: Button = Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(80, 0)
	delete_btn.modulate = Color.RED
	delete_btn.pressed.connect(func() -> void: _on_delete_entry(entry["id"]))
	
	# Add all to container
	container.add_child(id_label)
	container.add_child(username_input)
	container.add_child(score_input)
	container.add_child(update_btn)
	container.add_child(delete_btn)
	
	leaderboard_list.add_child(container)


# Handle update entry
func _on_update_entry(entry_id: int, new_username: String, new_score: int) -> void:
	print("Updating entry ID: ", entry_id, " to ", new_username, " - ", new_score)
	LeaderboardManager.update_score(entry_id, new_username, new_score)


# Handle delete entry
func _on_delete_entry(entry_id: int) -> void:
	print("Deleting entry ID: ", entry_id)
	LeaderboardManager.delete_score(entry_id)


# Handle score update response
func _on_score_updated(success: bool) -> void:
	if success:
		print("Score updated successfully")
	else:
		print("Failed to update score")


# Handle score delete response
func _on_score_deleted(success: bool) -> void:
	if success:
		print("Score deleted successfully")
	else:
		print("Failed to delete score")


# Handle errors
func _on_leaderboard_error(error_message: String) -> void:
	print("Leaderboard error: ", error_message)
