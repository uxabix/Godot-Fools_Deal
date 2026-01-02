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
	if only_neigbours:
		return [] # TODO
	if only_previous:
		var i := player_defending_index - 1
		if i < 0:
			i = len(players) - i
		return [players[i]]
	
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

func start_next_turn():
	player_defending_index += 1
	var player_attacking_index := player_defending_index - 1
	if player_defending_index >= len(players):
		player_defending_index = 0
		player_defending_index = len(players) - 1
	player_defending = players[player_defending_index]
	player_defending.state = PlayerState.Type.DEFEND
	players_attacking = [players[player_attacking_index]]
	update_players_attacking_state()

func set_player_state(player: Player, state: PlayerState.Type):
	player.state = state
	finish_turn()

func can_finish_turn():
	for player: Player in players:
		if player.state not in [PlayerState.Type.PASS,
								PlayerState.Type.LEFT,
								PlayerState.Type.TAKE_CARDS]:
			return false	
	return true

func finish_turn():
	print("Try finish turn")
	if not can_finish_turn():
		return
		
	print("Finish turn")
	
	for player: Player in players:
		player.state = PlayerState.Type.IDLE

func notify_defender():
	player_defending.play()
	finish_turn()
	
func notify_attackers():
	for player in players_attacking:
		set_player_state(player, PlayerState.Type.ATTACK)
	
func check_defended() -> bool:
	for pair in table.pairs:
		if pair["defense"] == null:
			return false
	
	player_defending.state = PlayerState.Type.PASS
	return true

func player_move():
	current_player.play()

func play_attack_card(player: Player, card: CardData) -> bool:
	var success : bool = table.add_attack(player, card)
	if success:
		set_player_state(player, PlayerState.Type.ATTACK)
		notify_defender()
	return success
	
func play_defense_card(player: Player, card: CardData, attack_index: int) -> bool:
	var success : bool = table.add_defense(player, card, attack_index)
	if success:
		notify_attackers()
		check_defended()
	return success
