# airglass

[![CI](https://github.com/Tjabooo/airglass/actions/workflows/ci.yml/badge.svg)](https://github.com/Tjabooo/airglass/actions/workflows/ci.yml) [![Release](https://img.shields.io/github/v/release/Tjabooo/airglass?include_prereleases&sort=semver)](https://github.com/Tjabooo/airglass/releases) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Mirror your iPhone or iPad to a Linux desktop over AirPlay, tuned for the lowest latency your hardware can do.

airglass is a small launcher around [UxPlay](https://github.com/FDH2/UxPlay), the open-source AirPlay mirroring server. UxPlay speaks the AirPlay protocol; airglass picks the fastest GStreamer pipeline for your machine, runs it as a systemd user service, and tells you (and your status bar) when a phone connects.

## Features

- **Low latency by default:** frames are shown the moment they're decoded (`-vsync no`), 60 fps instead of UxPlay's default of 30, no `decodebin` queueing when a direct decoder is available.
- **Zero-copy video on VA-API GPUs** (AMD, Intel): `vah264dec` hands DMA-BUF frames straight to `waylandsink`, so the picture never takes a trip through system memory.
- Falls back automatically: `vah264dec` > `nvh264dec` > `v4l2h264dec` > `avdec_h264`.
- Shows up in Control Center → Screen Mirroring under the name you choose.
- One command to toggle: `airglass toggle` (bind it to a key).
- Desktop notifications when mirroring starts and stops, plus a state file (`off` / `listening` / `mirroring`) and an `ON_CHANGE` hook for status bars.
- A new phone can take over from the current one; optional 4-digit PIN.
- `airglass doctor` checks every dependency and prints the firewall rules you need.

## Install

Dependencies: UxPlay, Avahi, GStreamer with the bad/good/libav plugin sets, and a VA-API driver for hardware decoding.

Arch Linux:

```sh
yay -S uxplay gst-plugin-va gst-libav gst-plugins-good gst-plugins-bad
sudo systemctl enable --now avahi-daemon
```

Debian/Ubuntu:

```sh
sudo apt install uxplay gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-plugins-good gstreamer1.0-vaapi avahi-daemon
```

Then:

```sh
git clone https://github.com/Tjabooo/airglass
cd airglass
./install.sh        # installs ~/.local/bin/airglass + the user service, then runs doctor
airglass start
```

If you run a firewall, the phone has to reach mDNS (UDP 5353) and AirPlay's fixed ports (TCP 7000, 7001, 7100 and UDP 6000, 6001, 7011). `airglass doctor` prints ready-made `ufw` rules for your LAN.

## Usage

```
airglass toggle     start or stop the receiver
airglass start | stop | restart | status
airglass state      off / listening / mirroring
airglass doctor     check dependencies + firewall, print the UxPlay command
airglass logs       follow the service log
airglass run        run in the foreground
```

On the iPhone: Control Center → Screen Mirroring → pick your computer's name.

### Hyprland example

```lua
hl.window_rule({ name = "airglass-float", match = { class = "^uxplay$" }, float = true, center = true,
                 max_size = { "monitor_w*0.9", "monitor_h*0.92" } })
hl.window_rule({ name = "airglass-awake", match = { class = "^uxplay$" }, idle_inhibit = "always" })
hl.bind("SUPER + ALT + I", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/airglass toggle"))
```

## Configuration

`~/.config/airglass/config` (created from [`config.example`](config.example) on install), `KEY=value` per line:

| Key | Default | What it does |
| --- | --- | --- |
| `NAME` | hostname | Name shown on the phone |
| `RESOLUTION` | `1920x1080` | Largest picture the phone is asked to send; set it to your monitor |
| `FPS` | `60` | Frame rate requested from the phone |
| `DECODER` | `auto` | GStreamer H.264 decoder |
| `VIDEOSINK` | `auto` | `waylandsink` on Wayland, else `glimagesink` |
| `AUDIOSINK` | `auto` | `pulsesink` > `pipewiresink` > `autoaudiosink`; `0` = no audio |
| `AV_SYNC` | `no` | `yes` holds video back for lip sync (adds latency) |
| `FULLSCREEN` | `no` | Open the mirror window fullscreen |
| `KEEP_WINDOW` | `no` | Keep the window after the phone stops |
| `TAKEOVER` | `yes` | A new phone may take over |
| `PIN` | empty | 4-digit PIN asked on first connect |
| `NOTIFY` | `yes` | Desktop notifications |
| `ON_CHANGE` | empty | Shell command after each state change (`$AIRGLASS_STATE` is set) |
| `EXTRA_ARGS` | empty | Extra UxPlay options, e.g. `-h265` |

## How it works

The phone finds the receiver over mDNS (Avahi) and streams H.264 over AirPlay to UxPlay. airglass builds UxPlay's pipeline:

```
appsrc → h264parse → vah264dec → videoconvert/videoscale (passthrough) → waylandsink sync=false
```

With matching DMA-BUF caps the convert/scale elements pass frames through untouched, so decode and display stay on the GPU. `sync=false` drops the clock wait at the sink: each frame goes to the compositor as soon as it exists. What's left is the phone's encoder and the Wi-Fi hop, which no receiver can remove; a 5 GHz network and keeping the phone close help most.

airglass reads UxPlay's log to know when mirroring starts and stops, writes `$XDG_RUNTIME_DIR/airglass/state` and sends notifications.

## License

MIT for airglass itself. UxPlay is GPL-3.0 and is installed separately.
