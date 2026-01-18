extends Control

const CONFIG_FILE_PATH: String = "user://game_settings.cfg"

@export var is_online: bool = false

var config: ConfigFile = ConfigFile.new()
var current_lobby: Lobby


func _ready():
	%MainMenu.visible = true
	%InGameUI.visible = false
	%SettingsMenu.visible = false


func swap_scene_to_file(replacement_scene_path: String) -> void:
	var scene = load(replacement_scene_path).instantiate()
	%MainMenu.queue_free()
	add_child(scene)
