extends Node2D

@onready var farm_tiles := $FarmTiles
@onready var player := $Player  # Optional: still used for visuals/movement

# Each tile stores: { "stage": int, "timer": float }
var crops := {}

@export var grow_time := 5.0

# Tile IDs from your tileset (match your TileMapLayer)
const TILE_GRASS   = 0
const TILE_TILLED  = 1
const TILE_PLANTED = 2
const TILE_SPROUT  = 3
const TILE_GROWN   = 4


func _ready():
	print("✅ GameManager ready")
	print("FarmTiles found:", farm_tiles)
	print("Player found:", player)


func _unhandled_input(event):
	# Only respond to left mouse button clicks
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Convert screen coordinates to FarmTiles local coordinates
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
	print("Planted seed at", tile_pos)
	crops[tile_pos]["stage"] = 1
	crops[tile_pos]["timer"] = 0.0
	farm_tiles.set_cell(tile_pos, TILE_PLANTED)


func harvest_crop(tile_pos: Vector2i):
	print("Harvested crop at", tile_pos)
	crops.erase(tile_pos)
	farm_tiles.set_cell(tile_pos, TILE_GRASS)


func _process(delta):
	for tile_pos in crops.keys():
		var crop = crops[tile_pos]
		
		# Skip if waiting to be planted or already grown
		if crop["stage"] == 0 or crop["stage"] >= 3:
			continue

		crop["timer"] += delta
		if crop["timer"] >= grow_time:
			crop["stage"] += 1
			crop["timer"] = 0.0
			update_crop_visual(tile_pos, crop["stage"])


func update_crop_visual(tile_pos: Vector2i, stage: int):
	match stage:
		1: farm_tiles.set_cell(tile_pos, TILE_PLANTED)
		2: farm_tiles.set_cell(tile_pos, TILE_SPROUT)
		3: farm_tiles.set_cell(tile_pos, TILE_GROWN)
