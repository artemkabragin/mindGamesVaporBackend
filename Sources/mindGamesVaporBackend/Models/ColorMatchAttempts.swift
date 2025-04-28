import Vapor
import Fluent

final class ColorMatchAttempts: Model, Content, @unchecked Sendable {
    static let schema = "color_match_attempts"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "initial_average")
    var initialAverage: Double

    @Field(key: "current_average")
    var currentAverage: Double
    
    @Field(key: "attempts")
    var attempts: [Double]

    @Parent(key: "user_id")
    var user: User

    init() {}

    init(
        id: UUID? = nil,
        initialAverage: Double = 0,
        currentAverage: Double = 0,
        attempts: [Double] = [],
        userID: User.IDValue
    ) {
        self.id = id
        self.initialAverage = initialAverage
        self.currentAverage = currentAverage
        self.attempts = attempts
        self.$user.id = userID
    }
}
