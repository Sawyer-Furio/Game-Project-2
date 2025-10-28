extends Node2D
class_name FlowerInstance

@export var flower_data: Flower
@onready var stem_layer := $StemLayer    # TileMapLayer for stem
@onready var bloom_layer := $BloomLayer  # TileMapLayer for bloom

# Growth state
var growth: float = 0.0
var growth_stage: int = 0
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

# Tile positions inside this layer
var tile_pos := Vector2i(0,0)  # Each flower uses only one tile

func _ready():
	if flower_data == null:
		push_error("FlowerInstance has no flower_data assigned!")
		return
	add_to_group("flowers")
	update_visuals()


func harvest():
	if grown:
		Inventory.add_item(flower_data)
		queue_free()  # Remove flower from scene


func _process(delta):
	# 🌱 Normal growth
	if not grown:
		growth += delta * flower_data.grow_speed
		var stage := int((growth / 100.0) * 3.0)
		if stage != growth_stage:
			growth_stage = clamp(stage, 0, 3)
			update_visuals()

		if growth >= 100:
			grow_to_full()

	# 💧 Water balloon logic
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
	stem_layer.clear()
	bloom_layer.clear()

	if not flower_data:
		return

	# Apply each tileset
	if flower_data.stem_tileset:
		stem_layer.tile_set = flower_data.stem_tileset
	if flower_data.bloom_tileset:
		bloom_layer.tile_set = flower_data.bloom_tileset

	var stage_to_draw := growth_stage
	if stage_to_draw == 0 and flower_data.stem_tile_ids.size() > 0:
		stage_to_draw = 1  # show first stage for seeds

	# Draw stem
	if stage_to_draw > 0 and stage_to_draw <= flower_data.stem_tile_ids.size():
		var stem_id = flower_data.stem_tile_ids[stage_to_draw - 1]
		stem_layer.set_cell(tile_pos, stem_id)
  

	# Draw bloom (only when fully grown)
	if growth_stage == flower_data.stem_tile_ids.size() and flower_data.bloom_tile_id >= 0:
		bloom_layer.set_cell(tile_pos, flower_data.bloom_tile_id)

	print("🌸 Drawing", flower_data.name)
	print("Stem tileset:", stem_layer.tile_set)
	print("Bloom tileset:", bloom_layer.tile_set)
	print("Stem IDs:", flower_data.stem_tile_ids)
	print("Bloom ID:", flower_data.bloom_tile_id)




func grow_to_full():
	grown = true
	print("%s fully grown!" % flower_data.name)
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
	print(flower_data.name + " (Piggy Bank) started 💰")

func process_piggy_bank(delta):
	piggy_timer += delta
	if piggy_timer >= piggy_rate:
		piggy_timer = 0.0
		for neighbor in get_tree().get_nodes_in_group("flowers"):
			if neighbor == self:
				continue
			if position.distance_to(neighbor.position) < 96:
				if neighbor.flower_data.sell_value > 1:
					neighbor.flower_data.sell_value -= 1
					flower_data.sell_value += 1
					print("%s steals 1 coin from %s" % [flower_data.name, neighbor.flower_data.name])


# Disco Bush
func start_disco_effect():
	set_process(true)
	print(flower_data.name + " (Disco Bush) starts glowing ✨")

func process_disco_effect(delta):
	disco_timer += delta
	if disco_timer >= disco_rate:
		disco_timer = 0.0
		for neighbor in get_tree().get_nodes_in_group("flowers"):
			if neighbor == self:
				continue
			if position.distance_to(neighbor.position) < 96:
				if neighbor.flower_data:
					neighbor.flower_data.sell_value += 1
					print("💡 %s boosts %s’s value!" % [flower_data.name, neighbor.flower_data.name])


# Water Balloon
func start_filling():
	is_filling = true
	water_fill = 0.0
	print(flower_data.name + " started filling 💧")

func release_water():
	is_filling = false
	water_fill = 0.0
	print(flower_data.name + " releases water 🌊")
	for neighbor in get_tree().get_nodes_in_group("flowers"):
		if neighbor != self and position.distance_to(neighbor.position) < 128:
			if neighbor.flower_data:
				neighbor.boost_growth(2.0)


# Weeds
func spread_weeds():
	for x_offset in range(-1,2):
		for y_offset in range(-1,2):
			if x_offset == 0 and y_offset == 0:
				continue
			var neighbor_pos = position + Vector2(x_offset*64, y_offset*64)
			var occupied := false
			for other in get_tree().get_nodes_in_group("flowers"):
				if other == self:
					continue
				if neighbor_pos.distance_to(other.position) < 32:
					occupied = true
					break
			if not occupied:
				var new_flower = load("res://scenes/FlowerInstance.tscn").instantiate()
				new_flower.position = neighbor_pos
				new_flower.flower_data = flower_data
				get_parent().add_child(new_flower)
				print("🌾 Weeds spread!")


# Shade / Eat / Boost
func shade_neighbors():
	for neighbor in get_tree().get_nodes_in_group("flowers"):
		if neighbor == self:
			continue
		if position.distance_to(neighbor.position) < 96:
			if neighbor.flower_data:
				neighbor.flower_data.grows_at_night = true

func eat_neighbors():
	for neighbor in get_tree().get_nodes_in_group("flowers"):
		if neighbor == self:
			continue
		if position.distance_to(neighbor.position) < 64:
			if neighbor.flower_data:
				print("%s ate %s!" % [flower_data.name, neighbor.flower_data.name])
			neighbor.queue_free()


func boost_growth(multiplier: float) -> void:
	var original_speed = flower_data.grow_speed
	flower_data.grow_speed *= multiplier
	print(flower_data.name + " growth boosted 🌿")
	await get_tree().create_timer(5.0).timeout
	flower_data.grow_speed = original_speed
	print(flower_data.name + " growth boost ended")
