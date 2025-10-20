extends Node2D

@export var mob_scene: PackedScene # Drag your mob scene here in the Inspector

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_mob_timer_timeout() -> void:
	# Choose a random location on the path
	var mob_spawn_location: Node = $Player/Camera2D/SpawnPath/SpawnLocation
	mob_spawn_location.progress_ratio = randf() # randf() gives a random float between 0 and 1
	# Create a mob instance and add it to the scene
	var mob: Node = mob_scene.instantiate()
	mob.global_position = mob_spawn_location.global_position
	add_child(mob)
