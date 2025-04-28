import Vapor
import Fluent

struct AchievementController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let usersRoute = routes.grouped("users")
        
        usersRoute.get("achievements", use: achievements)
    }
    
    func achievements(req: Request) async throws -> AchievementResponse {
        let user = try await userFromToken(req)
        let allAchievements = try await Achievement.query(on: req.db).all()
        let userAchievements = try await UserAchievement.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .all()
        let achievementsWithProgress = allAchievements.map { achievement in
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
