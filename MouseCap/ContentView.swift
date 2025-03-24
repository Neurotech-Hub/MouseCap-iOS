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

struct ContentView: View {
    let appName = "Creed DBS Control"
    var maxCharacteristicLength: Int {
        return bluetoothManager.getMaximumWriteLength()
    }
    @State private var debug = false
    @ObservedObject var bluetoothManager = BluetoothManager(
        serviceUUID: BluetoothDeviceUUIDs.Node.serviceUUID,
        nodeRxUUID: BluetoothDeviceUUIDs.Node.nodeRxUUID,
        nodeTxUUID: BluetoothDeviceUUIDs.Node.nodeTxUUID
    )
    @ObservedObject var terminalManager = TerminalManager.shared
    @State private var amplitude: Double = 0    // Ranges from 0 to 3000 uA
    @State private var frequency: Double = 130   // Ranges from 80 Hz to 160 Hz
    @State private var pulseDuration: Double = 50  // Ranges from 10% to 100%
    @State private var activateOnDisconnect: Bool = false
    @State private var requireSync: Bool = false
    @State private var ignoreChanges = true
    @State private var selectedCapID: String = "00"
    @State private var deviceBatteryLevel: Int = 100  // Add battery level state
    @State private var hasReceivedInitialValues: Bool = false  // Track if we've received initial values
    
    var isSimulator: Bool {
        #if targetEnvironment(simulator)
                // Code is running in the Simulator
                return true
        #else
                // Code is running on an actual device
                return false
        #endif
    }

