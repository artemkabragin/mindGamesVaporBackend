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
