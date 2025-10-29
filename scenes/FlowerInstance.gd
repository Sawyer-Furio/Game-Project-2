extends Node2D
class_name FlowerInstanceScript

@export var flower_data: Flower
@onready var stem_sprite := $StemSprite
@onready var bloom_sprite := $BloomSprite

# Growth state
var growth: float = 0.0
var growth_stage: int = 1   # start at 1 so seed shows immediately
var grown: bool = false

# Water balloon logic
var water_fill := 0.0
var is_filling := false
var fill_time := 5.0

# Special effects timers
var piggy_timer := 0.0
var piggy_rate := 2.0
var disco_timer := 0.0
var disco_rate := 3.0

func _ready():
	if not flower_data:
		push_error("FlowerInstance has no flower_data assigned!")
		return
	add_to_group("flowers")
	update_visuals()

func _process(delta):
	# 🌱 Growth
	if not grown:
		growth += delta * flower_data.grow_speed
		var stage = int((growth / 100.0) * 3.0) + 1
		if stage != growth_stage:
			growth_stage = clamp(stage, 1, 3)
			update_visuals()

		if growth >= 100:
			grow_to_full()

	# 💧 Water balloon
	if is_filling:
		water_fill += delta
		if water_fill >= fill_time:
			release_water()

	# 💰 Piggy Bank
	if flower_data.special_effect == "piggy_bank" and grown:
		process_piggy_bank(delta)

	# ✨ Disco Bush
	if flower_data.special_effect == "disco_bush" and grown:
		process_disco_effect(delta)

# ===============================
# 🌿 Visuals — stem + bloom
# ===============================
func update_visuals():
	if not flower_data:
		return
	#flower immediately starts growing
	# Stem sprite
	if growth_stage > 0 and growth_stage <= flower_data.stem_textures.size():
		stem_sprite.texture = flower_data.stem_textures[growth_stage - 1]
		stem_sprite.visible = true
	else:
		stem_sprite.visible = false
	
	# Bloom sprite
	bloom_sprite.texture = flower_data.bloom_texture if growth_stage == 3 else null
	bloom_sprite.visible = growth_stage == 3


# Fully grown
func grow_to_full():
	grown = true
	print("%s fully grown!" % flower_data.name)
	update_visuals()
	if flower_data.affects_neighbors:
		apply_special_effect()

# ===============================
# Special effects
# ===============================
func apply_special_effect():
	match flower_data.special_effect:
		"eat_neighbors": eat_neighbors()
		"shade_neighbors": shade_neighbors()
		"spread_weeds": spread_weeds()
		"water_neighbors": start_filling()
		"piggy_bank": start_piggy_bank_effect()
		"disco_bush": start_disco_effect()
		_:
			pass

# Piggy Bank
func start_piggy_bank_effect():
	set_process(true)
	print("%s (Piggy Bank) started 💰" % flower_data.name)

func process_piggy_bank(delta):
	piggy_timer += delta
	if piggy_timer >= piggy_rate:
		piggy_timer = 0.0
		for neighbor in get_tree().get_nodes_in_group("flowers"):
			if neighbor == self: continue
			if position.distance_to(neighbor.position) < 96:
				if neighbor.flower_data.sell_value > 1:
					neighbor.flower_data.sell_value -= 1
					flower_data.sell_value += 1
					print("%s steals 1 coin from %s" % [flower_data.name, neighbor.flower_data.name])

# Disco Bush
func start_disco_effect():
	set_process(true)
	print("%s (Disco Bush) starts glowing ✨" % flower_data.name)

func process_disco_effect(delta):
	disco_timer += delta
	if disco_timer >= disco_rate:
		disco_timer = 0.0
		for neighbor in get_tree().get_nodes_in_group("flowers"):
			if neighbor == self: continue
			if position.distance_to(neighbor.position) < 96 and neighbor.flower_data:
				neighbor.flower_data.sell_value += 1
				print("💡 %s boosts %s’s value!" % [flower_data.name, neighbor.flower_data.name])

# Water Balloon
func start_filling():
	is_filling = true
	water_fill = 0.0
	print("%s started filling 💧" % flower_data.name)

func release_water():
	is_filling = false
	water_fill = 0.0
	print("%s releases water 🌊" % flower_data.name)
	for neighbor in get_tree().get_nodes_in_group("flowers"):
		if neighbor != self and position.distance_to(neighbor.position) < 128:
			if neighbor.flower_data:
				neighbor.boost_growth(2.0)

# Weeds
func spread_weeds():
	for x_offset in range(-1,2):
		for y_offset in range(-1,2):
			if x_offset == 0 and y_offset == 0: continue
			var neighbor_pos = position + Vector2(x_offset*64, y_offset*64)
			var occupied := false
			for other in get_tree().get_nodes_in_group("flowers"):
				if other == self: continue
				if neighbor_pos.distance_to(other.position) < 32:
					occupied = true
					break
			if not occupied:
				var new_flower = load("res://scenes/FlowerInstance.tscn").instantiate()
				new_flower.position = neighbor_pos
				new_flower.flower_data = flower_data
				get_parent().add_child(new_flower)
				new_flower.update_visuals()
				print("🌾 Weeds spread!")

# Shade / Eat / Boost
func shade_neighbors():
	for neighbor in get_tree().get_nodes_in_group("flowers"):
		if neighbor == self: continue
		if position.distance_to(neighbor.position) < 96 and neighbor.flower_data:
			neighbor.flower_data.grows_at_night = true

func eat_neighbors():
	for neighbor in get_tree().get_nodes_in_group("flowers"):
		if neighbor == self: continue
		if position.distance_to(neighbor.position) < 64:
			if neighbor.flower_data:
				print("%s ate %s!" % [flower_data.name, neighbor.flower_data.name])
			neighbor.queue_free()

func boost_growth(multiplier: float) -> void:
	var original_speed = flower_data.grow_speed
	flower_data.grow_speed *= multiplier
	print("%s growth boosted 🌿" % flower_data.name)
	await get_tree().create_timer(5.0).timeout
	flower_data.grow_speed = original_speed
	print("%s growth boost ended" % flower_data.name)
