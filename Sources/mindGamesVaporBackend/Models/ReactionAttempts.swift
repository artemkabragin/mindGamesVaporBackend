import Vapor
import Fluent

final class ReactionAttempts: Model, Content, @unchecked Sendable {
    static let schema = "reaction_attempts"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "initial_average")
    var initialAverage: Double
    
    @Field(key: "current_average")
    var currentAverage: Double

    @Parent(key: "user_id")
    var user: User

    init() {}

    init(
        id: UUID? = nil,
        initialAverage: Double = 0,
        currentAverage: Double = 0,
        userID: User.IDValue
    ) {
        self.id = id
        self.initialAverage = initialAverage
        self.currentAverage = currentAverage
        self.$user.id = userID
    }
}
