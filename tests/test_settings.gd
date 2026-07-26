extends GutTest

const SM := preload("res://scripts/util/settings_manager.gd")

func after_each():
	var f := FileAccess.open("user://settings.cfg", FileAccess.WRITE)
	if f:
		f.close()

func test_rebindable_actions_not_empty():
	assert_gt(SM.REBINDABLE_ACTIONS.size(), 0, "REBINDABLE_ACTIONS is non-empty")

func test_all_rebindable_actions_have_input_map_entry():
	for action in SM.REBINDABLE_ACTIONS:
		assert_true(InputMap.has_action(action), "%s has InputMap entry" % action)

func test_default_values():
	var sm := SM.new()
	assert_false(sm.reduced_motion, "reduced_motion defaults to false")
	assert_true(sm.screen_shake, "screen_shake defaults to true")
	assert_eq(sm.colorblind_mode, 0, "colorblind_mode defaults to 0")

func test_save_and_reload_roundtrip():
	var sm := SM.new()
	sm.reduced_motion = true
	sm.screen_shake = false
	sm.colorblind_mode = 2
	sm.save()

	var sm2 := SM.new()
	assert_true(sm2.reduced_motion, "reduced_motion persists")
	assert_false(sm2.screen_shake, "screen_shake persists")
	assert_eq(sm2.colorblind_mode, 2, "colorblind_mode persists")

func test_save_creates_file():
	var sm := SM.new()
	sm.reduced_motion = true
	sm.save()
	assert_true(FileAccess.file_exists("user://settings.cfg"), "settings.cfg exists after save")

func after_all():
	var f := FileAccess.open("user://settings.cfg", FileAccess.WRITE)
	if f:
		f.close()
