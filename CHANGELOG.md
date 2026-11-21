# Changelog

## v0.2.1 (2026-11-21)

- Fix audio drifting further and further behind after pausing, seeking or scrolling (low-latency mode): a leaky 60 ms queue (`AUDIO_BUFFER_MS`) drops stale audio instead of letting it pile up.

## v0.2.0 (2026-11-21)

- Control the phone with the computer's mouse and keyboard: `airglass-hid` acts as a Bluetooth LE HID device; click the mirror window to take control, Right Ctrl to release.
- `airglass pair` (120 s pairing window), `airglass control`; doctor checks Bluetooth and input access.
- UxPlay now replaces the launcher shell (clean stops, no "Terminated" log noise).

## v0.1.0 (2026-11-21)

- First release: low-latency UxPlay launcher with VA-API zero-copy pipeline, systemd user service, notifications, state file, doctor.
