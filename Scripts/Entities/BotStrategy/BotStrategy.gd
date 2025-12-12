extends Resource
class_name BotStrategy

## Base class for all bot strategies.
## Each strategy must implement get_move(player, table)

func get_move(player: Player) -> Dictionary:
	## Return a dictionary describing intended move
	## Example:
	## { "action": "attack", "card": some_card }
	push_error("BotStrategy.get_move() must be overridden")
	return {}
