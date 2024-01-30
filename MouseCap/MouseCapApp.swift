//
//  MouseCapApp.swift
//  MouseCap
//
//  Created by Matt Gaidica on 1/29/24.
//

import SwiftUI

@main
struct MouseCapApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.colorScheme, .dark) // Forces dark mode for the entire app
        }
    }
}
