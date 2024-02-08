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
    let appName = "Mouse Cap Control"
    let nodeChracteristicLength = 20
    @State private var debug = false
    @ObservedObject var bluetoothManager = BluetoothManager(
        serviceUUID: BluetoothDeviceUUIDs.Node.serviceUUID,
        nodeRxUUID: BluetoothDeviceUUIDs.Node.nodeRxUUID,
        nodeTxUUID: BluetoothDeviceUUIDs.Node.nodeTxUUID
    )
    @ObservedObject var terminalManager = TerminalManager.shared
    @State private var amplitude: Double = 1    // Ranges from 0 to 3000 uA
    @State private var frequency: Double = 130   // Ranges from 80 Hz to 160 Hz
    @State private var pulseWidth: Double = 50  // Ranges from 10% to 100%
    @State private var activateOnDisconnect: Bool = false
    @State private var requireSync: Bool = false
    @State private var ignoreChanges = true
    
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
            
            if bluetoothManager.isConnected || debug || isSimulator {
                VStack {
                    Text("Cap ID: XXXX")
                        .padding()
                    // Amplitude control
                    VStack {
                        Slider(value: $amplitude, in: 0...3000, step: 100)
                            .accentColor(.mint)
                            .onChange(of: amplitude) {
                                if !ignoreChanges {
                                    requireSync = true
                                }
                            }
                        HStack {
                            Text("OFF")
                                .font(.caption)
                                .frame(alignment: .leading)
                                .foregroundColor(.gray)
                            
                            Spacer() // Pushes the next element towards center
                            
                            Text("Amplitude: \(amplitude, specifier: "%.0f") μA")
                                .font(.caption)
                            
                            Spacer() // Pushes the previous element towards center
                        }
                    }
                    
                    // Frequency control
                    VStack {
                        Slider(value: $frequency, in: 80...160, step: 5)
                            .accentColor(.cyan)
                            .onChange(of: frequency) {
                                if !ignoreChanges {
                                    requireSync = true
                                }
                            }
                        Text("Frequency: \(frequency, specifier: "%.0f") Hz")
                            .font(.caption)
                    }
                    
                    // Pulse Width control
                    VStack {
                        Slider(value: $pulseWidth, in: 10...1000, step: 10)
                            .onChange(of: pulseWidth) {
                                if !ignoreChanges {
                                    requireSync = true
                                }
                            }
                            .accentColor(.purple)
                        Text("Pulse Width: \(pulseWidth, specifier: "%.0f") μs")
                            .font(.caption)
                    }
                    
                    // Activate on disconnect toggle
                    Toggle("Activate on disconnect", isOn: $activateOnDisconnect)
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
                    bluetoothManager.readValue() // Trigger the read operation
                    
                    // Set ignoreChanges to false after a delay of 1 second
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        requireSync = false
                        ignoreChanges = false
                    }
                }
            }
            
            Spacer()
            
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
    }
    
    func handleBluetoothAction() {
        if bluetoothManager.isConnected || bluetoothManager.isConnecting {
            bluetoothManager.disconnect()
        } else {
            bluetoothManager.startScanning()
            ignoreChanges = true
        }
    }
    
    func resetAllViewVars() {
        activateOnDisconnect = false // reset
        requireSync = false // known state
    }
    
    func toggleLED() {
        bluetoothManager.writeValue("_L1")
        terminalManager.addMessage("Toggled LED")
    }
    
    func syncControls() {
        requireSync = false
        let amplitudeCommand = "A\(Int(amplitude))"
        let frequencyCommand = "F\(Int(frequency))"
        let pulseWidthCommand = "P\(Int(pulseWidth))"
        let activateOnDisconnectCommand = "G\(activateOnDisconnect ? 1 : 0)"
        
        let commandString = "_\(amplitudeCommand),\(frequencyCommand),\(pulseWidthCommand),\(activateOnDisconnectCommand)"
        // Send commandString to the Bluetooth device
        if commandString.count <= nodeChracteristicLength {
            bluetoothManager.writeValue(commandString)
            terminalManager.addMessage("Synced: \(commandString)")
        } else {
            terminalManager.addMessage("Command exceeds characteristic length")
        }
        
    }
    
    func readBuffer() {
        bluetoothManager.onNodeTxValueUpdated = { newValue in
            terminalManager.addMessage(newValue)
        }
        bluetoothManager.readValue()
    }
    
    func parseAndSetControlValues(from dataString: String) {
        terminalManager.addMessage("Syncing node...")
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
            case "P": // Pulse Width
                pulseWidth = Double(value)
            default:
                break // Unknown type, ignore
            }
        }
        requireSync = false    // Reset requireSync
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
