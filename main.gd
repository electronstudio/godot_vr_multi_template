extends Spatial


#var Bullet = preload("res://Bullet.tscn")

var score = 0

func _ready():
	pass


func _process(_delta):
	$Viewport/HUD.get_child(5).text = str(score)
#	if Input.is_action_just_pressed("fire"):
#		print("adding bullet")
#		var bullet = Bullet.instance()
#		bullet.translation = $ARVROrigin/ARVRCamera.get_global_transform().origin
#		bullet.rotation = $ARVROrigin/ARVRCamera.rotation
#		get_tree().root.add_child(bullet)
#
#
