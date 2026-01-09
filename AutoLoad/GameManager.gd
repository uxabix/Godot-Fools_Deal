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

var current_player_index := 0
var player_defending_index := 0

var FINISH_PLAYER_STATES = [PlayerState.Type.PASS,
							PlayerState.Type.LEFT,
							PlayerState.Type.TAKE_CARDS]

##
# Creates and initializes players.
# @param player_count - number of human players
# @param bot_count - number of AI players
##
func set_bot(player: Player):
	player.type = "Bot"
	player.strategy = EasyStrategy.new(player)

func set_player(player: Player):
	player.type = "Player"
	player.strategy = PlayerStrategy.new(player)

func set_players(player_count: int, bot_count: int = 0) -> void:
	for i in range(player_count + bot_count):
		var player: Player = Player.new()
		player.id = i
		if i < player_count:
			set_player(player)
		else:
			set_bot(player)
		players.append(player)

##
# Update trump suit for each player
##
func notify_players_trump():
	for player in players:
		player.trump = trump

func get_attacking_players(only_previous:=true, only_neigbours:=false) -> Array[Player]:
	if only_previous:
		var i := player_defending_index - 1
		if i < 0:
			i = len(players) - 1
		return [players[i]]
	if only_neigbours:
		return [] # TODO
	
	# !!! TODO current functionality also includes players that already won! CHANGE!
	var result = players.duplicate_deep()
	result.remove_at(player_defending_index)
	return result

##
# Starts a new game session.
# Initializes players, deck, ruleset, and deals cards.
##
func start_game() -> void:
	set_players(ruleset.common_options.players_count, ruleset.common_options.bot_count)
	current_player = players[current_player_index]
	start_next_turn()
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

func update_players_attacking_state():
	for player in players_attacking:
		player.state = PlayerState.Type.ATTACK
		
func update_attacking_players(only_neighbours:=false):
	players_attacking = get_attacking_players(only_neighbours)

func next_defender():
	print("Next defender invoked!")
	player_defending_index += 1
	if player_defending_index >= len(players):
		player_defending_index = 0
	player_defending = players[player_defending_index]
	player_defending.state = PlayerState.Type.DEFEND

func next_attackers(only_previous:=true, only_neigbours:=false):
	players_attacking = get_attacking_players(only_previous, only_neigbours)
	update_players_attacking_state()

func invoke_attackers():
	for player: Player in players_attacking:
		print(player.play())

func start_next_turn():
	next_defender()
	next_attackers()
	invoke_attackers()

func set_player_state(player: Player, state: PlayerState.Type) -> bool:
	print(player.type, " ", state)
	if state == PlayerState.Type.TAKE_CARDS and player != player_defending:
		return false
	if state == PlayerState.Type.TAKE_CARDS and all_cards_defended():
		return false
	if state == PlayerState.Type.PASS and player == player_defending:
		return false
	player.state = state
	finish_turn()
	return true

func all_cards_defended() -> bool:
	if len(table.pairs) <= 0:
		return false
	if len(table.get_cards_to_defend()) > 0:
		return false
	return true
	
func can_finish_turn():
	for player: Player in players:
		if player.state == PlayerState.Type.DEFEND and all_cards_defended():
			continue
		if player.state not in FINISH_PLAYER_STATES:
			return false
	return true

func finish_turn():
	if not can_finish_turn():
		return
		
	print("Finish turn")
	table.clear()
	start_next_turn()

func notify_defender():
	player_defending.play()
	finish_turn()
	
func notify_attackers():
	for player in players_attacking:
		set_player_state(player, PlayerState.Type.ATTACK)
	invoke_attackers()

func player_move():
	current_player.play()

func play_attack_card(player: Player, card: CardData) -> bool:
	var success : bool = table.add_attack(player, card)
	if success:
		set_player_state(player, PlayerState.Type.ATTACK)
	return success
	
func play_defense_card(player: Player, card: CardData, attack_index: int) -> bool:
	var success : bool = table.add_defense(player, card, attack_index)
	if success:
		all_cards_defended()
	return success

func notify_players_after_move(player: Player):
	if player.state == PlayerState.Type.ATTACK:
		return notify_defender()
	if player.state == PlayerState.Type.DEFEND:
		return notify_attackers()
