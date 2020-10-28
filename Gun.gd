extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var Bullet: PackedScene = preload("res://Bullet2.tscn") if OS.get_name()=="Android" or OS.get_name()=="iOS" else preload("res://Bullet.tscn")
#export var Bullet2 = preload("res://Bullet2.tscn")
export var actions = ["VR_LEFT_INDEX_TRIGGER", "fire", "VR_SCREEN_TAP"]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(_delta):
	for action in actions:
		if Input.is_action_just_pressed(action):
			var bullet = Bullet.instance()
			bullet.transform = self.get_global_transform()
			get_tree().root.add_child(bullet)
		
		
