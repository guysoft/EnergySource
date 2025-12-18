extends VBoxContainer

@onready var playlist_items = $ListContainer/PlaylistItems
@onready var scroll_up_btn = $ListContainer/ScrollUpBtn
@onready var scroll_down_btn = $ListContainer/ScrollDownBtn
@onready var play_button = $PlayButton


func _ready():
	# Connect button signals using button_down for VR raycast compatibility
	if scroll_up_btn and not scroll_up_btn.button_down.is_connected(_on_scroll_up_pressed):
		scroll_up_btn.button_down.connect(_on_scroll_up_pressed)
	if scroll_down_btn and not scroll_down_btn.button_down.is_connected(_on_scroll_down_pressed):
		scroll_down_btn.button_down.connect(_on_scroll_down_pressed)
	if play_button and not play_button.button_down.is_connected(_on_play_pressed):
		play_button.button_down.connect(_on_play_pressed)
	if playlist_items and not playlist_items.item_selected.is_connected(_on_item_selected):
		playlist_items.item_selected.connect(_on_item_selected)


func _on_scroll_up_pressed():
	# Placeholder - scroll logic will be added later
	pass


func _on_scroll_down_pressed():
	# Placeholder - scroll logic will be added later
	pass


func _on_play_pressed():
	# Placeholder - play logic will be added later
	pass


func _on_item_selected(index: int):
	# Placeholder - selection logic will be added later
	pass

