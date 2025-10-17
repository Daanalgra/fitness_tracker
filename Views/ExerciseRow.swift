import SwiftUI

struct ExerciseRow: View {
    let exercise: Exercise
    let targetSets: Int
    let targetReps: Int
    let completedSets: [ExerciseSet]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(.headline)
                Text(exercise.muscleGroup.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(targetSets) sets × \(targetReps) reps")
                    .font(.subheadline)
                if !completedSets.isEmpty {
                    Text("Completed: \(completedSets.count) sets")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ExerciseRow(
        exercise: Exercise(
            name: "Bench Press",
            muscleGroup: .chest,
            equipment: .barbell,
            difficulty: .intermediate,
            description: "Classic chest compound movement",
            imageURL: nil
        ),
        targetSets: 3,
        targetReps: 10,
        completedSets: []
    )
} 