class_name PortraitGenerator
extends RefCounted

const RasterArt = preload("res://assets/SelectionRasterArt.gd")
const OUTLINE := Color("#171924")


static func generate(primary: Color, accent: Color, silhouette_id: int) -> Texture2D:
	return ImageTexture.create_from_image(generate_image(primary, accent, silhouette_id))


static func generate_image(primary: Color, accent: Color, silhouette_id: int) -> Image:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	match silhouette_id:
		0:
			draw_light(image, primary, accent)
		1:
			draw_medium_light(image, primary, accent)
		2:
			draw_medium_heavy(image, primary, accent)
		_:
			draw_heavy(image, primary, accent)
	return image


static func draw_light(image: Image, primary: Color, accent: Color) -> void:
	# Two helmet spikes give the light racer a small, energetic outline.
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(35, 42), Vector2(24, 12), Vector2(51, 29)]), OUTLINE)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(77, 29), Vector2(105, 13), Vector2(93, 45)]), OUTLINE)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(36, 37), Vector2(28, 19), Vector2(48, 31)]), accent)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(80, 31), Vector2(100, 19), Vector2(92, 39)]), accent)
	RasterArt.fill_ellipse(image, Vector2i(64, 108), 43, 20, OUTLINE)
	RasterArt.fill_ellipse(image, Vector2i(64, 108), 39, 16, primary)
	RasterArt.fill_circle(image, Vector2i(64, 62), 35, OUTLINE)
	RasterArt.fill_circle(image, Vector2i(64, 62), 31, primary)
	RasterArt.fill_ellipse(image, Vector2i(64, 66), 23, 13, accent)
	RasterArt.fill_circle(image, Vector2i(55, 64), 4, OUTLINE)
	RasterArt.fill_circle(image, Vector2i(74, 64), 4, OUTLINE)
	RasterArt.fill_rect(image, Rect2i(59, 80, 11, 3), OUTLINE)


static func draw_medium_light(image: Image, primary: Color, accent: Color) -> void:
	# An asymmetric side fin and stripe distinguish the agile all-rounder.
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(90, 37), Vector2(113, 49), Vector2(93, 63)]), OUTLINE)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(91, 42), Vector2(105, 49), Vector2(93, 57)]), accent)
	RasterArt.fill_ellipse(image, Vector2i(64, 108), 46, 21, OUTLINE)
	RasterArt.fill_ellipse(image, Vector2i(64, 108), 42, 17, primary)
	RasterArt.fill_ellipse(image, Vector2i(62, 61), 35, 39, OUTLINE)
	RasterArt.fill_ellipse(image, Vector2i(62, 61), 31, 35, primary)
	RasterArt.fill_polygon(image, PackedVector2Array([Vector2(37, 35), Vector2(48, 27), Vector2(45, 87), Vector2(34, 76)]), accent)
	RasterArt.fill_rect(image, Rect2i(45, 55, 42, 12), OUTLINE)
	RasterArt.fill_rect(image, Rect2i(49, 58, 34, 6), accent)
	RasterArt.fill_circle(image, Vector2i(55, 60), 3, OUTLINE)
	RasterArt.fill_circle(image, Vector2i(76, 60), 3, OUTLINE)


static func draw_medium_heavy(image: Image, primary: Color, accent: Color) -> void:
	# Broad shoulders and an unmistakable two-lens goggles band read at a glance.
	RasterArt.fill_ellipse(image, Vector2i(64, 107), 55, 24, OUTLINE)
	RasterArt.fill_ellipse(image, Vector2i(64, 107), 50, 19, primary)
	RasterArt.fill_ellipse(image, Vector2i(64, 59), 45, 36, OUTLINE)
	RasterArt.fill_ellipse(image, Vector2i(64, 59), 40, 31, primary)
	RasterArt.fill_rect(image, Rect2i(20, 51, 88, 17), OUTLINE)
	RasterArt.fill_circle(image, Vector2i(48, 59), 14, OUTLINE)
	RasterArt.fill_circle(image, Vector2i(80, 59), 14, OUTLINE)
	RasterArt.fill_circle(image, Vector2i(48, 59), 9, accent)
	RasterArt.fill_circle(image, Vector2i(80, 59), 9, accent)
	RasterArt.fill_circle(image, Vector2i(48, 59), 4, OUTLINE)
	RasterArt.fill_circle(image, Vector2i(80, 59), 4, OUTLINE)
	RasterArt.fill_rect(image, Rect2i(55, 82, 18, 4), OUTLINE)


static func draw_heavy(image: Image, primary: Color, accent: Color) -> void:
	# The heavy racer uses a large block helmet and the thickest silhouette.
	RasterArt.fill_ellipse(image, Vector2i(64, 108), 61, 27, OUTLINE)
	RasterArt.fill_ellipse(image, Vector2i(64, 108), 54, 20, primary)
	RasterArt.fill_rect(image, Rect2i(10, 43, 15, 34), OUTLINE)
	RasterArt.fill_rect(image, Rect2i(103, 43, 15, 34), OUTLINE)
	RasterArt.fill_rounded_rect(image, Rect2i(21, 18, 86, 82), 18, OUTLINE)
	RasterArt.fill_rounded_rect(image, Rect2i(27, 24, 74, 70), 14, primary)
	RasterArt.fill_rect(image, Rect2i(28, 36, 72, 16), accent)
	RasterArt.fill_rect(image, Rect2i(35, 53, 58, 20), OUTLINE)
	RasterArt.fill_rect(image, Rect2i(41, 57, 46, 12), accent)
	RasterArt.fill_rect(image, Rect2i(47, 58, 8, 10), OUTLINE)
	RasterArt.fill_rect(image, Rect2i(73, 58, 8, 10), OUTLINE)
	RasterArt.fill_rect(image, Rect2i(52, 82, 24, 5), OUTLINE)

