extends Control

const VOLUNTEER_DATA_SCRIPT := preload("res://scripts/data/volunteer_data.gd")
const PLAYER_SHEET := preload("res://assets/sprites/where/character_9_frame32x32.png")
const VOLUNTEER_SHEET := preload("res://assets/sprites/where/character_1_frame32x32.png")
const ENEMY_SHEET := preload("res://assets/sprites/where/character_17_frame32x32.png")

enum Phase {DAY, NIGHT, ENDED}

const GRID_SIZE := 8
const MAX_DAYS := 10
const PLAYER_MOVES_PER_DAY := 4
const VOLUNTEER_COST := 5
const ITEM_VALUE := 3
const MOVEMENT_ANIM_DURATION := 1.0
# 玩家 / 志愿者 / 扒手统一用同一显示尺寸（与地砖比例一致）。
const GRID_ACTOR_DISPLAY_SIZE := Vector2(96, 96)
# 图集角色在格内视觉微调：相对脚底对齐公式的偏移。
const ACTOR_CELL_NUDGE := Vector2(-45, 36)
const ENEMY_COUNT := 3
const DIRS_8: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]
const CARDINAL_DIRS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

@onready var game_name_label: Label = $RootMargin/MainVBox/TopBar/GameNameLabel
@onready var version_label: Label = $RootMargin/MainVBox/TopBar/VersionLabel
@onready var restart_button: Button = $RootMargin/MainVBox/TopBar/RestartButton
@onready var help_button: Button = $RootMargin/MainVBox/TopBar/HelpButton
@onready var map_panel: PanelContainer = $RootMargin/MainVBox/CenterPanel/MapPanel
@onready var map_grid: GridContainer = $RootMargin/MainVBox/CenterPanel/MapPanel/MapMargin/MapGrid
@onready var actor_viewport_container: SubViewportContainer = $RootMargin/MainVBox/CenterPanel/MapPanel/MapMargin/ActorViewportContainer
@onready var actor_subviewport: SubViewport = $RootMargin/MainVBox/CenterPanel/MapPanel/MapMargin/ActorViewportContainer/ActorSubViewport
@onready var actors_root: Node2D = $RootMargin/MainVBox/CenterPanel/MapPanel/MapMargin/ActorViewportContainer/ActorSubViewport/ActorsRoot
@onready var fx_layer: Control = $RootMargin/MainVBox/CenterPanel/MapPanel/MapMargin/FxLayer
@onready var night_overlay: ColorRect = $RootMargin/MainVBox/CenterPanel/MapPanel/MapMargin/NightOverlay
@onready var top_bar: HBoxContainer = $RootMargin/MainVBox/TopBar
@onready var info_sidebar_title: Label = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/InfoSidebarTitle
@onready var info_panel: PanelContainer = $RootMargin/MainVBox/CenterPanel/InfoPanel
@onready var turn_card: PanelContainer = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/TurnCard
@onready var enemy_card: PanelContainer = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/EnemyCard
@onready var ally_card: PanelContainer = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard
@onready var status_label: Label = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/TurnCard/TurnMargin/TurnVBox/StatusLabel
@onready var objective_label: Label = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/EnemyCard/EnemyMargin/EnemyVBox/ObjectiveLabel
@onready var enemy_avatar_row: HBoxContainer = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/EnemyCard/EnemyMargin/EnemyVBox/EnemyAvatarRow
@onready var shop_gold_label: Label = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/ShopHeader/ShopGoldLabel
@onready var shop_volunteer_button: Button = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/ShopVolunteerButton
@onready var shop_volunteer_dot: Panel = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/ShopVolunteerButton/ShopVolunteerDot
@onready var shop_price_bg: Panel = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/ShopVolunteerButton/ShopPriceBg
@onready var end_day_button: Button = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/TurnCard/TurnMargin/TurnVBox/EndDayButton
@onready var move_label: Label = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/MoveLabel
@onready var move_grid: GridContainer = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/MoveGrid
@onready var move_up_left_button: Button = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/MoveGrid/MoveUpLeftButton
@onready var move_up_button: Button = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/MoveGrid/MoveUpButton
@onready var move_up_right_button: Button = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/MoveGrid/MoveUpRightButton
@onready var move_left_button: Button = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/MoveGrid/MoveLeftButton
@onready var move_right_button: Button = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/MoveGrid/MoveRightButton
@onready var move_down_left_button: Button = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/MoveGrid/MoveDownLeftButton
@onready var move_down_button: Button = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/MoveGrid/MoveDownButton
@onready var move_down_right_button: Button = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/MoveGrid/MoveDownRightButton
@onready var event_log_label: RichTextLabel = $RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/LogCard/LogMargin/LogVBox/EventLogLabel
@onready var help_dialog: AcceptDialog = $HelpDialog
@onready var phase_banner: Label = $PhaseBanner

var phase: int = Phase.DAY
var current_day: int = 1
var moves_left: int = PLAYER_MOVES_PER_DAY
var coins: int = 10
var survey_used_today: bool = false

var player_pos: Vector2i = Vector2i.ZERO
var player_facing: Vector2i = Vector2i(0, 1)
var enemy_positions: Array[Vector2i] = []
var enemy_facings: Array[Vector2i] = []
var revealed_enemy_positions: Array[Vector2i] = []
var item_positions: Array[Vector2i] = []
var volunteers: Array[VolunteerData] = []

var animating_move: bool = false
var night_active_enemy_index: int = -1
var map_buttons: Array[Button] = []
var logs: Array[String] = []
var survey_flash_cells: Array[Vector2i] = []
var survey_flash_on: bool = false
var night_trail_pending: bool = false
var is_shaking: bool = false
var night_overlay_tween: Tween
var phase_focus_tween: Tween
var night_particles: CPUParticles2D
var night_vignette_top: ColorRect
var night_vignette_bottom: ColorRect
var night_vignette_left: ColorRect
var night_vignette_right: ColorRect
var tile_style_cache: Dictionary = {}
var slot_style_cache: Dictionary = {}
var player_actor: MapAnimatedActor = null
var volunteer_actors: Array[MapAnimatedActor] = []
var enemy_actors: Array[MapAnimatedActor] = []
var prev_player_pos: Vector2i = Vector2i(-1, -1)
var prev_volunteer_positions: Array[Vector2i] = []
var prev_enemy_positions: Array[Vector2i] = []


