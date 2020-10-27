extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var Skeleton = preload("res://Skeleton.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Timer_timeout():
	print("spawn")
	var skeleton = Skeleton.instance()
	skeleton.transform = transform
	add_child(skeleton)
	$Timer.wait_time = rand_range(5,20)
