# LIGHTING (S-01): looks, helpers, budgets, baking

Source of truth for how every scene is lit. The rules come from `docs/ART_BIBLE.md` 4 ("Lighting rules"); this file is how to obey them in code.
Code lives in `scenes/lighting/`. Try everything in `res://scenes/lighting/lighting_test_room.tscn` (F6).

## The rules (ART_BIBLE 4, enforced where marked)
1. **Motivated light.** Every light has a visible source (lamp, window, TV, candle, moon). Unmotivated light is a wrongness: rare and deliberate.
2. **Real darkness.** Night looks keep ambient energy <= 0.08 (`test_lighting_presets` checks it). Never "ambient-fill" a dark room: add a motivated light.
3. **Colour temperature carries mood.** Warm practicals (~2700 K) vs cold moon. `UnrealGrade` base grades only tie the frame together.
4. **At most 2 shadow-casting dynamic lights per view** (enforced by `LightBudget`). Everything else is baked or unshadowed.
5. **The moon** is a light: milky, cool, slightly too bright (`MoonLight`).
6. **No strobing, ever** (max 3 flashes/s, no full-screen flashes). `LightFlicker` has the maths and a detector the tests use.

## Team budgets (proposed by S-01; flagged in NOTES FOR DIRECTION for the human to confirm)
| Budget | Limit | Where checked |
|---|---|---|
| Shadow-casting lights in view | 2 | `LightBudget.in_view` |
| Lights of any kind in view | 24 | `LightBudget.in_view` |
| Flicker changes (swings >= 10%) | 3 per second | `LightFlicker.max_changes_per_second` |
| Lightmap texture size | 4096 | `BakeHelper.LIGHTMAP` |
| Volumetric fog length | 40 m high, 30 m medium (80 m only for the dawn exterior) | `EnvPresets` |
Frame budget (60 fps, GTX 1660 class) is S-12's job; probe it there with the lighting test room as a reference scene.

## Environment looks (`EnvPresets`, five of them)
| Look | Used by acts | Mood |
|---|---|---|
| `night_dark` | 1, 2, 4 (interiors, road) | near-black, cold air, volumetric shafts are the only thing you see |
| `dawn` | 3, 9 (exterior) | peach horizon, long gold shafts, black forest, ACES |
| `dream` | 5, 6 | ruby-maroon, milky, thick fog, strong glow |
| `day` | 7, 8 | honey sun, clean, quietly false |
| `fire` | 9 night | the fire is the only light; amber fog that glows |
Every look has SSAO, glow, fog and tonemap on; all but `night_dark`/`fire`/`dream` use a procedural sky only where there is sky to see.
`EnvPresets.GRADE_TO_LOOK` maps each location mood (the act's `base_grade`) to a look.

**In an act:** add one `MoodEnvironment` to the scene and tick `follow_grade`. It follows `ActBase.base_grade` (via PostFX), the hidden Unreality value
(air thickens and sickens, never brightens), and `Game.settings["quality"]`. Mid-act changes: `mood.set_look("fire", 2.0)`. A scene should have exactly one.
Enum/bool properties (e.g. sky on/off) switch at the halfway point of an ease: do big look changes under a fade (`Acts.transition_to` already fades).

## Quality ladder (runtime)
`high` (and `auto`) everything on. `medium`: volumetric length <= 30 m, SSAO detail 0, radius x0.8. `low`: volumetric fog and SSAO off, glow x0.6.
(`Game.settings["quality"]` is currently auto/high/low; `medium` is ready for when the menu offers it.)

## Light helpers (`scenes/lighting/lights/`)
| Node | Kind | Shadows | Notes |
|---|---|---|---|
| `PracticalLamp` | OmniLight3D + bulb | off | hums at "off" band, drops out at "wrong"; with `wrong_id` it goes cold at "fraying" |
| `CandleLight` | OmniLight3D + flame | off | +/-7% organic flicker; cheap enough for the thirteen candles |
| `TVLight` | OmniLight3D | off | <= 2.5 level changes/s, always eased; `level()` for the screen material; Reduced Motion = steady |
| `WindowLight` | SpotLight3D | **on** | `kind` day / dawn / night; contributes to volumetric fog (the shaft). Aim the node's -Z into the room, tilted down ~12 deg |
| `MoonLight` | DirectionalLight3D | **on** | `elevation_deg`, `azimuth_deg`; turns warm when `wrong_id` goes wrong |
| `LightShaft` | FogVolume | n/a | thickens a shaft locally. Static. Dust motes are S-14 |
Window + moon are the two default shadow casters; use `shadows = false` on a secondary window. All helpers read Unreality only through
`Unreality.ramp` / `wrongs` / `motion_scale()`, as the ART_BIBLE authoring rules require. Flicker is *light*, so Reduced Motion makes it steady.

## Light shafts
A shaft = a shadowed spot/directional light with `light_volumetric_fog_energy > 0` inside an Environment with volumetric fog enabled (all looks except at
`low` quality), plus optionally a `LightShaft` for local density. The window frame casts the pattern because the light is shadowed.

## Baking workflow (interiors)
Interiors are baked or probe-lit; only the lamp/candle/TV/moon-type lights stay dynamic. Baking needs the Godot **editor** (agents cannot do it in a
software-rendered sandbox), so the code does the preparation and the human clicks once.
1. In the room builder: `BakeHelper.add_room_probes(room, bounds, room_id)` (LightmapGI + an interior box-projected ReflectionProbe), `BakeHelper.ensure_uv2(room)` for
   primitive/greybox meshes, `BakeHelper.mark_dynamic(node)` for anything that moves or is a wrongness object (chandeliers that breathe, doors, props).
2. Static fixtures (chandelier, sconce, window sun) get `BakeHelper.set_light_baked(light, true)`. Anything with flicker or Unreality behaviour stays dynamic.
3. Imported `.glb` meshes: import with *Light Baking: Static Lightmaps* (generates UV2). Walls/floors/ceilings must be one-sided-correct and closed (no gaps at corners) or light leaks.
4. Editor: open the room scene, select `<room>_lightmap`, **Bake Lightmaps**. Save the `.lmbake` next to the scene. The reflection probe updates once on load.
5. Re-bake after moving static geometry or baked lights. Do not commit giant lightmaps casually: ask the human first where bakes should live (open question below).
Because the bake ignores sky (`interior = true`, environment disabled), a window only lights the room if a baked window light exists; `WindowLight` baked + dynamic moon is the usual night setup.

## Verification limits (read before claiming anything)
The agents' sandbox renders in software with the Compatibility renderer: **no SSAO, no volumetric fog, no glow quality, no FogVolume**. What is verified here:
headless tests for the maths, budgets and node setup (`test_lighting_presets`, `test_mood_environment`, `test_light_helpers`, `test_light_budget`, `test_lighting_room`,
`test_bake_helper`) and software screenshots that "render and read correctly" (night_dark, dawn). **Unverified in a real window:** SSAO strength, glow/bloom, fog colour and
density, the volumetric shafts and `LightShaft`, the baked results, the whole `dream`/`day`/`fire` look, and the `medium` quality step. The human should open the test
room, press 1-5 and U, and judge.

## Open questions for the human
- Where do baked `.lmbake` files live (repo size)? Git LFS, or bake in CI/locally only?
- Confirm the team budgets above (24 lights in view; 4096 lightmaps).
- Should `medium` appear in the Settings menu?
