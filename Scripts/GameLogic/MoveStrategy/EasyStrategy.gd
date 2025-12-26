extends MoveStrategy
class_name EasyStrategy

## Very dumb strategy:
## - Attacks with the smallest non-trump card
## - Defends with the smallest possible card
## - Avoids complex logic

func play_move() -> Dictionary:
	var move := get_move()
	var result := executor.execute_turn(move)
	assert(result, "Can't execute turn! - %s" % move)
	return move

func get_move() -> Dictionary:
	var hand = player.hand
	if hand.is_empty():
		return { "action": TurnType.Type.HAND_EMPTY }
		
	if player in GameManager.players_attacking:
		return _attack(hand)

	if GameManager.player_defending:
		return _defend(player, hand)

	return { "action": TurnType.Type.PASS }


func _attack(hand: Array[CardData]):
	var candidates = []
	for c: CardData in hand:
		if c.suit != GameManager.trump:
			candidates.append(c)

	if candidates.is_empty():
		candidates = hand

	candidates.sort_custom(func(a, b): return a.rank_value < b.rank_value)

	return {
		"action": TurnType.Type.ATTACK,
		"card": candidates[0]
	}

func sort_cards_by_rank(cards: Array[CardData]) -> void:
	if cards.is_empty():
		return

	cards.sort_custom(func(a: CardData, b: CardData) -> bool:
		if a.suit == GameManager.trump and b.suit != GameManager.trump:
			return false
		if a.suit != GameManager.trump and b.suit == GameManager.trump:
			return true
		return a.rank < b.rank
	)

func _defend(player: Player, hand: Array[CardData]):
	var result = { "action": TurnType.Type.DEFENSE, "data": []}
	var attack_cards := GameManager.table.get_cards_to_defend()
	var remained_in_hand = hand.duplicate_deep()
	sort_cards_by_rank(remained_in_hand)
	for attack in attack_cards:
		var is_grabbing := true
		for in_hand in range(len(remained_in_hand)):
			if GameManager.ruleset.can_defend(player, remained_in_hand[in_hand], attack["attack"]):
				var data := {"defense": remained_in_hand[in_hand], "index": attack["index"]} 
				result["data"].append(data)
				remained_in_hand.remove_at(in_hand)
				is_grabbing = false
				break
		if is_grabbing:
			return {"action": TurnType.Type.TAKE_CARDS}
				
	return result
