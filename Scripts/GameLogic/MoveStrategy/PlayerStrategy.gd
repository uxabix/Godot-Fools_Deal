extends MoveStrategy
class_name PlayerStrategy


var card_played: CardData
var target: Dictionary

func play_move() -> bool:
	var move: Dictionary
	if not card_played:
		move = { }
	elif target.is_empty():
		move = {
			"action": TurnType.Type.ATTACK,
			"card": card_played
		}
	else:
		move =  { 
			"action": TurnType.Type.DEFENSE,
			"data": [{"defense": card_played, "index": target["index"]} ]
		}
	card_played = null
	target = {}
	var result := false
	if move:
		result = executor.execute_turn(move)
	else:
		print("Waiting for player!")
	return result
