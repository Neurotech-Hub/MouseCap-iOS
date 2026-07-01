//
//  InfoView.swift
//  MouseCap
//

import SwiftUI

struct InfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Start")
                    .font(.title2)
                    .fontWeight(.bold)

                Group {
                    infoStep("1", "Tap Connect and wait for the device to pair.")
                    infoStep("2", "Wait for initial settings to sync from the device.")
                    infoStep("3", "Adjust parameters, then tap Sync to send settings.")
                    infoStep("4", "Use the Terminal tab to monitor BLE messages.")
                }

                Divider()

                Text("Stimulation Modes")
                    .font(.headline)

                Text("**Continuous** — tonic DBS at a fixed frequency (80–160 Hz).")
                Text("**Burst** — pulse trains at intra-burst frequency `IF`, separated by burst period `BP`, each lasting `BD` ms.")

                Divider()

                Text("Parameters")
                    .font(.headline)

                parameterRow("Mode (M)", "0 = Continuous, 1 = Burst.")
                parameterRow("Amplitude (A)", "0–100% pulse amplitude. Shared across modes.")
                parameterRow("Pulse Duration (P)", "90–600 μs. Shared across modes.")
                parameterRow("Frequency (F)", "Continuous mode only. 80–160 Hz.")
                parameterRow("Burst Period (BP)", "Burst mode only. 1 ms – 60 min.")
                parameterRow("Intra-burst Frequency (IF)", "Burst mode only. 80–160 Hz.")
                parameterRow("Burst Duration (BD)", "Burst mode only. 1 ms – 120 s (sent as ms).")
                parameterRow("Activate Stimulation (G)", "Continue stimulation on disconnect.")
                parameterRow("Cap ID (N)", "Device identifier, 00–99.")
                parameterRow("Firmware (FW)", "Device → app. Encoded as major×10+minor (1 = v0.1). Defaults to v0.0.")

                Divider()

                Text("BLE Protocol")
                    .font(.headline)

                Text("Messages use the format `_<key><value>,...`")
                    .font(.system(.body, design: .monospaced))

                Text("Example continuous: `_M0,A50,F130,P90,G0,N0`")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("Example burst: `_M1,A50,P90,BP30000,IF130,BD10000,G0,N0`")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("Full MCU specification: MCU_BLE_PROTOCOL.md in the repository.")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func infoStep(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .fontWeight(.bold)
                .frame(width: 20, alignment: .trailing)
            Text(text)
        }
    }

    private func parameterRow(_ name: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .fontWeight(.semibold)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    InfoView()
        .preferredColorScheme(.dark)
}
