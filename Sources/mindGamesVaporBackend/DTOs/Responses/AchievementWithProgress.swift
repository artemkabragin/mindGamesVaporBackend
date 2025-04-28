import Vapor

struct AchievementWithProgress: Content {
    let id: UUID
    let title: String
    let description: String
    let type: AchievementType
    let gameType: GameType
    let isUnlocked: Bool
    let progress: Double
    let dateUnlocked: Date?
    
    init(
        achievement: Achievement,
        isUnlocked: Bool,
        progress: Double,
        dateUnlocked: Date?
    ) {
        self.id = achievement.id ?? UUID()
        self.title = achievement.title
        self.description = achievement.description
        self.type = achievement.type
        self.gameType = achievement.gameType
        self.isUnlocked = isUnlocked
        self.progress = progress
        self.dateUnlocked = dateUnlocked
    }
}
