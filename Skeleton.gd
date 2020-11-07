extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var target = Vector3(0,0,0)

var dead = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$spawnSound.play()
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
	if not dead:
		dead = true
		$deathSound.play()
		$AnimationPlayer.play("Skeleton_Death")
		get_tree().current_scene.score += 1


func _on_Skeleton_area_entered(area):
	if area.has_method("enemy_hit"):
		area.enemy_hit(10)
		queue_free()
