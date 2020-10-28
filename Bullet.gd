extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	translate(Vector3(0,0,-0.2))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(Vector3(0,0,delta*-5))


func _on_Timer_timeout():
	queue_free()


func _on_Bullet_area_entered(area):
	print(area)
	if area.has_method("bullet_hit"):
		area.bullet_hit(10)
		queue_free()
