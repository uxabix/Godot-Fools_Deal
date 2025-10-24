class_name CardData
extends Resource

##
# Represents a single card with suit, rank, and special attributes.
# Used for logical representation of cards across the game.
##
const cd = preload("res://Scripts/Utils/card_defines.gd")

@export var suit: cd.Suit      ## The suit of the card (hearts, spades, etc.)
@export var rank: cd.Rank      ## The rank of the card (6, 7, 8, ..., Ace)
@export var special: bool = false  ## Whether this card has special behavior or effects
