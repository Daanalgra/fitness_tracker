import Foundation

struct WorkoutExercise: Identifiable, Codable, Hashable {
    let id: UUID
    let workoutId: UUID
    let exerciseId: UUID
    var exercise: Exercise
    var order: Int
    var targetSets: Int?
    var targetReps: Int?
    var targetWeight: Double?
    var targetRest: TimeInterval?
    var notes: String?
    var sets: [ExerciseSet]
    
    init(
        id: UUID = UUID(),
        workoutId: UUID = UUID(),
        exercise: Exercise,
        order: Int = 0,
        targetSets: Int? = nil,
        targetReps: Int? = nil,
        targetWeight: Double? = nil,
        targetRest: TimeInterval? = nil,
        notes: String? = nil,
        sets: [ExerciseSet] = []
    ) {
        self.id = id
        self.workoutId = workoutId
        self.exerciseId = exercise.id
        self.exercise = exercise
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.targetRest = targetRest
        self.notes = notes
        self.sets = sets
    }
} 
