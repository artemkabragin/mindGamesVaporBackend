import Vapor
import Fluent

struct AchievementService {
    
    static func checkAchievements(for user: User, attempt: GameAttemptData, db: any Database) async throws -> [UserAchievement] {
        
        let userAchievements = try await UserAchievement.query(on: db)
            .filter(\.$user.$id == user.requireID())
            .with(\.$achievement)
            .all()
        
        async let a = try await checkOrCreateHighScore(
            for: user,
            attempt: attempt,
            userAchievements: userAchievements,
            db: db
        )
        
        async let b = try await checkOrCreateTotalPlays(
            for: user,
            attempt: attempt,
            userAchievements: userAchievements,
            db: db
        )
        
        async let c = try await checkOrCreateDailyStreak(
            for: user,
            attempt: attempt,
            userAchievements: userAchievements,
            db: db
        )
        
        let results: [UserAchievement?] = [try await a, try await b, try await c]
        return results.compactMap { $0 }
    }
    
    private static func checkOrCreateHighScore(
        for user: User,
        attempt: GameAttemptData,
        userAchievements: [UserAchievement],
        db: any Database
    ) async throws -> UserAchievement? {
        if let highScoreAchievement = userAchievements.first(where: { $0.achievement.type == .highScore && $0.achievement.gameType == attempt.gameType }) {
            // Если ачивка уже есть — обновляем её
            if attempt.attempt < (highScoreAchievement.progress == 0 ? Double.greatestFiniteMagnitude : highScoreAchievement.progress) {
                highScoreAchievement.progress = attempt.attempt
                highScoreAchievement.isUnlocked = true
                highScoreAchievement.dateUnlocked = Date()
                highScoreAchievement.dateChanged = Date()
                try await highScoreAchievement.save(on: db)
                return highScoreAchievement
            }
        } else {
            // Если нет — создаём новую ачивку для highScore
            if let achievement = try await findAchievement(type: .highScore, gameType: attempt.gameType, db: db) {
                let newUserAchievement = UserAchievement(
                    userID: try user.requireID(),
                    achievementID: try achievement.requireID(),
                    isUnlocked: true,
                    progress: attempt.attempt,
                    dateChanged: Date(),
                    dateUnlocked: Date()
                )
                try await newUserAchievement.save(on: db)
                return newUserAchievement
            }
        }
        
        return nil
    }
    
    private static func checkOrCreateTotalPlays(
        for user: User,
        attempt: GameAttemptData,
        userAchievements: [UserAchievement],
        db: any Database
    ) async throws -> UserAchievement? {
        
        if let totalPlaysAchievement = userAchievements.first(where: { $0.achievement.type == .totalPlays && $0.achievement.gameType == attempt.gameType }) {
            totalPlaysAchievement.dateChanged = Date()
            totalPlaysAchievement.progress += 0.1
            if totalPlaysAchievement.progress > 0.9 && !totalPlaysAchievement.isUnlocked {
                totalPlaysAchievement.isUnlocked = true
                totalPlaysAchievement.dateUnlocked = Date()
            }
            try await totalPlaysAchievement.save(on: db)
            return totalPlaysAchievement
        } else {
            if let achievement = try await findAchievement(type: .totalPlays, gameType: attempt.gameType, db: db) {
                let newUserAchievement = UserAchievement(
                    userID: try user.requireID(),
                    achievementID: try achievement.requireID(),
                    isUnlocked: false,
                    progress: 0.1,
                    dateChanged: Date(),
                    dateUnlocked: nil
                )
                try await newUserAchievement.save(on: db)
                return newUserAchievement
            }
        }
        return nil
    }
    
    private static func checkOrCreateDailyStreak(
        for user: User,
        attempt: GameAttemptData,
        userAchievements: [UserAchievement],
        db: any Database
    ) async throws -> UserAchievement? {
        
        if let totalPlaysAchievement = userAchievements.first(where: { $0.achievement.type == .dailyStreak && $0.achievement.gameType == attempt.gameType }) {
            let lastDate = totalPlaysAchievement.dateChanged
            
            let calendar = Calendar.current
            if calendar.isDateInYesterday(lastDate) {
                totalPlaysAchievement.progress += 0.1
            } else {
                totalPlaysAchievement.progress = 0.1
            }
                        
            totalPlaysAchievement.dateChanged = Date()
            if totalPlaysAchievement.progress > 0.9 && !totalPlaysAchievement.isUnlocked {
                totalPlaysAchievement.isUnlocked = true
                totalPlaysAchievement.dateUnlocked = Date()
            }
            try await totalPlaysAchievement.save(on: db)
            return totalPlaysAchievement
        } else {
            if let achievement = try await findAchievement(type: .dailyStreak, gameType: attempt.gameType, db: db) {
                let newUserAchievement = UserAchievement(
                    userID: try user.requireID(),
                    achievementID: try achievement.requireID(),
                    isUnlocked: false,
                    progress: 0.1,
                    dateChanged: Date(),
                    dateUnlocked: nil
                )
                try await newUserAchievement.save(on: db)
                return newUserAchievement
            }
        }
        return nil
    }
    
    private static func findAchievement(
        type: AchievementType,
        gameType: GameType,
        db: any Database
    ) async throws -> Achievement? {
        return try await Achievement.query(on: db)
            .filter(\.$type == type)
            .filter(\.$gameType == gameType)
            .first()
    }
}
