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
var only_neigbours_can_attack = false ## No functionality for true state yet TODO

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
	deal_cards()

func deal_cards() -> bool: # Return false if deck is empty or deck is not initialized
	print("GM.deal_cards: called!")
	if deck == null:
		print("GM.deal_cards: deck not initialized!")
		return false
	# Deal cards to each player
	var dealing_order = get_attacking_players(true) # First attacker is first to get cards
	var other_attckers = get_attacking_players(false, only_neigbours_can_attack)
	other_attckers.erase(dealing_order[0])
	dealing_order += other_attckers
	dealing_order.append(player_defending)
	for player: Player in dealing_order:
		for i in range(ruleset.cards_in_hand - player.get_cards_count()):
			if player.get_cards_count() >= ruleset.cards_in_hand:
				break
			var card = deck.draw_card()
			if card == null:
				return false
			player.add_card(card)
	if deck.size() <= 0:
		return false
	return true

func update_players_attacking_state(ignore_player : Player = null):
	for player in players_attacking:
		if player == ignore_player:
			continue
		player.state = PlayerState.Type.ATTACK

func next_defender():
	print("GM.next_defender: Next defender invoked!")
	player_defending_index += 1
	if player_defending_index >= len(players):
		player_defending_index = 0
	player_defending = players[player_defending_index]
	player_defending.state = PlayerState.Type.DEFEND

func next_attackers(only_previous:=true, only_neigbours:=false, ignore_player : Player = null):
	players_attacking = get_attacking_players(only_previous, only_neigbours)
	update_players_attacking_state(ignore_player)

func invoke_attackers(ignore_player: Player = null):
	for player: Player in players_attacking:
		if player == ignore_player:
			continue
		var res = player.play()
		print("GM.invoke_attackers: Invoked attacker ", player.id, ", result:", res)

func start_next_turn():
	deal_cards()
	next_defender()
	next_attackers()
	invoke_attackers()

func set_player_state(player: Player, state: PlayerState.Type, ignore_invoking: bool = false) -> bool:
	print("GM.set_player_state: An attempt to change ", player.type, player.id,
	 " state from ", PlayerState.get_state(player.state), " TO ", PlayerState.get_state(state))
	if state == PlayerState.Type.TAKE_CARDS and player != player_defending:
		return false
	if state == PlayerState.Type.TAKE_CARDS and all_cards_defended():
		return false
	if state == PlayerState.Type.PASS and player == player_defending:
		return false
		
	player.state = state
	if not ignore_invoking and \
	 state == PlayerState.Type.PASS and \
	 player in players_attacking and len(players_attacking) <= 1:
		print("GM.set_player_state: First attacker's transition to PASS, invoking other players. Called by ", player.type, player.id)
		next_attackers(false, only_neigbours_can_attack, player)
		print("GM.set_player_state: New attackers: ", players_attacking)
		invoke_attackers(player)
		
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
		
	print("GM.finish_turn: Finish turn")
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
		
func print_states():
	for p in players:
		print("GM.print_states: Player state! ", p.type, p.id, " ", PlayerState.get_state(p.state))
