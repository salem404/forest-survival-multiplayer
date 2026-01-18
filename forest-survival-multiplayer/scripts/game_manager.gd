extends Control

const CONFIG_FILE_PATH: String = "user://game_settings.cfg"
var config: ConfigFile = ConfigFile.new()


func _ready():
	%MainMenu.visible = true
	%InGameUI.visible = false
	%SettingsMenu.visible = false


func swap_scene_to_file(replacement_scene_path: String) -> void:
	var scene = load(replacement_scene_path).instantiate()
	%MainMenu.queue_free()
	add_child(scene)
