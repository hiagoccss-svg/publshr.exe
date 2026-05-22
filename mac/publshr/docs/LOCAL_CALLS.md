# Local voice & video calls

Publshr runs **voice and video entirely on your network** — no LiveKit Cloud, no third-party call API, and no cloud media relay.

## How it works

| Layer | What runs | Where |
|-------|-----------|--------|
| **Media (SFU)** | Open-source `livekit-server` in `--dev` mode | Started by the Mac app on the **call host** (LAN IP) |
| **Signaling** | TCP + Bonjour (`_publshr-call._tcp`) | Same machine as host, port `8765` |
| **Tokens** | HMAC JWT generated in-app | `devkey` / `secret` (bundled dev keys, not cloud) |
| **Client** | LiveKit Swift SDK | Connects to `ws://<host-lan-ip>:7880` |

Up to **20 participants** per room (configurable in `LocalCallConfiguration.maxParticipants`).

## Requirements

1. **macOS 14+** Publshr app build with LiveKit Swift SDK (included in `Package.swift`).
2. **`livekit-server` binary** on the host Mac:
   - Bundled in `Publshr.app/Contents/Resources/livekit-server`, or
   - Installed to `/usr/local/bin/livekit-server`, or
   - On `PATH` as `livekit-server`

Fetch the binary when packaging:

```bash
cd mac/publshr
bash scripts/fetch-livekit-server-macos.sh
bash scripts/build-macos-app.sh …  # copies binary into the .app bundle
```

3. **Same LAN** (Wi‑Fi / Ethernet) for all participants — traffic stays on your network.

## Starting a call

1. Open a channel in chat → **Voice call** or **Video call**.
2. The first Mac becomes **host**: starts `livekit-server` + LAN signaling.
3. Others on the same channel/network join via Bonjour auto-discovery, or use the **room code** shown in the call sheet.

## Cloud discovery (optional)

By default, the app may still write `call_rooms` / `call_participants` to Supabase so remote teammates see that a call exists. **Audio and video never go through Supabase.**

To disable cloud discovery entirely, set workspace settings:

```json
{ "calls_mode": "local" }
```

(Any value other than `"cloud"` keeps local-only media; cloud rows are skipped when `calls_mode` is `"local"` — use `calls_mode: "cloud"` only if you want Supabase room discovery.)

## Voice notes (local-first)

Voice notes are saved under **Application Support** immediately. Upload to Supabase storage is attempted when online; if upload fails, playback uses the **local file** on that Mac.

## Limits & expectations

- **Not internet-wide P2P** without a VPN: participants need LAN reachability (or port forwarding on the host).
- **Host machine** runs the SFU; use a wired Mac on the office LAN for best results with 20 video tiles.
- **CPU/bandwidth** on the host scales with participant count; 20×720p may require a strong Mac and gigabit LAN.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| “Install livekit-server…” | Run `scripts/fetch-livekit-server-macos.sh` and rebuild the `.app` |
| Others can’t join | Same Wi‑Fi, macOS firewall allows Publshr incoming, check room code in call UI |
| No video | Grant camera in System Settings → Privacy |
| High lag | Reduce participants, disable video, use wired LAN |
