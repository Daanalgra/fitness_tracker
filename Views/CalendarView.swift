import SwiftUI
import EventKit

struct CalendarView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var selectedDate = Date()
    @State private var showingNewWorkoutSheet = false
    @State private var showingWorkoutDetails = false
    @State private var selectedWorkout: Workout?
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Calendar Header
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                        }
                        
                        Text(monthYearString(from: selectedDate))
                            .font(.title2)
                            .bold()
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Days of Week Header
                    HStack {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day)
                                .frame(maxWidth: .infinity)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Calendar Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(daysInMonth(), id: \.self) { date in
                            if let date = date {
                                DayCell(
                                    date: date,
                                    selectedDate: $selectedDate,
                                    hasWorkout: hasWorkout(on: date)
                                )
                            } else {
                                Color.clear
                                    .aspectRatio(1, contentMode: .fill)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Workouts List
                    if let workouts = workoutsForSelectedDate {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Workouts")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(workouts) { workout in
                                WorkoutRow(workout: workout)
                                    .onTapGesture {
                                        selectedWorkout = workout
                                        showingWorkoutDetails = true
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            // TODO: Implement delete
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            // TODO: Implement edit
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.orange)
                                    }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewWorkoutSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewWorkoutSheet) {
                PastWorkoutSheet()
            }
            .sheet(isPresented: $showingWorkoutDetails) {
                if let workout = selectedWorkout {
                    WorkoutDetailsView(workout: workout)
                }
            }
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func daysInMonth() -> [Date?] {
        let interval = DateInterval(start: startOfMonth(), end: endOfMonth())
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        
        // Add empty cells for days before the first day of the month
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        // Add days of the month
        calendar.enumerateDates(
            startingAfter: interval.start,
            matching: DateComponents(day: 1),
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date, date <= interval.end {
                days.append(date)
            } else {
                stop = true
            }
        }
        
        // Pad the end of the array to make it a multiple of 7
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func startOfMonth() -> Date {
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        return calendar.date(from: components) ?? selectedDate
    }
    
    private func endOfMonth() -> Date {
        let components = DateComponents(month: 1, day: -1)
        return calendar.date(byAdding: components, to: startOfMonth()) ?? selectedDate
    }
    
    private func hasWorkout(on date: Date) -> Bool {
        viewModel.workouts.contains { workout in
            if let start = workout.startedAt {
                return calendar.isDate(start, inSameDayAs: date)
            }
            return false
        }
    }
    
    private var workoutsForSelectedDate: [Workout]? {
        viewModel.workouts.filter { workout in
            if let start = workout.startedAt {
                return calendar.isDate(start, inSameDayAs: selectedDate)
            }
            return false
        }.sorted { ($0.startedAt ?? Date()) > ($1.startedAt ?? Date()) }
    }
}

struct DayCell: View {
    let date: Date
    @Binding var selectedDate: Date
    let hasWorkout: Bool
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.blue.opacity(0.3) : Color.clear)
            
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline)
                
                if hasWorkout {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fill)
        .onTapGesture {
            selectedDate = date
        }
    }
    
    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
}

