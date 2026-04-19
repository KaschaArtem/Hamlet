extends Node3D


@export_group("Links")
@export var world_env: WorldEnvironment
@export var sun_light: DirectionalLight3D
@export var moon_light: DirectionalLight3D

@export_group("Sky Colors Day")
@export var day_top_color := Color("6d8794")
@export var day_horizon_color := Color("b8ccd1")
@export var day_ground_bottom_color := Color("1a1c1e")
@export var day_ground_horizon_color := Color("4a535c")

@export_group("Sky Colors Sunset")
@export var sunset_top_color := Color("2a3d52")
@export var sunset_horizon_color := Color("e67e22")
@export var sunset_ground_bottom_color := Color("101010")
@export var sunset_ground_horizon_color := Color("3a2315")

@export_group("Sky Colors Night")
@export var night_top_color := Color("010102")
@export var night_horizon_color := Color("040508")
@export var night_ground_bottom_color := Color("000000")
@export var night_ground_horizon_color := Color("020203")

const FULL_CIRCLE = TAU
const SUN_START_ANGLE = -PI / 3 
const MOON_START_ANGLE = SUN_START_ANGLE + PI 


func _ready() -> void:
	if world_env and world_env.environment:
		world_env.environment = world_env.environment.duplicate()
		if world_env.environment.sky:
			world_env.environment.sky = world_env.environment.sky.duplicate()
			world_env.environment.sky.sky_material = world_env.environment.sky.sky_material.duplicate()


func _update_lights(progress: float) -> void:
	var angle_offset = progress * FULL_CIRCLE

	sun_light.rotation.x = SUN_START_ANGLE - angle_offset
	var sun_h = -sin(sun_light.rotation.x)
	
	sun_light.light_energy = clamp(sun_h * 2.0, 0.0, 1.0)
	sun_light.visible = sun_light.light_energy > 0

	var sun_color_factor = clamp(remap(sun_h, -0.1, 0.7, 0.0, 1.0), 0.0, 1.0)
	sun_light.light_color = Color("ff4500").lerp(Color("fff5eb"), sun_color_factor)

	moon_light.rotation.x = MOON_START_ANGLE - angle_offset
	var moon_h = -sin(moon_light.rotation.x)
	moon_light.light_energy = clamp(moon_h * 0.5, 0.0, 0.3)
	moon_light.visible = moon_light.light_energy > 0

	if world_env and world_env.environment:
		var env = world_env.environment
		var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
		
		if sky_mat:
			var target_top: Color
			var target_horizon: Color
			var target_g_bottom: Color
			var target_g_horizon: Color

			if sun_h > 0.7:
				target_top = day_top_color
				target_horizon = day_horizon_color
				target_g_bottom = day_ground_bottom_color
				target_g_horizon = day_ground_horizon_color
			elif sun_h > -0.3:
				var sunset_factor = clamp(remap(sun_h, -0.3, 0.7, 0.0, 1.0), 0.0, 1.0)
				
				sunset_factor = smoothstep(0.0, 1.0, sunset_factor)
				
				target_top = sunset_top_color.lerp(day_top_color, sunset_factor)
				target_horizon = sunset_horizon_color.lerp(day_horizon_color, sunset_factor)
				target_g_bottom = sunset_ground_bottom_color.lerp(day_ground_bottom_color, sunset_factor)
				target_g_horizon = sunset_ground_horizon_color.lerp(day_ground_horizon_color, sunset_factor)
			else:
				var night_factor = clamp(remap(sun_h, -0.8, -0.3, 1.0, 0.0), 0.0, 1.0)
				night_factor = smoothstep(0.0, 1.0, night_factor)
				
				target_top = sunset_top_color.lerp(night_top_color, night_factor)
				target_horizon = sunset_horizon_color.lerp(night_horizon_color, night_factor)
				target_g_bottom = sunset_ground_bottom_color.lerp(night_ground_bottom_color, night_factor)
				target_g_horizon = sunset_ground_horizon_color.lerp(night_ground_horizon_color, night_factor)

			sky_mat.sky_top_color = target_top
			sky_mat.sky_horizon_color = target_horizon
			sky_mat.ground_bottom_color = target_g_bottom
			sky_mat.ground_horizon_color = target_g_horizon

		var general_night_factor = clamp(remap(sun_h, -0.5, 0.3, 1.0, 0.0), 0.0, 1.0)
		env.set("exposure_multiplier", lerp(1.1, 0.1, general_night_factor))
		env.ambient_light_energy = lerp(1.0, 0.0, general_night_factor)
		env.set("sky_energy_multiplier", lerp(1.0, 0.01, general_night_factor))