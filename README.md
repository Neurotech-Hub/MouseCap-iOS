# MouseCap

A SwiftUI-based iOS application for controlling and monitoring DBS (Deep Brain Stimulation) devices via Bluetooth Low Energy (BLE).

![Mouse with brain implant running happily](./MouseCapAppIcon.jpg)

## Features

- Real-time device control and monitoring
- Bluetooth Low Energy connectivity
- Battery level monitoring
- Device configuration management
- Dark mode interface
- Debug terminal for communication monitoring

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repository
2. Open `MouseCap.xcodeproj` in Xcode
3. Build and run the project

## Usage

1. Launch the app
2. Connect to your DBS device using the Connect button
3. Wait for initial device settings to sync
4. Use the interface to control and monitor the device

## Development

The app is built using SwiftUI and follows MVVM architecture patterns. It uses CoreBluetooth for BLE communication.

### Burst stimulation

Burst mode uses keys `M1`, `BP`, `IF`, and `BD` in addition to shared keys `A`, `P`, `G`, and `N`. See [MCU_BLE_PROTOCOL.md](MCU_BLE_PROTOCOL.md) for the complete command set.

## Data Protocol

The app communicates with the DBS device using a text-based protocol documented in **[MCU_BLE_PROTOCOL.md](MCU_BLE_PROTOCOL.md)** (authoritative reference for firmware developers).

### Quick reference

| Key | Parameter |
|-----|-----------|
| `M` | Mode: 0 = continuous, 1 = burst |
| `A` | Amplitude (0–100%) |
| `F` | Frequency, Hz (continuous only) |
| `P` | Pulse duration, µs |
| `BP` | Burst period, ms (burst only) |
| `IF` | Intra-burst frequency, Hz (burst only) |
| `BD` | Burst duration, ms (burst only) |
| `G` | Activate on disconnect (0 or 1) |
| `N` | Cap ID (0–99) |
| `V` | Battery voltage, mV (device → app) |
| `FW` | Firmware version (device → app; `1` = v0.1) |

### Example messages

Continuous sync:
```
_M0,A50,F130,P90,G0,N0
```

Burst sync:
```
_M1,A50,P90,BP30000,IF130,BD10000,G0,N0
```

### MTU / Write Size

The BGM220S peripheral should request MTU exchange (≥ 131 for 128-byte payload, or up to 247). iOS participates automatically as the central — no explicit MTU request is required in the app.

After connect, the terminal logs negotiated MTU and per-write payload limits (`withResponse` and `withoutResponse`). The app uses `writeWithoutResponse` on `nodeRx` when the characteristic supports it, otherwise `writeWithResponse`. Sync commands are rejected if they exceed `getMaximumWriteLength()`.

## License

MIT License

Copyright (c) 2025 Neurotech Hub & Creed Lab at Washington University in St. Louis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. 