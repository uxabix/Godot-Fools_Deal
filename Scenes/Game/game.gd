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

@export var see_enemy_cards: bool = false ## Enable in game drawing of enemy cards faces (Debug)

# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------

func clear_enemy_hand_container():
	for child in $CanvasLayer/EnemyContainer/EnemyHandContainer.get_children():
		if "HandContainer" in child.name:
			child.queue_free()

func create_container(player: Player) -> Node:
	var enemy_hand = hand_container.instantiate()
	enemy_hand.player_id = player.id
	enemy_hand.appearance = enemy_hand_container_data
	$CanvasLayer/EnemyContainer/EnemyHandContainer.add_child(enemy_hand)

	return enemy_hand

func draw_cards(container: Node):
	var player := GameManager.players[container.player_id]
	container.set_cards(player.hand, player_card_appearance if see_enemy_cards else enemy_card_appearance)

func draw_players():
	clear_enemy_hand_container()
	for player in GameManager.players:
		if player == GameManager.current_player: continue
		var hand = create_container(player)
		draw_cards(hand)
		

func test_table_container() -> void:
	var cardAttack = CardData.new()
	cardAttack.rank = cd.Rank.TEN
	cardAttack.suit = cd.Suit.DIAMONDS
	var cardDefense = CardData.new()
	cardDefense.rank = cd.Rank.KING
	cardDefense.suit = cd.Suit.SPADES
	
	for i in range(6):
		$CanvasLayer/Control/TableContainer.add_attack(cardAttack)
		$CanvasLayer/Control/TableContainer.add_defense(i, cardDefense)

# Called once when the node enters the scene tree
func _ready() -> void:
	UiManager.remove_preview_nodes(self)
	GameManager.start_game()
	deck.update_deck(GameManager.deck)
	UiManager.player_hand = $CanvasLayer/PlayerHand/HandContainer
	$CanvasLayer/PlayerHand/HandContainer.set_cards(GameManager.current_player.hand, player_card_appearance)
	draw_players()
	
	test_table_container()

# Called every frame (currently unused)
func _process(_delta: float) -> void:
	pass