func _ready() -> void:
	randomize()
	_apply_visual_style()
	_disable_button_focus()
	_connect_signals()
	_setup_help_text()
	_create_map_buttons()
	actor_viewport_container.resized.connect(_on_actor_viewport_resized)
	# 首帧内 GridContainer 子控件的 size/position 往往尚未更新，立刻算 _cell_to_actor_position 会得到 (0,0) 等错误值，
	# 角色会出现在棋盘外；点击触发 _sync_ui 后布局已稳定才“飞”回格内。等一帧再开局即可。
	await get_tree().process_frame
	_sync_actor_subviewport_size()
	_start_new_run()


func _exit_tree() -> void:
	if night_overlay_tween != null and night_overlay_tween.is_running():
		night_overlay_tween.kill()
	if phase_focus_tween != null and phase_focus_tween.is_running():
		phase_focus_tween.kill()
	if night_particles != null:
		night_particles.emitting = false
	tile_style_cache.clear()
	slot_style_cache.clear()
	survey_flash_cells.clear()
	_reset_actor_nodes()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_day_active() or animating_move:
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		match key_event.keycode:
			KEY_UP:
				_try_move_player(Vector2i(0, -1))
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_try_move_player(Vector2i(0, 1))
				get_viewport().set_input_as_handled()
			KEY_LEFT:
				_try_move_player(Vector2i(-1, 0))
				get_viewport().set_input_as_handled()
			KEY_RIGHT:
				_try_move_player(Vector2i(1, 0))
				get_viewport().set_input_as_handled()
			KEY_SPACE:
				_do_survey()
				get_viewport().set_input_as_handled()


func _connect_signals() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	help_button.pressed.connect(_on_help_pressed)
	shop_volunteer_button.pressed.connect(_on_shop_volunteer_pressed)
	end_day_button.pressed.connect(_on_end_day_pressed)

	move_up_button.pressed.connect(func() -> void: _try_move_player(Vector2i(0, -1)))
	move_left_button.pressed.connect(func() -> void: _try_move_player(Vector2i(-1, 0)))
	move_right_button.pressed.connect(func() -> void: _try_move_player(Vector2i(1, 0)))
	move_down_button.pressed.connect(func() -> void: _try_move_player(Vector2i(0, 1)))


func _setup_help_text() -> void:
	help_dialog.dialog_text = "《Where》第一幕（教学关）\n\n" \
	+ "1) 每局开局警长随机出生在某一空地；地图显示警长、志愿者与物品，扒手隐藏。\n" \
	+ "2) 警长白天只能上下左右移动，每天最多 4 步；移动有 1 秒动画，动画中无法操作。\n" \
	+ "3) 商店购买志愿者（5💴），随机落在空地，朝向随机，白天不可转向。\n" \
	+ "4) 警长白天可按空格进行一次调查：2步内扒手在当日显形。\n" \
	+ "5) 夜晚志愿者与扒手自动行动；右侧红色头像表示扒手，黑夜会高亮当前行动者。\n" \
	+ "6) 夜晚志愿者无法前进会转向 180° 再尝试；探测前后两格内扒手会短暂显形。\n" \
	+ "7) 物品被拾取可得 3💴。"


func _create_map_buttons() -> void:
	for child in map_grid.get_children():
		child.queue_free()
	map_buttons.clear()
	map_grid.columns = GRID_SIZE

	for i in GRID_SIZE * GRID_SIZE:
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(62, 62)
		tile.focus_mode = Control.FOCUS_NONE
		tile.flat = false
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		tile.add_theme_font_size_override("font_size", 20)
		tile.gui_input.connect(_on_tile_gui_input.bind(i))
		map_grid.add_child(tile)
		map_buttons.append(tile)


func _on_actor_viewport_resized() -> void:
	_sync_actor_subviewport_size()


func _sync_actor_subviewport_size() -> void:
	# 与棋盘最小尺寸一致，避免 SubViewportContainer 在 Margin 里撑满整列高度把顶栏挤出视口。
	var gms := map_grid.get_combined_minimum_size()
	if gms.x >= 1.0 and gms.y >= 1.0:
		actor_viewport_container.custom_minimum_size = gms
	var s := actor_viewport_container.size
	var w := maxi(1, int(s.x))
	var h := maxi(1, int(s.y))
	actor_subviewport.size = Vector2i(w, h)


func _disable_button_focus() -> void:
	for button in _collect_all_buttons(self):
		button.focus_mode = Control.FOCUS_NONE


