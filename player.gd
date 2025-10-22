extends CharacterBody2D

@export var speed := 200.0
@onready var anim_sprite := $AnimatedSprite2D  # Replace Sprite2D with AnimatedSprite2D

func _physics_process(delta):
	var direction = Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide()
	
	update_animation(direction)

func update_animation(direction: Vector2):
	if direction == Vector2.ZERO:
		anim_sprite.play("idle")  # No movement, play idle animation
		return

	# Determine primary movement direction
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			anim_sprite.play("right")
		else:
			anim_sprite.play("left")
	else:
		if direction.y > 0:
			anim_sprite.play("down")
		else:
			anim_sprite.play("up")
