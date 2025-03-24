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

## Data Protocol

The app communicates with the DBS device using a simple text-based protocol. All messages start with an underscore ("_") followed by comma-separated key-value pairs.

### Message Format
```
_<key1><value1>,<key2><value2>,...
```

### Supported Parameters

- `A`: Amplitude (0-100%)
- `F`: Frequency (80-160 Hz)
- `P`: Pulse Duration (90-600 μs)
- `G`: Activate on Disconnect (0 or 1)
- `N`: Cap ID (0-99)
- `V`: Battery Voltage (1400-2800 mV)

### Example Message
```
_A50,F130,P90,G0,N00,V2100
```
This message sets:
- Amplitude to 50%
- Frequency to 130 Hz
- Pulse Duration to 90 μs
- Activate on Disconnect to false
- Cap ID to 00
- Battery Voltage to 2100 mV

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