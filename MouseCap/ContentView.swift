//
//  ContentView.swift
//  APEX Comm
//
//  Created by Matt Gaidica on 1/22/24.
//

import SwiftUI
import Foundation
import CoreLocation
import BLEAppHelpers

enum AppTab: String, CaseIterable {
    case controls = "Controls"
    case terminal = "Terminal"
    case info = "Info"

    var icon: String {
        switch self {
        case .controls: return "slider.horizontal.3"
        case .terminal: return "terminal"
        case .info: return "info.circle"
        }
    }
}

struct ContentView: View {
    let appName = "Creed DBS Control"
    var maxCharacteristicLength: Int {
        return bluetoothManager.getMaximumWriteLength()
    }
    @State private var debug = false
    @StateObject private var bluetoothManager = BluetoothManager(
        serviceUUID: BluetoothDeviceUUIDs.Node.serviceUUID,
        nodeRxUUID: BluetoothDeviceUUIDs.Node.nodeRxUUID,
        nodeTxUUID: BluetoothDeviceUUIDs.Node.nodeTxUUID
    )
    @ObservedObject private var terminalManager = TerminalManager.shared
    @State private var selectedTab: AppTab = .controls
    @State private var stimulationMode: StimulationMode = .continuous
    @State private var amplitude: Double = 0
    @State private var frequency: Double = 130
    @State private var pulseDuration: Double = 50
    @State private var burstPeriodMs: Double = 30_000
    @State private var intraBurstFrequency: Double = 130
    @State private var burstDurationMs: Double = 10_000
    @State private var activateOnDisconnect: Bool = false
    @State private var requireSync: Bool = false
    @State private var ignoreChanges = true
    @State private var selectedCapID: String = "00"
    @State private var deviceBatteryLevel: Int = 100
    @State private var firmwareVersionWire: Int = 0
    @State private var awaitingConfigBlock1Response = false
    @State private var suppressModeSyncFlag = false
    @State private var hasReceivedInitialValues: Bool = false

    private var firmwareVersionLabel: String {
        DBSProtocol.formatFirmwareVersion(wireValue: firmwareVersionWire)
    }

    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private var connectButtonTitle: String {
        if bluetoothManager.isConnected {
            return "Disconnect"
        } else if bluetoothManager.isConnecting {
            return "Connecting..."
        } else {
            return "Connect"
        }
    }

