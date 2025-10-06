# Author: Caleb Schmid
# Name: hud.gd
# Controls the HUD 

extends CanvasLayer


signal start_game


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Displays a given text as a large message in the middle of the screen
func show_message(text: String) -> void:
	$Message.text = text
	$Message.show()
	$MessageTimer.start()


# Shows the game over screen
func show_game_over() -> void:
	show_message("Game Over")
	# Wait until the MessageTimer has counted downz
	await $MessageTimer.timeout
	
	$Message.text = "Merge Onslaught"
	$Message.show()
	# Make a one-shot timer and wait for it to finish
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()


# Updates the current score with a given score 
func update_score(score: int) -> void:
	$ScoreLabel.text = str(score)


# Emits start_game when the start button is pressed
func _on_start_button_pressed() -> void:
	$StartButton.hide()
	start_game.emit()


# Hides the Message when the MessageTimer runs out
func _on_message_timer_timeout() -> void:
	$Message.hide()
