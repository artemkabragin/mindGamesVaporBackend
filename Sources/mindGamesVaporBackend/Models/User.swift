import Vapor
import Fluent

final class User: Model, Content, @unchecked Sendable, Authenticatable {
    
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "passwordHash")
    var passwordHash: String
    
    @Field(key: "isOnboardingComplete")
    var isOnboardingComplete: Bool

    init() {}

    init(
        id: UUID? = nil,
        username: String,
        passwordHash: String,
        isOnboardingComplete: Bool = false
    ) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.isOnboardingComplete = isOnboardingComplete
    }
    
    func toPublic() -> User.Public {
        User.Public(
            username: username,
            isOnboardingComplete: isOnboardingComplete
        )
    }
}

extension User {
    struct Create: Content {
        let username: String
        let password: String
    }
    
    struct Login: Content {
        let username: String
        let password: String
    }
    
    struct Public: Content {
        let username: String
        let isOnboardingComplete: Bool
    }
}

extension User {
    static func findOrUnauthorized(_ id: UUID, on db: any Database) async throws -> User {
        guard let user = try await User.find(id, on: db) else {
            throw Abort(.unauthorized, reason: "User not found")
        }
        return user
    }
}
