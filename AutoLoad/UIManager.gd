extends Node


##
# Manages UI-related behaviors such as hover detection
# and collision activation for cards in the player's hand.
##
var card_hovered = null: # Index of selected card in hand
	set(value):
		card_hovered = value
		set_collisions()
var is_dragging: bool = false # Flag indicates if player dragging a card
var in_action_area: bool = false
var player_hand: HandContainer ## Reference to the player's HandContainer scene
var table: TableContainer ## Refence to the player's HandContainer scene

var dragging_just_started = 1
var selected_card: Card

func try_attack() -> bool:
	return GameManager.play_attack_card(GameManager.current_player, selected_card.get_data())

#func try_defend() -> bool:
	#return GameManager.play_defense_card(GameManager.current_player, selected_card.get_data(), )

func update_ui_attack():
	table.add_attack(selected_card.get_data())
	player_hand.remove_child(selected_card)

func update_ui_defend():
	table.add_attack(selected_card.get_data())
	player_hand.remove_child(selected_card)
	
func _input(event: InputEvent) -> void:
	if selected_card and Input.is_action_just_released("LMB"):
		selected_card.stop_animation()
		if in_action_area and try_attack():
			update_ui_attack()
		#elif try_defend():
			#update_ui_defend()
		dragging_just_started = 1
		selected_card = null
		is_dragging = false
		card_hovered = null
		player_hand.update_layout()
		table.clear_all_highlights()
	if event is InputEventMouseMotion and Input.is_action_pressed("LMB"):
		if card_hovered == null: return
		is_dragging = true
		selected_card = player_hand.get_child(card_hovered)
		selected_card.position += event.relative
		selected_card.play_animation("Dragging")
		if dragging_just_started == 1:
			player_hand.update_layout()
			dragging_just_started = 0
		
		# Defense
		if in_action_area and GameManager.current_player == GameManager.player_defending:
			print(table.update_highlight_to_selected())
		else:
			table.clear_all_highlights()

# ------------------------------------------------------------------------------
# Cards in hand helper functions
# ------------------------------------------------------------------------------

##
# Updates which cards are interactive based on the hovered card.
# Only the hovered card (or all, if none is hovered) will have collision enabled.
##
func set_collisions() -> void:
	var i: int = 0
	for card: Card in player_hand.get_children():
		card.collision = card_hovered == i or card_hovered == null
		i += 1


# ------------------------------------------------------------------------------
# UI helper functions
# ------------------------------------------------------------------------------

##
# Recursively removes all child nodes whose names start with "Preview".
#
# @param node The root node to start searching from.
##
func remove_preview_nodes(node: Node) -> void:
	for child in node.get_children():
		# Check if the node name starts with "Preview"
		if child.name.begins_with("Preview"):
			child.queue_free()
		else:
			# Recursively process deeper hierarchy
			remove_preview_nodes(child)
