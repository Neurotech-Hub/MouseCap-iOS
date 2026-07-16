//
//  DBSProtocol.swift
//  MouseCap
//

import Foundation

/// BLE text protocol for Creed DBS / MouseCap devices.
/// See MCU_BLE_PROTOCOL.md for the full specification.
enum DBSProtocolKey: String, CaseIterable {
    case mode = "M"
    case amplitude = "A"
    case frequency = "F"
    case pulseDuration = "P"
    case burstPeriod = "BP"
    case intraBurstFrequency = "IF"
    case burstDuration = "BD"
    case activateOnDisconnect = "G"
    case capID = "N"
    case batteryVoltage = "V"
    case firmwareVersion = "FW"

    static let byDescendingLength: [DBSProtocolKey] = allCases.sorted {
        $0.rawValue.count > $1.rawValue.count
    }
}

enum DBSProtocol {
    static let modeContinuous = 0
    static let modeBurst = 1

    static func parseKeyValue(from component: Substring) -> (key: DBSProtocolKey, value: Int)? {
        let text = String(component)
        guard text.count >= 2 else { return nil }

        for key in DBSProtocolKey.byDescendingLength {
            if text.hasPrefix(key.rawValue) {
                let valueText = String(text.dropFirst(key.rawValue.count))
                guard !valueText.isEmpty, let value = Int(valueText) else { return nil }
                return (key, value)
            }
        }
        return nil
    }

    /// Current firmware continuous sync (`M0` included).
    static func buildContinuousCommand(
        amplitude: Int,
        frequency: Int,
        pulseDuration: Int,
        activateOnDisconnect: Bool,
        capID: String
    ) -> String {
        buildCommand(pairs: continuousPairs(
            amplitude: amplitude,
            frequency: frequency,
            pulseDuration: pulseDuration,
            activateOnDisconnect: activateOnDisconnect,
            capID: capID,
            includeMode: true
        ))
    }

    /// Pre-burst / no-`FW` devices: omit `M0`. Prefer the chunked builders below —
    /// a single combined string overflows the legacy receive buffer once values grow
    /// (e.g. `_A20,F80,P90,G1,N75` = 19 chars).
    static func buildLegacyContinuousCommand(
        amplitude: Int,
        frequency: Int,
        pulseDuration: Int,
        activateOnDisconnect: Bool,
        capID: String
    ) -> String {
        buildCommand(pairs: continuousPairs(
            amplitude: amplitude,
            frequency: frequency,
            pulseDuration: pulseDuration,
            activateOnDisconnect: activateOnDisconnect,
            capID: capID,
            includeMode: false
        ))
    }

    /// Legacy sync as two short writes that each fit the classic ~18-byte device buffer.
    /// Chunk 1 matches historical `_1` readback (`A`,`F`,`P`); chunk 2 carries `G`,`N`.
    static func buildLegacyContinuousChunks(
        amplitude: Int,
        frequency: Int,
        pulseDuration: Int,
        activateOnDisconnect: Bool,
        capID: Int
    ) -> [String] {
        [
            buildCommand(pairs: [
                "A\(amplitude)",
                "F\(frequency)",
                "P\(pulseDuration)"
            ]),
            buildCommand(pairs: [
                "G\(activateOnDisconnect ? 1 : 0)",
                "N\(capID)"
            ])
        ]
    }

    private static func continuousPairs(
        amplitude: Int,
        frequency: Int,
        pulseDuration: Int,
        activateOnDisconnect: Bool,
        capID: String,
        includeMode: Bool
    ) -> [String] {
        var pairs: [String] = []
        if includeMode {
            pairs.append("M\(modeContinuous)")
        }
        pairs.append(contentsOf: [
            "A\(amplitude)",
            "F\(frequency)",
            "P\(pulseDuration)",
            "G\(activateOnDisconnect ? 1 : 0)",
            "N\(capID)"
        ])
        return pairs
    }

    static func buildBurstCommand(
        amplitude: Int,
        pulseDuration: Int,
        burstPeriodMs: Int,
        intraBurstFrequency: Int,
        burstDurationMs: Int,
        activateOnDisconnect: Bool,
        capID: String
    ) -> String {
        buildCommand(pairs: [
            "M\(modeBurst)",
            "A\(amplitude)",
            "P\(pulseDuration)",
            "BP\(burstPeriodMs)",
            "IF\(intraBurstFrequency)",
            "BD\(burstDurationMs)",
            "G\(activateOnDisconnect ? 1 : 0)",
            "N\(capID)"
        ])
    }

    private static func buildCommand(pairs: [String]) -> String {
        "_" + pairs.joined(separator: ",")
    }

    static func batteryPercentage(fromMillivolts value: Int) -> Int {
        let minVoltage = 1400.0
        let maxVoltage = 2800.0
        let percentage = max(0, min(100, ((Double(value) - minVoltage) / (maxVoltage - minVoltage)) * 100))
        return Int(round(percentage))
    }

    static func responseIncludesFirmwareVersion(_ dataString: String) -> Bool {
        guard dataString.starts(with: "_") else { return false }
        return dataString.dropFirst().split(separator: ",").contains { component in
            parseKeyValue(from: component)?.key == .firmwareVersion
        }
    }

    /// Wire value encodes `major.minor` as `major * 10 + minor` (e.g. 1 → v0.1, 10 → v1.0).
    static func formatFirmwareVersion(wireValue: Int) -> String {
        let major = wireValue / 10
        let minor = wireValue % 10
        return "v\(major).\(minor)"
    }
}
