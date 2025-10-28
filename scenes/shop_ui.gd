extends Control

@onready var item_list := $VBoxContainer/ItemList
@onready var sell_button := $VBoxContainer/Button

func _ready():
	update_item_list()
	sell_button.pressed.connect(self, "_on_sell_pressed")

func update_item_list():
	item_list.clear()
	for flower_name in Inventory.items.keys():
		var count = Inventory.items[flower_name]
		item_list.add_item("%s x%d" % [flower_name, count])

func _on_sell_pressed():
	var selected = item_list.get_selected_items()
	for index in selected:
		var item_text = item_list.get_item_text(index)
		var flower_name = item_text.split(" x")[0]
		var count = Inventory.get_item_count(flower_name)
		
		# Example: 5 coins per item
		var total = count * 5
		print("Sold %d x %s for %d coins" % [count, flower_name, total])
		
		Inventory.remove_item(flower_name, count)
	update_item_list()
