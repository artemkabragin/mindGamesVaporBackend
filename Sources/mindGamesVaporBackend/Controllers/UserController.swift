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
        user.initialAverage = initialAverage
        try await user.save(on: req.db)
        
        return initialAverage
    }
    
    func submitGameAttempt(req: Request) async throws -> HTTPStatus {
        let data = try req.content.decode(GameAttemptData.self)
        
        let user = try await userFromToken(req)
        
        user.attempts.append(data.attempt)
        user.currentAverage = user.attempts.reduce(0, +) / Double(user.attempts.count)
        
        try await user.save(on: req.db)
        
        return .ok
    }
    
    func getProgress(req: Request) async throws -> ProgressResponse {
        let user = try await userFromToken(req)
        let progress = ((user.initialAverage - user.currentAverage) / user.initialAverage) * 100
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


// Структура данных для онбординга
struct OnboardingData: Content {
    var attempts: [Double]
}

// Структура данных для попытки игры
struct GameAttemptData: Content {
    var attempt: Double
}

// Структура для ответа с прогрессом
struct ProgressResponse: Content {
    var progress: Double
}
