@abstract
class_name RulesetBase
extends Resource

##
# Base class defining the core rules for different game modes.
# Provides methods for attack, defense, and transfer conditions.
##
const cd = preload("res://Scripts/Utils/card_defines.gd")

var name: String = "Classic"            ## Name of the rule set
var cards_in_hand: int = 6              ## Number of cards each player starts with
var translated_mode: bool = false       ## Whether the mode supports card transfers
var use_jokers: bool = false            ## Whether jokers are included
var suits: Array[cd.Suit] = cd.ALL_SUITS
var ranks: Array[cd.Rank]

var min_players: int = 2 ## Minimal count of players to start a game

var common_options: CommonOptions
var utils: Resource = RulesetUtilsBase


func init_basics(cards_count: int = 36, players_count: int = 1, bot_count: int = 1) -> void:
	ranks = utils.get_ranks(cards_count)
	common_options = CommonOptions.new(cards_count, players_count, bot_count)
	

func _init(cards_count: int = 36, players_count: int = 1, bot_count: int = 1) -> void:
	if players_count + bot_count < min_players: return
	init_basics(cards_count)


##
# Determines if a card can be transferred (used in translation mode).
# @param card - the card being considered for transfer
# @param attack_cards - the list of cards already in attack
##
func can_transfer(card: CardData, attack_cards: Array[CardData]) -> bool:
	var rank: cd.Rank = attack_cards[0].rank
	var flag: bool = true
	for i in attack_cards:
		if i.rank != rank:
			flag = false
			break
	flag = flag and card.rank == rank
	
	return translated_mode and flag


##
# Determines if a card can be played as an attack in the current context.
# By default, all cards can attack.
##
func can_attack(defense_card: CardData, attack_card: CardData, trump: cd.Suit) -> bool:
	if defense_card.suit != trump and defense_card.suit != attack_card.suit:
		return false
		
	return defense_card.rank > attack_card.rank
