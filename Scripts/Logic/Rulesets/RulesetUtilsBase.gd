class_name RulesetUtilsBase
extends Resource


const cd = preload("res://Scripts/Utils/card_defines.gd")


static func get_ranks(cards_count: int) -> Array[cd.Rank]:
	if cards_count < 24 or cards_count > 52: return []
	var start
	match cards_count:
		24:
			start = cd.ALL_RANKS.find(cd.Rank.NINE)
		36:
			start = cd.ALL_RANKS.find(cd.Rank.SIX)
		52:
			start = cd.ALL_RANKS.find(cd.Rank.TWO)
		_:
			start = 0
	return cd.ALL_RANKS.slice(start)
