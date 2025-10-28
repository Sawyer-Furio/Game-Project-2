extends Node2D

@onready var flower := $FlowerInstance

var stage_timer := 0.0
var grow_interval := 2.0  # seconds per stage

func _ready():
	print("🌱 Starting Basic Flower growth test...")
	flower.growth_stage = 0
	flower.update_visuals()

func _process(delta):
	stage_timer += delta
	if stage_timer >= grow_interval:
		stage_timer = 0.0
		if flower.growth_stage < 3:
			flower.grow(delta)
		else:
			print("🌸 Flower fully grown with bloom!")
