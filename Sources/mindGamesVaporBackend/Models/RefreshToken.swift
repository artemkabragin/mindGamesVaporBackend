import Vapor
import JWTKit
import Fluent

final class RefreshToken: Model, Content, @unchecked Sendable {
    static let schema = "refresh_tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "expires_at")
    var expiresAt: Date
    
    init() {}
    
    init(
        userID: User.IDValue,
        value: String,
        expiresAt: Date
    ) {
        self.value = value
        self.$user.id = userID
        self.expiresAt = expiresAt
    }
    
    static func generate(for user: User) throws -> RefreshToken {
        let refreshTokenValue = [UInt8].random(count: 32).base64
        let refreshToken = RefreshToken(
            userID: try user.requireID(),
            value: refreshTokenValue,
            expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 7) // week
        )
        return refreshToken
    }
}
