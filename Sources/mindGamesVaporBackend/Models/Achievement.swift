import Fluent
import Vapor

final class Achievement: Model, Content, @unchecked Sendable {
    static let schema = "achievements"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "type")
    var type: AchievementType
    
    @Field(key: "game_type")
    var gameType: GameType

    init() { }
    
    init(
        id: UUID? = nil,
        title: String,
        description: String,
        type: AchievementType,
        gameType: GameType
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.gameType = gameType
    }
}
