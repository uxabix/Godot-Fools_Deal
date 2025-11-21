extends Node2D
class_name TableContainer

const cd = preload("res://Scripts/Utils/card_defines.gd")

@export var card_scene: PackedScene = preload("res://Scenes/Card/card.tscn")
@export var card_spacing: float = 120.0
@export var row_offset: float = 80.0
@export var defense_offset: float = 20.0
@export var max_rotation: float = 5.0
@export var min_rotation: float = -2.0

@export var animate: bool = true
@export var animation_time: float = 0.25

var max_pairs: int = 6

var pairs: Array[Dictionary] = []
var ghost_data: CardData = CardData.new()

var attack_nodes: Array[Card] = []
var defense_nodes: Array[Card] = []

var prev_positions := {}
var prev_rotations := {}

# ---------------------- Keys for Cards ------------------------
func get_card_key(card: Card) -> int:
	if card and card.get_data():
		return card.get_data().get_instance_id()
	return -1

func get_data_key(data: CardData) -> int:
	if data:
		return data.get_instance_id()
	return -1

# ---------------------- Initialization ------------------------
func _ready() -> void:
	update_layout()
	_update_attack_drop_area()

# ---------------------- Public API ----------------------------
func add_attack(card: CardData) -> bool:
	if pairs.size() >= max_pairs:
		return false
	pairs.append({"attack": card, "defense": null})
	var key = get_data_key(card)
	if not prev_rotations.has(key):
		prev_rotations[key] = -get_random_rotation(min_rotation, max_rotation)
	update_layout()
	return true

func add_defense(attack_index: int, card: CardData) -> bool:
	if attack_index < 0 or attack_index >= pairs.size():
		return false
	if pairs[attack_index]["defense"] != null:
		return false
	pairs[attack_index]["defense"] = card
	var key = get_data_key(card)
	if not prev_rotations.has(key):
		prev_rotations[key] = get_random_rotation(min_rotation, max_rotation)
	update_layout()
	return true

func clear() -> void:
	pairs.clear()
	prev_rotations.clear()
	for c in attack_nodes + defense_nodes:
		if c:
			c.visible = false
	update_transfer_ghost(false)

# ---------------------- Helpers -------------------------------
func calc_x(index: int, count: int) -> float:
	if count <= 1:
		return 0.0
	var total_width = (count - 1) * card_spacing
	return -total_width / 2.0 + index * card_spacing

func get_random_rotation(min_rot: float, max_rot: float) -> float:
	return deg_to_rad(randf_range(min_rot, max_rot))

func _get_from_pool(pool: Array[Card], parent_container: Node) -> Card:
	for card in pool:
		if not card.visible:
			if card.get_parent() != parent_container:
				parent_container.add_child(card)
			return card
	var new_card: Card = card_scene.instantiate()
	new_card.collision = false
	parent_container.add_child(new_card)
	new_card.visible = false
	pool.append(new_card)
	return new_card

# Setup card position, rotation, visibility, and animation
func _setup_card(card: Card, target_pos: Vector2, target_rot: float, start_pos: Vector2) -> void:
	card.global_position = start_pos
	card.visible = true
	if animate:
		var t := create_tween()
		t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(card, "position", target_pos, animation_time)
		t.tween_property(card, "rotation", target_rot, animation_time)
	else:
		card.position = target_pos
		card.rotation = target_rot

# ---------------------- Layout -------------------------------
func update_layout() -> void:
	if not is_inside_tree():
		return

	# Save previous positions and rotations
	prev_positions.clear()
	for c in attack_nodes + defense_nodes:
		if c.visible:
			var key = get_card_key(c)
			if key != -1:
				prev_positions[key] = c.global_position
				prev_rotations[key] = c.rotation

	var total_cards: int = pairs.size()
	if total_cards == 0:
		for c in attack_nodes + defense_nodes:
			if c:
				c.visible = false
		update_transfer_ghost(false)
		return

	var first_row_count = min(total_cards, 3)
	var second_row_count = max(0, total_cards - 3)

	var has_dragged := UIManager.is_dragging and UIManager.selected_card
	var dragged_old_pos := Vector2.ZERO
	if has_dragged:
		dragged_old_pos = UIManager.selected_card.global_position

	var used_attack_nodes: Array[Card] = []
	var used_defense_nodes: Array[Card] = []

	for i in range(total_cards):
		var pair = pairs[i]
		var row = i / 3
		# ensure integer row (0 or 1)
		row = int(row)
		var index_in_row = i % 3
		var count_in_row = first_row_count if row == 0 else second_row_count
		var pos_x = calc_x(index_in_row, count_in_row)
		var pos_y = -row_offset / 2.0 if row == 0 else row_offset / 2.0

		# ---------------- Attack Card -----------------
		if pair["attack"]:
			var attack_card: Card = _get_from_pool(attack_nodes, $AttackContainer)
			attack_card.init(pair["attack"])
			var key = get_data_key(pair["attack"])
			var target_pos = Vector2(pos_x, pos_y)
			var target_rot = prev_rotations.get(key, -get_random_rotation(min_rotation, max_rotation))
			var start_pos = prev_positions[key] if prev_positions.has(key) else global_position + target_pos
			if has_dragged and i == total_cards - 1:
				start_pos = dragged_old_pos
			_setup_card(attack_card, target_pos, target_rot, start_pos)
			used_attack_nodes.append(attack_card)

		# ---------------- Defense Card -----------------
		if pair["defense"]:
			var defense_card: Card = _get_from_pool(defense_nodes, $DefenseContainer)
			defense_card.init(pair["defense"])
			var key = get_data_key(pair["defense"])
			var target_pos = Vector2(pos_x + defense_offset, pos_y + defense_offset)
			var target_rot = prev_rotations.get(key, get_random_rotation(min_rotation, max_rotation))
			var start_pos = prev_positions[key] if prev_positions.has(key) else global_position + target_pos
			if has_dragged and i == total_cards - 1:
				start_pos = dragged_old_pos
			_setup_card(defense_card, target_pos, target_rot, start_pos)
			used_defense_nodes.append(defense_card)

	# Hide unused nodes
	for card in attack_nodes:
		if card not in used_attack_nodes:
			card.visible = false
	for card in defense_nodes:
		if card not in used_defense_nodes:
			card.visible = false

	update_transfer_ghost(true)

