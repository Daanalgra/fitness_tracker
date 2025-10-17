//
//  Fitness_TrackerApp.swift
//  Fitness Tracker
//
//  Created by Daan Algra on 30/03/2025.
//

import SwiftUI

@main
struct Fitness_TrackerApp: App {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
