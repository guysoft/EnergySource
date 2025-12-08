.PHONY: deps run editor

deps:
	./get_deps.sh

run:
	godot --path src/

editor:
	godot -e --path src/

