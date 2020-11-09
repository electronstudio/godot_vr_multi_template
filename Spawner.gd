extends Spatial

var Skeleton = preload("res://Skeleton.tscn")


func _on_Timer_timeout():
	var skeleton = Skeleton.instance()
	skeleton.transform = self.get_global_transform()
	print(skeleton.transform)
	get_tree().current_scene.add_child(skeleton)
	$Timer.wait_time = rand_range(5,25)
	$Timer.start()
