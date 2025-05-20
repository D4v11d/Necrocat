extends AudioStreamPlayer2D

func _ready() -> void:
	MusicPlayer.playing = false
	self.playing = true
