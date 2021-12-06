extends Node

#remaps a value from input range to output range
func remap_value(value, input_range:Vector2, output_range:Vector2)->float:
	return (value-input_range.x) / (input_range.y - input_range.x) * (output_range.y - output_range.x) + output_range.x

func rangef(start: float, end: float, step: float):
	var res = Array()
	var i = start
	if step < 0:
		while i > end:
			res.push_back(i)
			i += step
	elif step > 0:
		while i < end:
			res.push_back(i)
			i += step
	return res
