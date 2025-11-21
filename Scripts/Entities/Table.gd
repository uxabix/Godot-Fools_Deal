extends Node
class_name Table

## Represents the logical card layout on the table.
## Supports up to 6 attacking cards, each optionally covered by a defending card.

const cd = preload("res://Scripts/Utils/card_defines.gd")

signal pairs_changed
signal ghost_changed

@export var max_pairs := 6

var ruleset: RulesetBase
var pairs: Array[Dictionary] = [] # { "attack": CardData, "defense": CardData }
var ranks_on_table: Array[cd.Rank] = []
var ghost_data: CardData = null

func _init() -> void:
	ruleset = GameManager.ruleset

# ---------------------- Attack / Defense ----------------------
func add_attack(player: Player, card: CardData) -> bool:
	if not ruleset.can_attack(player, card, len(pairs), max_pairs, ranks_on_table):
		return false
	if pairs.size() >= max_pairs:
		return false
	pairs.append({ "attack": card, "defense": null })
	ranks_on_table.append(card.rank)
	emit_signal("pairs_changed")
	emit_signal("ghost_changed")
	return true

func add_defense(player: Player, card: CardData, attack_index: int) -> bool:
	if attack_index < 0 or attack_index >= pairs.size():
		return false
	if pairs[attack_index]["defense"] != null:
		return false
	if not ruleset.can_defend(player, card, pairs[attack_index]["attack"]):
		return false
	pairs[attack_index]["defense"] = card
	ranks_on_table.append(card.rank)
	emit_signal("pairs_changed")
	emit_signal("ghost_changed")
	return true

func clear() -> void:
	pairs.clear()
	ranks_on_table.clear()
	ghost_data = null
	emit_signal("pairs_changed")
	emit_signal("ghost_changed")

# ---------------------- Transfer Ghost ------------------------
func get_can_transfer() -> bool:
	if not ruleset.translated_mode or pairs.size() < 1:
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

	ghost_data = CardData.new()
	ghost_data.rank = rank
	var remained_suits = cd.ALL_SUITS.filter(func(x): return x not in suits)
	ghost_data.suit = remained_suits.pick_random()
	return true

func set_ghost_appearance() -> void:
	if not get_can_transfer():
		ghost_data = null
	emit_signal("ghost_changed")
