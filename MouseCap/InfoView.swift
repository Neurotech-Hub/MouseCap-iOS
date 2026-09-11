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
                    infoStep("1", "Look for the 1 Hz LED chirp — the device is advertising and ready to connect.")
                    infoStep("2", "Tap Connect and wait for the LED to go solid ON.")
                    infoStep("3", "Wait for initial settings to sync from the device.")
                    infoStep("4", "Adjust parameters, then tap Sync to send settings.")
                    infoStep("5", "Use the Terminal tab to monitor BLE messages.")
                }

                Divider()

                Text("LED Status")
                    .font(.headline)

                Text("One status LED, three mutually exclusive patterns:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ledRow(
                    "Ready to connect",
                    pattern: "1 Hz chirp (50 ms on, ~950 ms off)",
                    detail: "Advertising ON. Boot, disconnect with G=0, or after a magnet swipe."
                )
                ledRow(
                    "Connected",
                    pattern: "Solid ON",
                    detail: "Advertising OFF. Stays solid while the phone is connected (even if G=1). Toggle with Toggle LED (L)."
                )
                ledRow(
                    "Stimulating (disconnected)",
                    pattern: "Heartbeat every ~10 s (50 ms blink)",
                    detail: "Advertising OFF. G=1 after disconnect — therapy continues without the app. Not an error."
                )

                Text("Connected always wins over the stim heartbeat. The 1 Hz chirp and 10 s heartbeat never run together.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                Text("Magnet Swipe")
                    .font(.headline)

                Text("Always enters Ready to connect: re-enables advertising and switches the LED to the 1 Hz chirp.")
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Does not:")
                        .fontWeight(.semibold)
                    Text("• Stop stimulation (G=1 output continues)")
                    Text("• Disconnect an active BLE session")
                    Text("• Change any stim parameters")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                Text("During stim, magnet is “make me discoverable again” — reconnect and read status; G will still be 1 if therapy was running.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                Text("Stimulation Modes")
                    .font(.headline)

                Text("Continuous — tonic DBS at a fixed frequency (80–160 Hz).")
                Text("Burst — pulse trains at intra-burst frequency IF, separated by burst period BP, each lasting BD ms.")

                Divider()

                Text("Parameters")
                    .font(.headline)

                parameterRow("Mode (M)", "0 = Continuous, 1 = Burst. Current firmware only.")
                parameterRow("Amplitude (A)", "0–100% pulse amplitude. Shared across modes.")
                parameterRow("Pulse Duration (P)", "90–600 μs. Shared across modes.")
                parameterRow("Frequency (F)", "Continuous mode only. 80–160 Hz.")
                parameterRow("Burst Period (BP)", "Burst mode only. 1 ms – 60 min.")
                parameterRow("Intra-burst Frequency (IF)", "Burst mode only. 80–160 Hz.")
                parameterRow("Burst Duration (BD)", "Burst mode only. 1 ms – 120 s (sent as ms).")
                parameterRow(
                    "Activate Stimulation (G)",
                    "1 = keep stimulating after BLE drop. While connected, LED stays solid ON. After disconnect with G=1: stim continues + 10 s LED heartbeat, no advertising. G=0 stops stim and returns to ready chirp."
                )
                parameterRow(
                    "Toggle LED (L)",
                    "Only while connected — toggles solid on/off. Ignored when disconnected."
                )
                parameterRow("Cap ID (N)", "Device identifier, 00–99.")
                parameterRow("Firmware (FW)", "Device → app. Encoded as major×10+minor (1 = v0.1). Missing FW means legacy hardware.")

                Divider()

                Text("Typical Flows")
                    .font(.headline)

                flowRow("Pair", "1 Hz chirp → Connect → solid ON.")
                flowRow("Stim while connected", "Set G=1 → stim runs; LED stays solid ON.")
                flowRow("Stim after disconnect", "If G=1 → stim continues + 10 s heartbeat; advertising off.")
                flowRow("Recover during stim", "Magnet → 1 Hz chirp + advertising; stim still on if G=1.")
                flowRow("Stop everything", "Connect and set G=0, or disconnect with G=0 → ready chirp + advertising.")

                Divider()

                Text("BLE Protocol")
                    .font(.headline)

                Text("Messages use the format _<key><value>,...")
                    .font(.system(.body, design: .monospaced))

                Text("Example continuous: _M0,A50,F130,P90,G0,N0")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("Legacy continuous (no FW, chunked): _A50,F130,P90 then _G0,N0")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("Example burst: _M1,A50,P90,BP30000,IF130,BD10000,G0,N0")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("Full MCU specification: MCU_BLE_PROTOCOL.md in the repository.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Shelf mode (radio off, LED off, magnet-only wake) is planned but not in firmware yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                Text(appVersionLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var appVersionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "iOS \(version) (\(build))"
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

    private func ledRow(_ title: String, pattern: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .fontWeight(.semibold)
            Text(pattern)
                .font(.caption.monospaced())
                .foregroundColor(.accentColor)
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func flowRow(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .fontWeight(.semibold)
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    InfoView()
        .preferredColorScheme(.dark)
}
