extends Node2D
class_name GameTable

# ------------------------------------------------------------------------------
# GameTable
# Handles the visual representation of the main card table, including:
# - Displaying the deck and trump card.
# - Managing previews and updating the deck layout.
# - Initializing the game state and player UI references.
# ------------------------------------------------------------------------------

# Preload definitions containing enums and helper utilities for suits/ranks
const cd = preload("res://Scripts/Utils/card_defines.gd")

@export var player_card_appearance: CardAppearanceData = preload("res://Scripts/Entities/Resources/CardAppearance/Variants/Player.tres")
@export var enemy_card_appearance: CardAppearanceData = preload("res://Scripts/Entities/Resources/CardAppearance/Variants/Enemy.tres")
@export var hand_container: PackedScene = preload("res://Scenes/HandContainer/HandContainer.tscn")
@export var enemy_hand_container_data: HandContainerData = preload("res://Scripts/Entities/Resources/HandContainer/Variants/EnemyHand.tres")

@export var deck: Node;

@export var show_enemy_cards: bool = true ## Enable in game drawing of enemy cards faces (Debug)

# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------

func clear_enemy_hand_container():
	for child in $CanvasLayer/EnemyContainer/EnemyHandContainer.get_children():
		if child is HandContainer:
			$CanvasLayer/EnemyContainer/EnemyHandContainer.remove_child(child)

func create_container(player: Player) -> Node:
	var enemy_hand := hand_container.instantiate()
	enemy_hand.player = player
	enemy_hand.data = enemy_hand_container_data
	enemy_hand.appearance = enemy_card_appearance
	$CanvasLayer/EnemyContainer/EnemyHandContainer.add_child(enemy_hand)

	return enemy_hand

func draw_cards(container: Node):
	var player : Player = container.player
	container.set_cards(player.hand)

func draw_players():
	clear_enemy_hand_container()
	for player in GameManager.players:
		if player == GameManager.current_player: continue
		var hand = create_container(player)
		draw_cards(hand)
		

func test_table_container() -> void:
	var cardAttack = CardData.new()
	cardAttack.rank = cd.Rank.THREE
	cardAttack.suit = cd.Suit.DIAMONDS
	var cardDefense = CardData.new()
	cardDefense.rank = cd.Rank.KING
	cardDefense.suit = cd.Suit.SPADES
	
	for i in range(6):
		$CanvasLayer/ContainerControl/TableContainer.add_attack(cardAttack)
	for i in range(0):
		$CanvasLayer/ContainerControl/TableContainer.add_defense(i, cardDefense)

func update_players_state():
	$CanvasLayer/Label.text = ""
	for container: HandContainer in $CanvasLayer/EnemyContainer/EnemyHandContainer.get_children():
		$CanvasLayer/Label.text += str(container.player.id) + ": "
		$CanvasLayer/Label.text += PlayerState.get_state(container.player.state)
		$CanvasLayer/Label.text += " "
	$CanvasLayer/Label.text += "Player: "
	$CanvasLayer/Label.text += PlayerState.get_state(GameManager.current_player.state)

# Called once when the node enters the scene tree
func _ready() -> void:
	GameManager.table_container = $CanvasLayer/ContainerControl/TableContainer
	UIManager.remove_preview_nodes(self)
	UIManager.player_hand = $CanvasLayer/PlayerHand/HandContainer
	UIManager.table = $CanvasLayer/ContainerControl/TableContainer
	
	GameManager.start_game()
	$CanvasLayer/PlayerHand/HandContainer.appearance = player_card_appearance
	$CanvasLayer/PlayerHand/HandContainer.player = GameManager.current_player
	#
	deck.update_deck(GameManager.deck)
	$CanvasLayer/PlayerHand/HandContainer.set_cards(GameManager.current_player.hand)
	draw_players()
	update_players_state()
	
	#test_table_container()

# Called every frame (currently unused)
func _process(_delta: float) -> void:
	pass


func _on_turn_button_pressed() -> void:
	if GameManager.current_player in GameManager.players_attacking:
		GameManager.set_player_state(GameManager.current_player, PlayerState.Type.PASS)
	elif GameManager.current_player == GameManager.player_defending:
		GameManager.set_player_state(GameManager.current_player, PlayerState.Type.TAKE_CARDS)
	
	update_players_state()
