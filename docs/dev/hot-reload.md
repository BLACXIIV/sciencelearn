# Flutter hot reload on save (local dev)

Workspace `.vscode/settings.json` enables autosave (2s delay) +
`dart.flutterHotReloadOnSave: "all"`, so saving a Dart file during a
debug session reloads the running app automatically. Requires the
Dart-Code + Flutter extensions (see `.vscode/extensions.json`).

## Run the app

```powershell
cd mobile
flutter devices          # list targets
flutter emulators        # list / launch emulators
flutter run -d <id>      # e.g. -d emulator-5554, -d windows, -d chrome
```

VS Code fork: `F5` or **Run > Start Debugging**, pick the device in the
status bar. Hot reload only works in **debug** builds.

## Reload vs restart

| Key in `flutter run` | Action | Keeps app state? |
|---|---|---|
| `r` | Hot reload — inject changed code, rebuild widgets | Yes |
| `R` | Hot restart — rerun `main()`, reset state | No |
| `q` | Quit | — |

## Needs a full restart (`q` + `flutter run`)

- `main()` and global/static variable changes
- `initState` changes in already-open screens
- `pubspec.yaml` / asset changes (after `flutter pub get`)
- Native Android/iOS changes
- Enum-to-class (or class-to-enum) changes

## Notes

- **Failed reloads are harmless.** If a save lands mid-edit with
  compile errors (e.g. an agent touched several files), the reload is
  skipped and the running app keeps its last good build — fix the code
  and save again.
- **Terminal `flutter run` can't reload-on-save.** The setting only
  reaches apps launched through a Dart-Code debug session (F5, or
  "Dart: Attach to Flutter on Device" for an already-running app). In
  a plain terminal, press `r`/`R` manually.
- **Agent edits don't trigger reload.** Reload-on-save fires on editor
  save events, not filesystem writes. After an agent edits files, save
  any open Dart file (or press `r`) to apply them.
- **Prefer manual saves:** set `"dart.flutterHotReloadOnSave": "manual"`
  (and optionally drop `files.autoSave`) so only Ctrl+S reloads.
- **Android Studio / IntelliJ:** the setting lives in the IDE, not the
  repo. `Settings > Languages & Frameworks > Flutter` → check
  **Perform hot reload on save**. For autosave:
  `Settings > Tools > Actions on Save` → **Configure autosave options**
  → *Save files if the IDE is idle for X seconds* (recommended: 2s).
- Workspace settings live at the repo root because that's the folder
  the editor opens. If you open `mobile/` standalone instead, copy
  `.vscode/settings.json` into `mobile/.vscode/`.