struct WorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.name)
                    .font(.headline)
                
                Spacer()
                
                if let start = workout.startedAt {
                    Text(start, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let location = workout.location {
                HStack {
                    Image(systemName: "location.fill")
                    Text(location.name)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            if !workout.exerciseLogs.isEmpty {
                Text("\(workout.exerciseLogs.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
        .padding(.horizontal)
    }
}

struct WorkoutDetailsSection: View {
    @Binding var workoutName: String
    @Binding var selectedDate: Date
    @Binding var selectedTime: Date
    @Binding var selectedLocation: Location?
    @Binding var showingLocationPicker: Bool
    
    var body: some View {
        Section("Workout Details") {
            TextField("Workout Name", text: $workoutName)
            
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
            DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
            
            Button {
                showingLocationPicker = true
            } label: {
                HStack {
                    Text("Location")
                    Spacer()
                    if let location = selectedLocation {
                        Text(location.name)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct ExercisesSection: View {
    @Binding var exercises: [WorkoutExercise]
    @Binding var showingExercisePicker: Bool
    
    var body: some View {
        Section("Exercises") {
            ForEach(exercises) { exercise in
                ExerciseRow(
                    exercise: exercise.exercise,
                    targetSets: exercise.sets.count,
                    targetReps: exercise.sets.first?.reps ?? 0,
                    completedSets: exercise.sets
                )
            }
            
            Button {
                showingExercisePicker = true
            } label: {
                Label("Add Exercise", systemImage: "plus.circle.fill")
            }
        }
    }
}

struct NotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        Section("Notes") {
            TextEditor(text: $notes)
                .frame(height: 100)
        }
    }
}

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AppViewModel
    @Binding var selectedLocation: Location?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredLocations) { location in
                    Button {
                        selectedLocation = location
                        dismiss()
                    } label: {
                        HStack {
                            Text(location.name)
                            Spacer()
                            if selectedLocation?.id == location.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search locations")
            .navigationTitle("Select Location")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
    
    private var filteredLocations: [Location] {
        if searchText.isEmpty {
            return viewModel.locations
        }
        return viewModel.locations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

struct PastWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var workoutName = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var selectedLocation: Location?
    @State private var showingLocationPicker = false
    @State private var showingExercisePicker = false
    @State private var exercises: [WorkoutExercise] = []
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                WorkoutDetailsSection(
                    workoutName: $workoutName,
                    selectedDate: $selectedDate,
                    selectedTime: $selectedTime,
                    selectedLocation: $selectedLocation,
                    showingLocationPicker: $showingLocationPicker
                )
                
                ExercisesSection(
                    exercises: $exercises,
                    showingExercisePicker: $showingExercisePicker
                )
                
                NotesSection(notes: $notes)
            }
            .navigationTitle("Log Past Workout")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveWorkout()
                }
                .disabled(workoutName.isEmpty)
            )
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(selectedLocation: $selectedLocation)
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExerciseSelectionView { exercise in
                    exercises.append(WorkoutExercise(exercise: exercise))
                }
                .environmentObject(viewModel)
            }
        }
    }
    
    private func saveWorkout() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        
        var finalDate = calendar.date(from: components) ?? Date()
        finalDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                minute: timeComponents.minute ?? 0,
                                second: 0,
                                of: finalDate) ?? finalDate
        
        viewModel.logPastWorkout(
            name: workoutName,
            date: finalDate,
            location: selectedLocation,
            exercises: exercises,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

struct WorkoutDetailsView: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss
    @State private var showingMap = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(workout.name)
                            .font(.title)
                            .bold()
                        
                        if let start = workout.startedAt {
                            Text(start, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Location
                    if let location = workout.location {
                        Button {
                            showingMap = true
                        } label: {
                            HStack {
                                Image(systemName: "location.fill")
                                Text(location.name)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 1)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Exercises
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercises")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(workout.exerciseLogs) { plannedExercise in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(plannedExercise.exercise.name)
                                    .font(.headline)
                                
                                HStack(spacing: 8) {
                                    if let sets = plannedExercise.targetSets, let reps = plannedExercise.targetReps {
                                        Text("\(sets) sets × \(reps) reps")
                                    } else {
                                        Text("Targets not set")
                                    }
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 1)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    
                    // Notes
                    if let notes = workout.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 1)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(isPresented: $showingMap) {
                if let location = workout.location {
                    LocationMapView(location: location)
                }
            }
        }
    }
}

struct ExerciseDetailRow: View {
    let exercise: WorkoutExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exercise.name)
                .font(.headline)
            
            if !exercise.sets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(exercise.sets) { set in
                            SetBadge(set: set)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
        .padding(.horizontal)
    }
}

struct EventRow: View {
    let event: EKEvent
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(event.title)
                .font(.headline)
            Text(event.startDate, style: .time)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// Helper extension for calendar date generation
extension Calendar {
    func generateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(startingAfter: interval.start,
                      matching: components,
                      matchingPolicy: .nextTime) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
} 
