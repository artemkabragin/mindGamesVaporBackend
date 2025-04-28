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
