extends MoveStrategy
class_name PlayerStrategy


var card_played: CardData
var target: Dictionary

func play_move() -> Dictionary:
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
	var result := executor.execute_turn(move)
	card_played = null
	target = {}
	return move
