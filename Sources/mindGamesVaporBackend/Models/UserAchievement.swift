import Fluent
import Vapor

import Fluent
import Vapor

final class UserAchievement: Model, Content, @unchecked Sendable {
    static let schema = "user_achievements"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User

    @Parent(key: "achievement_id")
    var achievement: Achievement
    
    @Field(key: "is_unlocked")
    var isUnlocked: Bool
    
    @Field(key: "progress")
    var progress: Double
    
    @OptionalField(key: "date_unlocked")
    var dateUnlocked: Date?

    init() { }
    
    init(
        id: UUID? = nil,
        userID: UUID,
        achievementID: UUID,
        isUnlocked: Bool = false,
        progress: Double = 0.0,
        dateUnlocked: Date? = nil
    ) {
        self.id = id
        self.$user.id = userID
        self.$achievement.id = achievementID
        self.isUnlocked = isUnlocked
        self.progress = progress
        self.dateUnlocked = dateUnlocked
    }
}



import Fluent
import Vapor


final class Achievement: Model, Content, @unchecked Sendable {
    static let schema = "achievements"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "type")
    var type: AchievementType
    
    @Field(key: "game_type")
    var gameType: GameType

    init() { }
    
    init(
        id: UUID? = nil,
        title: String,
        description: String,
        type: AchievementType,
        gameType: GameType
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.gameType = gameType
    }
    
//    init(
//        id: UUID? = nil,
//        type: AchievementType,
//        gameType: GameType,
//        isUnlocked: Bool = false,
//        progress: Double = 0.0,
//        dateUnlocked: Date? = nil
//    ) {
//        self.id = id
//        self.title = type.getTitle(by: gameType)
//        self.description = type.getDescription(by: gameType)
//        self.type = type
//        self.gameType = gameType
//    }
}

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
