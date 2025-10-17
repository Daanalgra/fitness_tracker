import Foundation
import CoreLocation
import EventKit

enum CalendarError: Error {
    case accessDenied
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var workoutPlans: [WorkoutPlan] = []
    @Published var exercises: [Exercise] = []
    @Published var currentWorkout: Workout?
    @Published var selectedPlan: WorkoutPlan?
    @Published var calendarEvents: [EKEvent] = []
    @Published var locations: [Location] = []
    @Published var activeWorkout: Workout?
    
    private let eventStore = EKEventStore()
    private let locationManager = CLLocationManager()
    
    init() {
        loadData()
        setupInitialAccess()
    }
    
    private func setupInitialAccess() {
        Task {
            do {
                try await requestCalendarAccess()
                await loadCalendarEvents()
            } catch {
                print("Failed to get calendar access: \(error)")
            }
        }
        requestLocationAccess()
    }
    
    // MARK: - Data Management
    
    private func loadData() {
        var requiresMigrationSave = false
        do {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let workoutsURL = documentsDirectory.appendingPathComponent("workouts.json")
            let locationsURL = documentsDirectory.appendingPathComponent("locations.json")
            
            if let workoutsData = try? Data(contentsOf: workoutsURL) {
                let decoded = try WorkoutPersistence.decodeWorkouts(from: workoutsData)
                workouts = decoded.workouts
                requiresMigrationSave = decoded.migrated
            }
            
            if let locationsData = try? Data(contentsOf: locationsURL) {
                locations = try JSONDecoder().decode([Location].self, from: locationsData)
            }
        } catch {
            print("Error loading data: \(error)")
        }
        
        loadDefaultExercises()
        if workoutPlans.isEmpty {
            loadDefaultWorkoutPlans()
        }
        
        if requiresMigrationSave {
            saveData()
        }
    }
    
    private func loadDefaultExercises() {
        exercises = [
            // Chest Exercise Variations
            Exercise(
                name: "Bench Press",
                muscleGroup: .chest,
                equipment: .barbell,
                difficulty: .intermediate,
                description: """
                    Classic chest compound movement.
                    Form cues:
                    - Retract shoulder blades
                    - Keep feet flat on floor
                    - Lower bar to mid-chest
                    - Maintain natural arch in lower back
                    """,
                imageURL: URL(string: "https://api.exercisedb.io/image/bench-press"),
                variations: ["Close Grip", "Wide Grip", "Paused"]
            ),
            Exercise(
                name: "Incline Dumbbell Press",
                muscleGroup: .chest,
                equipment: .dumbbells,
                difficulty: .intermediate,
                description: """
                    Upper chest focused press.
                    Form cues:
                    - Set bench angle 30-45 degrees
                    - Keep elbows at 45-degree angle
                    - Drive dumbbells up and slightly in
                    - Control the eccentric phase
                    """,
                imageURL: URL(string: "https://api.exercisedb.io/image/incline-db-press"),
                variations: ["Neutral Grip", "Alternating", "Single Arm"]
            ),
            
            // Back Exercise Variations
            Exercise(
                name: "Pull-up",
                muscleGroup: .back,
                equipment: .bodyweight,
                difficulty: .intermediate,
                description: """
                    Upper body pulling movement.
                    Form cues:
                    - Start from dead hang
                    - Pull shoulder blades down first
                    - Lead with chest to bar
                    - Control descent
                    Progression steps:
                    1. Negative pull-ups
                    2. Band-assisted pull-ups
                    3. Full pull-ups
                    4. Weighted pull-ups
                    """,
                imageURL: URL(string: "https://api.exercisedb.io/image/pull-up"),
                variations: ["Wide Grip", "Neutral Grip", "Chin-up", "Mixed Grip"]
            ),
            
            // Leg Exercise Variations
            Exercise(
                name: "Squat",
                muscleGroup: .legs,
                equipment: .barbell,
                difficulty: .intermediate,
                description: """
                    Fundamental lower body movement.
                    Form cues:
                    - Feet shoulder-width apart
                    - Break at hips and knees
                    - Keep chest up
                    - Drive through heels
                    Progression steps:
                    1. Bodyweight squat
                    2. Goblet squat
                    3. Front squat
                    4. Back squat
                    """,
                imageURL: URL(string: "https://api.exercisedb.io/image/squat"),
                variations: ["Front Squat", "Box Squat", "Pause Squat", "High-Bar", "Low-Bar"]
            ),
            
            // Shoulder Exercise Variations
            Exercise(
                name: "Overhead Press",
                muscleGroup: .shoulders,
                equipment: .barbell,
                difficulty: .intermediate,
                description: """
                    Vertical pressing movement.
                    Form cues:
                    - Stack joints (wrist, elbow, shoulder)
                    - Brace core tight
                    - Press straight up
                    - Clear face quickly
                    Progression steps:
                    1. Dumbbell press
                    2. Seated barbell press
                    3. Standing strict press
                    4. Push press
                    """,
                imageURL: URL(string: "https://api.exercisedb.io/image/overhead-press"),
                variations: ["Push Press", "Behind Neck", "Single Arm", "Seated"]
            ),
            
            // Advanced Variations
            Exercise(
                name: "Muscle Up",
                muscleGroup: .back,
                equipment: .bodyweight,
                difficulty: .advanced,
                description: """
                    Advanced pulling and pushing movement.
                    Prerequisites:
                    - Strong pull-ups (10+ strict)
                    - Explosive power
                    - Good false grip
                    Progression steps:
                    1. High pull-ups
                    2. Deep dips
                    3. False grip pull-ups
                    4. Negative muscle ups
                    5. Full muscle up
                    """,
                imageURL: URL(string: "https://api.exercisedb.io/image/muscle-up"),
                variations: ["Bar Muscle Up", "Ring Muscle Up", "Strict Muscle Up"]
            ),
            Exercise(
                name: "Planche Push-up",
                muscleGroup: .chest,
                equipment: .bodyweight,
                difficulty: .advanced,
                description: """
                    Advanced pushing movement.
                    Prerequisites:
                    - Strong push-ups
                    - Good shoulder strength
                    - Core control
                    Progression steps:
                    1. Pseudo planche push-ups
                    2. Tuck planche
                    3. Advanced tuck planche
                    4. Straddle planche
                    5. Full planche
                    """,
                imageURL: URL(string: "https://api.exercisedb.io/image/planche-pushup"),
                variations: ["Tuck", "Advanced Tuck", "Straddle", "Full"]
            ),
            
            // Specialized Exercise Variations
            Exercise(
                name: "Turkish Get-up",
                muscleGroup: .core,
                equipment: .dumbbells,
                difficulty: .intermediate,
                description: """
                    Full-body control movement.
                    Key points:
                    - Keep eye on weight
                    - Maintain vertical arm
                    - Move deliberately
                    - Control throughout
                    Progression steps:
                    1. No weight
                    2. Light dumbbell
                    3. Kettlebell
                    4. Heavy kettlebell
                    """,
                imageURL: URL(string: "https://api.exercisedb.io/image/turkish-getup"),
                variations: ["Dumbbell", "Kettlebell", "Barbell"]
            ),
            
            // Chest Exercises (Additional)
            Exercise(
                name: "Decline Bench Press",
                muscleGroup: .chest,
                equipment: .barbell,
                difficulty: .intermediate,
                description: "Targets lower chest muscles",
                imageURL: URL(string: "https://api.exercisedb.io/image/decline-bench-press")
            ),
            Exercise(
                name: "Dumbbell Flyes",
                muscleGroup: .chest,
                equipment: .dumbbells,
                difficulty: .intermediate,
                description: "Isolation exercise for chest width",
                imageURL: URL(string: "https://api.exercisedb.io/image/dumbbell-flyes")
            ),
            
            // Back Exercises (Additional)
            Exercise(
                name: "Meadows Row",
                muscleGroup: .back,
                equipment: .barbell,
                difficulty: .intermediate,
                description: "Unilateral back thickness exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/meadows-row")
            ),
            Exercise(
                name: "Straight Arm Pulldown",
                muscleGroup: .back,
                equipment: .cable,
                difficulty: .beginner,
                description: "Lat isolation exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/straight-arm-pulldown")
            ),
            
