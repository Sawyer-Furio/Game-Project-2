extends Resource
class_name Flower

@export var id: int = 0
@export var name: String
@export var grow_speed: float = 1.0
@export var sell_value: int = 5
@export var grows_at_night: bool = false
@export var affects_neighbors: bool = false
@export var color: Color = Color.WHITE
@export var special_effect: String = ""

# 🌱 Sprite references (new)
@export var stem_textures: Array[Texture2D] = []  # [stage1, stage2, stage3]
@export var bloom_texture: Texture2D              # shown at full growth
