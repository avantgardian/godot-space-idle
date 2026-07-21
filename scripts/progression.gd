extends "res://scripts/game_controller.gd"

const GM_UNIT := 4.0 * PI * PI * 350.0 * 350.0 * 350.0 / (25.0 * 25.0)

# Per-type physical parameters (rooted in Eddington-Milne limb darkening,
# Snodgrass-Ulrich differential rotation, and observed convective features):
#   limb_strength       - limb darkening coefficient (O/B faint, M strong)
#   granulation_scale   - relative spatial frequency of convective cells
#                         (G2V ref ~1.0, F/A finer, K/M coarser, O/B ~invisible)
#   spot_regime         - "none" | "equatorial" | "polar"
#                         O/B/A: no convection-driven magnetic spots
#                         F/G/K: equatorial band |lat| < 35deg
#                         M: large polar spots (fully convective dwarfs)
#   spot_count          - number of spot seeds to seed into the u_spots array
#   corona_falloff      - glow sprite falloff power (M compact, O/B extended)
#   corona_radius_mult   - outer corona radius multiplier per type
const STAR_TYPES: Array[Dictionary] = [
	{ type="O5V", mass_min=15.0, mass_max=30.0, tex_size=320, weight=3,
	  core_0=Color(0.7, 0.85, 1.0), core_1=Color(0.5, 0.7, 0.95), core_2=Color(0.3, 0.5, 0.8),
	  glow_tint=Color(0.6, 0.8, 1.0), base_mod=Color(0.5, 0.7, 1.0), hot_mod=Color(0.7, 0.9, 1.0),
	  limb_strength=0.20, granulation_scale=1.6, spot_regime="none",    spot_count=0,
	  corona_falloff=1.0, corona_radius_mult=2.6 },
	{ type="B5V", mass_min=4.0, mass_max=12.0, tex_size=288, weight=7,
	  core_0=Color(0.8, 0.9, 1.0), core_1=Color(0.7, 0.8, 0.95), core_2=Color(0.5, 0.65, 0.85),
	  glow_tint=Color(0.7, 0.8, 1.0), base_mod=Color(0.65, 0.8, 0.95), hot_mod=Color(0.8, 0.9, 1.0),
	  limb_strength=0.30, granulation_scale=1.6, spot_regime="none",    spot_count=0,
	  corona_falloff=1.2, corona_radius_mult=2.3 },
	{ type="A5V", mass_min=1.8, mass_max=3.5, tex_size=272, weight=12,
	  core_0=Color(1.0, 1.0, 1.0), core_1=Color(0.95, 0.95, 0.9), core_2=Color(0.85, 0.85, 0.7),
	  glow_tint=Color(0.95, 0.95, 0.85), base_mod=Color(0.9, 0.9, 0.85), hot_mod=Color(0.85, 0.9, 1.0),
	  limb_strength=0.50, granulation_scale=1.6, spot_regime="none",    spot_count=0,
	  corona_falloff=1.6, corona_radius_mult=1.9 },
	{ type="F5V", mass_min=1.1, mass_max=1.8, tex_size=264, weight=18,
	  core_0=Color(1.0, 1.0, 0.9), core_1=Color(1.0, 0.95, 0.8), core_2=Color(0.9, 0.8, 0.5),
	  glow_tint=Color(1.0, 0.95, 0.7), base_mod=Color(1.0, 0.95, 0.7), hot_mod=Color(0.95, 0.95, 0.9),
	  limb_strength=0.60, granulation_scale=1.4, spot_regime="equatorial", spot_count=3,
	  corona_falloff=2.0, corona_radius_mult=1.7 },
	{ type="G2V", mass_min=0.8, mass_max=1.3, tex_size=256, weight=20,
	  core_0=Color(1.0, 0.95, 0.8), core_1=Color(1.0, 0.7, 0.2), core_2=Color(0.8, 0.3, 0.05),
	  glow_tint=Color(1.0, 0.5, 0.1), base_mod=Color(1.0, 1.0, 0.5), hot_mod=Color(1.0, 0.35, 0.05),
	  limb_strength=0.65, granulation_scale=1.0, spot_regime="equatorial", spot_count=4,
	  corona_falloff=2.2, corona_radius_mult=1.6 },
	{ type="K5V", mass_min=0.4, mass_max=0.9, tex_size=224, weight=22,
	  core_0=Color(1.0, 0.8, 0.5), core_1=Color(1.0, 0.55, 0.2), core_2=Color(0.7, 0.2, 0.05),
	  glow_tint=Color(1.0, 0.5, 0.1), base_mod=Color(1.0, 0.7, 0.3), hot_mod=Color(1.0, 0.3, 0.05),
	  limb_strength=0.75, granulation_scale=0.7, spot_regime="equatorial", spot_count=5,
	  corona_falloff=2.5, corona_radius_mult=1.4 },
	{ type="M4V", mass_min=0.1, mass_max=0.5, tex_size=192, weight=18,
	  core_0=Color(1.0, 0.5, 0.25), core_1=Color(0.9, 0.3, 0.1), core_2=Color(0.5, 0.1, 0.02),
	  glow_tint=Color(1.0, 0.3, 0.05), base_mod=Color(0.95, 0.4, 0.15), hot_mod=Color(0.6, 0.1, 0.02),
	  limb_strength=0.85, granulation_scale=0.5, spot_regime="polar",     spot_count=4,
	  corona_falloff=3.0, corona_radius_mult=1.25 },
]

