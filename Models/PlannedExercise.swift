import Foundation

struct PlannedExercise: Identifiable, Codable {
    let id: UUID
    let exercise: Exercise
    var targetSets: Int
    var targetReps: Int
    var restDuration: TimeInterval
    var notes: String?
    
    init(
        id: UUID = UUID(),
        exercise: Exercise,
        targetSets: Int,
        targetReps: Int,
        restDuration: TimeInterval = 60,
        notes: String? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.restDuration = restDuration
        self.notes = notes
    }
} 