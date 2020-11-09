extends Spatial

var score = 0

func _process(_delta):
	$VR/Headset/HUD/Viewport/HUD/score.text = str(score)