func _collect_all_buttons(root: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for child in root.get_children():
		if child is Button:
			buttons.append(child)
		buttons.append_array(_collect_all_buttons(child))
	return buttons


func _start_new_run() -> void:
	phase = Phase.DAY
	current_day = 1
	moves_left = PLAYER_MOVES_PER_DAY
	coins = 10
	survey_used_today = false
	volunteers.clear()
	night_active_enemy_index = -1
	enemy_facings.clear()
	revealed_enemy_positions.clear()
	item_positions.clear()
	logs.clear()
	_reset_actor_nodes()
	_set_night_ambience(false, false)

	player_pos = _initial_player_position()
	enemy_positions.clear()
	var occupied: Array[Vector2i] = [player_pos]
	for _i in ENEMY_COUNT:
		var e := _random_empty_position(occupied)
		enemy_positions.append(e)
		enemy_facings.append(Vector2i(0, 1))
		occupied.append(e)

	_spawn_initial_items(8)
	_add_log("警长随机出生在 (%d,%d)。" % [player_pos.x, player_pos.y])
	_add_log("第一幕开始。目标：逮捕全部扒手。")
	_sync_ui()
	_show_phase_banner("白天", Color("67e8f9"))


func _on_restart_pressed() -> void:
	_start_new_run()


func _on_help_pressed() -> void:
	help_dialog.popup_centered()


func _on_shop_volunteer_pressed() -> void:
	if not _is_day_active() or animating_move:
		return
	if coins < VOLUNTEER_COST:
		_add_log("金币不足，需要 5💴。")
		return
	var pos := _random_empty_cell_for_volunteer_deploy()
	if pos.x < 0:
		_add_log("没有可部署志愿者的空地。")
		return
	coins -= VOLUNTEER_COST
	var dir_idx := randi() % CARDINAL_DIRS.size()
	volunteers.append(VOLUNTEER_DATA_SCRIPT.new(pos, dir_idx, current_day))
	_add_log("已购买志愿者，随机部署于 (%d,%d)。" % [pos.x, pos.y])
	_sync_ui()


func _on_end_day_pressed() -> void:
	if phase != Phase.DAY or animating_move:
		return
	_start_night_transition_async()


func _start_night_transition_async() -> void:
	phase = Phase.NIGHT
	night_trail_pending = true
	night_active_enemy_index = -1
	_play_phase_focus_fx(false)
	_set_night_ambience(true, true)
	revealed_enemy_positions.clear()
	_sync_ui()
	_show_phase_banner("黑夜", Color("818cf8"))
	await _process_night_phase_async()

	if _is_game_ended():
		night_active_enemy_index = -1
		_sync_ui()
		return

	current_day += 1
	if current_day > MAX_DAYS:
		_end_game(false, "天数用尽，仍有扒手在逃。")
		night_active_enemy_index = -1
		_sync_ui()
		return

	phase = Phase.DAY
	moves_left = PLAYER_MOVES_PER_DAY
	survey_used_today = false
	revealed_enemy_positions.clear()
	night_active_enemy_index = -1
	_play_phase_focus_fx(true)
	_set_night_ambience(false, true)
	_add_log("第 %d 天白天开始。警长恢复 4 步行动。" % current_day)
	_sync_ui()
	_show_phase_banner("白天", Color("67e8f9"))


func _on_tile_gui_input(event: InputEvent, tile_index: int) -> void:
	if phase == Phase.ENDED or animating_move:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			return
		var pos := Vector2i(tile_index % GRID_SIZE, floori(float(tile_index) / float(GRID_SIZE)))
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_on_left_click_tile(pos)


func _on_left_click_tile(_pos: Vector2i) -> void:
	if not _is_day_active():
		return
	_add_log("白天请用方向键移动警长，或从商店购买志愿者。")
	_sync_ui()


func _try_move_player(delta: Vector2i) -> void:
	if not _is_day_active() or animating_move:
		return
	if moves_left <= 0:
		_add_log("今日警长行动步数已用完。")
		return
	var next := player_pos + delta
	if not _is_inside(next):
		_add_log("超出边界，无法移动。")
		return

	if player_actor == null:
		_ensure_player_actor()

	animating_move = true
	player_facing = delta
	moves_left -= 1
	var from_cell := player_pos
	var target_cell := next
	player_actor.set_facing(delta)
	player_actor.snap_to(_cell_to_actor_position(from_cell, player_actor))
	await player_actor.animate_to(_cell_to_actor_position(target_cell, player_actor), MOVEMENT_ANIM_DURATION)
	player_pos = target_cell
	animating_move = false
	prev_player_pos = player_pos
	_capture_enemy_at(player_pos)
	_pick_item_at(player_pos, "警长")
	_add_log("警长移动到 (%d,%d)，剩余步数 %d。" % [player_pos.x, player_pos.y, moves_left])
	_check_victory()
	_sync_ui()


func _process_night_phase_async() -> void:
	if phase != Phase.NIGHT or _is_game_ended():
		return

	# 志愿者：移动 + 扫描（每步 1s 动画）
	for i in volunteers.size():
		var old_pos: Vector2i = volunteers[i].pos
		_apply_volunteer_night_move(i)
		var new_pos: Vector2i = volunteers[i].pos
		_pick_item_at(volunteers[i].pos, "志愿者")
		if old_pos != new_pos and i < volunteer_actors.size():
			var actor: MapAnimatedActor = volunteer_actors[i]
			var v := volunteers[i]
			actor.set_facing(CARDINAL_DIRS[v.dir_index])
			if night_trail_pending:
				_spawn_trail_from_actor(actor)
			await actor.animate_to(_cell_to_actor_position(new_pos, actor), MOVEMENT_ANIM_DURATION)
		else:
			await get_tree().create_timer(MOVEMENT_ANIM_DURATION).timeout
		await _volunteer_scan_reveal_async(volunteers[i].pos, CARDINAL_DIRS[volunteers[i].dir_index])
		_sync_ui()

	# 扒手：隐藏移动，无地图特效；头像边框高亮当前行动者
	var blocked := _allied_positions()
	for i in enemy_positions.size():
		night_active_enemy_index = i
		_sync_ui()
		var from := enemy_positions[i]
		var to := _enemy_step(enemy_positions[i], blocked)
		enemy_positions[i] = to
		var delta := to - from
		if delta != Vector2i.ZERO and i < enemy_facings.size():
			enemy_facings[i] = delta
		blocked = _allied_positions()
		await get_tree().create_timer(MOVEMENT_ANIM_DURATION).timeout

	night_active_enemy_index = -1
	_sync_ui()

	if enemy_positions.has(player_pos):
		_end_game(false, "黑夜中扒手贴脸，警长行动失败。")
		return

	_check_victory()


func _apply_volunteer_night_move(i: int) -> void:
	var v := volunteers[i]
	var dir := CARDINAL_DIRS[v.dir_index]
	var next := v.pos + dir
	if _volunteer_can_enter_cell(next):
		v.pos = next
	else:
		v.dir_index = (v.dir_index + 2) % CARDINAL_DIRS.size()
		dir = CARDINAL_DIRS[v.dir_index]
		next = v.pos + dir
		if _volunteer_can_enter_cell(next):
			v.pos = next
	volunteers[i] = v


func _volunteer_can_enter_cell(p: Vector2i) -> bool:
	if not _is_inside(p):
		return false
	if _volunteer_index_at(p) >= 0:
		return false
	if p == player_pos:
		return false
	if enemy_positions.has(p):
		return false
	return true


func _volunteer_scan_cells(pos: Vector2i, dir: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for step_idx in 2:
		var step := step_idx + 1
		var front: Vector2i = pos + dir * step
		var back: Vector2i = pos - dir * step
		if _is_inside(front) and not cells.has(front):
			cells.append(front)
		if _is_inside(back) and not cells.has(back):
			cells.append(back)
	return cells


func _volunteer_scan_reveal_async(pos: Vector2i, dir: Vector2i) -> void:
	var found_front := false
	var found_back := false
	var found_cells: Array[Vector2i] = []
	for step_idx in 2:
		var step := step_idx + 1
		var front: Vector2i = pos + dir * step
		var back: Vector2i = pos - dir * step
		if _is_inside(front) and enemy_positions.has(front):
			found_front = true
			if not found_cells.has(front):
				found_cells.append(front)
		if _is_inside(back) and enemy_positions.has(back):
			found_back = true
			if not found_cells.has(back):
				found_cells.append(back)

	var flash_cells := _volunteer_scan_cells(pos, dir)
	await _play_volunteer_scan_flash_async(flash_cells)

	if found_front or found_back:
		var report := ""
		if found_front:
			report += "前方"
		if found_back:
			report += "后方"
		_add_log("志愿者(%d,%d) 报告：%s2格内有扒手。"
			% [pos.x, pos.y, report])
		_spawn_floating_text("发现!", Color("f97316"), pos)
		_play_screen_shake(3.0, 3, 0.14)
		for c in found_cells:
			if not revealed_enemy_positions.has(c):
				revealed_enemy_positions.append(c)
		_sync_ui()


func _play_volunteer_scan_flash_async(cells: Array[Vector2i]) -> void:
	if cells.is_empty():
		return
	survey_flash_cells = cells.duplicate()
	survey_flash_on = true
	_sync_ui()
	await get_tree().create_timer(0.10).timeout
	survey_flash_on = false
	_sync_ui()
	await get_tree().create_timer(0.10).timeout
	survey_flash_on = true
	_sync_ui()
	await get_tree().create_timer(0.16).timeout
	survey_flash_on = false
	survey_flash_cells.clear()
	_sync_ui()


func _enemy_step(from: Vector2i, blocked: Array[Vector2i]) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for d in CARDINAL_DIRS:
		var next := from + d
		if _is_inside(next) and not blocked.has(next):
			candidates.append(next)
	if candidates.is_empty():
		return from if not blocked.has(from) else from
	return candidates[randi() % candidates.size()]


func _do_survey() -> void:
	if not _is_day_active() or animating_move:
		return
	if survey_used_today:
		_add_log("今天已经调查过了。")
		return
	survey_used_today = true
	var flash_cells := _get_cells_within_steps(player_pos, 2)
	_play_survey_flash(flash_cells)
	var found := 0
	for e in enemy_positions:
		if _manhattan(player_pos, e) <= 2 and not revealed_enemy_positions.has(e):
			revealed_enemy_positions.append(e)
			found += 1
	_add_log("调查完成：2步范围内发现扒手 %d 名（当日显形）。" % found)
	_spawn_floating_text("发现 %d" % found, Color("fbbf24"), player_pos)
	if found > 0:
		_play_screen_shake(4.0, 4, 0.18)
	_sync_ui()


func _play_survey_flash(cells: Array[Vector2i]) -> void:
	survey_flash_cells = cells.duplicate()
	survey_flash_on = true
	_sync_ui()
	await get_tree().create_timer(0.10).timeout
	survey_flash_on = false
	_sync_ui()
	await get_tree().create_timer(0.10).timeout
	survey_flash_on = true
	_sync_ui()
	await get_tree().create_timer(0.16).timeout
	survey_flash_on = false
	survey_flash_cells.clear()
	_sync_ui()


func _capture_enemy_at(pos: Vector2i) -> void:
	var count := 0
	var captured_positions: Array[Vector2i] = []
	for i in range(enemy_positions.size() - 1, -1, -1):
		if enemy_positions[i] == pos:
			captured_positions.append(enemy_positions[i])
			revealed_enemy_positions.erase(enemy_positions[i])
			enemy_positions.remove_at(i)
			if i < enemy_facings.size():
				enemy_facings.remove_at(i)
			count += 1
	if count > 0:
		_add_log("抓捕成功：逮捕扒手 %d 名。" % count)
		for cp in captured_positions:
			_spawn_capture_flash(cp)
			_spawn_floating_text("抓捕!", Color("ef4444"), cp)
		_play_screen_shake(7.0, 6, 0.26)


func _pick_item_at(pos: Vector2i, picker: String) -> void:
	for i in range(item_positions.size() - 1, -1, -1):
		if item_positions[i] == pos:
			item_positions.remove_at(i)
			coins += ITEM_VALUE
			_add_log("%s拾取物品，获得 %d💴。" % [picker, ITEM_VALUE])


func _check_victory() -> void:
	if enemy_positions.is_empty() and not _is_game_ended():
		_end_game(true, "所有扒手已被逮捕。")


func _sync_ui() -> void:
	game_name_label.text = "WHERE · 第一幕教学关"
	version_label.text = "v0.1.0"
	end_day_button.text = "结束白天"
	info_sidebar_title.text = "本局信息"

	status_label.text = "回合\n第 %d/%d 天 · %s" % [current_day, MAX_DAYS, _phase_text()]
	objective_label.text = "扒手（占位头像）"

	shop_gold_label.text = "💴 %d" % coins
	shop_volunteer_button.disabled = not _is_day_active() or animating_move or coins < VOLUNTEER_COST

	end_day_button.disabled = phase != Phase.DAY or animating_move

	var can_move := _is_day_active() and moves_left > 0 and not animating_move
	move_up_button.disabled = not can_move
	move_left_button.disabled = not can_move
	move_right_button.disabled = not can_move
	move_down_button.disabled = not can_move
	var survey_text := "已用" if survey_used_today else "可用"
	move_label.text = "步数：%d（方向键） 调查[空格]：%s" % [moves_left, survey_text]

	_render_enemy_avatars()
	_render_map()
	_render_actors()
	_render_log()
	_sync_actor_subviewport_size()


func _render_enemy_avatars() -> void:
	for c in enemy_avatar_row.get_children():
		c.queue_free()
	for i in enemy_positions.size():
		var avatar_node := PanelContainer.new()
		avatar_node.custom_minimum_size = Vector2(40, 40)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.82, 0.18, 0.18, 1.0)
		style.corner_radius_top_left = 99
		style.corner_radius_top_right = 99
		style.corner_radius_bottom_left = 99
		style.corner_radius_bottom_right = 99
		if night_active_enemy_index == i:
			style.border_color = Color(1.0, 0.92, 0.35, 1.0)
			style.border_width_left = 4
			style.border_width_top = 4
			style.border_width_right = 4
			style.border_width_bottom = 4
		else:
			style.border_color = Color(0.35, 0.35, 0.4, 1.0)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
		avatar_node.add_theme_stylebox_override("panel", style)
		enemy_avatar_row.add_child(avatar_node)


func _render_map() -> void:
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var pos := Vector2i(x, y)
			var idx := y * GRID_SIZE + x
			var tile := map_buttons[idx]

			# 地图仅显示己方与物品，扒手隐藏。
			var icon := ""
			if item_positions.has(pos):
				icon = "💴"
			var vol_idx := _volunteer_index_at(pos)
			if enemy_positions.has(pos) and pos == player_pos:
				icon = "💥"

			tile.text = icon
			tile.tooltip_text = "坐标(%d,%d)" % [x, y]
			_style_tile(
				tile,
				pos == player_pos,
				item_positions.has(pos),
				vol_idx >= 0,
				((x + y) % 2) == 0,
				survey_flash_on and survey_flash_cells.has(pos)
			)


func _render_actors() -> void:
	if map_buttons.is_empty():
		return
	_ensure_player_actor()
	_sync_player_actor()
	_sync_volunteer_actors()
	_sync_enemy_actors()
	night_trail_pending = false
	prev_player_pos = player_pos
	prev_volunteer_positions.clear()
	for v in volunteers:
		prev_volunteer_positions.append(v.pos)
	prev_enemy_positions.clear()
	prev_enemy_positions.append_array(enemy_positions)


func _ensure_player_actor() -> void:
	if player_actor != null:
		return
	player_actor = MapAnimatedActor.new()
	player_actor.name = "PlayerActor"
	actors_root.add_child(player_actor)
	player_actor.setup_from_sheet(PLAYER_SHEET, 32, GRID_ACTOR_DISPLAY_SIZE)


func _sync_player_actor() -> void:
	if player_actor == null:
		return
	if animating_move:
		return
	player_actor.visible = true
	player_actor.set_facing(player_facing)
	player_actor.snap_to(_cell_to_actor_position(player_pos, player_actor))


func _sync_volunteer_actors() -> void:
	while volunteer_actors.size() < volunteers.size():
		var actor := MapAnimatedActor.new()
		actor.name = "VolunteerActor_%d" % volunteer_actors.size()
		actors_root.add_child(actor)
		actor.setup_from_sheet(VOLUNTEER_SHEET, 32, GRID_ACTOR_DISPLAY_SIZE)
		volunteer_actors.append(actor)
	while volunteer_actors.size() > volunteers.size():
		var last: MapAnimatedActor = volunteer_actors.pop_back()
		last.queue_free()

	for i in volunteers.size():
		var actor: MapAnimatedActor = volunteer_actors[i]
		var volunteer := volunteers[i]
		var facing := CARDINAL_DIRS[volunteer.dir_index]
		actor.set_facing(facing)
		actor.visible = true
		var target := _cell_to_actor_position(volunteer.pos, actor)
		actor.snap_to(target)


func _sync_enemy_actors() -> void:
	while enemy_actors.size() < enemy_positions.size():
		var actor := MapAnimatedActor.new()
		actor.name = "EnemyActor_%d" % enemy_actors.size()
		actors_root.add_child(actor)
		actor.setup_from_sheet(ENEMY_SHEET, 32, GRID_ACTOR_DISPLAY_SIZE)
		enemy_actors.append(actor)
	while enemy_actors.size() > enemy_positions.size():
		var last: MapAnimatedActor = enemy_actors.pop_back()
		last.queue_free()

	for i in enemy_positions.size():
		var actor: MapAnimatedActor = enemy_actors[i]
		var pos := enemy_positions[i]
		var can_show := revealed_enemy_positions.has(pos) or _is_game_ended()
		actor.visible = can_show and pos != player_pos
		if i < enemy_facings.size():
			actor.set_facing(enemy_facings[i])
		var target := _cell_to_actor_position(pos, actor)
		actor.snap_to(target)


func _cell_to_actor_position(cell: Vector2i, actor: MapAnimatedActor) -> Vector2:
	var idx := cell.y * GRID_SIZE + cell.x
	if idx < 0 or idx >= map_buttons.size():
		return Vector2.ZERO
	var tile := map_buttons[idx]
	var center := map_grid.position + tile.position + tile.size * 0.5
	var actor_size := actor.display_size
	# 角色脚点对齐到格子中心（底部居中），人物向上覆盖到上方格子边线附近。
	return center - Vector2(actor_size.x * 0.5, actor_size.y) + ACTOR_CELL_NUDGE


func _cell_center(cell: Vector2i) -> Vector2:
	var idx := cell.y * GRID_SIZE + cell.x
	if idx < 0 or idx >= map_buttons.size():
		return Vector2.ZERO
	var tile := map_buttons[idx]
	return map_grid.position + tile.position + tile.size * 0.5


func _spawn_floating_text(text: String, color: Color, cell: Vector2i) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 26)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(label)
	var center := _cell_center(cell)
	label.position = center - Vector2(26, 38)
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 24.0, 0.35)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35)
	tween.finished.connect(func() -> void: label.queue_free())


