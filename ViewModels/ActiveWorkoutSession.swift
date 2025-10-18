import Foundation

struct RestTimer: Equatable {
    let duration: TimeInterval
    let startedAt: Date
    var endsAt: Date { startedAt.addingTimeInterval(duration) }
    func remaining(now: Date = Date()) -> TimeInterval { max(0, endsAt.timeIntervalSince(now)) }
    var isFinished: Bool { remaining() <= 0 }
}

@MainActor
final class ActiveWorkoutSession: ObservableObject {
    @Published var workout: Workout
    @Published var currentExerciseIndex: Int = 0
    @Published var restTimer: RestTimer?
    
    private let notificationScheduler: RestNotificationScheduling
    
    init(workout: Workout, notificationScheduler: RestNotificationScheduling) {
        self.workout = workout
        self.notificationScheduler = notificationScheduler
    }
    
    var currentExercise: WorkoutExercise? {
        guard workout.exerciseLogs.indices.contains(currentExerciseIndex) else { return nil }
        return workout.exerciseLogs[currentExerciseIndex]
    }
    
    func nextExercise() {
        guard currentExerciseIndex + 1 < workout.exerciseLogs.count else { return }
        currentExerciseIndex += 1
    }
    
    func previousExercise() {
        guard currentExerciseIndex - 1 >= 0 else { return }
        currentExerciseIndex -= 1
    }
    
    func addSet(reps: Int, weight: Double? = nil, rpe: Double? = nil) {
        guard var ex = currentExercise else { return }
        let idx = ex.sets.count
        let set = ExerciseSet(setIndex: idx, reps: reps, weight: weight, rpe: rpe, completedAt: nil, completed: false)
        ex.sets.append(set)
        workout.exerciseLogs[currentExerciseIndex] = ex
    }
    
    func updateSet(at index: Int, reps: Int, weight: Double?, rpe: Double?) {
        guard var ex = currentExercise, ex.sets.indices.contains(index) else { return }
        ex.sets[index].reps = reps
        ex.sets[index].weight = weight
        ex.sets[index].rpe = rpe
        workout.exerciseLogs[currentExerciseIndex] = ex
    }
    
    func completeSet(at index: Int) {
        guard var ex = currentExercise, ex.sets.indices.contains(index) else { return }
        ex.sets[index].completed = true
        ex.sets[index].completedAt = Date()
        workout.exerciseLogs[currentExerciseIndex] = ex
        // Start rest timer based on targetRest if available
        if let rest = ex.targetRest, rest > 0 {
            startRestTimer(duration: rest)
        }
    }
    
    func startRestTimer(duration: TimeInterval) {
        let started = Date()
        restTimer = RestTimer(duration: duration, startedAt: started)
        notificationScheduler.requestAuthorizationIfNeeded()
        notificationScheduler.scheduleRestNotification(
            endsAt: started.addingTimeInterval(duration),
            title: "Rest finished",
            body: "Time to start your next set"
        )
    }
    
    func cancelRestTimer() { restTimer = nil }
    
    func finalize() -> Workout {
        var w = workout
        if w.startedAt == nil { w.startedAt = Date() }
        w.endedAt = Date()
        return w
    }
}

