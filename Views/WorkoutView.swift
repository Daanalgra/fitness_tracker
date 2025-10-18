import SwiftUI
import MapKit
import CoreLocation

struct WorkoutView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showingNewWorkoutSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Suggested Workouts")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            SuggestedWorkoutCard(
                                title: "Full Body",
                                subtitle: "45 min",
                                systemImage: "figure.strengthtraining.traditional",
                                color: .blue
                            ) {
                                viewModel.startNewWorkout(name: "Full Body Workout", plan: viewModel.workoutPlans.first { $0.name == "Full Body" })
                            }
                            
                            SuggestedWorkoutCard(
                                title: "Core",
                                subtitle: "30 min",
                                systemImage: "figure.core.training",
                                color: .green
                            ) {
                                viewModel.startNewWorkout(name: "Core Workout", plan: viewModel.workoutPlans.first { $0.name == "Core" })
                            }
                            
                            SuggestedWorkoutCard(
                                title: "Back",
                                subtitle: "40 min",
                                systemImage: "figure.back.massage",
                                color: .orange
                            ) {
                                viewModel.startNewWorkout(name: "Back Workout", plan: viewModel.workoutPlans.first { $0.name == "Back" })
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Workout")
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
            NewWorkoutSheet()
        }
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.activeWorkout != nil },
            set: { if !$0 { viewModel.activeWorkout = nil; viewModel.session = nil } }
        )) {
            WorkoutInProgressView()
                .environmentObject(viewModel)
        }
    }
}
}

struct SuggestedWorkoutCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

struct PlanPickerView: View {
    @Binding var selectedPlan: WorkoutPlan?
    let plans: [WorkoutPlan]
    
    var body: some View {
        Picker("Plan", selection: $selectedPlan) {
            Text("No Plan").tag(nil as WorkoutPlan?)
            ForEach(plans) { plan in
                Text(plan.name).tag(plan as WorkoutPlan?)
            }
        }
    }
}

struct NewWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var name = ""
    @State private var selectedPlan: WorkoutPlan?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                    PlanPickerView(selectedPlan: $selectedPlan, plans: viewModel.workoutPlans)
                } header: {
                    Text("Workout Details")
                }
            }
            .navigationTitle("New Workout")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Start") {
                    viewModel.startNewWorkout(name: name, plan: selectedPlan)
                    dismiss()
                }
                .disabled(name.isEmpty)
            )
        }
    }
}

struct CurrentWorkoutCard: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Workout")
                .font(.headline)
            
            Text(workout.name)
                .font(.title2)
                .bold()
            
            if let start = workout.startedAt {
                Text("Started: \(start.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(workout.exerciseLogs.count), total: Double(workout.exerciseLogs.count))
                .tint(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PlannedExerciseRow: View {
    let exercise: PlannedExercise
    @State private var showingDetails = false
    
    var body: some View {
        Button {
            showingDetails = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exercise.name)
                        .font(.headline)
                    
                    HStack {
                        Text("\(exercise.targetSets) sets × \(exercise.targetReps) reps")
                        Text("•")
                        Text("\(Int(exercise.restDuration))s rest")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showingDetails) {
            ExerciseDetailView(exercise: exercise.exercise)
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let imageURL = exercise.imageURL {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                        } placeholder: {
                            ProgressView()
                                .frame(height: 200)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.title)
                            .bold()
                        
                        HStack {
                            Label(exercise.muscleGroup.rawValue, systemImage: "figure.walk")
                            Spacer()
                            Label(exercise.equipment.rawValue, systemImage: "dumbbell.fill")
                            Spacer()
                            Label(exercise.difficulty.rawValue, systemImage: "chart.bar.fill")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        Text("Description")
                            .font(.headline)
                        Text(exercise.description)
                            .font(.body)
                        
                        if let variations = exercise.variations {
                            Text("Variations")
                                .font(.headline)
                            ForEach(variations, id: \.self) { variation in
                                Text("• \(variation)")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    WorkoutView()
        .environmentObject(AppViewModel())
} 