func _spawn_capture_flash(cell: Vector2i) -> void:
	var idx := cell.y * GRID_SIZE + cell.x
	if idx < 0 or idx >= map_buttons.size():
		return
	var tile := map_buttons[idx]
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.1, 0.1, 0.55)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.position = map_grid.position + tile.position
	flash.size = tile.size
	fx_layer.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.28)
	tween.finished.connect(func() -> void: flash.queue_free())


func _spawn_danger_wave(cell: Vector2i) -> void:
	var center := _cell_center(cell)
	var wave := Panel.new()
	wave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wave.position = center - Vector2(8, 8)
	wave.size = Vector2(16, 16)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(1.0, 0.24, 0.24, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 99
	style.corner_radius_top_right = 99
	style.corner_radius_bottom_left = 99
	style.corner_radius_bottom_right = 99
	wave.add_theme_stylebox_override("panel", style)
	fx_layer.add_child(wave)

	var tween := create_tween()
	tween.tween_property(wave, "size", Vector2(76, 76), 0.24)
	tween.parallel().tween_property(wave, "position", center - Vector2(38, 38), 0.24)
	tween.parallel().tween_property(wave, "modulate:a", 0.0, 0.24)
	tween.finished.connect(func() -> void: wave.queue_free())


func _set_night_ambience(active: bool, animated: bool) -> void:
	_ensure_night_fx_nodes()
	if night_overlay_tween != null and night_overlay_tween.is_running():
		night_overlay_tween.kill()
	if active:
		night_overlay.visible = true
		_show_vignette_nodes(true)
		if night_particles != null:
			night_particles.visible = true
			night_particles.emitting = true
		if animated:
			night_overlay_tween = create_tween()
			night_overlay_tween.tween_property(night_overlay, "color", Color(0.03, 0.04, 0.08, 0.14), 0.32)
			night_overlay_tween.parallel().tween_property(night_vignette_top, "color", Color(0.0, 0.0, 0.0, 0.20), 0.32)
			night_overlay_tween.parallel().tween_property(night_vignette_bottom, "color", Color(0.0, 0.0, 0.0, 0.20), 0.32)
			night_overlay_tween.parallel().tween_property(night_vignette_left, "color", Color(0.0, 0.0, 0.0, 0.16), 0.32)
			night_overlay_tween.parallel().tween_property(night_vignette_right, "color", Color(0.0, 0.0, 0.0, 0.16), 0.32)
			if night_particles != null:
				night_overlay_tween.parallel().tween_property(night_particles, "modulate:a", 1.0, 0.32)
		else:
			night_overlay.color = Color(0.03, 0.04, 0.08, 0.14)
			night_vignette_top.color = Color(0.0, 0.0, 0.0, 0.20)
			night_vignette_bottom.color = Color(0.0, 0.0, 0.0, 0.20)
			night_vignette_left.color = Color(0.0, 0.0, 0.0, 0.16)
			night_vignette_right.color = Color(0.0, 0.0, 0.0, 0.16)
			if night_particles != null:
				night_particles.modulate.a = 1.0
	else:
		if animated:
			night_overlay_tween = create_tween()
			night_overlay_tween.tween_property(night_overlay, "color", Color(0.03, 0.04, 0.08, 0.0), 0.28)
			night_overlay_tween.parallel().tween_property(night_vignette_top, "color", Color(0.0, 0.0, 0.0, 0.0), 0.28)
			night_overlay_tween.parallel().tween_property(night_vignette_bottom, "color", Color(0.0, 0.0, 0.0, 0.0), 0.28)
			night_overlay_tween.parallel().tween_property(night_vignette_left, "color", Color(0.0, 0.0, 0.0, 0.0), 0.28)
			night_overlay_tween.parallel().tween_property(night_vignette_right, "color", Color(0.0, 0.0, 0.0, 0.0), 0.28)
			if night_particles != null:
				night_overlay_tween.parallel().tween_property(night_particles, "modulate:a", 0.0, 0.28)
			night_overlay_tween.finished.connect(func() -> void:
				night_overlay.visible = false
				_show_vignette_nodes(false)
				if night_particles != null:
					night_particles.emitting = false
					night_particles.visible = false
			)
		else:
			night_overlay.color = Color(0.03, 0.04, 0.08, 0.0)
			night_overlay.visible = false
			night_vignette_top.color = Color(0.0, 0.0, 0.0, 0.0)
			night_vignette_bottom.color = Color(0.0, 0.0, 0.0, 0.0)
			night_vignette_left.color = Color(0.0, 0.0, 0.0, 0.0)
			night_vignette_right.color = Color(0.0, 0.0, 0.0, 0.0)
			_show_vignette_nodes(false)
			if night_particles != null:
				night_particles.modulate.a = 0.0
				night_particles.emitting = false
				night_particles.visible = false


func _spawn_trail_from_actor(actor: MapAnimatedActor) -> void:
	var tex := actor.get_current_frame_texture()
	if tex == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = tex
	ghost.scale = actor.sprite.scale
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.centered = false
	ghost.position = actor.position
	ghost.modulate = Color(0.5, 0.8, 1.0, 0.45)
	actors_root.add_child(ghost)
	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.parallel().tween_property(ghost, "position:y", ghost.position.y - 6.0, 0.22)
	tween.finished.connect(func() -> void: ghost.queue_free())


func _ensure_night_fx_nodes() -> void:
	var fx_parent := night_overlay.get_parent()
	if night_vignette_top == null:
		night_vignette_top = _create_vignette_strip("NightVignetteTop", fx_parent)
		night_vignette_top.anchor_left = 0.0
		night_vignette_top.anchor_right = 1.0
		night_vignette_top.anchor_top = 0.0
		night_vignette_top.anchor_bottom = 0.0
		night_vignette_top.offset_left = 0.0
		night_vignette_top.offset_right = 0.0
		night_vignette_top.offset_top = 0.0
		night_vignette_top.offset_bottom = 86.0
	if night_vignette_bottom == null:
		night_vignette_bottom = _create_vignette_strip("NightVignetteBottom", fx_parent)
		night_vignette_bottom.anchor_left = 0.0
		night_vignette_bottom.anchor_right = 1.0
		night_vignette_bottom.anchor_top = 1.0
		night_vignette_bottom.anchor_bottom = 1.0
		night_vignette_bottom.offset_left = 0.0
		night_vignette_bottom.offset_right = 0.0
		night_vignette_bottom.offset_top = -86.0
		night_vignette_bottom.offset_bottom = 0.0
	if night_vignette_left == null:
		night_vignette_left = _create_vignette_strip("NightVignetteLeft", fx_parent)
		night_vignette_left.anchor_left = 0.0
		night_vignette_left.anchor_right = 0.0
		night_vignette_left.anchor_top = 0.0
		night_vignette_left.anchor_bottom = 1.0
		night_vignette_left.offset_left = 0.0
		night_vignette_left.offset_right = 74.0
		night_vignette_left.offset_top = 0.0
		night_vignette_left.offset_bottom = 0.0
	if night_vignette_right == null:
		night_vignette_right = _create_vignette_strip("NightVignetteRight", fx_parent)
		night_vignette_right.anchor_left = 1.0
		night_vignette_right.anchor_right = 1.0
		night_vignette_right.anchor_top = 0.0
		night_vignette_right.anchor_bottom = 1.0
		night_vignette_right.offset_left = -74.0
		night_vignette_right.offset_right = 0.0
		night_vignette_right.offset_top = 0.0
		night_vignette_right.offset_bottom = 0.0

	if night_particles == null:
		night_particles = CPUParticles2D.new()
		night_particles.name = "NightDust"
		night_particles.amount = 55
		night_particles.lifetime = 2.8
		night_particles.one_shot = false
		night_particles.preprocess = 1.2
		night_particles.emitting = false
		night_particles.visible = false
		night_particles.local_coords = false
		night_particles.direction = Vector2(-0.2, 1.0)
		night_particles.spread = 36.0
		night_particles.initial_velocity_min = 8.0
		night_particles.initial_velocity_max = 18.0
		night_particles.gravity = Vector2(-8.0, 5.0)
		night_particles.scale_amount_min = 0.45
		night_particles.scale_amount_max = 0.8
		night_particles.color = Color(0.72, 0.78, 0.95, 0.22)
		night_particles.z_index = 30
		night_particles.position = map_grid.position + map_grid.size * 0.5
		night_particles.modulate.a = 0.0
		fx_parent.add_child(night_particles)


func _create_vignette_strip(node_name: String, parent: Node) -> ColorRect:
	var strip := ColorRect.new()
	strip.name = node_name
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.visible = false
	strip.color = Color(0.0, 0.0, 0.0, 0.0)
	strip.z_index = 20
	parent.add_child(strip)
	return strip


func _show_vignette_nodes(should_show: bool) -> void:
	if night_vignette_top != null:
		night_vignette_top.visible = should_show
	if night_vignette_bottom != null:
		night_vignette_bottom.visible = should_show
	if night_vignette_left != null:
		night_vignette_left.visible = should_show
	if night_vignette_right != null:
		night_vignette_right.visible = should_show


func _play_screen_shake(intensity: float, steps: int, duration_sec: float) -> void:
	if is_shaking:
		return
	if steps <= 0:
		return
	is_shaking = true
	var base_fx := fx_layer.position
	var base_map_grid := map_grid.position
	var base_actor_vp := actor_viewport_container.position
	for _i in steps:
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		fx_layer.position = base_fx + offset
		map_grid.position = base_map_grid + offset
		actor_viewport_container.position = base_actor_vp + offset
		await get_tree().create_timer(duration_sec / float(steps)).timeout
	fx_layer.position = base_fx
	map_grid.position = base_map_grid
	actor_viewport_container.position = base_actor_vp
	is_shaking = false


func _reset_actor_nodes() -> void:
	for child in actors_root.get_children():
		child.queue_free()
	for child in fx_layer.get_children():
		child.queue_free()
	player_actor = null
	volunteer_actors.clear()
	enemy_actors.clear()
	prev_player_pos = Vector2i(-1, -1)
	prev_volunteer_positions.clear()
	prev_enemy_positions.clear()


func _render_log() -> void:
	event_log_label.text = "[color=#93c5fd]%s[/color]" % "\n".join(logs)


func _add_log(message: String) -> void:
	logs.append("• " + message)
	if logs.size() > 14:
		logs.remove_at(0)


func _end_game(is_win: bool, reason: String) -> void:
	phase = Phase.ENDED
	var result := "胜利" if is_win else "失败"
	_add_log("游戏结束：%s。%s" % [result, reason])


func _show_phase_banner(text: String, color: Color) -> void:
	phase_banner.visible = true
	phase_banner.text = text
	phase_banner.modulate = Color(color.r, color.g, color.b, 0.0)
	var tween := create_tween()
	tween.tween_property(phase_banner, "modulate:a", 1.0, 0.25)
	tween.tween_interval(0.35)
	tween.tween_property(phase_banner, "modulate:a", 0.0, 0.35)
	tween.finished.connect(func() -> void: phase_banner.visible = false)


func _play_phase_focus_fx(is_day: bool) -> void:
	if phase_focus_tween != null and phase_focus_tween.is_running():
		phase_focus_tween.kill()

	var target_card: PanelContainer = turn_card if is_day else enemy_card
	var card_color := Color("67e8f9") if is_day else Color("c084fc")

	map_panel.pivot_offset = map_panel.size * 0.5
	target_card.pivot_offset = target_card.size * 0.5

	map_panel.scale = Vector2.ONE
	target_card.scale = Vector2.ONE
	target_card.modulate = Color(1, 1, 1, 1)

	phase_focus_tween = create_tween()
	phase_focus_tween.tween_property(map_panel, "scale", Vector2(1.03, 1.03), 0.18)
	phase_focus_tween.parallel().tween_property(target_card, "scale", Vector2(1.035, 1.035), 0.18)
	phase_focus_tween.parallel().tween_property(target_card, "modulate", Color(card_color.r, card_color.g, card_color.b, 1.0), 0.18)
	phase_focus_tween.tween_property(map_panel, "scale", Vector2.ONE, 0.26)
	phase_focus_tween.parallel().tween_property(target_card, "scale", Vector2.ONE, 0.26)
	phase_focus_tween.parallel().tween_property(target_card, "modulate", Color(1, 1, 1, 1), 0.26)


func _is_day_active() -> bool:
	return phase == Phase.DAY and not _is_game_ended()


func _is_game_ended() -> bool:
	return phase == Phase.ENDED


func _phase_text() -> String:
	match phase:
		Phase.DAY:
			return "白天"
		Phase.NIGHT:
			return "黑夜"
		Phase.ENDED:
			return "已结束"
		_:
			return "-"


func _is_inside(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < GRID_SIZE and pos.y < GRID_SIZE


func _allied_positions() -> Array[Vector2i]:
	var occupied: Array[Vector2i] = [player_pos]
	for v in volunteers:
		occupied.append(v.pos)
	return occupied


func _random_empty_position(occupied: Array[Vector2i]) -> Vector2i:
	var all_positions: Array[Vector2i] = []
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var p := Vector2i(x, y)
			if not occupied.has(p):
				all_positions.append(p)
	return all_positions[randi() % all_positions.size()]


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _get_cells_within_steps(center: Vector2i, max_steps: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var p := Vector2i(x, y)
			if _manhattan(center, p) <= max_steps:
				cells.append(p)
	return cells


func _volunteer_index_at(pos: Vector2i) -> int:
	for i in volunteers.size():
		if volunteers[i].pos == pos:
			return i
	return -1


func _random_empty_cell_for_volunteer_deploy() -> Vector2i:
	var candidates: Array[Vector2i] = []
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var p := Vector2i(x, y)
			if p == player_pos:
				continue
			if enemy_positions.has(p):
				continue
			if _volunteer_index_at(p) >= 0:
				continue
			candidates.append(p)
	if candidates.is_empty():
		return Vector2i(-1, -1)
	return candidates[randi() % candidates.size()]


func _spawn_initial_items(count: int) -> void:
	var occupied: Array[Vector2i] = [player_pos]
	occupied.append_array(enemy_positions)
	item_positions.clear()
	for _i in count:
		var candidates: Array[Vector2i] = []
		for y in GRID_SIZE:
			for x in GRID_SIZE:
				var p := Vector2i(x, y)
				if not occupied.has(p) and not item_positions.has(p):
					candidates.append(p)
		if candidates.is_empty():
			break
		item_positions.append(candidates[randi() % candidates.size()])
	_add_log("开局：%d 个物品已随机散落在地图上。" % item_positions.size())


func _apply_visual_style() -> void:
	var background := get_node_or_null("Background") as ColorRect
	if background == null:
		background = ColorRect.new()
		background.name = "Background"
		background.color = Color(0.03, 0.05, 0.10, 1.0)
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(background)
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		move_child(background, 0)

	top_bar.custom_minimum_size = Vector2(0, 52)
	game_name_label.add_theme_font_size_override("font_size", 34)
	game_name_label.add_theme_color_override("font_color", Color("7dd3fc"))
	version_label.add_theme_color_override("font_color", Color("94a3b8"))
	info_sidebar_title.add_theme_font_size_override("font_size", 22)
	info_sidebar_title.add_theme_color_override("font_color", Color("7dd3fc"))
	status_label.add_theme_color_override("font_color", Color("e2e8f0"))
	objective_label.add_theme_color_override("font_color", Color("cbd5e1"))
	shop_gold_label.add_theme_color_override("font_color", Color("fef08a"))
	move_label.add_theme_color_override("font_color", Color("93c5fd"))
	event_log_label.add_theme_color_override("default_color", Color("93c5fd"))

	map_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("0f172a"), Color("334155")))
	info_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("111827"), Color("1d4ed8")))
	turn_card.add_theme_stylebox_override("panel", _make_panel_style(Color("0b1220"), Color("2563eb")))
	enemy_card.add_theme_stylebox_override("panel", _make_panel_style(Color("111827"), Color("7c3aed")))
	ally_card.add_theme_stylebox_override("panel", _make_panel_style(Color("0b1220"), Color("0ea5e9")))
	$RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/LogCard.add_theme_stylebox_override("panel", _make_panel_style(Color("0b1220"), Color("334155")))

	_style_action_button(restart_button, Color("ef4444"))
	_style_action_button(help_button, Color("0284c7"))
	_style_shop_volunteer_button()
	_style_action_button(end_day_button, Color("dc2626"))
	for b in [move_up_button, move_left_button, move_right_button, move_down_button]:
		_style_action_button(b, Color("2563eb"))

	# 禁止对角移动，隐藏对角按钮
	move_up_left_button.visible = false
	move_up_right_button.visible = false
	move_down_left_button.visible = false
	move_down_right_button.visible = false
	$RootMargin/MainVBox/CenterPanel/InfoPanel/InfoMargin/InfoVBox/AllyCard/AllyMargin/AllyVBox/MoveGrid/MoveCenterLabel.visible = false
	move_grid.visible = false

	move_grid.add_theme_constant_override("h_separation", 10)
	move_grid.add_theme_constant_override("v_separation", 10)
	map_grid.add_theme_constant_override("h_separation", 3)
	map_grid.add_theme_constant_override("v_separation", 3)
	map_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	map_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# 左侧面板只随棋盘增高，不在整窗高度上纵向撑满（否则顶栏易被挤出可见区域）。
	map_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var center_row := map_panel.get_parent() as HBoxContainer
	if center_row != null:
		center_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	actor_viewport_container.stretch = false
	actor_viewport_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	actor_viewport_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for b in [move_up_button, move_left_button, move_right_button, move_down_button]:
		b.custom_minimum_size = Vector2(72, 72)
		b.add_theme_font_size_override("font_size", 28)


