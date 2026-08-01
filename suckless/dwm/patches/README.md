# dwm patches (voidwolf)

Phase 1 (already applied into `dwm.c` / helpers):

| Patch | Role |
|-------|------|
| actualfullscreen | Super+F true fullscreen |
| restartsig | Super+Ctrl+Shift+Q re-exec; SIGHUP/SIGTERM |
| movestack | Super+Shift+H/J and arrows |
| focusdir | Super+H/J/L and Super+Arrows |

Phase 3 / PR13b (applied into tree; diffs kept for reference):

| Patch | Role |
|-------|------|
| vanitygaps | gaps + alternate layouts (`vanitygaps.c`) |
| scratchpad | Super+S floating scratch terminal |
| sticky | Super+O stick client across tags |
| attachaside | new clients attach after master, not as new master |

Build: `./bootstrap/build-suckless.sh --dwm-only` (does not re-apply diffs; sources are pre-patched).
