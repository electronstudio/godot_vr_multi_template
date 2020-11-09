extends Area


var score = 0
var health = 100

onready var env = get_node("/root/Main/WorldEnvironment").environment
onready var HUD = get_node("../HUD/Viewport/HUD")

func _ready():
	Globals.connect("score_points", self, "_score_points")

	
func _score_points(points):
	score += points

func _process(_delta):
	HUD.get_node("score").text = str(score)
	HUD.get_node("health").text = str(health)


func enemy_hit(damage):
	print("player hit")
	health -= damage
	$PlayerHit.play()
	HUD.get_node("red_filter").visible = true
	yield(get_tree().create_timer(0.3), "timeout")
	HUD.get_node("red_filter").visible = false
	if health <= 0:
		gameover()
	
func gameover():
	HUD.get_node("GameOver").visible = true
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.0
	get_tree().paused = true
	yield(get_tree().create_timer(5.0), "timeout")
	get_tree().paused = false
	get_tree().change_scene("res://TitleScreen.tscn")

