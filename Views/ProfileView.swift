import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("User Name")
                                .font(.title2)
                                .bold()
                            Text("Member since 2024")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Statistics") {
                    StatRow(title: "Total Workouts", value: "\(viewModel.workouts.count)")
                    
                    let thisWeekCount = viewModel.workouts.filter { workout in
                        guard let start = workout.startedAt else { return false }
                        return Calendar.current.isDateInThisWeek(start)
                    }.count
                    StatRow(title: "This Week", value: "\(thisWeekCount)")
                    
                    let thisMonthCount = viewModel.workouts.filter { workout in
                        guard let start = workout.startedAt else { return false }
                        return Calendar.current.isDateInThisMonth(start)
                    }.count
                    StatRow(title: "This Month", value: "\(thisMonthCount)")
                }
                
                Section("Settings") {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("App Settings", systemImage: "gear")
                    }
                    
                    Button {
                        // TODO: Implement export data
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        // TODO: Implement backup
                    } label: {
                        Label("Backup & Restore", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("useMetricSystem") private var useMetricSystem = true
    @AppStorage("showRestTimer") private var showRestTimer = true
    @AppStorage("defaultRestDuration") private var defaultRestDuration = 60
    
    var body: some View {
        NavigationView {
            Form {
                Section("Units") {
                    Toggle("Use Metric System", isOn: $useMetricSystem)
                }
                
                Section("Workout") {
                    Toggle("Show Rest Timer", isOn: $showRestTimer)
                    if showRestTimer {
                        Stepper("Default Rest Duration: \(defaultRestDuration)s", value: $defaultRestDuration, in: 0...300, step: 15)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

extension Calendar {
    func isDateInThisWeek(_ date: Date) -> Bool {
        isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    func isDateInThisMonth(_ date: Date) -> Bool {
        isDate(date, equalTo: Date(), toGranularity: .month)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppViewModel())
} 
