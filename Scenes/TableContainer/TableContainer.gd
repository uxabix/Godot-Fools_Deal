extends Node2D
class_name TableContainer

## Represents the card layout on the table.
## Supports up to 6 attacking cards, each optionally covered by a defending card.

# Preload definitions containing enums and helper utilities for suits/ranks
const cd = preload("res://Scripts/Utils/card_defines.gd")

@export var card_scene: PackedScene = preload("res://Scenes/Card/card.tscn")
@export var card_spacing: float = 120.0
@export var row_offset: float = 80.0
@export var defense_offset: float = 20.0
@export var max_rotation: float = 5 # Maximum card rotation in degrees
@export var min_rotation: float = -2 # Minimum card rotation in degrees

var ruleset: RulesetBase

var max_pairs := 6

var pairs: Array[Dictionary] = [] # Array of { "attack": CardData, "defense": CardData }
var ghost_data: CardData = CardData.new()

func _ready() -> void:
	ruleset = GameManager.ruleset
	update_layout()
	_update_attack_drop_area()

func add_attack(card: CardData) -> bool:
	if pairs.size() >= max_pairs:
		return false
	pairs.append({ "attack": card, "defense": null })
	update_layout()
	return true


func add_defense(attack_index: int, card: CardData) -> bool:
	if attack_index < 0 or attack_index >= pairs.size():
		return false
	if pairs[attack_index]["defense"] != null:
		return false
	pairs[attack_index]["defense"] = card
	update_layout()
	return true


func clear_containers() -> void:
	for container in [$AttackContainer, $DefenseContainer]:
		for child in container.get_children():
			child.queue_free()


func clear() -> void:
	clear_containers()
	pairs.clear()


## Helper — calculates X position for cards in a centered row
func calc_x(index: int, count: int) -> float:
	if count <= 1:
		return 0.0
	var total_width = (count - 1) * card_spacing
	return -total_width / 2.0 + index * card_spacing

@warning_ignore("shadowed_variable")
func get_random_rotation(min_rotation: float, max_rotation: float) -> float:
	var random_degrees = randf_range(min_rotation, max_rotation)
	return deg_to_rad(random_degrees)


func update_layout() -> void:
	if not is_inside_tree():
		return

	clear_containers()

	var total_cards := pairs.size()
	if total_cards == 0:
		return

	var first_row_count = min(total_cards, 3)
	var second_row_count = max(0, total_cards - 3)

	for i in range(total_cards):
		var pair = pairs[i]
		var row = i / 3
		var index_in_row = i % 3

		var count_in_row =  first_row_count if row == 0 else second_row_count
		var pos_x = calc_x(index_in_row, count_in_row)
		var pos_y = -row_offset / 2.0 if row == 0 else row_offset / 2.0
		# Attack card
		if pair["attack"]:
			var attack_card: Card = card_scene.instantiate()
			attack_card.collision = false
			attack_card.init(pair["attack"])
			attack_card.position = Vector2(pos_x, pos_y)
			attack_card.rotation = -get_random_rotation(min_rotation, max_rotation)
			$AttackContainer.add_child(attack_card)

		# Defense card
		if pair["defense"]:
			var defense_card = card_scene.instantiate()
			defense_card.collision = false
			defense_card.init(pair["defense"])
			defense_card.position = Vector2(pos_x + defense_offset, pos_y + defense_offset)
			defense_card.rotation = get_random_rotation(min_rotation, max_rotation)
			$DefenseContainer.add_child(defense_card)
			
	update_transfer_ghost(true)

func _update_attack_drop_area() -> void:
	var shape := $AttackDropArea.get_node("CollisionShape2D")
	if not shape:
		return

	# Calculate approximate width and height of table size
	var width := (3 * card_spacing) * 2
	var height := row_offset * 3.0
	var rect := RectangleShape2D.new()
	rect.extents = Vector2(width * 0.5, height * 0.5)
	shape.shape = rect
	$AttackDropArea.position = Vector2(0, 0)

func get_can_transfer() -> bool:
	if not ruleset.translated_mode or len(pairs) < 1:
		return false
	
	# check if there's not defense cards on table
	for pair: Dictionary in pairs:
		if pair["defense"]:
			return false
	
	# check if all attack cards on table have the same rank and save their suit
	var rank: cd.Rank = pairs[0]["attack"].rank
	var suits: Array[cd.Suit]
	for pair: Dictionary in pairs:
		if pair["attack"].rank != rank:
			return false
		suits.append(pair["attack"].suit)
		
	ghost_data.rank = rank
	# Get random suit except those on table
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

	if not enabled or pairs.is_empty():
		return

	var last_index = pairs.size() - 1
	var row = last_index / 3
	var index_in_row = last_index % 3
	var count_in_row = min(pairs.size(), 3)
	var pos_x = calc_x(index_in_row, count_in_row) + card_spacing
	var pos_y = -row_offset / 2.0 if row == 0 else row_offset / 2.0

	ghost.position = Vector2(pos_x, pos_y)

	var sprite := ghost.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate.a = 0.5
