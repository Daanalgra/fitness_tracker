import Foundation

struct WorkoutPlan: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let duration: String
    let difficulty: Difficulty
    let exercises: [PlannedExercise]
    
    init(id: UUID = UUID(), name: String, description: String, duration: String, difficulty: Difficulty, exercises: [PlannedExercise]) {
        self.id = id
        self.name = name
        self.description = description
        self.duration = duration
        self.difficulty = difficulty
        self.exercises = exercises
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: WorkoutPlan, rhs: WorkoutPlan) -> Bool {
        lhs.id == rhs.id
    }
}
