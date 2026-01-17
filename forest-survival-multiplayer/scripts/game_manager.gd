extends Control

const CONFIG_FILE_PATH: String = "user://game_settings.cfg"
var config: ConfigFile = ConfigFile.new()

func _ready() :
	%MainMenu.visible = true
	%InGameUI.visible = false
	%SettingsMenu.visible = false
