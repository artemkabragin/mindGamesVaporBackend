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
            .filter{ $0.achievement.gameType == attempt.gameType }
        
        let tasks = AchievementType.allCases.map { type in
            Task {
                try await checkOrCreateAchievement(
                    by: type,
                    for: user,
                    attempt: attempt,
                    userAchievements: userAchievements,
                    db: db
                )
            }
        }
        
        var results: [UserAchievement] = []
        
        for task in tasks {
            if let achievement = try await task.value {
                results.append(achievement)
            }
        }
        
        return results
    }
}

// MARK: - Private Methods

private extension AchievementService {
    func checkOrCreateAchievement(
        by type: AchievementType,
        for user: User,
        attempt: GameAttemptData,
        userAchievements: [UserAchievement],
        db: any Database
    ) async throws -> UserAchievement? {
        guard let userAchievement = userAchievements.first(where: { $0.achievement.type == type }) else {
            return try await createNewUserAchievementIfPossible(
                type: type,
                for: user,
                attempt: attempt,
                db: db
            )
        }
        
        switch type {
        case .dailyStreak:
            return try await updateDailyStreakAchievement(
                userAchievement,
                db: db
            )
        case .highScore:
            return try await updateHighScoreAchievement(
                userAchievement,
                attempt: attempt,
                db: db
            )
        case .totalPlays:
            return try await updateTotalPlaysAchievement(
                userAchievement,
                db: db
            )
        case .perfectScore:
            return nil
        }
    }
    
    func updateHighScoreAchievement(
        _ userAchievement: UserAchievement,
        attempt: GameAttemptData,
        db: any Database
    ) async throws -> UserAchievement {
        let currentProgress = userAchievement.progress == 0
        ? Double.greatestFiniteMagnitude
        : userAchievement.progress
        
        guard attempt.attempt < currentProgress else { return userAchievement }
        
        let currentDate = Date()
        userAchievement.progress = attempt.attempt
        userAchievement.isUnlocked = true
        userAchievement.dateUnlocked = currentDate
        userAchievement.dateChanged = currentDate
        try await userAchievement.save(on: db)
        return userAchievement
    }
    
    func updateTotalPlaysAchievement(
        _ userAchievement: UserAchievement,
        db: any Database
    ) async throws -> UserAchievement {
        userAchievement.dateChanged = Date()
        userAchievement.progress += 0.1
        if userAchievement.progress > 0.9 && !userAchievement.isUnlocked {
            userAchievement.isUnlocked = true
            userAchievement.dateUnlocked = Date()
        }
        try await userAchievement.save(on: db)
        return userAchievement
    }
    
    func updateDailyStreakAchievement(
        _ userAchievement: UserAchievement,
        db: any Database
    ) async throws -> UserAchievement {
        let lastDate = userAchievement.dateChanged
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        if calendar.isDateInYesterday(lastDate) {
            userAchievement.progress += 0.1
        } else if !calendar.isDateInToday(lastDate) {
            userAchievement.progress = 0.1
        }
        
        let currentDate = Date()
        
        userAchievement.dateChanged = currentDate
        
        if userAchievement.progress > 0.9 && !userAchievement.isUnlocked {
            userAchievement.isUnlocked = true
            userAchievement.dateUnlocked = currentDate
        }
        try await userAchievement.save(on: db)
        return userAchievement
    }
    
    func createNewUserAchievementIfPossible(
        type: AchievementType,
        for user: User,
        attempt: GameAttemptData,
        db: any Database
    ) async throws -> UserAchievement? {
        guard let achievement = try await findAchievement(
            type: type,
            gameType: attempt.gameType,
            db: db
        ) else {
            return nil
        }
        
        let newUserAchievement = try createNewUserAchievement(
            achievement,
            for: user,
            attempt: attempt
        )
        try await newUserAchievement.save(on: db)
        return newUserAchievement
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
    
    func createNewUserAchievement(
        _ achievement: Achievement,
        for user: User,
        attempt: GameAttemptData
    ) throws -> UserAchievement {
        let progress: Double
        let isUnlocked: Bool
        
        switch achievement.type {
        case .dailyStreak:
            progress = 0.1
            isUnlocked = false
        case .perfectScore:
            // TODO: -
            progress = 0.1
            isUnlocked = false
        case .totalPlays:
            progress = 0.1
            isUnlocked = false
        case .highScore:
            progress = attempt.attempt
            isUnlocked = true
        }
        
        let currentDate = Date()
        
        let newUserAchievement = UserAchievement(
            userID: try user.requireID(),
            achievementID: try achievement.requireID(),
            isUnlocked: isUnlocked,
            progress: progress,
            dateChanged: currentDate,
            dateUnlocked: isUnlocked ? currentDate : nil
        )
        return newUserAchievement
    }
    
//    func checkOrCreatePerfectScore(
//        for user: User,
//        attempt: GameAttemptData,
//        userAchievements: [UserAchievement],
//        db: any Database
//    ) async throws -> UserAchievement? {
//        
//        if let totalPlaysAchievement = userAchievements.first(where: { $0.achievement.type == .perfectScore && $0.achievement.gameType == attempt.gameType }) {
//            let currentDate = Date()
//            let lastDate = totalPlaysAchievement.dateChanged
//            
//            var calendar = Calendar.current
//            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
//            
//            if calendar.isDateInYesterday(lastDate) {
//                totalPlaysAchievement.progress += 0.1
//            } else if !calendar.isDateInToday(lastDate) {
//                totalPlaysAchievement.progress = 0.1
//            }
//                        
//            totalPlaysAchievement.dateChanged = currentDate
//            if totalPlaysAchievement.progress > 0.9 && !totalPlaysAchievement.isUnlocked {
//                totalPlaysAchievement.isUnlocked = true
//                totalPlaysAchievement.dateUnlocked = currentDate
//            }
//            try await totalPlaysAchievement.save(on: db)
//            return totalPlaysAchievement
//        } else {
//            if let achievement = try await findAchievement(type: .perfectScore, gameType: attempt.gameType, db: db) {
//                let newUserAchievement = UserAchievement(
//                    userID: try user.requireID(),
//                    achievementID: try achievement.requireID(),
//                    isUnlocked: false,
//                    progress: 0.1,
//                    dateChanged: Date(),
//                    dateUnlocked: nil
//                )
//                try await newUserAchievement.save(on: db)
//                return newUserAchievement
//            }
//        }
//        return nil
//    }
    
    
}
