extends Area


var score = 0
var health = 100

func _ready():
	Globals.connect("score_points", self, "_score_points")
	
func _score_points(points):
	score += points

func _process(_delta):
	get_node("../HUD/Viewport/HUD/score").text = str(score)
	get_node("../HUD/Viewport/HUD/health").text = str(health)


func enemy_hit(damage):
	print("player died")
	health -= damage
	if health <= 0:
		gameover()
	
func gameover():
	get_node("../HUD/Viewport/HUD/GameOver").visible = true
	get_node("/root/Main/WorldEnvironment").environment.adjustment_enabled = true
	get_node("/root/Main/WorldEnvironment").environment.adjustment_saturation = 0.0
	get_tree().paused = true
	yield(get_tree().create_timer(5.0), "timeout")
	get_tree().paused = false
	get_tree().change_scene("res://TitleScreen.tscn")

