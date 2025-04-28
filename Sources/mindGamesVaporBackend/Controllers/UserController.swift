import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let usersRoute = routes.grouped("users")
        
        usersRoute.post("onboarding", use: submitOnboarding)
        usersRoute.post("play", use: submitGameAttempt)
        usersRoute.get("progress", use: getProgress)
    }
    
    func submitOnboarding(req: Request) async throws -> Double {
        let data = try req.content.decode(OnboardingData.self)
        let initialAverage = data.attempts.reduce(0, +) / Double(data.attempts.count)

        let user = try await userFromToken(req)

        let reactionAttempt = ReactionAttempts(
            initialAverage: initialAverage,
            userID: try user.requireID()
        )

        try await reactionAttempt.save(on: req.db)

        return initialAverage
    }
    
    func submitGameAttempt(req: Request) async throws -> HTTPStatus {
        let data = try req.content.decode(GameAttemptData.self)
        
        let user = try await userFromToken(req)
        
        guard let reactionAttempt = try await ReactionAttempts.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .first()
        else {
            throw Abort(.notFound, reason: "Reaction attempts not found for user")
        }
        
        reactionAttempt.attempts.append(data.attempt)
        
        reactionAttempt.currentAverage = reactionAttempt.attempts.reduce(0, +) / Double(reactionAttempt.attempts.count)
        
        try await reactionAttempt.save(on: req.db)
        
        return .ok
    }
    
    func getProgress(req: Request) async throws -> ProgressResponse {
        let gameType = try req.query.get(GameType.self, at: "gameType")

        let user = try await userFromToken(req)
        
        let progress: Double
        
        switch gameType {
        case .reaction:
            guard let reactionAttempt = try await ReactionAttempts.query(on: req.db)
                .filter(\.$user.$id == user.requireID())
                .first()
            else {
                throw Abort(.notFound, reason: "Reaction attempts not found for user")
            }
            let initialAverage = reactionAttempt.initialAverage
            let currentAverage = reactionAttempt.currentAverage
            progress = ((initialAverage - currentAverage) / initialAverage) * 100
        case .cardFlip:
            guard let cardFlipAttempt = try await CardFlipAttempts.query(on: req.db)
                .filter(\.$user.$id == user.requireID())
                .first()
            else {
                throw Abort(.notFound, reason: "CardFlip attempts not found for user")
            }
            
            guard let colorMatchAttempt = try await ColorMatchAttempts.query(on: req.db)
                .filter(\.$user.$id == user.requireID())
                .first()
            else {
                throw Abort(.notFound, reason: "ColorMatch attempts not found for user")
            }
            
            let cardFlipInitialAverage = cardFlipAttempt.initialAverage
            let cardFlipCurrentAverage = cardFlipAttempt.currentAverage
            let cardFlipProgress = ((cardFlipInitialAverage - cardFlipCurrentAverage) / cardFlipInitialAverage) * 100
            
            let colorMatchInitialAverage = colorMatchAttempt.initialAverage
            let colorMatchCurrentAverage = colorMatchAttempt.currentAverage
            let colorMatchProgress = ((colorMatchInitialAverage - colorMatchCurrentAverage) / colorMatchInitialAverage) * 100
            
            progress = (cardFlipProgress + colorMatchProgress) / 2
        case .colorMatch:
            guard let reactionAttempt = try await ColorMatchAttempts.query(on: req.db)
                .filter(\.$user.$id == user.requireID())
                .first()
            else {
                throw Abort(.notFound, reason: "ColorMatch attempts not found for user")
            }
            progress = 0
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

struct ProgressRequest: Content {
    let gameType: GameType
}
