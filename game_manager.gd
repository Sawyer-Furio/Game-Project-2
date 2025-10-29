extends Node2D

@onready var farm_tiles := $FarmTiles
@onready var player := $Player
@onready var bg := $BackgroundSprite
@onready var inventory_ui := $InventoryUI  # ✅ Add your UI node reference
const Flower = preload("res://scripts/Flower.gd")

# === Crop Data ===
var crops := {}
@export var grow_time := 5.0

# === Flower Selection ===
var selected_flower_path: String = ""  # Will be updated from UI

# === Tile Types ===
const TILE_GRASS   = 0
const TILE_TILLED  = 1
const TILE_PLANTED = 2
const TILE_SPROUT  = 3
const TILE_GROWN   = 4

# === Background Cycle Settings ===
@export var day_length := 60  # seconds for a full day-night loop
var elapsed_time := 0.0
var bg_height := 0.0


# =====================================================
# 🏁 READY
# =====================================================
func _ready():
	print("✅ GameManager ready")
	print("FarmTiles found:", farm_tiles)
	print("Player found:", player)

	# 🌸 Give starting flowers
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
		"res://flowers/WeedFlower.tres"
	]

	for path in flower_paths:
		var flower_res = load(path)
		if flower_res:
			Inventory.add_item(flower_res, 1)
			print("🧺 Added", flower_res.name, "to inventory")
		else:
			print("⚠️ Could not load flower:", path)

	# 🌿 Setup UI
	if inventory_ui:
		inventory_ui.update_display()

	# 🌄 Background setup
	if bg:
		bg.region_enabled = true
		bg_height = bg.texture.get_height()
		bg.region_rect = Rect2(0, 0, bg.texture.get_width(), get_viewport_rect().size.y)


# =====================================================
# 🖱️ HANDLE INPUT
# =====================================================
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()
		var tile_pos = farm_tiles.local_to_map(farm_tiles.get_local_mouse_position())
		print(mouse_pos)
		handle_tile_interaction(tile_pos)
		print(tile_pos)


# =====================================================
# 🪴 TILE ACTIONS
# =====================================================
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
	# ✅ Use currently selected flower from UI
	var selected_name = inventory_ui.get_selected_flower_name()
	if selected_name == "":
		print("⚠️ No flower selected to plant.")
		return

	# ✅ Find matching flower resource in files
	var flower_path = "res://flowers/%s.tres" % selected_name.replace(" ", "")
	if not FileAccess.file_exists(flower_path):
		print("⚠️ Could not find file for:", selected_name)
		return

	var flower_res = load(flower_path)
	if not flower_res:
		print("⚠️ Failed to load flower resource at:", flower_path)
		return

	# ✅ Check inventory
	if not Inventory.has_item(selected_name):
		print("⚠️ No", selected_name, "left in inventory.")
		return

	print("🌱 Planting", flower_res.name, "at", tile_pos)

	var flower_scene = preload("res://scenes/FlowerInstance.tscn").instantiate()
	flower_scene.flower_data = flower_res
	add_child(flower_scene)
	var worldlocation = Vector2(tile_pos.x, tile_pos.y + 1)
	flower_scene.position = farm_tiles.map_to_local(worldlocation)*4
	flower_scene.add_to_group("flowers")
	flower_scene.z_index = 5

	Inventory.remove_item(selected_name, 1)
	inventory_ui.update_display()

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
	inventory_ui.update_display()


# =====================================================
# 🕒 BACKGROUND + CROP GROWTH
# =====================================================
func _process(delta):
	update_crops(delta)
	update_background(delta)


func update_crops(delta):
	for tile_pos in crops.keys():
		var crop = crops[tile_pos]

		if crop["stage"] == 0 or crop["stage"] >= 3:
			continue

		var flower_instance = crop["flower"]
		if not flower_instance or not flower_instance.flower_data:
			continue

		var flower_data: Flower = flower_instance.flower_data

		var fraction := fmod(elapsed_time / day_length, 1.0)
		var is_daytime := fraction < 0.5
		var grows_now := (is_daytime and not flower_data.grows_at_night) or (not is_daytime and flower_data.grows_at_night)
		if not grows_now:
			continue

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
	var y_offset := fraction * (bg_height - get_viewport_rect().size.y)
	bg.region_rect.position.y = y_offset