func _style_shop_volunteer_button() -> void:
	shop_volunteer_button.flat = true
	shop_volunteer_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	shop_volunteer_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	shop_volunteer_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	shop_volunteer_button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())

	var dot := StyleBoxFlat.new()
	dot.bg_color = Color(0.22, 0.48, 0.96, 1.0)
	dot.corner_radius_top_left = 99
	dot.corner_radius_top_right = 99
	dot.corner_radius_bottom_left = 99
	dot.corner_radius_bottom_right = 99
	shop_volunteer_dot.add_theme_stylebox_override("panel", dot)

	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.22, 0.48, 0.96, 1.0)
	base.corner_radius_top_left = 99
	base.corner_radius_top_right = 99
	base.corner_radius_bottom_left = 99
	base.corner_radius_bottom_right = 99
	var hover := base.duplicate()
	hover.bg_color = Color(0.32, 0.58, 1.0, 1.0)
	var pressed := base.duplicate()
	pressed.bg_color = Color(0.14, 0.36, 0.82, 1.0)
	var disabled := base.duplicate()
	disabled.bg_color = Color(0.28, 0.32, 0.4, 1.0)
	shop_volunteer_button.add_theme_stylebox_override("normal", base)
	shop_volunteer_button.add_theme_stylebox_override("hover", hover)
	shop_volunteer_button.add_theme_stylebox_override("pressed", pressed)
	shop_volunteer_button.add_theme_stylebox_override("disabled", disabled)

	var badge := StyleBoxFlat.new()
	badge.bg_color = Color(1.0, 0.86, 0.22, 1.0)
	badge.corner_radius_top_left = 99
	badge.corner_radius_top_right = 99
	badge.corner_radius_bottom_left = 99
	badge.corner_radius_bottom_right = 99
	shop_price_bg.add_theme_stylebox_override("panel", badge)


