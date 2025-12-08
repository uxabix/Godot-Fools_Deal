class_name TransferRuleset
extends RulesetBase

##
# Transfer ruleset — allows passing the attack if possible.
# Still uses a 36-card deck without jokers.
##
func _init(cards_count: int = 36, players_count: int = 1, bot_count: int = 1):
	super._init(cards_count, players_count, bot_count)
	name = "Translated"
	cards_in_hand = 6
	translated_mode = true
	use_jokers = false
	suits = cd.ALL_SUITS
	ranks = cd.ALL_RANKS.slice(4)
