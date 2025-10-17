import Foundation
import CoreLocation

struct Workout: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var startedAt: Date?
    var endedAt: Date?
    var location: Location?
    var notes: String?
    var exerciseLogs: [WorkoutExercise]
    
    init(
        id: UUID = UUID(),
        name: String,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        location: Location? = nil,
        notes: String? = nil,
        exerciseLogs: [WorkoutExercise] = []
    ) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.location = location
        self.notes = notes
        self.exerciseLogs = exerciseLogs
    }
    
    var duration: TimeInterval? {
        guard let startedAt, let endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
    }
} 
