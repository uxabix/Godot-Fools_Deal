extends Node
class_name Deck

##
# Represents the deck of cards in the game.
# Responsible for storing, shuffling, and drawing cards.
##

var cards: Array[CardData] = []

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

# Draws the top card from the deck
func draw_card() -> CardData:
	return null if cards.is_empty() else cards.pop_back() 

# Returns first card in deck (Trump in classical rules)
func get_first() -> CardData:
	return null if cards.is_empty() else cards[0]

# Shuffles the deck
func shuffle() -> void:
	cards.shuffle()

# Returns the number of remaining cards
func size() -> int:
	return cards.size()
