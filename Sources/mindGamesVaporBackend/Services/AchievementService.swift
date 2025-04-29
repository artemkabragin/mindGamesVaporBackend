import Vapor
import Fluent

struct AchievementService {
    
    // MARK: - Public Methods
    
    func checkAchievements(
        for user: User,
        attempt: GameAttemptData,
        db: any Database
    ) async throws -> [UserAchievement] {
        let userAchievements = try await UserAchievement.query(on: db)
            .filter(\.$user.$id == user.requireID())
            .with(\.$achievement)
            .all()
        
        async let highScoreAchievement = try await checkOrCreateHighScore(
            for: user,
            attempt: attempt,
            userAchievements: userAchievements,
            db: db
        )
        
        async let totalPlaysAchievement = try await checkOrCreateTotalPlays(
            for: user,
            attempt: attempt,
            userAchievements: userAchievements,
            db: db
        )
        
        async let dailyStreakAchievement = try await checkOrCreateDailyStreak(
            for: user,
            attempt: attempt,
            userAchievements: userAchievements,
            db: db
        )
        
        let results: [UserAchievement?] = [
            try await highScoreAchievement,
            try await totalPlaysAchievement,
            try await dailyStreakAchievement
        ]
        return results.compactMap { $0 }
    }
}

// MARK: - Private Methods

private extension AchievementService {
    func checkOrCreateHighScore(
        for user: User,
        attempt: GameAttemptData,
        userAchievements: [UserAchievement],
        db: any Database
    ) async throws -> UserAchievement? {
        if let highScoreAchievement = userAchievements.first(where: { $0.achievement.type == .highScore && $0.achievement.gameType == attempt.gameType }) {
            // Если ачивка уже есть — обновляем её
            if attempt.attempt < (highScoreAchievement.progress == 0 ? Double.greatestFiniteMagnitude : highScoreAchievement.progress) {
                let currentDate = Date()
                highScoreAchievement.progress = attempt.attempt
                highScoreAchievement.isUnlocked = true
                highScoreAchievement.dateUnlocked = currentDate
                highScoreAchievement.dateChanged = currentDate
                try await highScoreAchievement.save(on: db)
                return highScoreAchievement
            }
        } else {
            // Если нет — создаём новую ачивку для highScore
            if let achievement = try await findAchievement(type: .highScore, gameType: attempt.gameType, db: db) {
                let currentDate = Date()
                let newUserAchievement = UserAchievement(
                    userID: try user.requireID(),
                    achievementID: try achievement.requireID(),
                    isUnlocked: true,
                    progress: attempt.attempt,
                    dateChanged: currentDate,
                    dateUnlocked: currentDate
                )
                try await newUserAchievement.save(on: db)
                return newUserAchievement
            }
        }
        
        return nil
    }
    
    func checkOrCreateTotalPlays(
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
    
    func checkOrCreateDailyStreak(
        for user: User,
        attempt: GameAttemptData,
        userAchievements: [UserAchievement],
        db: any Database
    ) async throws -> UserAchievement? {
        
        if let totalPlaysAchievement = userAchievements.first(where: { $0.achievement.type == .dailyStreak && $0.achievement.gameType == attempt.gameType }) {
            let currentDate = Date()
            let lastDate = totalPlaysAchievement.dateChanged
            
            var calendar = Calendar.current
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            
            if calendar.isDateInYesterday(lastDate) {
                totalPlaysAchievement.progress += 0.1
            } else if !calendar.isDateInToday(lastDate) {
                totalPlaysAchievement.progress = 0.1
            }
                        
            totalPlaysAchievement.dateChanged = currentDate
            if totalPlaysAchievement.progress > 0.9 && !totalPlaysAchievement.isUnlocked {
                totalPlaysAchievement.isUnlocked = true
                totalPlaysAchievement.dateUnlocked = currentDate
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
    
    func findAchievement(
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
