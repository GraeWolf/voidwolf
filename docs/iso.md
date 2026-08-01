# ISO / live image (PR17)

voidwolf live/install media is built with **void-mklive**, not a custom forked installer. This repo supplies package lists, a rootfs overlay, and `iso/build-iso.sh`.

## Goals

- Bootable **glibc x86_64** image branded **voidwolf**
- **startx** session story (no display manager)
- Optional inclusion of **local** `packages/repo` (PR15–16)
- Documented post-boot path for XLibre, Brave, NVIDIA

## Non-goals

- Full disk encryption (LUKS) in the installer
- musl as primary ISO target (later)
- Shipping private keys or public signed hosting
- Guaranteeing third-party repos on the build host without operator setup

## Decisions locked in PR17

| Item | Decision |
|------|----------|
| Hostname | `voidwolf` (`iso/overlay/etc/hostname`) |
| Session | startx → dwm; MOTD / ISO-README explain flow |
| Greeter | None |
| Default live username | `voidwolf` (set via void-mklive user flags when building; see upstream `-h`) |
| FDE | Out of scope — note in MOTD and design |
| Local packages | `voidwolf-desktop`, `helpers`, `suckless`, `themes`, `base` when repo present |
| Image title | `voidwolf` (`-T`) |

Password policy for the live user is **operator-defined** at build time (void-mklive version-specific). Document the password you choose in your private build notes; do not hardcode secrets in git.

## Build host requirements

1. Void (or compatible) build machine with **root** for mklive
2. Clone of [void-linux/void-mklive](https://github.com/void-linux/void-mklive)
3. Network to Void mirrors
4. Optional: `./packages/build-local-repo.sh` so voidwolf-* packages resolve

```bash
git clone https://github.com/void-linux/void-mklive ~/src/void-mklive
export VOID_MKLIVE_DIR=~/src/void-mklive

cp iso/mklive.env.example iso/mklive.env
# edit paths

./iso/build-iso.sh --dry-run
sudo -E ./iso/build-iso.sh
# → iso/out/voidwolf-x86_64.iso (default names)
```

## Overlay contents

| Path | Purpose |
|------|---------|
| `etc/hostname` | voidwolf |
| `etc/issue` / `etc/motd` | startx reminder |
| `usr/share/voidwolf/ISO-README` | Live + post-install guide |

void-mklive `-I overlay` merges these into the rootfs.

## Package composition

`iso/scripts/assemble-pkglist.sh` merges:

1. `package-lists/live-base.txt` — networking, editors, partition tools  
2. `package-lists/voidwolf.txt` — local meta packages (if enabled)

XLibre / vw-repo / nonfree NVIDIA are **not** auto-injected: they need fail-closed keys from `bootstrap/repos.sh`. After first boot:

```bash
# on installed system with this git tree
./bootstrap/repos.sh
./bootstrap/bootstrap.sh --profile desktop --gpu nvidia --with-suckless
# or xbps-install from your local repo + install-dotfiles.sh
```

## User creation

void-mklive’s flags for default users change over time. PR17 **documents** the product intent rather than pinning a brittle `-u` string:

- Create an unprivileged user named **voidwolf** in the wheel group when upstream allows
- Prefer forcing password change on first login if the tool supports it
- Never commit plaintext passwords to the voidwolf git repo

If your mklive version supports a user file or `-u user:pass:…` form, pass it via:

```bash
export VOIDWOLF_MKLIVE_EXTRA_ARGS='…upstream flags…'
./iso/build-iso.sh
```

## Installer story (high level)

1. Boot live ISO → login → optional `startx` to verify hardware  
2. Install Void rootfs to disk with void-installer **or** manual partitions (no FDE automation)  
3. Boot target → install voidwolf packages / run bootstrap  
4. `startx` as daily driver  

A custom curses installer is **not** required for PR17.

## Testing without mklive

```bash
./iso/build-iso.sh --dry-run          # no mklive → exits 0, prints scaffold help
./iso/scripts/assemble-pkglist.sh     # prints package list
make test                             # iso-scaffold-validate
```

## Related

- [packaging.md](packaging.md) — local XBPS  
- [session.md](session.md) — startx  
- [nvidia.md](nvidia.md)  
- [repos.md](repos.md)  
- [design.md](design.md) — Phase 5  
