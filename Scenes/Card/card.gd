@tool
extends Node2D
class_name Card

# ------------------------------------------------------------------------------
# Card
# Represents a single playing card with a rank, suit, and orientation.
# The card can display its front or back texture, react to mouse hover,
# and optionally animate when hovered or flipped.
# ------------------------------------------------------------------------------

# Preload definitions containing enums and helper utilities for suits/ranks
const cd = preload("res://Scripts/Utils/card_defines.gd")

# ------------------------------------------------------------------------------
# Exported Properties
# ------------------------------------------------------------------------------

# Indicates whether the card is currently face-up (true) or face-down (false)
@export var is_face_up: bool = true:
	set(value):
		is_face_up = value
		flip()  # Update card side visibility when this property changes

# Suit of the card (e.g. Hearts, Spades, Clubs, Diamonds)
@export var suit: cd.Suit:
	set(value):
		suit = value
		set_textures()  # Refresh textures when suit changes

# Rank of the card (2–10, Jack, Queen, King, Ace)
@export var rank: cd.Rank:
	set(value):
		rank = value
		set_textures()  # Update textures for new rank
		set_text()      # Update displayed rank label

# Enables card hover animation when true
@export var animate: bool = false

# Enables or disables the collision area for hover detection
@export var collision: bool = true:
	set(value):
		collision = value
		$HoverArea/CollisionShape2D.disabled = not value


# ------------------------------------------------------------------------------
# Visual and Interaction Logic
# ------------------------------------------------------------------------------

# Flips the card to show front (face-up) or back (face-down)
func flip() -> void:
	$Front.visible = is_face_up
	$Back.visible = not is_face_up
	$HoverArea/CollisionShape2D.disabled = not is_face_up


# Updates suit and rank textures based on the current card properties
func set_textures() -> void:
	# Update all small suit icons
	for i in $Front/Suits.get_children():
		i.texture = load(cd.get_suit_image(suit))

	# Determine if the rank has a dedicated image (e.g., Jack, Queen, King)
	$Front/Images/Rank.visible = rank in cd.HAS_TEXTURE
	$Front/Images/Suits.visible = not $Front/Images/Rank.visible

	if $Front/Images/Rank.visible:
		# Load and display the dedicated rank image
		$Front/Images/Rank.texture = load(cd.get_rank_image(suit, rank))
	else:
		# Use pattern overlay when rank has no dedicated texture
		var i := 0
		for image in $Front/Images/Suits.get_children():
			image.visible = cd.patterns[rank][i]
			image.texture = load(cd.get_suit_image(suit))
			i += 1


# Updates the textual label representation of the card's rank
func set_text() -> void:
	for i in $Front/Ranks/Control.get_children():
		var card_name: String = cd.get_rank_name(rank)
		# Fallback to numeric value if rank name is empty
		card_name = str(rank + cd.FIRST_CARD_VALUE) if card_name == "" else card_name
		# Shorten text if too long (e.g., "Queen" → "Q")
		i.text = card_name if len(card_name) < 3 else card_name[0]


# Initializes the card with given data (typically from CardData resource)
func init(data: CardData) -> void:
	suit = data.suit
	rank = data.rank


# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------

func _ready() -> void:
	set_textures()
	set_text()


# Currently unused, reserved for per-frame updates (e.g., animations)
func _process(_delta: float) -> void:
	pass


# ------------------------------------------------------------------------------
# Hover Events
# ------------------------------------------------------------------------------

# Triggered when the mouse cursor enters the card's hover area
func _on_hover_area_mouse_entered() -> void:
	if not animate:
		return
	$AnimationPlayer.play("Hover")
	UiManager.card_hovered = get_index()


# Triggered when the mouse cursor leaves the card's hover area
func _on_hover_area_mouse_exited() -> void:
	if not animate:
		return
	$AnimationPlayer.play_backwards("Hover")
	UiManager.card_hovered = null


# ------------------------------------------------------------------------------
# Utility
# ------------------------------------------------------------------------------

# Returns the card's size in world units (scaled)
func get_size() -> Vector2:
	return $Front/Front.texture.get_size() * $Front/Front.scale * scale