    var body: some View {
        VStack {
            ZStack {
                // Centered ClockView
                ClockView()
                
                HStack {
                    Spacer() // Pushes everything to the right
                    Button(action: {
                        self.debug.toggle() // Toggle the debug state
                    }) {
                        Text("debug")
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
            }

            Button(action: handleBluetoothAction) {
                Text(bluetoothManager.isConnected ? "Disconnect" : "Connect")
                    .frame(minWidth: 100, minHeight: 44)
                    .foregroundColor(.white)
                    .background(bluetoothManager.isConnected ? Color.red : Color.black)
                    .cornerRadius(8) // Apply cornerRadius here to affect the background
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            .padding()
            
            Divider()
            
            Spacer()
            
            if bluetoothManager.isConnected || debug || isSimulator {
                VStack {
                    VStack {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Cap ID:")
                                    .padding(.trailing, 5)
                                    .fontWeight(.bold)
                                
                                Picker("Select Cap ID", selection: $selectedCapID) {
                                    ForEach(0..<100) { number in
                                        Text(String(format: "%02d", number)).tag(String(format: "%02d", number))
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 100)  // Increased width for 3 digits
                                .fixedSize()  // Prevent wrapping
                                .onChange(of: selectedCapID) { oldValue, newValue in
                                    requireSync = true
                                }
                                
                                Spacer()
                                    .frame(minWidth: 20)  // Minimum spacing between elements
                                
                                // Battery indicator
                                HStack(spacing: 4) {
                                    Image(systemName: deviceBatteryLevel > 20 ? "battery.100" : "battery.25")
                                        .foregroundColor(deviceBatteryLevel > 20 ? .green : .red)
                                    Text("\(deviceBatteryLevel)%")
                                        .foregroundColor(deviceBatteryLevel > 20 ? .primary : .red)
                                }
                            }
                        }
                        
                        // Amplitude control
                        VStack {
                            HStack {
                                Text("OFF")
                                    .font(.caption)
                                    .frame(alignment: .leading)
                                    .foregroundColor(.gray)
                                
                                Spacer() // Pushes the next element towards center
                                
                                let maxValue: Double = 600 // Maximum value for calculation
                                let calculatedValue: Double = (amplitude / 100) * maxValue
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Amplitude: \(amplitude, specifier: "%.0f")% (\(calculatedValue, specifier: "%.0f") µA @ 1kΩ)")
                                    
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(.green)
                                        Text("Charge balancing is ON")
                                    }
                                }
                                
                                Spacer() // Pushes the previous element towards center
                            }
                            
                            Slider(value: $amplitude, in: 0...100, step: 1)
                                .accentColor(.mint)
                                .onChange(of: amplitude) {
                                    if !ignoreChanges {
                                        requireSync = true
                                    }
                                }
                        }.padding(.top)
                        
                        // Frequency control
                        VStack {
                            Text("Frequency: \(frequency, specifier: "%.0f") Hz")
                            Slider(value: $frequency, in: 80...160, step: 5)
                                .accentColor(.cyan)
                                .onChange(of: frequency) {
                                    if !ignoreChanges {
                                        requireSync = true
                                    }
                                }
                        }.padding(.top)
                        
                        // Pulse Width control
                        VStack {
                            Text("Pulse Duration: \(pulseDuration, specifier: "%.0f") μs")
                            Slider(value: $pulseDuration, in: 90...600, step: 30)
                                .onChange(of: pulseDuration) {
                                    if !ignoreChanges {
                                        requireSync = true
                                    }
                                }
                                .accentColor(.purple)
                        }.padding(.top)
                        
                        // Activate on disconnect toggle
                        Toggle("Activate Stimulation", isOn: $activateOnDisconnect)
                            .onChange(of: activateOnDisconnect) {
                                if !ignoreChanges {
                                    requireSync = true
                                }
                            }
                            .padding()
                    }
                    .padding([.leading, .trailing, .top],30)
                    
                    Spacer()
                    
                    HStack {
                        Button(action: syncControls) {
                            Text("Sync")
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(requireSync ? Color.red : Color.clear, lineWidth: 5) // Red outline when requireSync is true
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
                    .padding([.leading, .trailing])
                    .onAppear {
                        bluetoothManager.onDisconnect = {
                            resetAllViewVars()
                        }
                        bluetoothManager.onNodeTxValueUpdated = { dataString in
                            parseAndSetControlValues(from: dataString)
                        }
                        
                        // Request configuration values before reading
                        bluetoothManager.writeValue("_1")
                        bluetoothManager.readValue()
                        
                        // Request additional values
                        bluetoothManager.writeValue("_2")
                        bluetoothManager.readValue()
                        
                        // Set ignoreChanges to false after a delay of 1 second
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            requireSync = false
                            ignoreChanges = false
                        }
                    }
                }
                .opacity(!hasReceivedInitialValues && !debug && !isSimulator ? 0.25 : 1.0)
                .disabled(!hasReceivedInitialValues && !debug && !isSimulator)
            }
            
            Divider()
            
            // terminal
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(terminalManager.receivedMessages, id: \.self) { message in
                        Text(message)
                            .foregroundColor(Color.green)
                            .font(.system(size: 11, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading) // Align text to the left
                    }
                }
                .padding(5)
                .onTapGesture {
                    let textToCopy = terminalManager.receivedMessages.joined(separator: "\n")
                    UIPasteboard.general.string = textToCopy
                    terminalManager.addMessage("Terminal copied to clipboard")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 150) // Full width and fixed height
            .background(Color.black)
            .cornerRadius(5)
            .padding()
        }
        .edgesIgnoringSafeArea(.bottom) // Ignore safe area to extend to the bottom edge
        .onAppear {
            terminalManager.addMessage("Hello, \(appName).")
        }
        .preferredColorScheme(.dark)  // Force dark mode
    }
    
    func handleBluetoothAction() {
        if bluetoothManager.isConnected || bluetoothManager.isConnecting {
            bluetoothManager.disconnect()
            hasReceivedInitialValues = false  // Reset the state on disconnect
        } else {
            bluetoothManager.startScanning()
            ignoreChanges = true
        }
    }
    
    func resetAllViewVars() {
        activateOnDisconnect = false
        requireSync = false
        hasReceivedInitialValues = false  // Reset on disconnect
    }
    
    func toggleLED() {
        bluetoothManager.writeValue("_L1")
        terminalManager.addMessage("Toggled LED")
    }
    
    func syncControls() {
        requireSync = false
        let amplitudeCommand = "A\(Int(amplitude))"
        let frequencyCommand = "F\(Int(frequency))"
        let pulseDurationCommand = "P\(Int(pulseDuration))"
        let activateOnDisconnectCommand = "G\(activateOnDisconnect ? 1 : 0)"
        let capId = "N\(Int(selectedCapID) ?? 0)"
        
        let commandString = "_\(amplitudeCommand),\(frequencyCommand),\(pulseDurationCommand),\(activateOnDisconnectCommand),\(capId)"
        // Send commandString to the Bluetooth device
        if commandString.count <= maxCharacteristicLength {
            bluetoothManager.writeValue(commandString)
            terminalManager.addMessage("Synced: \(commandString)")
        } else {
            terminalManager.addMessage("Command exceeds characteristic length (\(commandString.count) > \(maxCharacteristicLength))")
        }
    }
    
    func readBuffer() {
        // First request configuration values
        bluetoothManager.writeValue("_1")
        bluetoothManager.readValue()
        
        // Then request additional values
        bluetoothManager.writeValue("_2")
        bluetoothManager.readValue()
        
        terminalManager.addMessage("Reading configuration values...")
    }
    
    func parseAndSetControlValues(from dataString: String) {
        terminalManager.addMessage("Syncing node...")
        terminalManager.addMessage("Raw data: \(dataString)")  // Add raw data debug message
        // Check if the string starts with "_"
        guard dataString.starts(with: "_") else {
            return
        }
        
        // Remove the leading "_" and split the string by commas
        let components = dataString.dropFirst().split(separator: ",")
        
        for component in components {
            // Ensure each component has at least 2 characters (e.g., "A1")
            guard component.count >= 2 else { continue }
            
            let type = component.prefix(1)   // The control type (e.g., 'A', 'F', 'P')
            let valueString = component.dropFirst() // The rest of the string representing the value
            
            // Convert the value part to an integer
            guard let value = Int(valueString) else { continue }
            
            // Set the appropriate variable based on the type
            switch type {
            case "A": // Amplitude
                amplitude = Double(value)
            case "F": // Frequency
                frequency = Double(value)
            case "P": // Pulse duration
                pulseDuration = Double(value)
            case "G":
                activateOnDisconnect = (value != 0)
            case "N":
                updateSelectedCapID(to: value)
            case "V": // Battery voltage in millivolts
                let minVoltage: Double = 1400 // 1.4V in mV
                let maxVoltage: Double = 2800 // 2.8V in mV
                let percentage = max(0, min(100, ((Double(value) - minVoltage) / (maxVoltage - minVoltage)) * 100))
                deviceBatteryLevel = Int(round(percentage))
            default:
                break // Unknown type, ignore
            }
        }
        requireSync = false    // Reset requireSync
        hasReceivedInitialValues = true     // Mark that we've received initial values
    }
    
    // Function to update selectedCapID programmatically
    func updateSelectedCapID(to newCapID: Int) {
        selectedCapID = String(format: "%02d", newCapID)
    }
}

struct ClockView: View {
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("\(currentTime, formatter: Self.localFormatter)")
                .font(.largeTitle)
                .onReceive(timer) { _ in
                    self.currentTime = Date()
                }
            HStack {
                //                Text("\(currentTime.timeIntervalSince1970, specifier: "%.0f")")
                Text("\(String(format: "0x%08X", Int32(currentTime.timeIntervalSince1970)))")
            }
        }
    }
    
    static var localFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }
}

#Preview {
    ContentView()
}
