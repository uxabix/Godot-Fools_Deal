class_name ClassicRuleset
extends RulesetBase


##
# Classic ruleset — no card translation.
# Uses a standard 36-card deck without jokers.
##
func _init(cards_count: int = 36, players_count: int = 1, bot_count: int = 1):
	super._init(cards_count, players_count, bot_count)
	name = "Classic"
	cards_in_hand = 6
	translated_mode = false
	use_jokers = false
	suits = cd.ALL_SUITS
	
	#ranks =  ## REPLACE

##
# In classic rules, transferring cards is not allowed.
##
func can_transfer(card, attack_card) -> bool:
	return false
