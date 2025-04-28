import Vapor
import Fluent

final class User: Model, Content, @unchecked Sendable {
    typealias IDValue = UUID
    
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "passwordHash")
    var passwordHash: String
    
    @Field(key: "initial_average")
    var initialAverage: Double
    
    @Field(key: "current_average")
    var currentAverage: Double
    
    @Field(key: "attempts")
    var attempts: [Double]

    init() {}

    init(id: UUID? = nil, username: String, passwordHash: String, initialAverage: Double = 0, currentAverage: Double = 0, attempts: [Double] = []) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.initialAverage = initialAverage
        self.currentAverage = currentAverage
        self.attempts = attempts
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
        let id: UUID?
        let username: String
    }
    
    struct Authenticated: Content {
        var user: User
        var token: String
    }
    
    func asPublic() -> Public {
        Public(id: id, username: username)
    }
}
