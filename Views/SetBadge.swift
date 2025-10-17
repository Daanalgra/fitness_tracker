import SwiftUI

struct SetBadge: View {
    let set: ExerciseSet
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(set.reps) reps")
                .font(.caption)
                .bold()
            
            if let weight = set.weight {
                Text("\(Int(weight))kg")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    SetBadge(set: ExerciseSet(reps: 12, weight: 60))
}
