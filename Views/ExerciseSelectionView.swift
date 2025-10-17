import SwiftUI

struct ExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AppViewModel
    let onExerciseSelected: (Exercise) -> Void
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    
    private var filteredExercises: [Exercise] {
        var exercises = viewModel.exercises
        
        // Filter by search text
        if !searchText.isEmpty {
            exercises = exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Filter by muscle group
        if let muscleGroup = selectedMuscleGroup {
            exercises = exercises.filter { $0.muscleGroup == muscleGroup }
        }
        
        return exercises
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Muscle group filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(MuscleGroup.allCases, id: \.self) { muscleGroup in
                            FilterChip(
                                title: muscleGroup.rawValue,
                                isSelected: selectedMuscleGroup == muscleGroup
                            ) {
                                if selectedMuscleGroup == muscleGroup {
                                    selectedMuscleGroup = nil
                                } else {
                                    selectedMuscleGroup = muscleGroup
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Exercise list
                List(filteredExercises) { exercise in
                    Button {
                        onExerciseSelected(exercise)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(exercise.name)
                                    .font(.headline)
                                Text(exercise.muscleGroup.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ExerciseSelectionView(onExerciseSelected: { _ in })
        .environmentObject(AppViewModel())
} 