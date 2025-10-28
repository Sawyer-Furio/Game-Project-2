extends Node2D

@onready var farm_tiles := $FarmTiles
@onready var player := $Player
@onready var bg := $BackgroundSprite  # Add your background node reference
const Flower = preload("res://scripts/Flower.gd")

# === Crop Data ===
var crops := {}
@export var grow_time := 5.0
# === Flower Selection ===
var selected_flower_path: String = "res://flowers/BasicFlower.tres"  # default


const TILE_GRASS   = 0
const TILE_TILLED  = 1
const TILE_PLANTED = 2
const TILE_SPROUT  = 3
const TILE_GROWN   = 4

# === Background Cycle Settings ===
@export var day_length := 60  # seconds for a full day-night loop
var elapsed_time := 0.0
var bg_height := 0.0


func _ready():
	print("✅ GameManager ready")
	print("FarmTiles found:", farm_tiles)
	print("Player found:", player)

	# 🌸 Give starting flowers (one of each)
	var flower_paths = [
		"res://flowers/BasicFlower.tres",
		"res://flowers/PiranhaFlower.tres",
		"res://flowers/BambooFlower.tres",
		"res://flowers/HydrangeaFlower.tres",
		"res://flowers/LightningBugFlower.tres",
		"res://flowers/Mushroom.tres",
		"res://flowers/NightFlower.tres",
		"res://flowers/PiggyBankFlower.tres",
		"res://flowers/WaterBalloonFlower.tres",
		"res://flowers/WeedFlower.tres",
	]
	for path in flower_paths:
		var flower_res = load(path)
		if flower_res:
			Inventory.add_item(flower_res, 1)
			print("🧺 Added", flower_res.name, "to inventory")
		else:
			print("⚠️ Could not load flower:", path)

	# Background setup
	if bg:
		bg.region_enabled = true
		bg_height = bg.texture.get_height()
		bg.region_rect = Rect2(0, 0, bg.texture.get_width(), get_viewport_rect().size.y)


	# Background setup
	if bg:
		bg.region_enabled = true
		bg_height = bg.texture.get_height()
		bg.region_rect = Rect2(0, 0, bg.texture.get_width(), get_viewport_rect().size.y)


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()
		var tile_pos = farm_tiles.local_to_map(farm_tiles.to_local(mouse_pos))
		handle_tile_interaction(tile_pos)


func handle_tile_interaction(tile_pos: Vector2i):
	if not crops.has(tile_pos):
		till_soil(tile_pos)
	elif crops[tile_pos]["stage"] == 0:
		plant_seed(tile_pos)
	elif crops[tile_pos]["stage"] == 3:
		harvest_crop(tile_pos)


func till_soil(tile_pos: Vector2i):
	print("Tilled soil at", tile_pos)
	crops[tile_pos] = {"stage": 0, "timer": 0.0}
	farm_tiles.set_cell(tile_pos, TILE_TILLED)

func plant_seed(tile_pos: Vector2i):
	if not selected_flower_path:
		print("⚠️ No flower selected to plant.")
		return

	var flower_res = load(selected_flower_path)
	if not flower_res:
		print("⚠️ Could not load flower resource at:", selected_flower_path)
		return

	if not Inventory.has_item(flower_res.name):
		print("⚠️ No", flower_res.name, "left in inventory.")
		return

	print("🌱 Planting", flower_res.name, "at", tile_pos)

	var flower_scene = preload("res://scenes/FlowerInstance.tscn").instantiate()
	flower_scene.flower_data = flower_res
	add_child(flower_scene)
	flower_scene.position = farm_tiles.map_to_local(tile_pos)
	flower_scene.add_to_group("flowers")

	Inventory.remove_item(flower_res.name, 1)

	crops[tile_pos] = {
		"stage": 1,
		"timer": 0.0,
		"flower": flower_scene
	}

	farm_tiles.set_cell(tile_pos, TILE_PLANTED)




func harvest_crop(tile_pos: Vector2i):
	var crop = crops[tile_pos]
	if crop.has("flower"):
		crop["flower"].harvest()  # adds to inventory
	crops.erase(tile_pos)
	farm_tiles.set_cell(tile_pos, TILE_GRASS)


func open_shop():
	var shop_ui = preload("res://scenes/ShopUI.tscn").instantiate()
	get_tree().root.add_child(shop_ui)


func _process(delta):
	update_crops(delta)
	update_background(delta)


func update_crops(delta):
	for tile_pos in crops.keys():
		var crop = crops[tile_pos]

		# Skip untiled or fully grown crops
		if crop["stage"] == 0 or crop["stage"] >= 3:
			continue

		# Get the flower instance and its data
		var flower_instance = crop["flower"]  # Node2D with FlowerInstance script
		if not flower_instance or not flower_instance.flower_data:
			continue  # safety check

		var flower_data: Flower = flower_instance.flower_data

		# Determine day/night
		var fraction := fmod(elapsed_time / day_length, 1.0)
		var is_daytime := fraction < 0.5  # First half = day, second = night

		# Skip growth if wrong time
		var grows_now := (is_daytime and not flower_data.grows_at_night) or (not is_daytime and flower_data.grows_at_night)
		if not grows_now:
			continue

		# Increment growth timer
		crop["timer"] += delta * flower_data.grow_speed
		if crop["timer"] >= grow_time:
			crop["stage"] += 1
			crop["timer"] = 0.0
			update_crop_visual(tile_pos, crop["stage"])


func update_crop_visual(tile_pos: Vector2i, stage: int):
	match stage:
		1: farm_tiles.set_cell(tile_pos, TILE_PLANTED)
		2: farm_tiles.set_cell(tile_pos, TILE_SPROUT)
		3: farm_tiles.set_cell(tile_pos, TILE_GROWN)


func update_background(delta):
	if not bg:
		return
	
	elapsed_time += delta
	var fraction := fmod(elapsed_time / day_length, 1.0)
	
	# Scroll vertically
	var y_offset := fraction * (bg_height - get_viewport_rect().size.y)
	bg.region_rect.position.y = y_offset
