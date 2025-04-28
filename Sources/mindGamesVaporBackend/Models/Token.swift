import Vapor
import Fluent

final class Token: Model, Content, @unchecked Sendable {
    static let schema = "tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "user_id")
    var user: User

    init() {}

    init(
        id: UUID? = nil,
        value: String,
        userID: User.IDValue
    ) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
    
    static func generate(for user: User) throws -> Token {
        let tokenString = [UInt8].random(count: 16).base64
        return Token(value: tokenString, userID: try user.requireID())
    }
}
