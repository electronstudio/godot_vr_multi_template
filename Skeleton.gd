extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var target = Vector3(0,0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("Skeleton_Spawn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if $AnimationPlayer.current_animation=="Skeleton_Running":
		look_at(target, Vector3.UP)
		rotate_y(PI)
		translate_object_local(Vector3(0,0,delta*5))


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name=="Skeleton_Spawn":
		$AnimationPlayer.play("Skeleton_Running")
	elif anim_name=="Skeleton_Running":
		$AnimationPlayer.play("Skeleton_Running")
	elif anim_name=="Skeleton_Death":
		queue_free()
		
func bullet_hit(damage):
	$AnimationPlayer.play("Skeleton_Death")
