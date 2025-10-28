extends Resource
class_name Flower

@export var id: int = 0
@export var name: String = ""
@export var grow_speed: float = 1.0
@export var sell_value: int = 5
@export var grows_at_night: bool = false
@export var affects_neighbors: bool = false
@export var color: Color = Color.WHITE
@export var special_effect: String = ""

# 🌿 Tile references
@export var stem_tileset: TileSet
@export var stem_tile_ids: Array[int] = []   # [stage1, stage2, stage3]
@export var bloom_tileset: TileSet
@export var bloom_tile_id: int = -1
