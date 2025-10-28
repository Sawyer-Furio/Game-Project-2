extends Node

var items := {}  # e.g. { "PiranhaFlower": 3, "Sunflower": 2 }

func add_item(flower_resource: Resource, amount := 1):
	var name = flower_resource.name
	if not items.has(name):
		items[name] = 0
	items[name] += amount
	print("🪴 Added", amount, name, "-> total:", items[name])

func remove_item(flower_name: String, amount := 1) -> bool:
	if not items.has(flower_name) or items[flower_name] < amount:
		return false
	items[flower_name] -= amount
	if items[flower_name] <= 0:
		items.erase(flower_name)
	return true

func has_item(flower_name: String) -> bool:
	return items.has(flower_name) and items[flower_name] > 0
