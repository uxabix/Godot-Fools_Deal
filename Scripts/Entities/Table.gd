extends Node
class_name Table

## Represents the logical card layout on the table.
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
var max_pairs_this_turn := max_pairs
var pairs: Array[Dictionary] = [] # Array of { "attack": CardData, "defense": CardData }
var ranks_on_table: Array[cd.Rank] = []
var ghost_data: CardData = CardData.new()

func _init() -> void:
	ruleset = GameManager.ruleset

func add_attack(player: Player, card: CardData) -> bool:
	if not ruleset.can_attack(player, card, len(pairs), max_pairs_this_turn, ranks_on_table):
		return false
	if pairs.size() >= max_pairs:
		return false
	pairs.append({ "attack": card, "defense": null })
	ranks_on_table.append(card.rank)
	return true

func add_defense(player: Player, card: CardData, attack_index: int) -> bool:
	if not ruleset.can_defend(player, card, pairs[attack_index]["attack"]):
		return false
	if attack_index < 0 or attack_index >= pairs.size():
		return false
	if pairs[attack_index]["defense"] != null:
		return false
	pairs[attack_index]["defense"] = card
	ranks_on_table.append(card.rank)
	return true

func clear() -> void:
	pairs.clear()
	ranks_on_table.clear()

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

# Probably should be changed so it'll return the card data of ghost
# and TableContainer will set it up accordingly
func set_ghost_appearance() -> void:
	if not get_can_transfer():
		return
	
