class_name SelectionRasterArt
extends RefCounted


static func fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var start_x := maxi(rect.position.x, 0)
	var start_y := maxi(rect.position.y, 0)
	var end_x := mini(rect.end.x, image.get_width())
	var end_y := mini(rect.end.y, image.get_height())
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			image.set_pixel(x, y, color)


static func fill_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	var radius_squared := radius * radius
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var offset_x := x - center.x
			var offset_y := y - center.y
			if offset_x * offset_x + offset_y * offset_y <= radius_squared:
				set_pixel_safe(image, x, y, color)


static func fill_ellipse(image: Image, center: Vector2i, radius_x: int, radius_y: int, color: Color) -> void:
	for y in range(center.y - radius_y, center.y + radius_y + 1):
		for x in range(center.x - radius_x, center.x + radius_x + 1):
			var normalized_x := float(x - center.x) / float(radius_x)
			var normalized_y := float(y - center.y) / float(radius_y)
			if normalized_x * normalized_x + normalized_y * normalized_y <= 1.0:
				set_pixel_safe(image, x, y, color)


static func fill_rounded_rect(image: Image, rect: Rect2i, radius: int, color: Color) -> void:
	fill_rect(image, Rect2i(rect.position.x + radius, rect.position.y, rect.size.x - radius * 2, rect.size.y), color)
	fill_rect(image, Rect2i(rect.position.x, rect.position.y + radius, rect.size.x, rect.size.y - radius * 2), color)
	fill_circle(image, rect.position + Vector2i(radius, radius), radius, color)
	fill_circle(image, Vector2i(rect.end.x - radius - 1, rect.position.y + radius), radius, color)
	fill_circle(image, Vector2i(rect.position.x + radius, rect.end.y - radius - 1), radius, color)
	fill_circle(image, rect.end - Vector2i(radius + 1, radius + 1), radius, color)


static func fill_polygon(image: Image, points: PackedVector2Array, color: Color) -> void:
	if points.size() < 3:
		return
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for point in points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	var start_x := maxi(int(floor(minimum.x)), 0)
	var start_y := maxi(int(floor(minimum.y)), 0)
	var end_x := mini(int(ceil(maximum.x)), image.get_width() - 1)
	var end_y := mini(int(ceil(maximum.y)), image.get_height() - 1)
	for y in range(start_y, end_y + 1):
		for x in range(start_x, end_x + 1):
			if point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				image.set_pixel(x, y, color)


static func point_in_polygon(point: Vector2, points: PackedVector2Array) -> bool:
	var inside := false
	var previous_index := points.size() - 1
	for index in points.size():
		var current: Vector2 = points[index]
		var previous: Vector2 = points[previous_index]
		if (current.y > point.y) != (previous.y > point.y):
			var intersection_x := (previous.x - current.x) * (point.y - current.y) / (previous.y - current.y) + current.x
			if point.x < intersection_x:
				inside = not inside
		previous_index = index
	return inside


static func set_pixel_safe(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
		image.set_pixel(x, y, color)

