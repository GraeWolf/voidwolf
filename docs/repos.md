# Third-party repositories

voidwolf wires **official Void nonfree** (and optional multilib) plus two third-party XBPS sources. Keys are **fail-closed**: pinned fingerprint + SHA256 of the key plist.

Implementation: `bootstrap/repos.sh` (PR2).

## Quick start

```bash
# Dry-run (no root, no writes)
./bootstrap/repos.sh --dry-run

# On Void Linux (requires sudo/root)
./bootstrap/repos.sh

# With multilib (32-bit NVIDIA / gaming)
./bootstrap/repos.sh --with-32bit

# Via bootstrap entrypoint
./bootstrap/bootstrap.sh --repos-only
./bootstrap/bootstrap.sh --repos-only --with-32bit

# Rollback third-party repos only
./bootstrap/repos.sh --disable-third-party
```

Validate shipped key pins without root:

```bash
./tests/repos-pins-validate.sh
# or
make test
```

## Repositories

| Source | Purpose | Conf path |
|--------|---------|-----------|
| `void-repo-nonfree` | NVIDIA and other nonfree (mirror-aware) | via Void package under `/usr/share/xbps.d` |
| `void-repo-multilib` + multilib-nonfree | Optional; `--with-32bit` only | via Void packages |
| [xlibre-void/xlibre](https://github.com/xlibre-void/xlibre) | XLibre X server | `/etc/xbps.d/99-repository-xlibre.conf` |
| [Graewolf/vw-repo](https://codeberg.org/Graewolf/vw-repo) | `brave-origin` (and other personal packages) | `/etc/xbps.d/10-vw-repo.conf` |

### Official nonfree (idiomatic)

```bash
sudo xbps-install -y void-repo-nonfree
```

Do **not** hard-code `repo-default.voidlinux.org` — the meta-package follows the system mirror.

### Multilib (optional)

```bash
# only with --with-32bit
sudo xbps-install -y void-repo-multilib void-repo-multilib-nonfree
```

### XLibre

```text
repository=https://github.com/xlibre-void/xlibre/releases/latest/download/
```

Phase 1 package pin (PR3): **`xlibre-minimal`** + tools. Full meta: `--xlibre-full`.

### vw-repo

```text
repository=https://codeberg.org/Graewolf/vw-repo/raw/branch/main/x86_64
```

Verified packages include **`brave-origin`** and `obsidian`. Browser default: `brave-origin`.

Upstream README’s `tee /var/db/xbps/keys/vw-repo.pub` is **not** used. XBPS expects fingerprint-named `.plist` files.

## Pinned keys (fail-closed)

Pins live in `bootstrap/keys/pins.conf`. Shipped plists live in `bootstrap/keys/`.

| Repo | Fingerprint (filename) | SHA256 of plist |
|------|------------------------|-----------------|
| XLibre | `00:ca:42:57:c9:c0:9a:ec:94:b4:7d:97:e5:a9:aa:1e` | `1ca08e7d38c844e614dd397624d2e3775b0b85c9d43ab19155ed84372dd55805` |
| vw-repo | `94:85:7f:4b:ca:9e:0a:8c:e9:e5:42:dc:07:40:57:74` | `ea848dbcdcddef80f89566becba3443ef89bd9770302359782a002f4579d107d` |

`repos.sh` will **abort** if:

1. The shipped key file SHA256 does not match the pin, or  
2. The filename does not match `{fingerprint}.plist`.

Keys install to `/var/db/xbps/keys/{fingerprint}.plist`.

### How XBPS fingerprints work

XBPS names keys by an **OpenSSH-style RSA MD5 fingerprint** of the public key (not MD5 of the PEM file bytes). See `xbps_pubkey2fp()` in [void-linux/xbps `lib/pubkey2fp.c`](https://github.com/void-linux/xbps/blob/master/lib/pubkey2fp.c).

### Regenerating the vw-repo plist

If the vw-repo signing key rotates:

1. Fetch the new PEM (`vw-repo.pub`).
2. Build a plist with `public-key` (PEM as data), `public-key-size` (bits), `signature-by`.
3. Compute the XBPS fingerprint (OpenSSH MD5 of RSA n/e wire format).
4. Name the file `{fp}.plist`, update `pins.conf` SHA256, re-run `tests/repos-pins-validate.sh`.

XLibre key is vendored from:

```text
https://github.com/xlibre-void/xlibre/raw/refs/heads/main/repo-keys/x86_64/00:ca:42:57:c9:c0:9a:ec:94:b4:7d:97:e5:a9:aa:1e.plist
```

## Rollback

```bash
./bootstrap/repos.sh --disable-third-party
# moves 99-repository-xlibre.conf and 10-vw-repo.conf to *.disabled
# then xbps-install -S
```

Official nonfree is left enabled (it is not third-party).

## Security notes

- Third-party repos are part of the **TCB** for packages they provide.
- Bootstrap never silently falls back from XLibre to Xorg; recovery is explicit (`--allow-xorg-fallback` / docs, PR10).
- Prefer re-running pin validation after any key file edit.

## Related

- [design.md](design.md) — architecture, package install order  
- [nvidia.md](nvidia.md) — NVIDIA + nonfree + XLibre  
- PR2: `bootstrap/repos.sh`, `bootstrap/bootstrap.sh --repos-only`
