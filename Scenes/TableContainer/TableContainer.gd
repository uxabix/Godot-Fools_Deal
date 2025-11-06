extends Node2D
class_name TableContainer

## Represents the card layout on the table.
## Supports up to 6 attacking cards, each optionally covered by a defending card.

@export var card_scene: PackedScene = preload("res://Scenes/Card/card.tscn")
@export var card_spacing: float = 120.0
@export var row_offset: float = 80.0
@export var defense_offset: float = 20.0
@export var max_rotation: float = 5 # Maximum card rotation in degrees
@export var min_rotation: float = -2 # Maximum card rotation in degrees

const MAX_PAIRS := 6

var pairs: Array[Dictionary] = [] # Array of { "attack": CardData, "defense": CardData }


func _ready() -> void:
	update_layout()


func add_attack(card: CardData) -> bool:
	if pairs.size() >= MAX_PAIRS:
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
