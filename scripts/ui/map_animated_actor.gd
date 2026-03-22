extends Node2D
class_name MapAnimatedActor

const ANIM_DOWN := &"down"
const ANIM_LEFT := &"left"
const ANIM_RIGHT := &"right"
const ANIM_UP := &"up"

var sprite: AnimatedSprite2D
var display_size: Vector2 = Vector2(32, 32)
var facing: Vector2i = Vector2i(0, 1)
var idle_tween: Tween


func _ensure_sprite() -> void:
	if sprite != null:
		return
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	add_child(sprite)


func setup_from_sheet(sheet: Texture2D, frame_px: int, size_override: Vector2) -> void:
	_ensure_sprite()
	display_size = size_override
	var sf := SpriteFrames.new()
	var anim_names: Array[StringName] = [ANIM_DOWN, ANIM_LEFT, ANIM_RIGHT, ANIM_UP]
	for row in 4:
		var anim_name: StringName = anim_names[row]
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, true)
		sf.set_animation_speed(anim_name, 8.0)
		for col in 3:
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = Rect2(col * frame_px, row * frame_px, frame_px, frame_px)
			sf.add_frame(anim_name, at)
	sprite.sprite_frames = sf
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sc := Vector2(display_size.x / float(frame_px), display_size.y / float(frame_px))
	sprite.scale = sc
	sprite.position = Vector2.ZERO
	sprite.animation = ANIM_DOWN
	set_facing(facing)
	_start_idle()


func _anim_for_dir(d: Vector2i) -> StringName:
	if d.y > 0:
		return ANIM_DOWN
	if d.y < 0:
		return ANIM_UP
	if d.x < 0:
		return ANIM_LEFT
	return ANIM_RIGHT


func set_facing(direction: Vector2i) -> void:
	if direction == Vector2i.ZERO:
		return
	facing = direction
	if sprite.sprite_frames == null:
		return
	var anim := _anim_for_dir(facing)
	if not sprite.sprite_frames.has_animation(anim):
		return
	sprite.animation = anim
	sprite.play(anim)
	sprite.pause()
	sprite.frame = 1


func get_current_frame_texture() -> Texture2D:
	if sprite == null or sprite.sprite_frames == null:
		return null
	var anim: StringName = sprite.animation
	if anim.is_empty() or not sprite.sprite_frames.has_animation(anim):
		anim = _anim_for_dir(facing)
	if not sprite.sprite_frames.has_animation(anim):
		return null
	return sprite.sprite_frames.get_frame_texture(anim, sprite.frame)


func snap_to(point: Vector2) -> void:
	position = point
	set_facing(facing)
	if idle_tween == null or not idle_tween.is_running():
		_start_idle()


func animate_to(point: Vector2, duration_sec: float = 1.0) -> void:
	_stop_idle()
	if sprite.sprite_frames != null:
		var anim := _anim_for_dir(facing)
		if sprite.sprite_frames.has_animation(anim):
			sprite.animation = anim
			sprite.play(anim)
	var tween := create_tween()
	tween.tween_property(self, "position", point, duration_sec)
	await tween.finished
	if sprite != null and sprite.sprite_frames != null:
		sprite.pause()
		sprite.frame = 1
	_start_idle()


func _start_idle() -> void:
	_stop_idle()
	idle_tween = create_tween()
	idle_tween.set_loops()
	idle_tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.48)
	idle_tween.tween_property(self, "scale", Vector2.ONE, 0.48)


func _stop_idle() -> void:
	if idle_tween != null and idle_tween.is_running():
		idle_tween.kill()
	idle_tween = null
	scale = Vector2.ONE
