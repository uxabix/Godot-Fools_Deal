extends Resource
class_name MoveStrategy

## Base class for all playing strategies.
## Each strategy must implement get_move(player, table)

var player: Player
var executor: TurnExecutor

func _init(owner: Player) -> void:
	player = owner
	executor = TurnExecutor.new(player)

func play_move() -> bool:
	## Play best posible move with current strategy and
	## return a 
	## Example:
	## { "action": "attack", "card": some_card }
	push_error("BotStrategy.get_move() must be overridden")
	return false

func get_move() -> Dictionary:
	## Return a dictionary describing intended move
	## Example:
	## { "action": "attack", "card": some_card }
	push_error("BotStrategy.get_move() must be overridden")
	return {}
