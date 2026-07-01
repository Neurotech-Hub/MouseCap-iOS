# MouseCap BLE Command Set — MCU Developer Reference

This document defines the complete text protocol between the **MouseCap iOS app** (BLE central) and the **BGM220S peripheral** firmware. It is the authoritative reference for MCU implementation.

## Transport

| Item | Value |
|------|-------|
| Service UUID | `EEE0` |
| App → device (write) | `EEE1` (`nodeRx`) |
| Device → app (read/notify) | `EEE2` (`nodeTx`) |
| Encoding | UTF-8 text, no trailing null required (app trims `\0`) |
| MTU | Peripheral requests exchange; target ≥ 131 (128-byte payload) or 247 max. iOS accepts automatically. |

Writes from the app use `writeWithoutResponse` when `nodeRx` supports it, otherwise `writeWithResponse`.

## Message Format

All application messages begin with `_` followed by comma-separated **key-value** tokens:

```
_<key><integer>[,<key><integer>...]
```

- Keys are uppercase ASCII letters (`A`, `M`, `BP`, …).
- Multi-letter keys (`BP`, `IF`, `BD`) must be parsed **longest-match-first** before single-letter keys.
- Values are unsigned decimal integers (no units in the wire format).
- Unknown keys should be ignored by firmware and the app.

## Stimulation Modes (`M`)

| Value | Mode | Description |
|-------|------|-------------|
| `0` | Continuous | Tonic DBS at fixed frequency `F` |
| `1` | Burst | Pulse trains at intra-burst rate `IF`, spaced by burst period `BP`, each lasting `BD` |

**Firmware rules:**

- In mode `0`, apply `F` as the stimulation frequency. Burst keys (`BP`, `IF`, `BD`) may be stored but must not drive output.
- In mode `1`, apply `BP`, `IF`, and `BD`. Do not use `F` for output timing (app does not send `F` in burst sync).
- `A` (amplitude) and `P` (pulse width) apply in **both** modes.

## Parameter Keys

| Key | Name | Unit | Range | Mode | Notes |
|-----|------|------|-------|------|-------|
| `M` | Stimulation mode | — | 0–1 | Both | 0 = continuous, 1 = burst |
| `A` | Amplitude | % | 0–100 | Both | Percent of full scale |
| `F` | Frequency | Hz | 80–160 | Continuous only | Tonic pulse rate |
| `P` | Pulse duration | µs | 90–600 | Both | Single-pulse width |
| `BP` | Burst period | ms | 1–3,600,000 | Burst only | Time between burst onsets (1 ms – 60 min) |
| `IF` | Intra-burst frequency | Hz | 80–160 | Burst only | Pulse rate within each burst |
| `BD` | Burst duration | ms | 1–120,000 | Burst only | Length of each burst (UI: ms / s / min) |
| `G` | Activate on disconnect | — | 0 or 1 | Both | 1 = keep stimulating after BLE drop |
| `N` | Cap ID | — | 0–99 | Both | Two-digit ID in app UI; wire value is integer |
| `V` | Battery voltage | mV | 1400–2800 | Device → app | Read-only from device |
| `FW` | Firmware version | — | 0–99 | Device → app | Encoded as `major×10 + minor`; see below |

### Firmware version (`FW`)

Read-only. Report firmware as a single integer: **`major × 10 + minor`**.

| Wire value | Display |
|------------|---------|
| `FW0` | v0.0 (default if omitted) |
| `FW1` | v0.1 |
| `FW10` | v1.0 |

Include `FW` in the `_1` readback on current firmware. The app shows **v0.0** until `FW` is received.

**MCU:** set `FW1` for the current v0.1 release.

## App → Device: Sync Commands

Sent when the user taps **Sync** in the app.

### Continuous mode (`M0`)

```
_M0,A<amplitude>,F<frequency>,P<pulse_us>,G<0|1>,N<cap_id>
```

**Example** — 50% amplitude, 130 Hz, 90 µs pulses, no activate-on-disconnect, cap 0:

```
_M0,A50,F130,P90,G0,N0
```

### Burst mode (`M1`)

```
_M1,A<amplitude>,P<pulse_us>,BP<period_ms>,IF<freq_hz>,BD<duration_ms>,G<0|1>,N<cap_id>
```

**Example** — 50% amplitude, 90 µs pulses, 30 s period, 130 Hz intra-burst, 10 s burst, cap 0:

```
_M1,A50,P90,BP30000,IF130,BD10000,G0,N0
```

## App → Device: Utility Commands

| Command | Action |
|---------|--------|
| `_1` | Request full configuration; app then reads `nodeTx` |
| `_2` | Request legacy configuration block 2 (legacy hardware only) |
| `_L1` | Toggle LED (debug) |

### Configuration read sequence

On connect (and when the user taps **Read**), the app:

1. Sends `_1` and reads `nodeTx`.
2. If the `_1` response includes **`FW`**, treats the device as **current firmware** — all parameters are in `_1`; **`_2` is not sent**.
3. If **`FW` is absent**, treats the device as **legacy** — sends `_2` and reads `nodeTx` for supplementary values (e.g. `V`).

Current firmware should return everything in one `_1` payload (stimulation params, `V`, `FW`). Legacy firmware may split params across `_1` and `_2`.

## Device → App: Status / Config Response

Notify or respond on `nodeTx` with the same key-value format. The app parses all recognized keys and updates its UI. Include `M` in readbacks so the app selects the correct mode tab.

### `_1` response (current firmware)

Single message with all keys, e.g.:

```
_A50,F130,P90,M0,G0,N0,V2100,FW1
```

Burst example:

```
_A50,P90,M1,BP30000,IF130,BD10000,G0,N0,V2100,FW1
```

### Legacy split (no `FW` in `_1`)

| Block | Typical contents |
|-------|------------------|
| `_1` | `M`, `A`, `F` or `BP`/`IF`/`BD`, `P`, `G`, `N` |
| `_2` | `V` and any keys that did not fit in legacy `_1` |

The app merges keys from both responses.

## Parsing Algorithm (Reference)

```
1. Strip leading '_' if present
2. Split on ','
3. For each token:
   a. Match key using longest-prefix table: BP, IF, BD, FW, then single-char keys
   b. Parse remainder as integer
   c. Apply to parameter store
```

## Message Length

With MTU ≥ 131, a full burst sync is ~45 bytes — well within limits. Longest expected sync:

```
_M1,A100,P600,BP3600000,IF160,BD120000,G1,N99
```

(~50 characters). Firmware should accept at least **128 bytes** per write on `nodeRx`.

## Versioning

| Document | Date |
|----------|------|
| Initial burst extension | 2025 — Neurotech Hub & Creed Lab, Washington University in St. Louis |

Future keys should use two-letter prefixes where possible to avoid ambiguity with single-letter keys.
