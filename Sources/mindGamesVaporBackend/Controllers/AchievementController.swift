import Vapor
import Fluent

import Vapor

struct AchievementResponse: Content {
    var achievements: [AchievementWithProgress]
}



//struct AchievementData: Content {
//    let gameType: GameType
//    let attempts: [Double]
//}



struct AchievementController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let usersRoute = routes.grouped("users")
        
        usersRoute.get("achievement", use: achievements)
//        usersRoute.post("play", use: submitGameAttempt)
//        usersRoute.get("progress", use: getProgress)
    }
        
    func achievements(req: Request) async throws -> AchievementResponse {
        let user = try await userFromToken(req)
        let allAchievements = try await Achievement.query(on: req.db).all()
        let userAchievements = try await UserAchievement.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .all()
//        
//        let userAchievementsDict = Dictionary(
//            uniqueKeysWithValues: userAchievements.map { ($0.$achievement.id, $0) }
//        )
        
        let achievementsWithProgress = allAchievements.map { achievement in
//            let userAchievement = userAchievementsDict[achievement.id ?? UUID()]
            let userAchievement = userAchievements.first { $0.$achievement.id == achievement.id }
            
            return AchievementWithProgress(
                achievement: achievement,
                isUnlocked: userAchievement?.isUnlocked ?? false,
                progress: userAchievement?.progress ?? 0.0,
                dateUnlocked: userAchievement?.dateUnlocked
            )
        }
        
        return AchievementResponse(achievements: achievementsWithProgress)
    }

    
    func submitGameAttempt(req: Request) async throws -> HTTPStatus {
        let data = try req.content.decode(GameAttemptData.self)
        let user = try await userFromToken(req)
        
        switch data.gameType {
        case .cardFlip:
            guard let cardFlipAttempt = try await CardFlipAttempts.query(on: req.db)
                .filter(\.$user.$id == user.requireID())
                .first()
            else {
                throw Abort(.notFound, reason: "Card flip attempts not found for user")
            }
            
            cardFlipAttempt.attempts.append(data.attempt)
            
            cardFlipAttempt.currentAverage = cardFlipAttempt.attempts.reduce(0, +) / Double(cardFlipAttempt.attempts.count)
            
            try await cardFlipAttempt.save(on: req.db)
        case .colorMatch:
            guard let colorMatchAttempt = try await ColorMatchAttempts.query(on: req.db)
                .filter(\.$user.$id == user.requireID())
                .first()
            else {
                throw Abort(.notFound, reason: "Card flip attempts not found for user")
            }
            
            colorMatchAttempt.attempts.append(data.attempt)
            
            colorMatchAttempt.currentAverage = colorMatchAttempt.attempts.reduce(0, +) / Double(colorMatchAttempt.attempts.count)
            
            try await colorMatchAttempt.save(on: req.db)
        case .reaction:
            guard let reactionAttempt = try await ReactionAttempts.query(on: req.db)
                .filter(\.$user.$id == user.requireID())
                .first()
            else {
                throw Abort(.notFound, reason: "Reaction attempts not found for user")
            }
            
            reactionAttempt.attempts.append(data.attempt)
            
            reactionAttempt.currentAverage = reactionAttempt.attempts.reduce(0, +) / Double(reactionAttempt.attempts.count)
            
            try await reactionAttempt.save(on: req.db)
        }
        
        return .ok
    }
    
    func getProgress(req: Request) async throws -> ProgressResponse {
        let progressType = try req.query.get(ProgressType.self, at: "type")

        let user = try await userFromToken(req)
        
        let progress: Double
        
        switch progressType {
        case .memory:
            guard let cardFlipAttempt = try await CardFlipAttempts.query(on: req.db)
                .filter(\.$user.$id == user.requireID())
                .first()
            else {
                throw Abort(.notFound, reason: "CardFlip attempts not found for user")
            }
            
            let cardFlipInitialAverage = cardFlipAttempt.initialAverage
            let cardFlipCurrentAverage = cardFlipAttempt.currentAverage
            let cardFlipConvertedInitialValue = 100 / cardFlipInitialAverage
            let cardFlipConvertedCurrentValue = 100 / cardFlipCurrentAverage
            let cardFlipProgress = ((cardFlipConvertedCurrentValue - cardFlipConvertedInitialValue) / cardFlipConvertedInitialValue) * 100
            progress = cardFlipProgress
            
        case .attention:
            
            guard let reactionAttempt = try await ReactionAttempts.query(on: req.db)
                .filter(\.$user.$id == user.requireID())
                .first()
            else {
                throw Abort(.notFound, reason: "Reaction attempts not found for user")
            }
            let reactionInitialAverage = reactionAttempt.initialAverage
            let reactionCurrentAverage = reactionAttempt.currentAverage
            let reactionConvertedInitialValue = 100 / reactionInitialAverage
            let reactionConvertedCurrentValue = 100 / reactionCurrentAverage
            
            let reactionProgress = ((reactionConvertedCurrentValue - reactionConvertedInitialValue) / reactionConvertedInitialValue) * 100
            
            guard let colorMatchAttempt = try await ColorMatchAttempts.query(on: req.db)
                .filter(\.$user.$id == user.requireID())
                .first()
            else {
                throw Abort(.notFound, reason: "ColorMatch attempts not found for user")
            }
            
            let colorMatchInitialAverage = colorMatchAttempt.initialAverage
            let colorMatchCurrentAverage = colorMatchAttempt.currentAverage
            let colorMatchConvertedInitialValue = colorMatchInitialAverage
            let colorMatchConvertedCurrentValue = colorMatchCurrentAverage
            let colorMatchProgress = ((colorMatchConvertedCurrentValue - colorMatchConvertedInitialValue) / colorMatchConvertedInitialValue) * 100
            progress = (reactionProgress + colorMatchProgress) / 2
        }
        
        return ProgressResponse(progress: progress)
    }
    
    private func userFromToken(_ req: Request) async throws -> User {
        guard let tokenValue = req.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing or invalid Authorization token")
        }
        
        guard let token = try await Token.query(on: req.db)
            .filter(\.$value == tokenValue)
            .with(\.$user)
            .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid token or user not found")
        }
        
        return token.user
    }
}
