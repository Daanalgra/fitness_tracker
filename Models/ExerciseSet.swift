import Foundation

struct ExerciseSet: Identifiable, Codable, Equatable {
    let id: UUID
    // New schema fields
    var setIndex: Int?
    var rpe: Double?
    var completedAt: Date?
    // Back-compat fields used throughout UI
    var reps: Int
    var weight: Double?
    var completed: Bool
    
    init(
        id: UUID = UUID(),
        setIndex: Int? = nil,
        reps: Int,
        weight: Double? = nil,
        rpe: Double? = nil,
        completedAt: Date? = nil,
        completed: Bool = false
    ) {
        self.id = id
        self.setIndex = setIndex
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.completedAt = completedAt
        self.completed = completed
    }
} 
