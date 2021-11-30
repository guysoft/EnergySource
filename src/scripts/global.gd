extends Node

const GameManager = preload("res://src/Utility/game_manager.gd");

var _game_manager : GameManager = null;

func manager() -> GameManager:
	if !_game_manager:
		var managers = get_tree().get_nodes_in_group("global_game_manager");
		if managers.size() > 0:
			_game_manager = managers[0];
	
	return _game_manager;
	
