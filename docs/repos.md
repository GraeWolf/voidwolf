# Third-party repositories

voidwolf wires official Void nonfree (and optional multilib) plus two third-party XBPS sources.

> **Status:** Stub for PR1. Working `bootstrap/repos.sh` and pinned fingerprints land in **PR2**.  
> Full design: [design.md](design.md) (Bootstrap / Security sections).

## Planned repos

| Repo | Purpose |
|------|---------|
| `void-repo-nonfree` | NVIDIA and other nonfree packages (mirror-aware via Void package) |
| `void-repo-multilib` + multilib-nonfree | Optional; only with `--with-32bit` |
| [xlibre-void](https://github.com/xlibre-void/xlibre) | XLibre X server |
| [Graewolf/vw-repo](https://codeberg.org/Graewolf/vw-repo) | `brave-origin` (and other personal packages) |

## Principles

1. Prefer **`xbps-install void-repo-nonfree`** over hard-coded `repo-default` URLs.
2. Third-party keys: **fingerprint-named plists**, fail closed on mismatch.
3. Do not dump raw PEM as a trusted key name unless converted to XBPS key format.
4. Document fingerprints in this file once verified (PR2).

## vw-repo (preview)

Upstream packaging lives at Codeberg:

```text
https://codeberg.org/Graewolf/vw-repo
```

Browser package: **`brave-origin`**.
