# pipewire.conf.d

`setup-pipewire.sh` creates symlinks here under `~/.config/pipewire/pipewire.conf.d/`:

- `10-wireplumber.conf` → Void example (starts WirePlumber from `pipewire`)
- `20-pipewire-pulse.conf` → Void example (starts pipewire-pulse from `pipewire`)

Do **not** start `wireplumber` or `pipewire-pulse` as sibling processes in `.xinitrc`.
