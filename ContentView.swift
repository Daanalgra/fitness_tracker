//
//  ContentView.swift
//  Fitness Tracker
//
//  Created by Daan Algra on 30/03/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        TabView {
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            WorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "figure.run")
                }
            
            WorkoutPlansView()
                .tabItem {
                    Label("Plans", systemImage: "list.bullet")
                }
            
            ExerciseLibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
}
