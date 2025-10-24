extends Node2D

##
# Main menu scene logic.
# Handles button interactions for starting or quitting the game.
##
func _ready() -> void:
	pass # Initialization if needed later


func _process(delta: float) -> void:
	pass # Frame-based updates if required


##
# Called when the Play button is pressed.
# Loads the main game scene.
##
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/SessionSettings/session_settings.tscn")


##
# Called when the Exit button is pressed.
# Closes the game.
##
func _on_exit_button_pressed() -> void:
	get_tree().quit()
