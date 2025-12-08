extends BotStrategy
class_name EasyStrategy

## Very dumb strategy:
## - Attacks with the smallest non-trump card
## - Defends with the smallest possible card
## - Avoids complex logic

func get_move(player, game_state):
	var hand = player.hand

	if game_state.is_attack_turn(player):
		return _attack(hand)

	if game_state.is_defense_turn(player):
		return _defend(hand, game_state)

	return { "action": "pass" }


func _attack(hand):
	var candidates = []
	for c in hand:
		if not c.is_trump:
			candidates.append(c)

	if candidates.is_empty():
		candidates = hand

	candidates.sort_custom(func(a, b): return a.rank_value < b.rank_value)

	return {
		"action": "attack",
		"card": candidates[0]
	}


func _defend(hand, game_state):
	var attack_card = game_state.get_last_attack()

	var valid = []
	for c in hand:
		if c.can_beat(attack_card):
			valid.append(c)

	if valid.is_empty():
		return { "action": "take" }

	valid.sort_custom(func(a,b): return a.rank_value < b.rank_value)

	return {
		"action": "defend",
		"card": valid[0]
	}
