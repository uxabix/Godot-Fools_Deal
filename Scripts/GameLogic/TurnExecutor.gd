class_name TurnExecutor


var player: Player

func _init(owner: Player) -> void:
	player = owner

func parse_attack(turn: Dictionary) -> bool:
	if turn["action"] != TurnType.Type.ATTACK:
		return false
	
	return GameManager.play_attack_card(player, turn["card"])

func parse_defense(turn: Dictionary) -> bool:
	if turn["action"] != TurnType.Type.DEFENSE:
		return false
	for details in turn["data"]:
		if GameManager.play_defense_card(player, details["defense"], details["index"]):
			assert(player.draw_card(details["defense"]))
		else:
			return false
	return true

func parse_pass(turn: Dictionary) -> bool:
	if turn["action"] != TurnType.Type.PASS:
		return false
	return false
	
func parse_take(turn: Dictionary) -> bool:
	if turn["action"] != TurnType.Type.TAKE_CARDS:
		return false
	GameManager.set_player_state(player, PlayerState.Type.TAKE_CARDS)
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
			pass
	return false
