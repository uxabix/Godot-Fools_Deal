@tool
extends Node2D


const opt = preload("res://Scripts/Utils/SessionOptions.gd")


func set_cards() -> void:
	$CanvasLayer/Control/VBoxContainer/Row1/VBoxContainer/CardsOptions.clear()
	for i: int in opt.cards_count:
		var temp := str(i)
		$CanvasLayer/Control/VBoxContainer/Row1/VBoxContainer/CardsOptions.add_item(temp)
	
func set_players() -> void:
	$CanvasLayer/Control/VBoxContainer/Row1/VBoxContainer2/PlayersOptions.clear()
	for i: int in opt.players_count:
		var temp := str(i)
		$CanvasLayer/Control/VBoxContainer/Row1/VBoxContainer2/PlayersOptions.add_item(temp)	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_cards()
	set_players()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_data() -> Dictionary:
	var data: Dictionary
	
	data["transferable"] = $CanvasLayer/Control/VBoxContainer/TransferableCheckBox.toggle_mode
	data["cards"] = opt.cards_count[$CanvasLayer/Control/VBoxContainer/Row1/VBoxContainer/CardsOptions.get_selected_id()]
	data["players"] = opt.players_count[$CanvasLayer/Control/VBoxContainer/Row1/VBoxContainer2/PlayersOptions.get_selected_id()]
	
	return data

func get_ruleset(data: Dictionary) -> RulesetBase:
	if data["transferable"]: 
		return TransferRuleset.new()
	if not data["transferable"]:
		return ClassicRuleset.new()
	return ClassicRuleset.new()

func display_error(message: String) -> void:
	$CanvasLayer/Control/VBoxContainer/ErrorLabel.text = message
	$CanvasLayer/Control/VBoxContainer/ErrorLabel.visible = true

func check_rules(data: Dictionary, ruleset: RulesetBase) -> bool:
	var min_cards = ruleset.cards_in_hand * data["players"]
	if min_cards > data["cards"]:
		display_error("Too few cards for this amount of players!\nShould be at least {0}.".format([min_cards]))
		return false
	if data["players"] < ruleset.min_players:
		display_error("Too few players for this game mode!\nShould be at least {0}.".format([ruleset.min_players]))
		return false
	return true

func set_ruleset_data(data: Dictionary, ruleset: RulesetBase) -> void:
	ruleset.init_basics(data["cards"], 1, data["players"] - 1) # Should be changed for multiplayer mode

func _on_play_button_pressed() -> void:
	var data: Dictionary= get_data()
	var ruleset: RulesetBase = get_ruleset(data)
	if not check_rules(data, ruleset):
		return
	set_ruleset_data(data, ruleset)
	GameManager.ruleset = ruleset
	get_tree().change_scene_to_file("res://Scenes/Game/game.tscn")