const _SPACESHIP := preload("res://scripts/spaceship.gd")

var _star_type: String = "G2V"

func _ready():
	super._ready()
	var star_data := _pick_star_type()
	sun_mass = randf_range(star_data.mass_min, star_data.mass_max)
	_star_type = star_data.type
	star_data["start_mass"] = sun_mass
	star_data["mass_span"] = sun_mass
	%Sun.generate(star_data)
	_collision_mgr = _COLLISION_MGR.new([], _ASTEROID_SCRIPT, %ImpactFX, %EventLog, _dummy_planet_idx, %PostProcessManager.trigger)
	var ship := _SPACESHIP.new()
	ship.name = "Spaceship"
	ship.init(Vector2(500, 0))
	add_child(ship)
	ship.owner = self
	ship.unique_name_in_owner = true

func _process(delta):
	super._process(delta)
	var cam_following_ship: bool = %Camera2D.is_following() and %Camera2D.get_follow_target() == %Spaceship
	%Spaceship.input_active = cam_following_ship
	var barrier_r: float = OrbitalBody.sun_collision_r(sun_mass) + %Spaceship.collision_radius + 50.0
	%Spaceship.enforce_sun_barrier(barrier_r)

func _get_asteroid_gm() -> float:
	return GM_UNIT

func _format_mass_label(mass: float) -> String:
	return "Msun = %.4f [%s]" % [mass, _star_type]

func _get_click_target(screen_pos: Vector2) -> Node2D:
	if _check_ship_click(screen_pos):
		return %Spaceship
	return null

func _on_key_pressed(event):
	if event.is_action_pressed("toggle_ship_follow"):
		if %Camera2D.is_following() and %Camera2D.get_follow_target() == %Spaceship:
			%Camera2D.unfollow()
		else:
			%Camera2D.follow_node(%Spaceship)

func _check_ship_click(screen_pos: Vector2) -> bool:
	var ship_screen: Vector2 = %Camera2D.get_canvas_transform() * %Spaceship.position
	var d := ship_screen.distance_to(screen_pos)
	var hit_r: float = max(28.0 * %Camera2D.zoom.x, 14.0)
	return d < hit_r

func _dummy_planet_idx(_node: Node2D) -> int:
	return -1

func _pick_star_type() -> Dictionary:
	var total := 0
	for entry in STAR_TYPES:
		total += entry.weight
	var roll := randf() * total
	var cumulative := 0.0
	for entry in STAR_TYPES:
		cumulative += entry.weight
		if roll <= cumulative:
			return entry.duplicate(true)
	return STAR_TYPES[-1]
