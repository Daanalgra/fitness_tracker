import SwiftUI

struct WorkoutPlansView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showingPlanDetails = false
    @State private var selectedPlan: WorkoutPlan?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Plan Section
                    if let plan = viewModel.selectedPlan {
                        CurrentPlanCard(plan: plan)
                    } else {
                        NoPlanCard()
                    }
                    
                    // Suggested Plans Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Suggested Plans")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(suggestedPlans) { plan in
                                    SuggestedPlanCard(plan: plan) {
                                        selectedPlan = plan
                                        showingPlanDetails = true
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Plans")
            .sheet(isPresented: $showingPlanDetails) {
                if let plan = selectedPlan {
                    PlanDetailsSheet(plan: plan)
                }
            }
        }
    }
    
    private var suggestedPlans: [WorkoutPlan] {
        [
            WorkoutPlan(
                name: "Beginner Strength",
                description: "Perfect for those new to strength training. Focus on proper form and building a foundation.",
                duration: "8 weeks",
                difficulty: .beginner,
                exercises: [
                    PlannedExercise(
                        exercise: Exercise(
                            name: "Squats",
                            muscleGroup: .legs,
                            equipment: .bodyweight,
                            difficulty: .beginner,
                            description: "Basic bodyweight squats"
                        ),
                        targetSets: 3,
                        targetReps: 12,
                        restDuration: 60
                    ),
                    PlannedExercise(
                        exercise: Exercise(
                            name: "Push-ups",
                            muscleGroup: .chest,
                            equipment: .bodyweight,
                            difficulty: .beginner,
                            description: "Standard push-ups"
                        ),
                        targetSets: 3,
                        targetReps: 10,
                        restDuration: 60
                    ),
                    PlannedExercise(
                        exercise: Exercise(
                            name: "Plank",
                            muscleGroup: .core,
                            equipment: .bodyweight,
                            difficulty: .beginner,
                            description: "Hold a plank position"
                        ),
                        targetSets: 3,
                        targetReps: 30,
                        restDuration: 60
                    )
                ]
            ),
            WorkoutPlan(
                name: "Intermediate Split",
                description: "A balanced split routine targeting different muscle groups on different days.",
                duration: "12 weeks",
                difficulty: .intermediate,
                exercises: [
                    PlannedExercise(
                        exercise: Exercise(
                            name: "Barbell Squats",
                            muscleGroup: .legs,
                            equipment: .barbell,
                            difficulty: .intermediate,
                            description: "Heavy compound movement"
                        ),
                        targetSets: 4,
                        targetReps: 8,
                        restDuration: 90
                    ),
                    PlannedExercise(
                        exercise: Exercise(
                            name: "Bench Press",
                            muscleGroup: .chest,
                            equipment: .barbell,
                            difficulty: .intermediate,
                            description: "Classic chest press"
                        ),
                        targetSets: 4,
                        targetReps: 8,
                        restDuration: 90
                    ),
                    PlannedExercise(
                        exercise: Exercise(
                            name: "Pull-ups",
                            muscleGroup: .back,
                            equipment: .bodyweight,
                            difficulty: .intermediate,
                            description: "Upper body pulling movement"
                        ),
                        targetSets: 4,
                        targetReps: 8,
                        restDuration: 90
                    )
                ]
            ),
            WorkoutPlan(
                name: "Advanced Powerlifting",
                description: "Focus on the three main lifts: squat, bench press, and deadlift.",
                duration: "16 weeks",
                difficulty: .advanced,
                exercises: [
                    PlannedExercise(
                        exercise: Exercise(
                            name: "Deadlift",
                            muscleGroup: .back,
                            equipment: .barbell,
                            difficulty: .advanced,
                            description: "Heavy compound movement"
                        ),
                        targetSets: 5,
                        targetReps: 5,
                        restDuration: 120
                    ),
                    PlannedExercise(
                        exercise: Exercise(
                            name: "Squats",
                            muscleGroup: .legs,
                            equipment: .barbell,
                            difficulty: .advanced,
                            description: "Heavy compound movement"
                        ),
                        targetSets: 5,
                        targetReps: 5,
                        restDuration: 120
                    ),
                    PlannedExercise(
                        exercise: Exercise(
                            name: "Bench Press",
                            muscleGroup: .chest,
                            equipment: .barbell,
                            difficulty: .advanced,
                            description: "Heavy compound movement"
                        ),
                        targetSets: 5,
                        targetReps: 5,
                        restDuration: 120
                    )
                ]
            )
        ]
    }
}

struct CurrentPlanCard: View {
    let plan: WorkoutPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Plan")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(plan.name)
                .font(.title)
                .bold()
            
            Text(plan.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Label(plan.duration, systemImage: "clock")
                Spacer()
                Label(plan.difficulty.rawValue, systemImage: "chart.bar.fill")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct NoPlanCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("No Plan Selected")
                .font(.title2)
                .bold()
            
            Text("Choose a plan to get started with your fitness journey")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct SuggestedPlanCard: View {
    let plan: WorkoutPlan
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Text(plan.name)
                    .font(.headline)
                
                Text(plan.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label(plan.duration, systemImage: "clock")
                    Spacer()
                    Label(plan.difficulty.rawValue, systemImage: "chart.bar.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 280)
            .background(Color(.systemGray6))
            .cornerRadius(15)
        }
    }
}

struct PlanDetailsSheet: View {
    let plan: WorkoutPlan
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text(plan.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label(plan.duration, systemImage: "clock")
                        Spacer()
                        Label(plan.difficulty.rawValue, systemImage: "chart.bar.fill")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                Section("Exercises") {
                    ForEach(plan.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.exercise.name)
                                .font(.headline)
                            
                            Text(exercise.exercise.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("\(exercise.targetSets) sets")
                                Text("•")
                                Text("\(exercise.targetReps) reps")
                                if exercise.restDuration > 0 {
                                    Text("•")
                                    Text("\(exercise.restDuration)s rest")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(plan.name)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Select Plan") {
                    viewModel.selectedPlan = plan
                    dismiss()
                }
            )
        }
    }
} 