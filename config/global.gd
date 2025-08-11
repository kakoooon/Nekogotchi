extends Node

func _ready() -> void:
	SaveFileHandler.init()


#
# Utils.
#
## Frame-independent lerp smoothing using exponential decay. Useful decay range 1 to 25 from slow to fast.
func elerp(a, b, decay: float, dt: float):
	return lerp(b, a, exp(-decay * dt))

func repeat(x: float, max_y: float) -> float:
	# Loops the returned value (y a.k.a. result), so that it is never larger than max_y and never smaller than 0.
	#
	#    y
	#    |   /  /  /  /
	#    |  /  /  /  /
	#   x|_/__/__/__/_
	#
	var result = clamp(x - floor(x / max_y) * max_y, 0.0, max_y)
	return result

func ping_pong(x: float, max_y: float) -> float:
	# PingPongs the returned value (y a.k.a. result), so that it is never larger than max_y and never smaller than 0.
	#
	#   y
	#   |   /\    /\    /\
	#   |  /  \  /  \  /  \
	#  x|_/____\/____\/____\_
	#
	x = repeat(x, max_y * 2.0)
	var result = max_y - abs(x - max_y);
	return result;
