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
    @ObservedObject var bluetoothManager = BluetoothManager(serviceUUID: "EEE0", nodeRxUUID: "EEE1", nodeTxUUID: "EEE2")
    @ObservedObject var terminalManager = TerminalManager.shared
    @State private var amplitude: Double = 1    // Ranges from 0 to 3 mA
    @State private var frequency: Double = 130   // Ranges from 80 Hz to 160 Hz
    @State private var pulseWidth: Double = 50  // Ranges from 10% to 100%
    @State private var activateOnDisconnect: Bool = false
    
    var body: some View {
        VStack {
            ClockView()

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
            
            if bluetoothManager.isConnecting {
                Text("Connecting...")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            
            Divider();
            
            if bluetoothManager.isConnected {
                VStack {
                    Text("Cap ID: XXXX")
                        .padding()
                    // Amplitude control
                    VStack {
                        Slider(value: $amplitude, in: 0...3, step: 0.2)
                            .accentColor(.mint)
                        HStack {
                            Text("OFF")
                                .font(.caption)
                                .frame(alignment: .leading)
                                .foregroundColor(.gray)
                            
                            Spacer() // Pushes the next element towards center
                            
                            Text("Amplitude: \(amplitude, specifier: "%.1f") mA")
                                .font(.caption)
                            
                            Spacer() // Pushes the previous element towards center
                        }
                    }
                    
                    // Frequency control
                    VStack {
                        Slider(value: $frequency, in: 80...160, step: 5)
                            .accentColor(.cyan)
                        Text("Frequency: \(frequency, specifier: "%.0f") Hz")
                            .font(.caption)
                    }
                    
                    // Pulse Width control
                    VStack {
                        Slider(value: $pulseWidth, in: 10...100, step: 10)
                            .accentColor(.purple)
                        Text("Pulse Width: \(pulseWidth, specifier: "%.0f")%")
                            .font(.caption)
                    }
                    
                    // Activate on disconnect toggle
                    Toggle("Activate on disconnect", isOn: $activateOnDisconnect)
                        .padding()
                }
                .padding([.leading, .trailing, .top],30)
                
                Spacer()
                
                HStack {
                    Button(action: handleFirstAction) {
                        Text("Sync")
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                            .foregroundColor(.white)
                            .background(.blue)
                            .cornerRadius(8)
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
                    
                    Button(action: handleSecondAction) {
                        Text("Dump Data")
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                            .foregroundColor(.white)
                            .background(.gray)
                            .cornerRadius(8)
                    }
                    .padding(5)
                    .disabled(true)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                .padding([.leading, .trailing])
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
            }
            .frame(maxWidth: .infinity, maxHeight: 200) // Full width and fixed height
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
        }
    }
    
    func toggleLED() {
        bluetoothManager.writeValue("0")
        terminalManager.addMessage("Toggled LED")
    }
    
    func handleFirstAction() {
        // TODO: Add the action you want to perform when the first button is tapped
        print("First button tapped")
    }
    
    func handleSecondAction() {
        // TODO: Add the action you want to perform when the first button is tapped
        print("Second button tapped")
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
