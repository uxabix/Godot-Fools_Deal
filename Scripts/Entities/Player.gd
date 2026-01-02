extends Node
class_name Player

signal move_evoked(player_id: int)

##
# Represents a player entity in the game.
# Holds player-related data such as hand, state, and strategy.
##

const cd = preload("res://Scripts/Utils/card_defines.gd")

var player_name: String                 ## Player display name
var id                                  ## Player unique identifier
var type                                ## Type of player (human, AI, etc.) # TODO Replace strings with an enum
var state: PlayerState.Type = PlayerState.Type.IDLE ## Current player state (IDLE, ATTACK, DEFEND, ...)
var strategy: MoveStrategy               ## Move strategy logic
var hand: Array[CardData]               ## Cards currently held by the player
var trump: cd.Suit                      ## Trump suit in cuurent game, used in sort_hand


func play() -> Dictionary:
	var result := strategy.play_move()
	move_evoked.emit(id)
	return result

##
# Sorts the player's hand based on suit and rank.
# Trump suit cards are grouped separately and placed at the end.
##
func sort_hand() -> void:
	if hand.is_empty():
		return

	# Get suit and rank order arrays from card_defines
	var suit_order: Array = cd.ALL_SUITS.duplicate()
	var rank_order: Array = cd.ALL_RANKS.duplicate()

	# Move trump suit to the end of suit_order for proper sorting
	suit_order.erase(trump)
	suit_order.append(trump)

	# Define custom sort comparator
	hand.sort_custom(func(a: CardData, b: CardData) -> bool:
		if a.suit == b.suit:
			# Compare by rank index if suits are equal
			return rank_order.find(a.rank) < rank_order.find(b.rank)
		else:
			# Compare by suit order (non-trump suits first)
			return suit_order.find(a.suit) < suit_order.find(b.suit)
	)


func add_card(card: CardData):
	hand.append(card)
	sort_hand()
	
func draw_card(card: CardData) -> bool:
	for c_i in len(hand):
		if card.equals(hand[c_i]):
			hand.pop_at(c_i)
			sort_hand()
			return true
	
	return false
