@tool
extends Node

# -----------------------------------------------------------------------------
# Card Defines
# -----------------------------------------------------------------------------
# This script provides enumerations, constants, and helper functions
# used across the card game system. It acts as a centralized "card library"
# for defining card types, suits, ranks, and utility methods.
# -----------------------------------------------------------------------------

# Enumeration of card types (can be extended for custom rules).
enum Type {
	NORMAL,   # Standard card
	TRUMP,    # Trump card (depending on game rules)
	SPECIAL   # Special card (e.g., jokers or custom mechanics)
}

# Enumeration of suits in a standard deck.
enum Suit {
	HEARTS,
	DIAMONDS,
	CLUBS,
	SPADES
}

# The first numeric value of a card (used for indexing ranks).
const FIRST_CARD_VALUE = 2

# Enumeration of card ranks.
# This assumes a standard deck from "Two" up to "Ace".
enum Rank {
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIX,
	SEVEN,
	EIGHT,
	NINE,
	TEN,
	JACK,
	QUEEN,
	KING,
	ACE
}

# Total number of numeric cards before face cards.
const NUMBERS = 9

# Patterns used to represent pips for numeric cards.
# Each sub-array defines a distribution of suit symbols
# (similar to the layout on traditional playing cards).
static var patterns = [
	[0, 0, 0,
	 1, 0, 1,
	 0, 0, 0,
	 0],
	[0, 0, 0,
	 1, 1, 1,
	 0, 0, 0,
	 0],
	[0, 0, 0,
	 1, 1, 1,
	 0, 1, 0,
	 0],
	[0, 1, 0,
	 1, 1, 1,
	 0, 1, 0,
	 0],
	[1, 0, 1,
	 0, 1, 0,
	 1, 1, 1,
	 0],
	[1, 0, 1,
	 1, 1, 1,
	 1, 0, 1,
	 0],
	[1, 1, 1,
	 1, 0, 1,
	 1, 0, 1,
	 1],
	[1, 1, 1,
	 1, 0, 1,
	 1, 1, 1,
	 1],
	[1, 1, 1,
	 1, 1, 1,
	 1, 1, 1,
	 1],
	[1, 1, 1,
	 1, 1, 1,
	 1, 1, 1,
	 1],
	[1, 1, 1,
	 1, 1, 1,
	 1, 1, 1,
	 1],
	[1, 1, 1,
	 1, 1, 1,
	 1, 1, 1,
	 1],
	[0, 0, 0,
	 0, 1, 0,
	 0, 0, 0,
	 0],
]

# Convenience arrays for iterating over all suits and ranks.
const ALL_SUITS: Array[Suit] = [Suit.HEARTS, Suit.DIAMONDS, Suit.CLUBS, Suit.SPADES]
const ALL_RANKS: Array[Rank] = [
	Rank.TWO, Rank.THREE, Rank.FOUR, Rank.FIVE, Rank.SIX,
	Rank.SEVEN, Rank.EIGHT, Rank.NINE, Rank.TEN,
	Rank.JACK, Rank.QUEEN, Rank.KING, Rank.ACE
]

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

# Returns the human-readable name of a suit.
static func get_suit_name(suit: Suit) -> String:
	match suit:
		Suit.HEARTS: return "Hearts"
		Suit.CLUBS: return "Clubs"
		Suit.SPADES: return "Spades"
		Suit.DIAMONDS: return "Diamonds"
		_: return ""

# Returns the human-readable name of a rank.
static func get_rank_name(rank: Rank) -> String:
	match rank:
		Rank.JACK: return "Jack"
		Rank.QUEEN: return "Queen"
		Rank.KING: return "King"
		Rank.ACE: return "Ace"
		_: return ""  # Numeric cards return an empty string by default

static func get_suit_image(suit: Suit) -> String:
	return "res://Assets/Textures/Cards/Suits/" + get_suit_name(suit) + "/Suit.png"

static func get_rank_image(suit: Suit, rank: Rank) -> String:
	return "res://Assets/Textures/Cards/Suits/" + get_suit_name(suit) + "/Ranks/" + get_rank_name(rank) + ".png"

# -----------------------------------------------------------------------------
# Constants for Visual Assets
# -----------------------------------------------------------------------------

# Defines which ranks have dedicated textures (face cards).
const HAS_TEXTURE = [Rank.JACK, Rank.QUEEN, Rank.KING]
