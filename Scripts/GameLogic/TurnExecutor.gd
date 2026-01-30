class_name TurnExecutor


var player: Player

func _init(owner: Player) -> void:
	player = owner

func parse_attack(turn: Dictionary) -> bool:
	if turn["action"] != TurnType.Type.ATTACK:
		print("IS NOT ATTACKING")
		return false
	
	if GameManager.play_attack_card(player, turn["card"]):
		assert(player.draw_card(turn["card"]))
		return true
	print("TurnExecutor: parse attack recieved GAMEMANAGER - FALSE; INVOKED BY, ", player.type, player.id)
	print("TurnExecutor: tried to play", CardData.cd.get_suit_name(turn["card"].suit), " ", CardData.cd.get_rank_name(turn["card"].rank))
	return false

func parse_defense(turn: Dictionary) -> bool:
	if turn["action"] != TurnType.Type.DEFENSE:
		return false
	for details in turn["data"]:
		if not GameManager.play_defense_card(player, details["defense"], details["index"]):
			return false
		assert(player.draw_card(details["defense"]))
		
	return true

func parse_pass(turn: Dictionary) -> bool:
	if turn["action"] != TurnType.Type.PASS:
		return false
	GameManager.set_player_state(player, PlayerState.Type.PASS)
	return true
	
func parse_take(turn: Dictionary) -> bool:
	if turn["action"] != TurnType.Type.TAKE_CARDS:
		return false
	GameManager.set_player_state(player, PlayerState.Type.TAKE_CARDS)
	return true

func parse_empty_hand(turn: Dictionary) -> bool:
	if turn["action"] != TurnType.Type.HAND_EMPTY:
		return false
	return true

func execute_turn(turn: Dictionary) -> bool:
	match turn["action"]:
		TurnType.Type.ATTACK:
			return parse_attack(turn)
		TurnType.Type.DEFENSE:
			return parse_defense(turn)
		TurnType.Type.PASS:
			return parse_pass(turn)
		TurnType.Type.TAKE_CARDS:
			return parse_take(turn)
		TurnType.Type.HAND_EMPTY:
			return parse_empty_hand(turn)
	return false
