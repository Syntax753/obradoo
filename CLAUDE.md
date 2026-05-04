# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Obradoo is an Obra Dinn-inspired deduction POC built in **Godot 4.6** (GL Compatibility renderer). The player roams a first-person 3D manor (`scenes/world/manor_3d.tscn`), rendered through a 1-bit dither post-process for the Obra Dinn aesthetic, and steps into "memory" triggers — each of which opens a turn-by-turn 2D diorama of a past scene.

## Commands

Both helper scripts auto-discover a `Godot_*.exe` under `%LOCALAPPDATA%\Programs\Godot\` and a few other common paths.

- `tools/launch.ps1` — open the project in the Godot editor.
- `tools/test.ps1` — headless validation: runs `--editor --quit` to catch scene/script parse errors, then runs `tools/validate.gd` to load every `Memory` resource, build every timeline, and instantiate every scene. **Run this after editing memories, timelines, or scenes.**
- Direct invocation: `Godot.exe --headless --path . --script res://tools/validate.gd`

There is no test framework — `tools/validate.gd` is the entire test suite.

## Architecture

### Autoloads (registered in `project.godot`)

- **`MemoryRegistry`** (`autoload/memory_registry.gd`) — at startup, scans `res://data/memories/` for `.tres` files, loads each as a `Memory` resource, and exposes them sorted by `order`. **This `DirAccess` scan does not work in exported builds**; for export, replace with an index resource.
- **`GameState`** (`autoload/game_state.gd`) — owns scene transitions and persistence. Save file is `user://obradoo_save.cfg` and stores `discovered_memories` (memory ids visited), `actor_guesses` (actor_id → player's guessed name), and `concluded` (whether the case has been finalised). All scene changes go through `GameState` (`enter_world`, `enter_memory`, `enter_active_memory_scene`, `return_to_menu`); deduction state changes go through `set_actor_guess` and `conclude_case`.

### Data model

A `Memory` (`data/memory.gd`, `class_name Memory extends Resource`) is a small descriptor: `id`, `order`, `title`, `subtitle`, `intro`, `scene_path` (the scene to instantiate when "entered"), `timeline_id` (key into `data/timelines/`), and `world_position` (tile in the manor where its trigger spawns). Memories are authored as `.tres` files in `data/memories/`.

A **timeline** is a GDScript in `data/timelines/<timeline_id>.gd` with a `build() -> Dictionary` method. The dictionary returns `{title, grid_width, grid_height, actors, props, turns}`. Each turn is `{actor_states, events}`:

- `actor_states[actor_id]` must contain the keys `pos, facing, action, holding, gesture, gesture_target` (validated by `tools/validate.gd`).
- `events[]` items have `kind ∈ {"narration", "dialogue", "action"}`.
- Use `Vector2i(-9999, -9999)` (the `NO_TARGET` sentinel) when a gesture has no target.

**Authoring conventions for timelines** (see comment header in `data/timelines/toast.gd`):
- Actor `label`s are anonymous tags ("1"–"5"). Real names appear **only** inside dialogue text — the player has to deduce identities.
- Actor IDs are **stable across all timelines**: `a1` in `arrival.gd` is the same person as `a1` in `discovery.gd`. The canonical roster (real name, role, colour) lives in `data/cast.gd` (`Cast.ROSTER`). When adding a new timeline, reuse the same `a1`–`a5` ids and colours.
- `holding` values are item IDs; their display labels live in `HELD_LABELS` in `scenes/timeline_memory/grid_view.gd`.
- Valid `gesture` values: `"" | "pour" | "drink" | "raise" | "lean" | "stagger" | "kneel" | "watch"`. Adding a new gesture requires a corresponding entry in `GESTURE_CAPTIONS` and (usually) a `_draw_*_overlay` method in `grid_view.gd`.

### Scene flow

`main_menu` → `manor` (world) → on trigger interaction, `GameState.enter_memory(memory)` → `intro_card` → `enter_active_memory_scene` → `timeline_memory` (or whatever `memory.scene_path` points to) → back to `manor`.

`scenes/timeline_memory/timeline_memory.tscn` is a generic player: it reads `GameState.active_memory()`, loads `res://data/timelines/<timeline_id>.gd`, and drives `GridView` (`grid_view.gd`) which renders the diorama and emits `actor_clicked`. Adding a new memory typically means: write a new timeline `.gd`, write a new `Memory` `.tres` pointing at it, and place its `world_position` in the manor.

### Manor world

`scenes/world/manor_3d.gd` builds the first-person world procedurally from `ROOMS`/`WALLS` tile constants and the `MemoryRegistry`. The 3D scene renders into a low-res `SubViewport` (640×360), and the `SubViewportContainer` carries a `ShaderMaterial` using `scenes/world/dither.gdshader` — a 4×4 Bayer ordered-dither that snaps every output pixel to one of two palette colours (ink + parchment). UI is a separate `CanvasLayer` so it isn't dithered.

Triggers are `Area3D` cylinders placed at each memory's `world_position`; entering one shows a "Glimpse"/"Recall" prompt, and `ui_accept` (Space) calls `GameState.enter_memory`. The first-person controller is in the same script: WASD/arrows for movement, mouse-look while captured, ESC to free the cursor (e.g. to click the Menu button), F1 or click-in-viewport to recapture.

`TILE = 2.0` metres in the 3D world. `Memory.world_position: Vector2i` maps to `((x + 0.5) * TILE, 0, (y + 0.5) * TILE)`. The wall layout in `WALLS` is mirrored from the original 2D version — door gaps are 1-tile holes in those rects.

### Casebook

`scenes/casebook/casebook.tscn` is a `CanvasLayer` overlay opened with **Tab** from either the manor or the timeline view (each scene's script instantiates it as a child node). It pauses the tree (`process_mode = PROCESS_MODE_ALWAYS` plus `get_tree().paused = true`) and builds its UI programmatically in `_ready` — the .tscn itself is intentionally a one-node stub.

The casebook has two sections:
- **Cast** — five portrait cards using `Cast.ROSTER` data, each with an `OptionButton` of name candidates. Selecting a name calls `GameState.set_actor_guess(id, name)` and writes through to the save file immediately.
- **Memories** — every `Memory` in the registry, gated by `discovered_memories`. Discovered entries show title/subtitle/intro plus a full transcript built by reloading the timeline script and walking its `events`. Locked entries show "?????".

Pressing **Conclude** calls `GameState.conclude_case()`, locks all dropdowns, and reveals correctness (✓/✗ + truth) on every card. The Tab handler in each scene checks for a `Casebook` child node before instantiating to avoid duplicates.

## Gotchas

- `tools/validate.gd` runs in `--script` mode (extends `SceneTree`), which **does not register autoloads**. Don't reference `MemoryRegistry` or `GameState` from validation code.
- When editing `.tres` resources or adding timelines, prefer running `tools/test.ps1` over launching the editor — it's much faster and catches the same parse/load errors.
- `.godot/` is gitignored; the editor regenerates it. `.gd.uid` files are tracked and should not be hand-edited.