            // Legs Exercises (Additional)
            Exercise(
                name: "Bulgarian Split Squat",
                muscleGroup: .legs,
                equipment: .dumbbells,
                difficulty: .intermediate,
                description: "Unilateral leg development",
                imageURL: URL(string: "https://api.exercisedb.io/image/bulgarian-split-squat")
            ),
            Exercise(
                name: "Hip Thrust",
                muscleGroup: .legs,
                equipment: .barbell,
                difficulty: .intermediate,
                description: "Glute focused exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/hip-thrust")
            ),
            
            // Shoulders Exercises (Additional)
            Exercise(
                name: "Upright Row",
                muscleGroup: .shoulders,
                equipment: .barbell,
                difficulty: .intermediate,
                description: "Compound shoulder exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/upright-row")
            ),
            Exercise(
                name: "Reverse Flyes",
                muscleGroup: .shoulders,
                equipment: .dumbbells,
                difficulty: .beginner,
                description: "Rear deltoid isolation",
                imageURL: URL(string: "https://api.exercisedb.io/image/reverse-flyes")
            ),
            
            // Arms Exercises (Additional)
            Exercise(
                name: "Concentration Curl",
                muscleGroup: .arms,
                equipment: .dumbbells,
                difficulty: .beginner,
                description: "Isolated bicep peak exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/concentration-curl")
            ),
            Exercise(
                name: "Diamond Push-up",
                muscleGroup: .arms,
                equipment: .bodyweight,
                difficulty: .intermediate,
                description: "Tricep focused push-up variation",
                imageURL: URL(string: "https://api.exercisedb.io/image/diamond-pushup")
            ),
            
            // Core Exercises (Additional)
            Exercise(
                name: "Dragon Flag",
                muscleGroup: .core,
                equipment: .bodyweight,
                difficulty: .advanced,
                description: "Advanced core control exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/dragon-flag")
            ),
            Exercise(
                name: "Pallof Press",
                muscleGroup: .core,
                equipment: .cable,
                difficulty: .intermediate,
                description: "Anti-rotation core exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/pallof-press")
            ),
            
            // Mobility Exercises
            Exercise(
                name: "Cat-Cow Stretch",
                muscleGroup: .core,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Spinal mobility exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/cat-cow")
            ),
            Exercise(
                name: "Hip Flexor Stretch",
                muscleGroup: .legs,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Hip mobility exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/hip-flexor-stretch")
            ),
            Exercise(
                name: "Shoulder Dislocates",
                muscleGroup: .shoulders,
                equipment: .other,
                difficulty: .beginner,
                description: "Shoulder mobility exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/shoulder-dislocates")
            ),
            Exercise(
                name: "World's Greatest Stretch",
                muscleGroup: .legs,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Full-body mobility exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/worlds-greatest-stretch")
            ),
            
            // Cardio/HIIT Exercises
            Exercise(
                name: "Burpee",
                muscleGroup: .legs,
                equipment: .bodyweight,
                difficulty: .intermediate,
                description: "Full-body conditioning exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/burpee")
            ),
            Exercise(
                name: "Mountain Climber",
                muscleGroup: .core,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Dynamic core and cardio exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/mountain-climber")
            ),
            Exercise(
                name: "Squat Jump",
                muscleGroup: .legs,
                equipment: .bodyweight,
                difficulty: .intermediate,
                description: "Explosive leg exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/squat-jump")
            ),
            
            // Advanced Bodyweight Exercises
            Exercise(
                name: "Pistol Squat",
                muscleGroup: .legs,
                equipment: .bodyweight,
                difficulty: .advanced,
                description: "Single-leg squat variation",
                imageURL: URL(string: "https://api.exercisedb.io/image/pistol-squat")
            ),
            Exercise(
                name: "Handstand Push-up",
                muscleGroup: .shoulders,
                equipment: .bodyweight,
                difficulty: .advanced,
                description: "Advanced shoulder press variation",
                imageURL: URL(string: "https://api.exercisedb.io/image/handstand-pushup")
            ),
            Exercise(
                name: "L-Sit",
                muscleGroup: .core,
                equipment: .bodyweight,
                difficulty: .advanced,
                description: "Advanced core control exercise",
                imageURL: URL(string: "https://api.exercisedb.io/image/l-sit")
            ),
            
            // Additional Exercises for Workout Plans
            Exercise(
                name: "Ab Wheel Rollout",
                muscleGroup: .core,
                equipment: .other,
                difficulty: .advanced,
                description: "Core stability exercise using an ab wheel",
                imageURL: nil
            ),
            Exercise(
                name: "Agility Ladder Drills",
                muscleGroup: .fullBody,
                equipment: .other,
                difficulty: .intermediate,
                description: "Footwork drills performed on an agility ladder",
                imageURL: nil
            ),
            Exercise(
                name: "Bent Over Row",
                muscleGroup: .back,
                equipment: .barbell,
                difficulty: .intermediate,
                description: "Compound back exercise focusing on upper back thickness",
                imageURL: nil
            ),
            Exercise(
                name: "Bird Dog",
                muscleGroup: .core,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Core stability drill alternating opposite arm and leg",
                imageURL: nil
            ),
            Exercise(
                name: "Bodyweight Squat",
                muscleGroup: .legs,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Fundamental squat performed with bodyweight only",
                imageURL: nil
            ),
            Exercise(
                name: "Box Jump",
                muscleGroup: .legs,
                equipment: .bodyweight,
                difficulty: .intermediate,
                description: "Plyometric jump onto a stable box",
                imageURL: nil
            ),
            Exercise(
                name: "Cable Woodchop",
                muscleGroup: .core,
                equipment: .cable,
                difficulty: .intermediate,
                description: "Rotational cable movement targeting the obliques",
                imageURL: nil
            ),
            Exercise(
                name: "Calf Raises",
                muscleGroup: .legs,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Calf strengthening movement performed standing",
                imageURL: nil
            ),
            Exercise(
                name: "Chair Squat",
                muscleGroup: .legs,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Assisted squat to a chair for stability",
                imageURL: nil
            ),
            Exercise(
                name: "Core Rotation",
                muscleGroup: .core,
                equipment: .cable,
                difficulty: .intermediate,
                description: "Rotational torso exercise using cables or bands",
                imageURL: nil
            ),
            Exercise(
                name: "Deadlift",
                muscleGroup: .legs,
                equipment: .barbell,
                difficulty: .advanced,
                description: "Heavy compound lift targeting the posterior chain",
                imageURL: nil
            ),
            Exercise(
                name: "Dumbbell Row",
                muscleGroup: .back,
                equipment: .dumbbells,
                difficulty: .intermediate,
                description: "Unilateral rowing movement with dumbbells",
                imageURL: nil
            ),
            Exercise(
                name: "Explosive Push-up",
                muscleGroup: .chest,
                equipment: .bodyweight,
                difficulty: .advanced,
                description: "Plyometric push-up variation for power development",
                imageURL: nil
            ),
            Exercise(
                name: "Face Pull",
                muscleGroup: .shoulders,
                equipment: .cable,
                difficulty: .intermediate,
                description: "Rear deltoid and upper back isolation using cables",
                imageURL: nil
            ),
            Exercise(
                name: "Foam Rolling",
                muscleGroup: .fullBody,
                equipment: .other,
                difficulty: .beginner,
                description: "Self-myofascial release using a foam roller",
                imageURL: nil
            ),
            Exercise(
                name: "Glute Bridge",
                muscleGroup: .legs,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Hip extension exercise targeting the glutes",
                imageURL: nil
            ),
            Exercise(
                name: "Hanging Leg Raise",
                muscleGroup: .core,
                equipment: .bodyweight,
                difficulty: .advanced,
                description: "Hanging core movement lifting the legs toward the torso",
                imageURL: nil
            ),
            Exercise(
                name: "Hip Hinge",
                muscleGroup: .legs,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Fundamental hip hinging pattern drill",
                imageURL: nil
            ),
            Exercise(
                name: "Jump Rope",
                muscleGroup: .fullBody,
                equipment: .other,
                difficulty: .beginner,
                description: "Cardio exercise performed with a jump rope",
                imageURL: nil
            ),
            Exercise(
                name: "Kettlebell Swing",
                muscleGroup: .fullBody,
                equipment: .kettlebell,
                difficulty: .intermediate,
                description: "Explosive hip hinge with a kettlebell",
                imageURL: nil
            ),
            Exercise(
                name: "Lat Pulldown",
                muscleGroup: .back,
                equipment: .machine,
                difficulty: .intermediate,
                description: "Latissimus dorsi isolation using a pulldown machine",
                imageURL: nil
            ),
            Exercise(
                name: "Lateral Bound",
                muscleGroup: .legs,
                equipment: .bodyweight,
                difficulty: .intermediate,
                description: "Side-to-side jumping drill for power and stability",
                imageURL: nil
            ),
            Exercise(
                name: "Lateral Raise",
                muscleGroup: .shoulders,
                equipment: .dumbbells,
                difficulty: .beginner,
                description: "Isolation movement targeting the middle deltoids",
                imageURL: nil
            ),
            Exercise(
                name: "Leg Extension",
                muscleGroup: .legs,
                equipment: .machine,
                difficulty: .beginner,
                description: "Quadriceps isolation exercise on a machine",
                imageURL: nil
            ),
            Exercise(
                name: "Leg Press",
                muscleGroup: .legs,
                equipment: .machine,
                difficulty: .intermediate,
                description: "Lower body compound movement on a press machine",
                imageURL: nil
            ),
            Exercise(
                name: "Medicine Ball Chest Throw",
                muscleGroup: .chest,
                equipment: .other,
                difficulty: .intermediate,
                description: "Power exercise throwing a medicine ball from the chest",
                imageURL: nil
            ),
            Exercise(
                name: "Medicine Ball Slam",
                muscleGroup: .fullBody,
                equipment: .other,
                difficulty: .intermediate,
                description: "Full-body power movement slamming a medicine ball",
                imageURL: nil
            ),
            Exercise(
                name: "Plank",
                muscleGroup: .core,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Isometric core stability hold",
                imageURL: nil
            ),
            Exercise(
                name: "Push-up",
                muscleGroup: .chest,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Classic bodyweight pressing exercise",
                imageURL: nil
            ),
            Exercise(
                name: "Romanian Deadlift",
                muscleGroup: .legs,
                equipment: .barbell,
                difficulty: .intermediate,
                description: "Hip hinge focusing on hamstrings and glutes",
                imageURL: nil
            ),
            Exercise(
                name: "Rower",
                muscleGroup: .fullBody,
                equipment: .machine,
                difficulty: .beginner,
                description: "Cardio workout performed on a rowing machine",
                imageURL: nil
            ),
            Exercise(
                name: "Russian Twist",
                muscleGroup: .core,
                equipment: .bodyweight,
                difficulty: .intermediate,
                description: "Rotational core exercise performed seated",
                imageURL: nil
            ),
            Exercise(
                name: "Seated Row",
                muscleGroup: .back,
                equipment: .machine,
                difficulty: .intermediate,
                description: "Horizontal pulling movement on a cable or machine",
                imageURL: nil
            ),
            Exercise(
                name: "Single Leg Deadlift",
                muscleGroup: .legs,
                equipment: .dumbbells,
                difficulty: .advanced,
                description: "Unilateral hip hinge improving balance and strength",
                imageURL: nil
            ),
            Exercise(
                name: "Standing Balance",
                muscleGroup: .fullBody,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Balance drill performed on one leg",
                imageURL: nil
            ),
            Exercise(
                name: "Tricep Extension",
                muscleGroup: .arms,
                equipment: .cable,
                difficulty: .intermediate,
                description: "Isolation movement targeting the triceps",
                imageURL: nil
            ),
            Exercise(
                name: "Wall Push-up",
                muscleGroup: .chest,
                equipment: .bodyweight,
                difficulty: .beginner,
                description: "Beginner-friendly push-up performed against a wall",
                imageURL: nil
            )
        ]
        
        // Add existing exercises here...
    }
    
    // MARK: - Calendar Integration
    
    func requestCalendarAccess() async throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .authorized:
            return
        case .notDetermined:
            do {
                if #available(iOS 17.0, *) {
                    try await eventStore.requestFullAccessToEvents()
                } else {
                    let granted = try await eventStore.requestAccess(to: .event)
                    guard granted else {
                        throw CalendarError.accessDenied
                    }
                }
            } catch {
                throw CalendarError.accessDenied
            }
        default:
            throw CalendarError.accessDenied
        }
    }
    
    private func loadCalendarEvents() async {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .year, value: 1, to: startDate)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )
        
        await MainActor.run {
            self.calendarEvents = self.eventStore.events(matching: predicate)
        }
    }
    
    func addWorkoutToCalendar(_ workout: Workout) async throws {
        guard let startTime = workout.startedAt,
              let endTime = workout.endedAt else {
            throw CalendarError.accessDenied
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = "Workout: \(workout.name)"
        event.startDate = startTime
        event.endDate = endTime
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        if let location = workout.location {
            event.location = location.name
        }
        
        if let notes = workout.notes {
            event.notes = notes
        }
        
        try eventStore.save(event, span: .thisEvent)
        calendarEvents.append(event)
    }
    
    func removeWorkoutFromCalendar(_ workout: Workout) {
        if let event = calendarEvents.first(where: { $0.title == "Workout: \(workout.name)" && $0.startDate == workout.startedAt }) {
            do {
                try eventStore.remove(event, span: .thisEvent)
                calendarEvents.removeAll { $0.eventIdentifier == event.eventIdentifier }
            } catch {
                print("Error removing event from calendar: \(error)")
            }
        }
    }
    
    func updateWorkoutInCalendar(_ workout: Workout) {
        removeWorkoutFromCalendar(workout)
        Task {
            do {
                try await addWorkoutToCalendar(workout)
            } catch {
                print("Error updating workout in calendar: \(error)")
            }
        }
    }
    
    // MARK: - Location Services
    
    private func requestLocationAccess() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getCurrentLocation() -> CLLocationCoordinate2D? {
        return locationManager.location?.coordinate
    }
    
    // MARK: - Workout Management
    
    func startNewWorkout(name: String, exercises: [PlannedExercise]) {
        let workoutId = UUID()
        let logs = exercises.enumerated().map { index, planned in
            WorkoutExercise(
                workoutId: workoutId,
                exercise: planned.exercise,
                order: index,
                targetSets: planned.targetSets,
                targetReps: planned.targetReps,
                targetWeight: nil,
                targetRest: planned.restDuration,
                notes: planned.notes,
                sets: []
            )
        }
        let workout = Workout(
            id: workoutId,
            name: name,
            startedAt: Date(),
            exerciseLogs: logs
        )
        activeWorkout = workout
    }
    
    func startNewWorkout(name: String, plan: WorkoutPlan?) {
        if let plan = plan {
            startNewWorkout(name: name, exercises: plan.exercises)
        } else {
            startNewWorkout(name: name, exercises: [])
        }
    }
    
    func endWorkout(_ workout: Workout) {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            var updatedWorkout = workout
            if updatedWorkout.endedAt == nil {
                updatedWorkout.endedAt = Date()
            }
            if updatedWorkout.startedAt == nil {
                updatedWorkout.startedAt = updatedWorkout.endedAt
            }
            workouts[index] = updatedWorkout
            Task {
                do {
                    try await addWorkoutToCalendar(updatedWorkout)
                } catch {
                    print("Error adding workout to calendar: \(error)")
                }
            }
        } else {
            var newWorkout = workout
            if newWorkout.startedAt == nil {
                newWorkout.startedAt = Date()
            }
            if newWorkout.endedAt == nil {
                newWorkout.endedAt = newWorkout.startedAt
            }
            workouts.append(newWorkout)
            Task {
                do {
                    try await addWorkoutToCalendar(newWorkout)
                } catch {
                    print("Error adding workout to calendar: \(error)")
                }
            }
        }
        activeWorkout = nil
        saveData()
    }
    
    func addExerciseToWorkout(_ exercise: PlannedExercise) {
        guard var workout = activeWorkout else { return }
        let order = workout.exerciseLogs.count
        let log = WorkoutExercise(
            workoutId: workout.id,
            exercise: exercise.exercise,
            order: order,
            targetSets: exercise.targetSets,
            targetReps: exercise.targetReps,
            targetWeight: nil,
            targetRest: exercise.restDuration,
            notes: exercise.notes,
            sets: []
        )
        workout.exerciseLogs.append(log)
        activeWorkout = workout
    }
    
    func logPastWorkout(name: String, date: Date, location: Location?, exercises: [WorkoutExercise], notes: String?) {
        let workoutId = UUID()
        let logs = exercises.enumerated().map { index, exercise in
            let normalisedSets = exercise.sets.enumerated().map { setIndex, set in
                ExerciseSet(
                    id: set.id,
                    setIndex: setIndex,
                    reps: set.reps,
                    weight: set.weight,
                    rpe: set.rpe,
                    completedAt: set.completedAt,
                    legacyCompleted: set.legacyCompleted
                )
            }
            return WorkoutExercise(
                id: exercise.id,
                workoutId: workoutId,
                exercise: exercise.exercise,
                order: index,
                targetSets: exercise.targetSets,
                targetReps: exercise.targetReps,
                targetWeight: exercise.targetWeight,
                targetRest: exercise.targetRest,
                notes: exercise.notes,
                sets: normalisedSets
            )
        }
        
        let workout = Workout(
            id: workoutId,
            name: name,
            startedAt: date,
            endedAt: date,
            location: location,
            notes: notes,
            exerciseLogs: logs
        )
        workouts.append(workout)
        saveData()
        
        Task {
            do {
                try await addWorkoutToCalendar(workout)
            } catch {
                print("Error adding workout to calendar: \(error)")
            }
        }
    }
    
    // MARK: - Exercise History
    
    func getExerciseHistory(_ exercise: Exercise) -> [String]? {
        let history = workouts.flatMap { workout in
            workout.exerciseLogs.filter { $0.exerciseId == exercise.id }
        }
        
        guard !history.isEmpty else { return nil }
        
        let summaries = history.compactMap { log -> String? in
            guard let sets = log.targetSets, let reps = log.targetReps else { return nil }
            return "\(sets) sets × \(reps) reps"
        }
        
        return summaries.isEmpty ? nil : summaries
    }
    
    // MARK: - Workout Plan Management
    
    func createWorkoutPlan(name: String, description: String, difficulty: Difficulty) {
        let plan = WorkoutPlan(
            name: name,
            description: description,
            duration: "60 minutes", // Default to 1 hour
            difficulty: difficulty,
            exercises: []
        )
        workoutPlans.append(plan)
        saveData()
    }
    
    // MARK: - Workout Plans
    
    private func loadDefaultWorkoutPlans() {
        workoutPlans = [
            createFullBodyPlan(),
            createUpperBodyPlan(),
            createLowerBodyPlan(),
            createPushPullLegsPlan(),
            createCardioEndurancePlan(),
            createHIITWorkoutPlan(),
            createStrengthPlan(),
            createMobilityPlan(),
            createBodyweightPlan(),
            createCoreIntensivePlan(),
            
            // Sports-specific plans
            createBasketballPlan(),
            createRunningPlan(),
            createSwimmingPlan(),
            createMartialArtsPlan(),
            
            // Goal-specific plans
            createWeightLossPlan(),
            createMuscleGainPlan(),
            createPostRehabPlan(),
            createSeniorFitnessPlan()
        ]
    }
    
    private func createFullBodyPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Full Body Workout",
            description: "A comprehensive full-body workout targeting all major muscle groups",
            duration: "60 minutes",
            difficulty: .intermediate,
            exercises: [
                PlannedExercise(exercise: findExercise("Squat")!, targetSets: 4, targetReps: 8),
                PlannedExercise(exercise: findExercise("Bench Press")!, targetSets: 4, targetReps: 8),
                PlannedExercise(exercise: findExercise("Bent Over Row")!, targetSets: 4, targetReps: 8),
                PlannedExercise(exercise: findExercise("Overhead Press")!, targetSets: 3, targetReps: 10),
                PlannedExercise(exercise: findExercise("Romanian Deadlift")!, targetSets: 3, targetReps: 10)
            ]
        )
    }
    
    private func createUpperBodyPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Upper Body Focus",
            description: "Intensive upper body workout targeting chest, back, shoulders, and arms",
            duration: "60 minutes",
            difficulty: .intermediate,
            exercises: [
                PlannedExercise(exercise: findExercise("Bench Press")!, targetSets: 4, targetReps: 8),
                PlannedExercise(exercise: findExercise("Pull-up")!, targetSets: 4, targetReps: 8),
                PlannedExercise(exercise: findExercise("Overhead Press")!, targetSets: 3, targetReps: 10),
                PlannedExercise(exercise: findExercise("Dumbbell Row")!, targetSets: 3, targetReps: 10),
                PlannedExercise(exercise: findExercise("Tricep Extension")!, targetSets: 3, targetReps: 12)
            ]
        )
    }
    
    private func createLowerBodyPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Lower Body Power",
            description: "Focus on building strength and muscle in the legs",
            duration: "60 minutes",
            difficulty: .intermediate,
            exercises: [
                PlannedExercise(exercise: findExercise("Squat")!, targetSets: 4, targetReps: 8),
                PlannedExercise(exercise: findExercise("Romanian Deadlift")!, targetSets: 4, targetReps: 8),
                PlannedExercise(exercise: findExercise("Leg Press")!, targetSets: 3, targetReps: 12),
                PlannedExercise(exercise: findExercise("Calf Raises")!, targetSets: 4, targetReps: 15),
                PlannedExercise(exercise: findExercise("Leg Extension")!, targetSets: 3, targetReps: 12)
            ]
        )
    }
    
    private func createPushPullLegsPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Push Day",
            description: "Focus on pushing movements for chest, shoulders, and triceps",
            duration: "60 minutes",
            difficulty: .advanced,
            exercises: [
                PlannedExercise(exercise: findExercise("Bench Press")!, targetSets: 4, targetReps: 8),
                PlannedExercise(exercise: findExercise("Overhead Press")!, targetSets: 4, targetReps: 8),
                PlannedExercise(exercise: findExercise("Incline Dumbbell Press")!, targetSets: 3, targetReps: 10),
                PlannedExercise(exercise: findExercise("Lateral Raise")!, targetSets: 3, targetReps: 12),
                PlannedExercise(exercise: findExercise("Tricep Extension")!, targetSets: 3, targetReps: 12)
            ]
        )
    }
    
    private func createCardioEndurancePlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Cardio & Endurance",
            description: "High-rep, low-weight workout focusing on endurance and cardiovascular health",
            duration: "45 minutes",
            difficulty: .beginner,
            exercises: [
                PlannedExercise(exercise: findExercise("Bodyweight Squat")!, targetSets: 3, targetReps: 20),
                PlannedExercise(exercise: findExercise("Push-up")!, targetSets: 3, targetReps: 15),
                PlannedExercise(exercise: findExercise("Mountain Climber")!, targetSets: 3, targetReps: 30),
                PlannedExercise(exercise: findExercise("Burpee")!, targetSets: 3, targetReps: 10),
                PlannedExercise(exercise: findExercise("Plank")!, targetSets: 3, targetReps: 60)
            ]
        )
    }
    
    private func createHIITWorkoutPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "HIIT Circuit",
            description: "High-intensity interval training to burn fat and improve conditioning",
            duration: "30 minutes",
            difficulty: .advanced,
            exercises: [
                PlannedExercise(exercise: findExercise("Burpee")!, targetSets: 4, targetReps: 12),
                PlannedExercise(exercise: findExercise("Mountain Climber")!, targetSets: 4, targetReps: 30),
                PlannedExercise(exercise: findExercise("Push-up")!, targetSets: 4, targetReps: 15),
                PlannedExercise(exercise: findExercise("Squat Jump")!, targetSets: 4, targetReps: 15),
                PlannedExercise(exercise: findExercise("Russian Twist")!, targetSets: 4, targetReps: 20)
            ]
        )
    }
    
    private func createStrengthPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Pure Strength",
            description: "Heavy compound movements for maximum strength gains",
            duration: "75 minutes",
            difficulty: .advanced,
            exercises: [
                PlannedExercise(exercise: findExercise("Deadlift")!, targetSets: 5, targetReps: 5),
                PlannedExercise(exercise: findExercise("Bench Press")!, targetSets: 5, targetReps: 5),
                PlannedExercise(exercise: findExercise("Squat")!, targetSets: 5, targetReps: 5),
                PlannedExercise(exercise: findExercise("Overhead Press")!, targetSets: 5, targetReps: 5),
                PlannedExercise(exercise: findExercise("Bent Over Row")!, targetSets: 5, targetReps: 5)
            ]
        )
    }
    
    private func createMobilityPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Mobility & Recovery",
            description: "Focus on flexibility, mobility, and recovery",
            duration: "45 minutes",
            difficulty: .beginner,
            exercises: [
                PlannedExercise(exercise: findExercise("Cat-Cow Stretch")!, targetSets: 3, targetReps: 10),
                PlannedExercise(exercise: findExercise("Hip Flexor Stretch")!, targetSets: 3, targetReps: 30),
                PlannedExercise(exercise: findExercise("Shoulder Dislocates")!, targetSets: 3, targetReps: 10),
                PlannedExercise(exercise: findExercise("World's Greatest Stretch")!, targetSets: 3, targetReps: 5),
                PlannedExercise(exercise: findExercise("Foam Rolling")!, targetSets: 3, targetReps: 60)
            ]
        )
    }
    
    private func createBodyweightPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Bodyweight Master",
            description: "Advanced calisthenics workout for strength and control",
            duration: "60 minutes",
            difficulty: .intermediate,
            exercises: [
                PlannedExercise(exercise: findExercise("Pull-up")!, targetSets: 4, targetReps: 8),
                PlannedExercise(exercise: findExercise("Push-up")!, targetSets: 4, targetReps: 15),
                PlannedExercise(exercise: findExercise("Pistol Squat")!, targetSets: 3, targetReps: 8),
                PlannedExercise(exercise: findExercise("Handstand Push-up")!, targetSets: 3, targetReps: 5),
                PlannedExercise(exercise: findExercise("L-Sit")!, targetSets: 4, targetReps: 20)
            ]
        )
    }
    
    private func createCoreIntensivePlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Core Intensive",
            description: "Comprehensive core workout targeting all aspects of the midsection",
            duration: "45 minutes",
            difficulty: .intermediate,
            exercises: [
                PlannedExercise(exercise: findExercise("Plank")!, targetSets: 4, targetReps: 45),
                PlannedExercise(exercise: findExercise("Hanging Leg Raise")!, targetSets: 4, targetReps: 12),
                PlannedExercise(exercise: findExercise("Ab Wheel Rollout")!, targetSets: 3, targetReps: 10),
                PlannedExercise(exercise: findExercise("Cable Woodchop")!, targetSets: 3, targetReps: 15),
                PlannedExercise(exercise: findExercise("Dragon Flag")!, targetSets: 3, targetReps: 8)
            ]
        )
    }
    
    private func createBasketballPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Basketball Performance",
            description: "Enhance explosiveness, agility, and endurance for basketball",
            duration: "60 minutes",
            difficulty: .advanced,
            exercises: [
                PlannedExercise(exercise: findExercise("Box Jump")!, targetSets: 4, targetReps: 8),
                PlannedExercise(exercise: findExercise("Lateral Bound")!, targetSets: 3, targetReps: 8),
                PlannedExercise(exercise: findExercise("Medicine Ball Chest Throw")!, targetSets: 3, targetReps: 10),
                PlannedExercise(exercise: findExercise("Squat Jump")!, targetSets: 4, targetReps: 10),
                PlannedExercise(exercise: findExercise("Agility Ladder Drills")!, targetSets: 3, targetReps: 30)
            ]
        )
    }
    
    private func createRunningPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Runner's Strength",
            description: "Build strength and prevent injuries for runners",
            duration: "45 minutes",
            difficulty: .intermediate,
            exercises: [
                PlannedExercise(exercise: findExercise("Single Leg Deadlift")!, targetSets: 3, targetReps: 12),
                PlannedExercise(exercise: findExercise("Calf Raises")!, targetSets: 4, targetReps: 20),
                PlannedExercise(exercise: findExercise("Hip Thrust")!, targetSets: 3, targetReps: 15),
                PlannedExercise(exercise: findExercise("Bulgarian Split Squat")!, targetSets: 3, targetReps: 12),
                PlannedExercise(exercise: findExercise("Plank")!, targetSets: 3, targetReps: 45)
            ]
        )
    }
    
    private func createSwimmingPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Swimmer's Power",
            description: "Develop strength and power for swimming performance",
            duration: "60 minutes",
            difficulty: .advanced,
            exercises: [
                PlannedExercise(exercise: findExercise("Pull-up")!, targetSets: 4, targetReps: 8),
                PlannedExercise(exercise: findExercise("Lat Pulldown")!, targetSets: 4, targetReps: 12),
                PlannedExercise(exercise: findExercise("Dumbbell Row")!, targetSets: 3, targetReps: 12),
                PlannedExercise(exercise: findExercise("Face Pull")!, targetSets: 3, targetReps: 15),
                PlannedExercise(exercise: findExercise("Core Rotation")!, targetSets: 3, targetReps: 15)
            ]
        )
    }
    
    private func createMartialArtsPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Martial Arts Conditioning",
            description: "Build functional strength and power for martial arts",
            duration: "60 minutes",
            difficulty: .advanced,
            exercises: [
                PlannedExercise(exercise: findExercise("Turkish Get-up")!, targetSets: 3, targetReps: 5),
                PlannedExercise(exercise: findExercise("Medicine Ball Slam")!, targetSets: 4, targetReps: 10),
                PlannedExercise(exercise: findExercise("Explosive Push-up")!, targetSets: 3, targetReps: 8),
                PlannedExercise(exercise: findExercise("Box Jump")!, targetSets: 4, targetReps: 6),
                PlannedExercise(exercise: findExercise("Core Rotation")!, targetSets: 3, targetReps: 15)
            ]
        )
    }
    
    private func createWeightLossPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Fat Loss Focus",
            description: "High-intensity circuit training for maximum calorie burn",
            duration: "45 minutes",
            difficulty: .intermediate,
            exercises: [
                PlannedExercise(exercise: findExercise("Burpee")!, targetSets: 4, targetReps: 15),
                PlannedExercise(exercise: findExercise("Mountain Climber")!, targetSets: 4, targetReps: 30),
                PlannedExercise(exercise: findExercise("Kettlebell Swing")!, targetSets: 3, targetReps: 20),
                PlannedExercise(exercise: findExercise("Jump Rope")!, targetSets: 4, targetReps: 50),
                PlannedExercise(exercise: findExercise("Rower")!, targetSets: 3, targetReps: 250)
            ]
        )
    }
    
    private func createMuscleGainPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Hypertrophy Focus",
            description: "Optimized for muscle growth with progressive overload",
            duration: "75 minutes",
            difficulty: .intermediate,
            exercises: [
                PlannedExercise(exercise: findExercise("Bench Press")!, targetSets: 4, targetReps: 10),
                PlannedExercise(exercise: findExercise("Squat")!, targetSets: 4, targetReps: 10),
                PlannedExercise(exercise: findExercise("Bent Over Row")!, targetSets: 4, targetReps: 10),
                PlannedExercise(exercise: findExercise("Overhead Press")!, targetSets: 4, targetReps: 10),
                PlannedExercise(exercise: findExercise("Romanian Deadlift")!, targetSets: 4, targetReps: 10)
            ]
        )
    }
    
    private func createPostRehabPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Post-Rehabilitation",
            description: "Gentle progression back to activity after injury",
            duration: "45 minutes",
            difficulty: .beginner,
            exercises: [
                PlannedExercise(exercise: findExercise("Wall Push-up")!, targetSets: 3, targetReps: 10),
                PlannedExercise(exercise: findExercise("Bodyweight Squat")!, targetSets: 3, targetReps: 10),
                PlannedExercise(exercise: findExercise("Bird Dog")!, targetSets: 3, targetReps: 10),
                PlannedExercise(exercise: findExercise("Glute Bridge")!, targetSets: 3, targetReps: 15),
                PlannedExercise(exercise: findExercise("Cat-Cow Stretch")!, targetSets: 3, targetReps: 10)
            ]
        )
    }
    
    private func createSeniorFitnessPlan() -> WorkoutPlan {
        WorkoutPlan(
            name: "Senior Strength & Balance",
            description: "Safe and effective exercises for older adults",
            duration: "45 minutes",
            difficulty: .beginner,
            exercises: [
                PlannedExercise(exercise: findExercise("Chair Squat")!, targetSets: 3, targetReps: 10),
                PlannedExercise(exercise: findExercise("Wall Push-up")!, targetSets: 3, targetReps: 8),
                PlannedExercise(exercise: findExercise("Seated Row")!, targetSets: 3, targetReps: 12),
                PlannedExercise(exercise: findExercise("Standing Balance")!, targetSets: 3, targetReps: 30),
                PlannedExercise(exercise: findExercise("Hip Hinge")!, targetSets: 3, targetReps: 10)
            ]
        )
    }
    
    private func defaultSets(_ count: Int, reps: Int) -> [ExerciseSet] {
        (0..<count).map { _ in ExerciseSet(reps: reps) }
    }
    
    private func findExercise(_ name: String) -> Exercise? {
        exercises.first { $0.name == name }
    }
    
    // MARK: - Location Management
    
    func addLocation(_ location: Location) {
        locations.append(location)
        saveData()
    }
    
    func getLocations() -> [Location] {
        return locations
    }
    
    func deleteLocation(_ location: Location) {
        locations.removeAll { $0.id == location.id }
        saveData()
    }
    
    // MARK: - Data Persistence
    
    private func saveData() {
        do {
            let workoutsData = try WorkoutPersistence.encodeWorkouts(workouts)
            let locationsData = try JSONEncoder().encode(locations)
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let workoutsURL = documentsDirectory.appendingPathComponent("workouts.json")
            let locationsURL = documentsDirectory.appendingPathComponent("locations.json")
            
            try workoutsData.write(to: workoutsURL)
            try locationsData.write(to: locationsURL)
        } catch {
            print("Error saving data: \(error)")
        }
    }
} 
