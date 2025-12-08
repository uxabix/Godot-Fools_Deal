class_name CommonOptions
extends Resource


var cards_count: int = 36
var players_count: int = 1
var bot_count: int = 1


func _init(cards: int = 36, players: int = 1, bots: int = 1) -> void:
	cards_count = cards
	players_count = players
	bot_count = bots
