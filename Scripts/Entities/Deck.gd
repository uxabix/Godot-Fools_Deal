extends Node
class_name Deck

##
# Represents the deck of cards in the game.
# Responsible for storing, shuffling, and drawing cards.
##

signal deck_update()

var cards: Array[CardData] = []
var trump: CardData;

# Initializes the deck based on a ruleset
func _init(ruleset):
	cards.clear()
	for suit in ruleset.suits:
		for rank in ruleset.ranks:
			var card = CardData.new()
			card.suit = suit
			card.rank = rank
			cards.append(card)
	cards.shuffle()
	trump = cards[0]

# Draws the top card from the deck
func draw_card() -> Variant:
	var res = cards.pop_back() 
	deck_update.emit()
	return res

# Shuffles the deck
func shuffle() -> void:
	cards.shuffle()

# Returns the number of remaining cards
func size() -> int:
	return cards.size()
