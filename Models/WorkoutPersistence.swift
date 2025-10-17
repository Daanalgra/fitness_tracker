import Foundation

enum WorkoutPersistence {
    static let currentSchemaVersion = 2
    
    struct StoredWorkouts: Codable {
        let schemaVersion: Int
        var workouts: [Workout]
    }
    
    static func decodeWorkouts(from data: Data) throws -> (workouts: [Workout], migrated: Bool) {
        let decoder = JSONDecoder()
        
        if let store = try? decoder.decode(StoredWorkouts.self, from: data) {
            let requiresMigration = store.schemaVersion < currentSchemaVersion
            return (store.workouts, requiresMigration)
        }
        
        let legacyWorkouts = try decoder.decode([LegacyWorkout].self, from: data)
        let migrated = legacyWorkouts.map { $0.toWorkout() }
        return (migrated, true)
    }
    
    static func encodeWorkouts(_ workouts: [Workout]) throws -> Data {
        let encoder = JSONEncoder()
        let store = StoredWorkouts(schemaVersion: currentSchemaVersion, workouts: workouts)
        return try encoder.encode(store)
    }
}

// MARK: - Legacy

private struct LegacyWorkout: Codable {
    let id: UUID
    let name: String
    let exercises: [PlannedExercise]
    let startTime: Date?
    let endTime: Date?
    let location: Location?
    let notes: String?
    
    func toWorkout() -> Workout {
        let logs = exercises.enumerated().map { index, planned -> WorkoutExercise in
            WorkoutExercise(
                workoutId: id,
                exercise: planned.exercise,
                order: index,
                targetSets: planned.targetSets,
                targetReps: planned.targetReps,
                targetRest: planned.restDuration,
                notes: planned.notes,
                sets: []
            )
        }
        
        return Workout(
            id: id,
            name: name,
            startedAt: startTime,
            endedAt: endTime,
            location: location,
            notes: notes,
            exerciseLogs: logs
        )
    }
}
