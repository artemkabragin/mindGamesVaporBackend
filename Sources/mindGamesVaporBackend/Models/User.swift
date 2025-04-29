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

    init() {}

    init(id: UUID? = nil, username: String, passwordHash: String) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
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
}

extension User {
    static func findOrUnauthorized(_ id: UUID, on db: any Database) async throws -> User {
        guard let user = try await User.find(id, on: db) else {
            throw Abort(.unauthorized, reason: "User not found")
        }
        return user
    }
}
