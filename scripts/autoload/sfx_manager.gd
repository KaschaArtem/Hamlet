extends Node


const MENU_SOUNDS = "res://assets/sounds/menu/"
const POOL_SIZE = 10

var sounds: Dictionary = {}

var players: Array = []


func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	
	sounds["menu_nav_button"] = preload(MENU_SOUNDS + "menu_nav_button.wav")
	sounds["menu_click_button"] = preload(MENU_SOUNDS + "menu_click_button.wav")
	
	for i in POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "Effects"
		add_child(player)
		players.append(player)

func play_sound(sound_name: String):
	if not sounds.has(sound_name):
		push_warning("Sound not found: " + sound_name)
		return
	
	for player in players:
		if not player.playing:
			player.stream = sounds[sound_name]
			player.play()
			return
	
	var player = players[0]
	player.stream = sounds[sound_name]
	player.play()
