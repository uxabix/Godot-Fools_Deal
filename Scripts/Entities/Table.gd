extends Node
class_name Table

## Represents the logical card layout on the table.
## Supports up to 6 attacking cards, each optionally covered by a defending card.

const cd = preload("res://Scripts/Utils/card_defines.gd")

signal pairs_changed
signal ghost_changed

const DEBUG = false

var max_pairs := 6

var ruleset: RulesetBase
var pairs: Array[Dictionary] = [] # Array of { "attack": CardData, "defense": CardData }
var ranks_on_table: Array[cd.Rank] = []
var ghost_data: CardData = null


func on_any_change(event: String = "Any") -> void:
	if not DEBUG: return
	print("-------------")
	print(event)
	print(pairs)

func _init() -> void:
	# assume GameManager.ruleset exists and is initialized before Table
	ruleset = GameManager.ruleset

# ---------------------- Attack / Defense ----------------------
# player param is required so ruleset.can_attack/can_defend can use it.
func add_attack(player: Player, card: CardData) -> bool:
	if not ruleset.can_attack(player, card, len(pairs), max_pairs, ranks_on_table):
		return false
	if pairs.size() >= max_pairs:
		return false
	pairs.append({ "attack": card, "defense": null })
	ranks_on_table.append(card.rank)
	emit_signal("pairs_changed")
	emit_signal("ghost_changed")
	on_any_change("Add attack")
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
	on_any_change("Add defense")
	return true
	
# return an array of { "attack": CardData, "index": attack_index, }
func get_cards_to_defend() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pair_i in range(len(pairs)):
		if pairs[pair_i]["defense"] == null:
			var data := {
				"attack": pairs[pair_i]["attack"],
				"index": pair_i,
			} 
			result.append(data)
	
	return result

func clear() -> void:
	pairs.clear()
	ranks_on_table.clear()
	ghost_data = null
	emit_signal("pairs_changed")
	emit_signal("ghost_changed")
	on_any_change("Clear")

# ---------------------- Transfer Ghost ------------------------
# Determines if transfer is allowed and prepares ghost_data accordingly.
func get_can_transfer() -> bool:
	if not ruleset.translated_mode or pairs.size() < 1:
		ghost_data = null
		return false
	for pair in pairs:
		if pair["defense"]:
			ghost_data = null
			return false

	var rank: cd.Rank = pairs[0]["attack"].rank
	var suits: Array[cd.Suit] = []
	for pair in pairs:
		# all attacks must have same rank
		if pair["attack"].rank != rank:
			ghost_data = null
			return false
		suits.append(pair["attack"].suit)

	ghost_data = CardData.new()
	ghost_data.rank = rank
	var remained_suits = cd.ALL_SUITS.filter(func(x): return x not in suits)
	ghost_data.suit = remained_suits.pick_random()
	return true

# Sets ghost appearance state (updates ghost_data if necessary and emits)
func set_ghost_appearance(emmiter: String = "self") -> void:
	# get_can_transfer will set ghost_data appropriately or null it
	get_can_transfer()
	if emmiter != "self":
		return
	emit_signal("ghost_changed")

# Convenience accessors for external callers
func get_pairs() -> Array:
	# return shallow copy - caller should not modify original
	return pairs.duplicate()

func get_ghost_data() -> CardData:
	return ghost_data

func get_ranks_on_table() -> Array:
	var result := []
	for pair in pairs:
		if pair["defense"]:
			result.append(pair["defense"].rank)
		result.append(pair["attack"].rank)
	return result
