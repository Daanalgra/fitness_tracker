import Foundation

struct WorkoutSet: Identifiable, Codable {
    let id: UUID
    let reps: Int
    let weight: Double?
    let duration: TimeInterval?
    let distance: Double?
    let notes: String?
    
    init(
        id: UUID = UUID(),
        reps: Int,
        weight: Double? = nil,
        duration: TimeInterval? = nil,
        distance: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.distance = distance
        self.notes = notes
    }
} 