    private var connectButtonBackground: Color {
        if bluetoothManager.isConnected {
            return .red
        } else if bluetoothManager.isConnecting {
            return .gray
        } else {
            return .black
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .controls:
                    controlsTab
                case .terminal:
                    terminalTab
                case .info:
                    InfoView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            footerTabBar
        }
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            terminalManager.addMessage("Hello, \(appName).")
        }
        .preferredColorScheme(.dark)
    }

    private var footerTabBar: some View {
        HStack {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        Text(tab.rawValue)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == tab ? .accentColor : .gray)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(white: 0.1))
    }

    private var controlsTab: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                ClockView()

                Spacer()

                Button(action: handleBluetoothAction) {
                    Text(connectButtonTitle)
                        .frame(minWidth: 100, minHeight: 36)
                        .foregroundColor(.white)
                        .background(connectButtonBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

//            Button(action: { debug.toggle() }) {
//                Text("debug")
//                    .foregroundColor(.gray)
//            }

            if bluetoothManager.isConnected || debug || isSimulator {
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("Cap ID:")
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .layoutPriority(1)

                        Menu {
                            ForEach(0..<100, id: \.self) { number in
                                let capID = String(format: "%02d", number)
                                Button(capID) {
                                    selectedCapID = capID
                                    requireSync = true
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedCapID)
                                    .font(.body.monospacedDigit())
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundColor(.accentColor)
                        }
                        .fixedSize(horizontal: true, vertical: false)

                        Spacer(minLength: 8)

                        Text(firmwareVersionLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Image(systemName: deviceBatteryLevel > 20 ? "battery.100" : "battery.25")
                                .foregroundColor(deviceBatteryLevel > 20 ? .green : .red)
                            Text("\(deviceBatteryLevel)%")
                                .foregroundColor(deviceBatteryLevel > 20 ? .primary : .red)
                                .lineLimit(1)
                        }
                        .layoutPriority(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            SharedStimulationControlsView(
                                amplitude: $amplitude,
                                pulseDuration: $pulseDuration,
                                ignoreChanges: ignoreChanges,
                                onValueChanged: { requireSync = true }
                            )

                            Picker("Stimulation Mode", selection: $stimulationMode) {
                                ForEach(StimulationMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.top, 4)
                            .onChange(of: stimulationMode) { _, _ in
                                if !ignoreChanges && !suppressModeSyncFlag {
                                    requireSync = true
                                }
                            }

                            if stimulationMode == .continuous {
                                ContinuousControlsView(
                                    frequency: $frequency,
                                    ignoreChanges: ignoreChanges,
                                    onValueChanged: { requireSync = true }
                                )
                            } else {
                                BurstControlsView(
                                    burstPeriodMs: $burstPeriodMs,
                                    intraBurstFrequency: $intraBurstFrequency,
                                    burstDurationMs: $burstDurationMs,
                                    ignoreChanges: ignoreChanges,
                                    onValueChanged: { requireSync = true }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                dismissKeyboard()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    Toggle("Activate Stimulation", isOn: $activateOnDisconnect)
                        .onChange(of: activateOnDisconnect) {
                            if !ignoreChanges {
                                requireSync = true
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    HStack {
                        Button(action: syncControls) {
                            Text("Sync")
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(requireSync ? Color.red : Color.clear, lineWidth: 5)
                                )
                        }
                        .padding(5)

                        Button(action: toggleLED) {
                            Text("Toggle LED")
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                                .foregroundColor(.white)
                                .background(.green)
                                .cornerRadius(8)
                        }
                        .padding(5)

                        Button(action: readBuffer) {
                            Text("Read")
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                                .foregroundColor(.white)
                                .background(.gray)
                                .cornerRadius(8)
                        }
                        .padding(5)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                    .padding([.leading, .trailing, .bottom], 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .opacity(!hasReceivedInitialValues && !debug && !isSimulator ? 0.25 : 1.0)
                .disabled(!hasReceivedInitialValues && !debug && !isSimulator)
                .onAppear {
                    bluetoothManager.onDisconnect = {
                        resetAllViewVars()
                    }
                    bluetoothManager.onNodeTxValueUpdated = { dataString in
                        parseAndSetControlValues(from: dataString)
                    }

                    requestConfiguration()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        requireSync = false
                        ignoreChanges = false
                    }
                }
            } else {
                Spacer(minLength: 0)
            }
        }
    }

    private var terminalTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(terminalManager.receivedMessages, id: \.self) { message in
                    Text(message)
                        .foregroundColor(Color.green)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(5)
            .onTapGesture {
                let textToCopy = terminalManager.receivedMessages.joined(separator: "\n")
                UIPasteboard.general.string = textToCopy
                terminalManager.addMessage("Terminal copied to clipboard")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    func handleBluetoothAction() {
        if bluetoothManager.isConnected || bluetoothManager.isConnecting {
            bluetoothManager.disconnect()
            hasReceivedInitialValues = false
        } else {
            bluetoothManager.startScanning()
            ignoreChanges = true
        }
    }

    func resetAllViewVars() {
        activateOnDisconnect = false
        requireSync = false
        hasReceivedInitialValues = false
        firmwareVersionWire = 0
        awaitingConfigBlock1Response = false
    }

    func toggleLED() {
        bluetoothManager.writeValue("_L1")
        terminalManager.addMessage("Toggled LED")
    }

    func syncControls() {
        requireSync = false

        let capID = String(format: "%02d", Int(selectedCapID) ?? 0)
        let commandString: String

        switch stimulationMode {
        case .continuous:
            commandString = DBSProtocol.buildContinuousCommand(
                amplitude: Int(amplitude),
                frequency: Int(frequency),
                pulseDuration: Int(pulseDuration),
                activateOnDisconnect: activateOnDisconnect,
                capID: capID
            )
        case .burst:
            commandString = DBSProtocol.buildBurstCommand(
                amplitude: Int(amplitude),
                pulseDuration: Int(pulseDuration),
                burstPeriodMs: Int(burstPeriodMs),
                intraBurstFrequency: Int(intraBurstFrequency),
                burstDurationMs: Int(burstDurationMs),
                activateOnDisconnect: activateOnDisconnect,
                capID: capID
            )
        }

        sendCommand(commandString)
    }

    func sendCommand(_ commandString: String) {
        if commandString.count <= maxCharacteristicLength {
            bluetoothManager.writeValue(commandString)
            terminalManager.addMessage("Synced: \(commandString)")
        } else {
            terminalManager.addMessage("Command exceeds characteristic length (\(commandString.count) > \(maxCharacteristicLength))")
        }
    }

    func readBuffer() {
        requestConfiguration()
    }

    func requestConfiguration() {
        awaitingConfigBlock1Response = true
        bluetoothManager.writeValue("_1")
        bluetoothManager.readValue()
        terminalManager.addMessage("Reading configuration (_1)...")
    }

    func requestLegacyConfigBlock2() {
        bluetoothManager.writeValue("_2")
        bluetoothManager.readValue()
        terminalManager.addMessage("Legacy device — reading configuration (_2)...")
    }

    func parseAndSetControlValues(from dataString: String) {
        terminalManager.addMessage("Syncing node...")
        terminalManager.addMessage("Raw data: \(dataString)")
        guard dataString.starts(with: "_") else {
            return
        }

        let components = dataString.dropFirst().split(separator: ",")
        let isNewFirmware = DBSProtocol.responseIncludesFirmwareVersion(dataString)

        for component in components {
            guard let (key, value) = DBSProtocol.parseKeyValue(from: component) else { continue }

            switch key {
            case .mode:
                suppressModeSyncFlag = true
                stimulationMode = value == DBSProtocol.modeBurst ? .burst : .continuous
                suppressModeSyncFlag = false
            case .amplitude:
                amplitude = Double(value)
            case .frequency:
                frequency = Double(value)
            case .pulseDuration:
                pulseDuration = Double(value)
            case .burstPeriod:
                burstPeriodMs = Double(value)
            case .intraBurstFrequency:
                intraBurstFrequency = Double(value)
            case .burstDuration:
                burstDurationMs = Double(value)
            case .activateOnDisconnect:
                activateOnDisconnect = (value != 0)
            case .capID:
                updateSelectedCapID(to: value)
            case .batteryVoltage:
                deviceBatteryLevel = DBSProtocol.batteryPercentage(fromMillivolts: value)
            case .firmwareVersion:
                firmwareVersionWire = value
            }
        }

        if awaitingConfigBlock1Response {
            awaitingConfigBlock1Response = false
            if isNewFirmware {
                terminalManager.addMessage("Firmware \(firmwareVersionLabel) — single config block (_1)")
            } else {
                requestLegacyConfigBlock2()
            }
        }

        requireSync = false
        hasReceivedInitialValues = true
    }

    func updateSelectedCapID(to newCapID: Int) {
        selectedCapID = String(format: "%02d", newCapID)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

struct ClockView: View {
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("\(currentTime, formatter: Self.localFormatter)")
            .font(.title2.monospacedDigit())
            .onReceive(timer) { _ in
                self.currentTime = Date()
            }
//        HStack {
//            Text("\(String(format: "0x%08X", Int32(currentTime.timeIntervalSince1970)))")
//        }
    }

    static var localFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