func _initial_player_position() -> Vector2i:
	var none: Array[Vector2i] = []
	return _random_empty_position(none)


func _make_panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 8
	return style


func _style_action_button(button: Button, color: Color) -> void:
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 15)

	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8

	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.12)
	var pressed := normal.duplicate()
	pressed.bg_color = color.darkened(0.2)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.30, 0.33, 0.38, 1.0)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)


func _slot_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color("64748b")
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	return s


func _get_cached_slot_styles(color: Color) -> Dictionary:
	var key := "slot_%s" % color.to_html()
	if slot_style_cache.has(key):
		return slot_style_cache[key]

	var style_set := {
		"normal": _slot_style(color),
		"hover": _slot_style(color.lightened(0.1)),
		"pressed": _slot_style(color.darkened(0.15)),
	}
	slot_style_cache[key] = style_set
	return style_set


func _get_cached_tile_styles(fill_color: Color, border_color: Color) -> Dictionary:
	var key := "tile_%s_%s" % [fill_color.to_html(), border_color.to_html()]
	if tile_style_cache.has(key):
		return tile_style_cache[key]

	var normal := StyleBoxFlat.new()
	normal.bg_color = fill_color
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = border_color
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6

	var hover := normal.duplicate()
	hover.bg_color = fill_color.lightened(0.14)
	hover.border_color = Color("d9e6fb")
	var pressed := normal.duplicate()
	pressed.bg_color = fill_color.darkened(0.1)

	var style_set := {
		"normal": normal,
		"hover": hover,
		"pressed": pressed,
	}
	tile_style_cache[key] = style_set
	return style_set


func _style_tile(
	tile: Button,
	is_player: bool,
	is_item: bool,
	is_volunteer: bool,
	is_even_cell: bool,
	is_survey_flash: bool
) -> void:
	# 黑灰棋盘底色，避免高饱和地砖干扰角色可读性。
	var color := Color("1f1f1f") if is_even_cell else Color("343434")
	if is_item:
		color = Color("92400e")
	if is_volunteer:
		color = Color("0f766e")
	if is_player:
		color = Color("1d4ed8")
	if is_survey_flash:
		color = Color("f59e0b")
	var border_color := Color("fef08a") if is_survey_flash else Color("9fb3d1")
	var styles := _get_cached_tile_styles(color, border_color)
	tile.add_theme_stylebox_override("normal", styles["normal"])
	tile.add_theme_stylebox_override("hover", styles["hover"])
	tile.add_theme_stylebox_override("pressed", styles["pressed"])
	tile.add_theme_stylebox_override("disabled", styles["normal"])
