import Vapor
import Fluent

struct UserController: RouteCollection {
    
    let achievementService = AchievementService()
    let jwtAuthenticator = JWTAuthenticator()
    
    func boot(routes: any RoutesBuilder) throws {
        let usersRoute = routes.grouped("users").grouped(jwtAuthenticator)
        
        usersRoute.post("onboarding", use: submitOnboarding)
        usersRoute.post("play", use: submitGameAttempt)
        usersRoute.get("progress", use: getProgress)
    }
    
    func submitOnboarding(req: Request) async throws -> Double {
        let data = try req.content.decode(OnboardingData.self)
        let user = try await req.getUser()
        let initialAverage = data.attempts.reduce(0, +) / Double(data.attempts.count)
        
        switch data.gameType {
        case .cardFlip:
            let cardFlipAttempt = CardFlipAttempts(
                initialAverage: initialAverage,
                currentAverage: initialAverage,
                userID: try user.requireID()
            )
            try await cardFlipAttempt.save(on: req.db)
        case .colorMatch:
            let colorMatchAttempt = ColorMatchAttempts(
                initialAverage: initialAverage,
                currentAverage: initialAverage,
                userID: try user.requireID()
            )
            try await colorMatchAttempt.save(on: req.db)
        case .reaction:
            let reactionAttempt = ReactionAttempts(
                initialAverage: initialAverage,
                currentAverage: initialAverage,
                userID: try user.requireID()
            )
            try await reactionAttempt.save(on: req.db)
        }
        
        return initialAverage
    }

    func submitGameAttempt(req: Request) async throws -> [AchievementWithProgress] {
        let data = try req.content.decode(GameAttemptData.self)
        let user = try await req.getUser()
        
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
        
        let userAchievements = try await achievementService.checkAchievements(
            for: user,
            attempt: data,
            db: req.db
        )

        let achievementIds = userAchievements.compactMap { $0.id }

        let userAchievementsFromDb = try await UserAchievement.query(on: req.db)
            .filter(\.$id ~~ achievementIds)
            .with(\.$achievement)
            .all()
        
        let achivementsDTO = userAchievementsFromDb.map { userAchivement in
            AchievementWithProgress(
                achievement: userAchivement.achievement,
                isUnlocked: userAchivement.isUnlocked,
                progress: userAchivement.progress,
                dateUnlocked: userAchivement.dateUnlocked
            )
        }
        
        return achivementsDTO
    }
    
    func getProgress(req: Request) async throws -> ProgressResponse {
        let progressType = try req.query.get(ProgressType.self, at: "type")

        let user = try await req.getUser()
        
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
}
