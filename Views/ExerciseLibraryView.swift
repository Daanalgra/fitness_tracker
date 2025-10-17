import SwiftUI
import AVKit

struct ExerciseLibraryView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var selectedEquipment: Equipment?
    @State private var selectedDifficulty: Difficulty?
    @State private var showingFilters = false
    
    var filteredExercises: [Exercise] {
        viewModel.exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty || 
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.description.localizedCaseInsensitiveContains(searchText)
            
            let matchesMuscleGroup = selectedMuscleGroup == nil || 
                exercise.muscleGroup == selectedMuscleGroup
            
            let matchesEquipment = selectedEquipment == nil || 
                exercise.equipment == selectedEquipment
            
            let matchesDifficulty = selectedDifficulty == nil || 
                exercise.difficulty == selectedDifficulty
            
            return matchesSearch && matchesMuscleGroup && 
                   matchesEquipment && matchesDifficulty
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText)
                
                Button {
                    showingFilters.toggle()
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filters")
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                }
                
                if showingFilters {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterSection(
                                title: "Muscle Group",
                                options: MuscleGroup.allCases,
                                selection: $selectedMuscleGroup
                            )
                            
                            FilterSection(
                                title: "Equipment",
                                options: Equipment.allCases,
                                selection: $selectedEquipment
                            )
                            
                            FilterSection(
                                title: "Difficulty",
                                options: Difficulty.allCases,
                                selection: $selectedDifficulty
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                List(filteredExercises) { exercise in
                    NavigationLink {
                        ExerciseDetailView(exercise: exercise)
                    } label: {
                        ExerciseListItem(exercise: exercise)
                    }
                }
            }
            .navigationTitle("Exercise Library")
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

struct AddToWorkoutSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var sets = 3
    @State private var reps = 10
    @State private var restDuration = 60
    
    var body: some View {
        NavigationView {
            Form {
                Section("Exercise Details") {
                    Stepper("Sets: \(sets)", value: $sets, in: 1...10)
                    Stepper("Reps: \(reps)", value: $reps, in: 1...100)
                    Stepper("Rest: \(Int(restDuration))s", value: $restDuration, in: 0...300, step: 15)
                }
            }
            .navigationTitle("Add to Workout")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") {
                    let plannedExercise = PlannedExercise(
                        exercise: exercise,
                        targetSets: sets,
                        targetReps: reps,
                        restDuration: TimeInterval(restDuration)
                    )
                    viewModel.addExerciseToWorkout(plannedExercise)
                    dismiss()
                }
            )
        }
    }
}

extension MuscleGroup: CustomStringConvertible {
    var description: String {
        self.rawValue
    }
}

extension Equipment: CustomStringConvertible {
    var description: String {
        self.rawValue
    }
}

extension Difficulty: CustomStringConvertible {
    var description: String {
        self.rawValue
    }
}

#Preview {
    ExerciseLibraryView()
        .environmentObject(AppViewModel())
} 