# ---------------------- Attack Drop Area ----------------------
func _update_attack_drop_area() -> void:
	var shape := $AttackDropArea.get_node("CollisionShape2D")
	if not shape:
		return
	var width := (3 * card_spacing) * 2.25
	var height := row_offset * 2.75
	var rect := RectangleShape2D.new()
	rect.extents = Vector2(width * 0.5, height * 0.5)
	shape.shape = rect
	$AttackDropArea.position = Vector2.ZERO

# ---------------------- Transfer Logic -----------------------
func get_can_transfer() -> bool:
	if not GameManager.ruleset.translated_mode or pairs.size() < 1:
		return false
	if GameManager.current_player != GameManager.player_defending:
		return false
	for pair in pairs:
		if pair["defense"]:
			return false

	var rank: cd.Rank = pairs[0]["attack"].rank
	var suits: Array[cd.Suit] = []
	for pair in pairs:
		if pair["attack"].rank != rank:
			return false
		suits.append(pair["attack"].suit)

	ghost_data.rank = rank
	var remained_suits = cd.ALL_SUITS.filter(func(x): return x not in suits)
	ghost_data.suit = remained_suits.pick_random()
	return true

func set_ghost_appearance() -> void:
	if not get_can_transfer():
		$TransferGhost.visible = false
		return
	$TransferGhost/Card.init(ghost_data)

func update_transfer_ghost(enabled: bool) -> void:
	var ghost := $TransferGhost
	ghost.visible = enabled
	set_ghost_appearance()
	if not enabled or pairs.size() == 0:
		return

	var last_index = pairs.size() - 1
	var row = int(last_index / 3)
	var index_in_row = last_index % 3
	# choose correct count_in_row depending on row
	var count_in_row = min(pairs.size(), 3) if row == 0 else max(0, pairs.size() - 3)

	var pos_x = calc_x(index_in_row, count_in_row) + card_spacing
	var pos_y = -row_offset / 2.0 if row == 0 else row_offset / 2.0
	ghost.position = Vector2(pos_x, pos_y)

	var sprite := ghost.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate.a = 0.5

# ==================== Highlight Logic =========================

func update_highlight_to_selected() -> Card:
	var selected: Card = UIManager.selected_card
	if not selected:
		clear_all_highlights()
		return null

	var target := _find_closest_table_card(selected.global_position)
	_apply_highlight(target)
	return target


func _find_closest_table_card(player_pos: Vector2) -> Card:
	var closest_card: Card = null
	var closest_dist := INF

	# Build set of attack instance ids that are defended (so we can skip them)
	var defended_attack_ids := {}
	for pair in pairs:
		if pair["attack"] and pair["defense"] != null:
			defended_attack_ids[get_data_key(pair["attack"])] = true

	# ----------- Check all visible attack cards (skip defended) -------------
	for attack_card in attack_nodes:
		if not attack_card:
			continue
		if not attack_card.visible:
			continue
		var data := attack_card.get_data()
		if not data:
			continue
		var data_id = get_data_key(data)
		if defended_attack_ids.has(data_id):
			continue  # skip defended attack cards
		var d := player_pos.distance_to(attack_card.global_position)
		if d < closest_dist:
			closest_dist = d
			closest_card = attack_card

	# ----------- Check transfer ghost -------------------------------
	var ghost := $TransferGhost
	if ghost.visible:
		var ghost_card := ghost.get_node_or_null("Card")
		if ghost_card:
			var d := player_pos.distance_to(ghost.global_position)
			if d < closest_dist:
				closest_card = ghost_card
				closest_dist = d

	return closest_card


func _apply_highlight(target: Card) -> void:
	# Turn off highlight on all attack and defense cards
	for c in attack_nodes:
		if c and c.visible:
			c.highlight = (c == target)

	for c in defense_nodes:
		if c and c.visible:
			c.highlight = false

	# ghost highlight
	var ghost := $TransferGhost
	if ghost.visible:
		var gcard := ghost.get_node_or_null("Card")
		var sprite := ghost.get_node_or_null("Sprite2D")
		if gcard:
			if gcard == target:
				gcard.highlight = true
				if sprite: sprite.modulate = Color(1, 1, 1, 0.9)
			else:
				gcard.highlight = false
				if sprite: sprite.modulate = Color(1, 1, 1, 0.5)


func clear_all_highlights() -> void:
	for c in attack_nodes:
		if c:
			c.highlight = false
	for c in defense_nodes:
		if c:
			c.highlight = false

	var ghost := $TransferGhost
	var gcard := ghost.get_node_or_null("Card")
	var sprite := ghost.get_node_or_null("Sprite2D")

	if gcard:
		gcard.highlight = false
	if sprite:
		sprite.modulate = Color(1, 1, 1, 0.5)


# ---------------------- Mouse Signals ------------------------
func _on_attack_drop_area_mouse_entered() -> void:
	if not UIManager.is_dragging:
		return
	UIManager.in_action_area = true

func _on_attack_drop_area_mouse_exited() -> void:
	UIManager.in_action_area = false
