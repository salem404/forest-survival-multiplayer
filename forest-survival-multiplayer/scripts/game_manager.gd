extends Control

const CONFIG_FILE_PATH: String = "user://game_settings.cfg"

@export var is_online: bool = false

var config: ConfigFile = ConfigFile.new()
var current_lobby: Node


func _ready():
	%MainMenu.visible = true
	%InGameUI.visible = false
	%SettingsMenu.visible = false


func swap_scene_to_file(replacement_scene_path: String) -> void:
	_clear_dynamic_scenes()
	if replacement_scene_path == "res://scenes/game.tscn":
		var main_menu = find_child("MainMenu", true, false)
		if main_menu:
			main_menu.queue_free()
	elif replacement_scene_path == "res://scenes/main_menu.tscn":
		var main_menu = find_child("MainMenu", true, false)
		if main_menu:
			main_menu.visible = true
			if main_menu.has_method("reset_menu"):
				main_menu.reset_menu()
			return
	var scene = load(replacement_scene_path).instantiate()
	add_child(scene)


func _clear_dynamic_scenes() -> void:
	for child in get_children():
		if child.name in ["AudioStreamPlayer", "MainMenu", "SettingsMenu", "InGameUI"]:
			continue
		child.queue_free()
