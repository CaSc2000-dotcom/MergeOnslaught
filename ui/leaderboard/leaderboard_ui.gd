# leaderboard_ui.gd
# UI for displaying leaderboard and submitting scores

extends CanvasLayer

signal continue_pressed

@onready var leaderboard_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/LeaderboardContainer
@onready var username_input: LineEdit = $Panel/MarginContainer/VBoxContainer/SubmissionPanel/HBoxContainer/UsernameInput
@onready var submit_button: Button = $Panel/MarginContainer/VBoxContainer/SubmissionPanel/HBoxContainer/SubmitButton
@onready var continue_button: Button = $Panel/MarginContainer/VBoxContainer/ContinueButton
@onready var status_label: Label = $Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var score_label: Label = $Panel/MarginContainer/VBoxContainer/ScoreLabel

var current_score: int = 0
var cached_username: String = ""
var score_submitted: bool = false


func _ready() -> void:
	# Start hidden
	visible = false
	
	# Connect to LeaderboardManager signals
	LeaderboardManager.leaderboard_loaded.connect(_on_leaderboard_loaded)
	LeaderboardManager.score_submitted.connect(_on_score_submitted)
	LeaderboardManager.leaderboard_error.connect(_on_leaderboard_error)
	
	# Connect button signals
	submit_button.pressed.connect(_on_submit_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	
	# Load cached username if available
	if cached_username != "":
		username_input.text = cached_username


# Show the leaderboard with the player's score
func show_leaderboard(score: int) -> void:
	print("=== show_leaderboard called with score: ", score)
	current_score = score
	score_submitted = false
	score_label.text = "Your Score: " + str(score)
	status_label.text = "Loading leaderboard..."
	status_label.modulate = Color.WHITE
	
	# Reset UI state
	submit_button.disabled = false
	username_input.editable = true
	
	print("Setting visible to true")
	visible = true
	print("Visible is now: ", visible)
	
	LeaderboardManager.fetch_leaderboard()


# Populate leaderboard display
func _on_leaderboard_loaded(scores: Array) -> void:
	# Clear existing entries
	for child in leaderboard_container.get_children():
		child.queue_free()
	
	# Check if player's score qualifies
	var is_top_score: bool = LeaderboardManager.is_top_score(current_score, scores)
	
	if scores.is_empty():
		_add_leaderboard_entry(0, "No scores yet!", 0)
		status_label.text = "Be the first to submit a score!"
	else:
		# Add entries
		for i in range(scores.size()):
			var entry: Dictionary = scores[i]
			_add_leaderboard_entry(i + 1, entry["username"], entry["score"])
		
		# Update status based on whether score qualifies
		if is_top_score and not score_submitted:
			status_label.text = "You made the top 10! Enter your name to submit."
			status_label.modulate = Color.GREEN
		elif score_submitted:
			status_label.text = "Score submitted successfully!"
			status_label.modulate = Color.GREEN
		else:
			status_label.text = "Better luck next time!"
			status_label.modulate = Color.YELLOW
			submit_button.disabled = true


# Create a single leaderboard entry
func _add_leaderboard_entry(rank: int, username: String, score: int) -> void:
	var entry: HBoxContainer = HBoxContainer.new()
	
	var rank_label: Label = Label.new()
	rank_label.text = str(rank) + "."
	rank_label.custom_minimum_size = Vector2(40, 0)
	
	var name_label: Label = Label.new()
	name_label.text = username
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var score_label_entry: Label = Label.new()
	score_label_entry.text = str(score)
	score_label_entry.custom_minimum_size = Vector2(80, 0)
	score_label_entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	entry.add_child(rank_label)
	entry.add_child(name_label)
	entry.add_child(score_label_entry)
	
	leaderboard_container.add_child(entry)


# Handle submit button press
func _on_submit_pressed() -> void:
	var username: String = username_input.text.strip_edges()
	
	if username.is_empty():
		status_label.text = "Please enter a username!"
		status_label.modulate = Color.RED
		return
	
	# Cache username for future use
	cached_username = username
	
	# Disable submission while processing
	submit_button.disabled = true
	username_input.editable = false
	status_label.text = "Submitting score..."
	status_label.modulate = Color.WHITE
	
	# Submit to leaderboard
	LeaderboardManager.submit_score(username, current_score)


# Handle score submission response
func _on_score_submitted(success: bool) -> void:
	score_submitted = success
	if success:
		status_label.text = "Score submitted! Refreshing leaderboard..."
		status_label.modulate = Color.GREEN
	else:
		status_label.text = "Failed to submit score. Try again."
		status_label.modulate = Color.RED
		submit_button.disabled = false
		username_input.editable = true


# Handle leaderboard errors
func _on_leaderboard_error(error_message: String) -> void:
	status_label.text = "Error: " + error_message
	status_label.modulate = Color.RED


# Handle continue button
func _on_continue_pressed() -> void:
	visible = false  # Use visible instead of hide()
	emit_signal("continue_pressed")
