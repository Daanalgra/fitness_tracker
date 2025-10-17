import Foundation

struct Exercise: Identifiable, Codable {
    let id: UUID
    let name: String
    let muscleGroup: MuscleGroup
    let equipment: Equipment
    let difficulty: Difficulty
    let description: String
    let imageURL: URL?
    let variations: [String]?
    
    init(id: UUID = UUID(), name: String, muscleGroup: MuscleGroup, equipment: Equipment, difficulty: Difficulty, description: String, imageURL: URL? = nil, variations: [String]? = nil) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.difficulty = difficulty
        self.description = description
        self.imageURL = imageURL
        self.variations = variations
    }
}

enum MuscleGroup: String, Codable, CaseIterable {
    case chest
    case back
    case legs
    case shoulders
    case arms
    case core
    case fullBody
}

enum Equipment: String, Codable, CaseIterable {
    case none
    case dumbbells
    case barbell
    case kettlebell
    case resistanceBands
    case machine
    case bodyweight
    case cable
    case other
}

enum Difficulty: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced
} 