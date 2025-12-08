extends Node

##
# Central game manager responsible for controlling
# the main game state, players, rules, and deck operations.
##
const cd = preload("res://Scripts/Utils/card_defines.gd")

var trump: cd.Suit = cd.Suit.DIAMONDS          ## Current trump suit for the game
var ruleset: RulesetBase = preload("res://Scripts/GameLogic/Rulesets/Variants/ClassicRuleset.gd").new()  ## Active game ruleset
var deck: Deck                                 ## Main deck used in the current game
var discard_pile: DiscardPile                  ## Pile for discarded cards
var table: Table
var table_container: TableContainer
var players: Array[Player] = []                ## List of all players (human and bots)
var current_player: Player
var players_attacking: Array[Player]
var player_defending: Player

##
# Creates and initializes players.
# @param player_count - number of human players
# @param bot_count - number of AI players
##
func set_players(player_count: int, bot_count: int = 0) -> void:
	for i in range(player_count + bot_count):
		var player: Player = Player.new()
		player.type = "Player" if i < player_count else "Bot"
		player.id = i
		players.append(player)

##
# Update trump suit for each player
##
func notify_players_trump():
	for player in players:
		player.trump = trump

##
# Starts a new game session.
# Initializes players, deck, ruleset, and deals cards.
##
func start_game() -> void:
	set_players(ruleset.common_options.players_count, ruleset.common_options.bot_count)
	current_player = players[0]
	players_attacking = [players[0]]
	player_defending = players[0]
	deck = Deck.new(ruleset)
	trump = deck.trump.suit
	notify_players_trump()
	discard_pile = DiscardPile.new()
	table = Table.new()
	table_container.table = table
	table_container.init()
	

	# Deal cards to each player
	for player in players:
		for i in range(ruleset.cards_in_hand):
			#if player == current_player:
				#var attack = CardData.new()
				#var defense = CardData.new()
				#defense.rank = cd.Rank.ACE
				#player.add_card(attack)
				#player.add_card(defense)
				#continue
			player.add_card(deck.draw_card())

func play_attack_card(player: Player, card: CardData) -> bool:
	return table.add_attack(player, card)
	
func play_defense_card(player: Player, card: CardData, attack_index: int) -> bool:
	return table.add_defense(player, card, attack_index)
