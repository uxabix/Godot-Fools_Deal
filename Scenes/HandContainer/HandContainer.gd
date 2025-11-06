@tool
extends Node2D
class_name HandContainer

# ------------------------------------------------------------------------------
# HandContainer
# Arranges and animates card nodes in a fan-like layout, simulating a player's hand.
# Supports smooth transitions, spacing adjustments, and flipping all cards face-up or down.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Layout Configuration
# ------------------------------------------------------------------------------

@export var appearance: HandContainerData = preload("res://Scripts/Entities/Resources/HandContainer/Variants/PlayerHand.tres")
var player_id: int = 0

var card_scene = preload("res://Scenes/Card/card.tscn")

# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------

func _ready() -> void:
	if Engine.is_editor_hint():
		update_layout()

	child_entered_tree.connect(_on_child_changed)
	child_exiting_tree.connect(_on_child_changed)

	call_deferred("_deferred_update_layout")


# Respond to editor transformations (for live layout updates)
func _notification(what: int) -> void:
	if Engine.is_editor_hint():
		if what == NOTIFICATION_TRANSFORM_CHANGED or what == NOTIFICATION_PARENTED:
			update_layout()


# ------------------------------------------------------------------------------
# Internal Callbacks
# ------------------------------------------------------------------------------

func _on_child_changed(_node: Node) -> void:
	call_deferred("_deferred_update_layout")

func _deferred_update_layout() -> void:
	update_layout()


# ------------------------------------------------------------------------------
# Layout Logic
# ------------------------------------------------------------------------------

# Evenly arranges all child card nodes in a curved, fan-like layout.
# If UIManager.is_dragging is true and UIManager.card_hovered points to an index,
# the layout is computed as if that child was removed (i.e. for count-1 cards).
func update_layout() -> void:
	var count := get_child_count()
	if count == 0:
		return

	# Determine whether we should ignore one child (the one being dragged)
	var ignore_index := -1
	var effective_count := count

	if UIManager.is_dragging and UIManager.card_hovered != null \
	 and UIManager.card_hovered >= 0 and UIManager.card_hovered < count:
		ignore_index = int(UIManager.card_hovered)
		effective_count = max(0, count - 1)

	# If nothing to ignore, layout normally
	if effective_count <= 0:
		return

	# Recompute geometry using effective_count (treating dragged card as absent)
	var total_width := (effective_count - 1) * appearance.spacing
	var start_x := -total_width * 0.5
	var center_y := appearance.vertical_offset
	var center_index := (effective_count - 1) / 2.0

	var angle_step := 0.0
	if appearance.fan_angle != 0.0:
		angle_step = deg_to_rad(appearance.fan_angle) / max(effective_count - 1, 1)

	# Iterate physical children but map them into virtual indices that skip the ignored one.
	# virtual_index runs from 0..effective_count-1
	var virtual_index := 0
	for i in range(count):
		# If this child is the one being dragged and should be ignored — skip it
		if i == ignore_index:
			continue

		var node := get_child(i)
		if not node is Card:
			# keep virtual_index consistent: skip non-node children without incrementing layout index
			continue

		# Compute position based on virtual_index (0..effective_count-1)
		var pos_x := start_x + virtual_index * appearance.spacing

		var offset: float = 0.0
		if center_index != 0:
			offset = (virtual_index - center_index) / center_index

		var pos_y: float = center_y + appearance.y_spacing * -cos(offset * PI * 0.5)
		var target_pos := Vector2(pos_x, pos_y)

		# Calculate rotation to create the fan effect (based on virtual index)
		var target_rot := 0.0
		if appearance.fan_angle != 0.0 and center_index != 0:
			target_rot = -deg_to_rad(appearance.fan_angle) * 0.5 + virtual_index * angle_step

		# Apply animation or direct placement
		if appearance.animate:
			var tween := create_tween()
			tween.tween_property(node, "position", target_pos, appearance.animation_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(node, "rotation", target_rot, appearance.animation_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		else:
			node.position = target_pos
			node.rotation = target_rot

		virtual_index += 1

# ------------------------------------------------------------------------------
# Utility Functions
# ------------------------------------------------------------------------------

# Flips all cards in the hand face-up or face-down
func flip_cards() -> void:
	for child in get_children():
		if child.has_method("flip"):
			child.is_face_up = appearance.is_face_up


func set_cards(cards: Array[CardData], cards_appearance: CardAppearanceData) -> void:
	for child in get_children():
		if child is Card:
			remove_child(child)
	for card_data: CardData in cards:
		var card: Card = card_scene.instantiate()
		card.is_face_up = false
		if !cards_appearance.cards_hidden:
			card.init(card_data)
			card.is_face_up = true
		card.animate = cards_appearance.is_current_player;
		add_child(card)


# Reserved for future logic
func show_cards() -> void:
	pass
