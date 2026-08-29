class_name VehicleIconGenerator
extends RefCounted

const RasterArt = preload("res://assets/SelectionRasterArt.gd")
const OUTLINE := Color("#171924")
const GLASS := Color("#bcecff")


static func generate(primary: Color, accent: Color, silhouette_id: int) -> Texture2D:
	return ImageTexture.create_from_image(generate_image(primary, accent, silhouette_id))


static func generate_image(primary: Color, accent: Color, silhouette_id: int) -> Image:
	var image := Image.create(128, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	match silhouette_id:
		0:
			draw_comet(image, primary, accent)
		1:
			draw_vortex(image, primary, accent)
		2:
			draw_zipbug(image, primary, accent)
		_:
			draw_slidewinder(image, primary, accent)
	return image


static func draw_wheels(image: Image, left_x: int, right_x: int, front_y: int, rear_y: int, width: int, height: int) -> void:
	for x in [left_x, right_x]:
		RasterArt.fill_rounded_rect(image, Rect2i(x, front_y, width, height), 3, OUTLINE)
		RasterArt.fill_rounded_rect(image, Rect2i(x, rear_y, width, height), 3, OUTLINE)


static func draw_comet(image: Image, primary: Color, accent: Color) -> void:
	# Balanced proportions and a rounded nose identify the standard body.
	draw_wheels(image, 33, 84, 18, 62, 11, 20)
	RasterArt.fill_rounded_rect(image, Rect2i(40, 5, 48, 87), 18, OUTLINE)
	RasterArt.fill_rounded_rect(image, Rect2i(45, 10, 38, 77), 14, primary)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(48, 25), Vector2(80, 25), Vector2(76, 43), Vector2(52, 43)]), GLASS)
	RasterArt.fill_rect(image, Rect2i(50, 66, 28, 12), accent)
	RasterArt.fill_circle(image, Vector2i(64, 83), 4, OUTLINE)


static func draw_vortex(image: Image, primary: Color, accent: Color) -> void:
	# A long tapered speed body has the narrowest frontal profile.
	draw_wheels(image, 38, 80, 21, 66, 9, 17)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(64, 1), Vector2(85, 21), Vector2(82, 82), Vector2(64, 95), Vector2(46, 82), Vector2(43, 21)]), OUTLINE)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(64, 8), Vector2(79, 24), Vector2(77, 78), Vector2(64, 88), Vector2(51, 78), Vector2(49, 24)]), primary)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(53, 27), Vector2(75, 27), Vector2(72, 46), Vector2(56, 46)]), GLASS)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(53, 58), Vector2(75, 58), Vector2(78, 75), Vector2(50, 75)]), accent)


static func draw_zipbug(image: Image, primary: Color, accent: Color) -> void:
	# Short, wide proportions communicate quick acceleration and stability.
	draw_wheels(image, 15, 101, 24, 57, 12, 18)
	RasterArt.fill_rounded_rect(image, Rect2i(23, 15, 82, 67), 22, OUTLINE)
	RasterArt.fill_rounded_rect(image, Rect2i(29, 20, 70, 57), 18, primary)
	RasterArt.fill_ellipse(image, Vector2i(64, 32), 25, 12, GLASS)
	RasterArt.fill_rect(image, Rect2i(34, 50, 60, 17), accent)
	RasterArt.fill_circle(image, Vector2i(44, 70), 4, OUTLINE)
	RasterArt.fill_circle(image, Vector2i(84, 70), 4, OUTLINE)


static func draw_slidewinder(image: Image, primary: Color, accent: Color) -> void:
	# A diamond-like wide rear gives the drift body a unique sideways stance.
	draw_wheels(image, 20, 96, 27, 65, 12, 18)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(64, 4), Vector2(88, 21), Vector2(105, 72), Vector2(84, 92), Vector2(44, 92), Vector2(23, 72), Vector2(40, 21)]), OUTLINE)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(64, 11), Vector2(82, 25), Vector2(98, 69), Vector2(80, 85), Vector2(48, 85), Vector2(30, 69), Vector2(46, 25)]), primary)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(47, 29), Vector2(81, 29), Vector2(75, 48), Vector2(53, 48)]), GLASS)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(38, 61), Vector2(90, 61), Vector2(81, 79), Vector2(47, 79)]), accent)

