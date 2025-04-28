import Vapor

struct AchievementResponse: Content {
    var achievements: [AchievementWithProgress]
}
