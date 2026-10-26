# Windows build and graphics modes

Export from the project root with `GODOT=/path/to/godot bash scripts/tools/export_windows.sh release`, or on Windows run `powershell -ExecutionPolicy Bypass -File scripts/tools/export_windows.ps1 -Mode release`. The export requires Godot Windows export templates matching the exact installed editor version. The result is `builds/windows/MoonGame.exe`, a 64-bit Windows executable with an embedded PCK. No signing keys are bundled. To check the preset without templates: `python scripts/tools/check_windows_export.py`.

Use `MoonGame.exe` for Forward+ rendering. Settings > Quality supports Auto (full resolution), High (full resolution, 4096 shadow atlas), Medium (85% 3D resolution, 2048 atlas), and Low (67% resolution, 1024 atlas). Settings are saved to `user://settings.json` on first launch. On the first exported-game launch, the Settings panel opens once so the player can review quality, sound, and accessibility options before playing. Launch flags after `--` override the quality for the current run, e.g. `MoonGame.exe -- --quality=medium`.

For hardware that cannot run Forward+, use the `Launch Compatibility.cmd` placed next to the exported executable. It starts Godot with `--rendering-method gl_compatibility` and selects low quality. The Compatibility renderer omits some Forward+ effects; review lighting and atmosphere on actual hardware. Do not put `--rendering-method` after the `--` separator.

A real GPU playtest and export-template installation are still required before marking S-17 complete.

After exporting, run "powershell -ExecutionPolicy Bypass -File scripts/tools/smoke_windows_export.ps1" to smoke the actual executable in Forward+ and Compatibility modes.
