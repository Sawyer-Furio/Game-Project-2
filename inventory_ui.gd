extends Control

@onready var list_label := $VBoxContainer/Label
@onready var selected_label := $Label

var items := {}  # From your Inventory singleton
var item_names := []  # Ordered names
var current_index := 0

func _ready():
	update_display()
	set_process_input(true)

func update_display():
	# Get data from Inventory singleton
	items = Inventory.items
	item_names = items.keys()

	# 🩹 Clamp index so it never goes out of range
	if current_index >= item_names.size():
		current_index = max(0, item_names.size() - 1)

	# Build formatted inventory list text
	var display_text := ""
	for i in range(item_names.size()):
		var name = item_names[i]
		var count = items[name]

		if i == current_index:
			# 🌟 Highlight selected item visually
			display_text += "[color=yellow][b]↑ %s ×%d[/b][/color]\n" % [name, count]
		else:
			display_text += "   %s ×%d\n" % [name, count]

	# Enable BBCode so colors and bold work
	list_label.bbcode_enabled = true
	list_label.text = display_text  # (no need to clear it multiple times)

	# Update current selection label
	if item_names.size() > 0:
		var selected_name = item_names[current_index]
		selected_label.text = "Selected: " + selected_name
	else:
		selected_label.text = "Inventory empty"


func _input(event):
	if event.is_action_pressed("ui_left"):
		select_previous()
	elif event.is_action_pressed("ui_right"):
		select_next()

func select_previous():
	if item_names.size() == 0:
		return
	current_index = (current_index - 1 + item_names.size()) % item_names.size()
	update_display()

func select_next():
	if item_names.size() == 0:
		return
	current_index = (current_index + 1) % item_names.size()
	update_display()

func get_selected_flower_name() -> String:
	if item_names.size() == 0:
		return ""
	return item_names[current_index]
