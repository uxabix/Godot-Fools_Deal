extends MoveStrategy
class_name EasyStrategy

## Very dumb strategy:
## - Attacks with the smallest non-trump card
## - Defends with the smallest possible card
## - Avoids complex logic

func play_move() -> bool:
	await DelayService.wait(randf_range(.25, 1.2))
	var move := get_move()
	var result := executor.execute_turn(move)
	assert(result, "Can't execute turn! - %s" % move)
	
	return result

func get_move() -> Dictionary:
	var hand = player.hand
	if hand.is_empty():
		return { "action": TurnType.Type.HAND_EMPTY }
		
	if player in GameManager.players_attacking:
		return _attack(hand)

	if GameManager.player_defending:
		return _defend(player, hand)

	return { "action": TurnType.Type.PASS }

func _first_attack(hand: Array[CardData]) -> Array[CardData]:
	var candidates: Array[CardData] = []
	for c: CardData in hand:
		if c.suit != GameManager.trump:
			candidates.append(c)

	if candidates.is_empty():
		candidates = hand
	
	return candidates
	
func _attack_cards_on_table(hand: Array[CardData]) -> Array[CardData]:
	var available_ranks := GameManager.table.get_ranks_on_table()
	var candidates: Array[CardData] = []
	for card: CardData in hand:
		if card.rank in available_ranks:
			candidates.append(card)
		
	return candidates
	
func _attack(hand: Array[CardData]):
	var candidates: Array[CardData] = []
	if len(GameManager.table.pairs) <= 0:
		candidates = _first_attack(hand)
	else:
		candidates = _attack_cards_on_table(hand)
	sort_cards_by_rank(candidates)
	if len(candidates) <= 0 or GameManager.table.is_full():
		print("EasyStrategy: ", player.type, player.id, " is skipping an attack!")
		return {
			"action": TurnType.Type.PASS
		}
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
