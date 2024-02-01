//
//  CBUUID.swift
//  MouseCap
//
//  Created by Matt Gaidica on 2/1/24.
//

import Foundation
import CoreBluetooth

public struct BluetoothDeviceUUIDs {
    public struct Node {
        public static let serviceUUID = CBUUID(string: "EEE0")
        public static let nodeRxUUID = CBUUID(string: "EEE1")
        public static let nodeTxUUID = CBUUID(string: "EEE2")
    }
}

