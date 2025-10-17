import SwiftUI

struct WorkoutInProgressView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var now = Date()
    @State private var showEndConfirm = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let session = viewModel.session {
                    header(session)
                    Divider()
                    content(session)
                    Divider()
                    footer(session)
                } else {
                    Text("No active workout")
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: prev) { Image(systemName: "chevron.left") }
                        .disabled((viewModel.session?.currentExerciseIndex ?? 0) == 0)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showEndConfirm = true }) { Text("End") }
                }
            }
            .alert("End workout?", isPresented: $showEndConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("End", role: .destructive) { endWorkout() }
            } message: {
                Text("Your progress will be saved to history.")
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
                now = date
            }
            .overlay(alignment: .bottom) {
                if let timer = viewModel.session?.restTimer {
                    restOverlay(timer: timer)
                }
            }
        }
    }
    
    private func header(_ session: ActiveWorkoutSession) -> some View {
        HStack {
            Text(session.workout.name).font(.headline)
            Spacer()
            Text("\(session.currentExerciseIndex + 1)/\(max(1, session.workout.exerciseLogs.count))")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func content(_ session: ActiveWorkoutSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let ex = session.currentExercise {
                    Text(ex.exercise.name).font(.title2).bold().padding(.horizontal)
                    ForEach(Array(ex.sets.enumerated()), id: \.offset) { idx, set in
                        HStack {
                            Text("Set \(idx + 1)").frame(width: 60, alignment: .leading)
                            Stepper("Reps: \(set.reps)", value: bindingForReps(session: session, index: idx))
                            Spacer()
                            if let w = set.weight {
                                Text("\(Int(w)) kg").foregroundColor(.secondary)
                            }
                            Button {
                                viewModel.session?.completeSet(at: idx)
                            } label: {
                                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(set.completed ? .green : .secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                    Button {
                        viewModel.session?.addSet(reps: 10)
                    } label: {
                        Label("Add Set", systemImage: "plus.circle")
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func footer(_ session: ActiveWorkoutSession) -> some View {
        HStack {
            if let started = session.workout.startedAt {
                let elapsed = now.timeIntervalSince(started)
                Text("Elapsed: \(format(time: elapsed))")
            }
            Spacer()
            let total = session.workout.exerciseLogs.reduce(0) { $0 + $1.sets.filter { $0.completed }.count }
            Text("Sets done: \(total)")
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding()
    }
    
    private func restOverlay(timer: RestTimer) -> some View {
        VStack {
            Text("Rest")
                .font(.headline)
            Text("\(format(time: timer.remaining(now: now)))")
                .font(.largeTitle).monospacedDigit()
                .padding(.bottom, 8)
            HStack {
                Button("Dismiss") { viewModel.session?.cancelRestTimer() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding()
    }
    
    private func bindingForReps(session: ActiveWorkoutSession, index: Int) -> Binding<Int> {
        Binding(
            get: {
                session.currentExercise?.sets[index].reps ?? 0
            },
            set: { newValue in
                viewModel.session?.updateSet(at: index, reps: newValue, weight: session.currentExercise?.sets[index].weight, rpe: session.currentExercise?.sets[index].rpe)
            }
        )
    }
    
    private func format(time: TimeInterval) -> String {
        let t = Int(time)
        return String(format: "%02d:%02d", t/60, t%60)
    }
    
    private func endWorkout() {
        guard let finalized = viewModel.session?.finalize() else { return }
        viewModel.endWorkout(finalized)
        dismiss()
    }
    
    private func prev() { viewModel.session?.previousExercise() }
}

#Preview {
    WorkoutInProgressView().environmentObject(AppViewModel())
}

