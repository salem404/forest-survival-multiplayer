extends HBoxContainer

@export var id: int
@export var player_info: Dictionary

@onready var id_label = $Label
@onready var reference_rect = $ReferenceRect
@onready var avatar = $ReferenceRect/AnimatedSprite2D
@onready var name_label = $Label2

func _ready() -> void:
	id_label.text = str(id)
	#name_label.text = Steam.getFriendPersonaName(Steam.getSteamID())
	name_label.text = player_info["name"]
	
	# Apply player color to the avatar container using self_modulate
	if player_info.has("color"):
		reference_rect.self_modulate = player_info["color"]
	
	var avatar_image
	#var avatar =  load("res://resources/"+player_info["avatar_id"]+".tres") as Avatar
	var avatar = player_info["avatar"]
	if avatar is EncodedObjectAsID:
		avatar =  load("res://resources/"+player_info["avatar_id"]+".tres") as Avatar		
		#avatar = instance_from_id(player_info["avatar"].get_object_id())
	avatar_image = avatar.image
	#Steam.avatar_loaded.connect(_on_loaded_avatar)
	#Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM)
	avatar.texture = avatar_image

func _on_loaded_avatar(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	print("Avatar for user: %s" % user_id)
	print("Size: %s" % avatar_size)

	# Create the image for loading
	var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)

	# Optionally resize the image if it is too large
	if avatar_size > 128:
		avatar_image.resize(128, 128, Image.INTERPOLATE_LANCZOS)

	# Apply the image to a texture
	var avatar_texture: ImageTexture = ImageTexture.create_from_image(avatar_image)

	# Set the texture to a Sprite, TextureRect, etc.
	avatar_img.texture = avatar_texture
